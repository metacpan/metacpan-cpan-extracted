package Langertha::Knarr::Proxy::Ollama;
our $VERSION = '0.007';
# ABSTRACT: Ollama native API format proxy handler
use strict;
use warnings;
use JSON::MaybeXS qw( encode_json decode_json );
use Time::HiRes qw( time );
use Langertha::Knarr::Input;
use Langertha::Knarr::Output;


sub format_name { 'ollama' }

sub passthrough_format { undef }

sub streaming_content_type { 'application/x-ndjson' }

sub extract_model {
  my ($class, $body) = @_;
  return $body->{model} // 'default';
}

sub extract_stream {
  my ($class, $body) = @_;
  # Ollama streams by default, unless explicitly set to false
  return defined $body->{stream} ? ($body->{stream} ? 1 : 0) : 1;
}

sub extract_messages {
  my ($class, $body) = @_;
  return $body->{messages} // [];
}

sub extract_params {
  my ($class, $body) = @_;
  my %params;
  if (my $opts = $body->{options}) {
    $params{temperature} = $opts->{temperature} if defined $opts->{temperature};
    $params{num_predict} = $opts->{num_predict} if defined $opts->{num_predict};
    $params{top_p}       = $opts->{top_p}       if defined $opts->{top_p};
  }
  $params{tools}       = $body->{tools}        if defined $body->{tools};
  $params{tool_choice} = $body->{tool_choice}  if defined $body->{tool_choice};
  return \%params;
}

sub prepare_engine_messages {
  my ($class, $engine, $messages, $params) = @_;
  return $messages unless $engine;

  if ($engine->isa('Langertha::Engine::OpenAIBase')) {
    my @out;
    for my $msg (@{$messages || []}) {
      next unless ref($msg) eq 'HASH';
      my %m = %$msg;
      $m{content} = _ollama_content_to_text($m{content}) if ref($m{content});
      if (($m{role} // '') eq 'assistant' && ref($m{tool_calls}) eq 'ARRAY') {
        for my $tc (@{$m{tool_calls}}) {
          next unless ref($tc) eq 'HASH';
          next unless ref($tc->{function}) eq 'HASH';
          my $args = $tc->{function}{arguments};
          if (ref($args) eq 'HASH') {
            my $encoded = eval { encode_json($args) };
            $tc->{function}{arguments} = $@ ? '{}' : $encoded;
          }
        }
      }
      push @out, \%m;
    }
    return \@out;
  }

  if ($engine->isa('Langertha::Engine::AnthropicBase')) {
    my @out;
    for my $msg (@{$messages || []}) {
      next unless ref($msg) eq 'HASH';
      my $role = $msg->{role} // '';
      my $content = $msg->{content};

      if ($role eq 'system' || $role eq 'user') {
        push @out, {
          role    => $role,
          content => ref($content) ? _ollama_content_to_text($content) : ($content // ''),
        };
        next;
      }

      if ($role eq 'assistant') {
        my @blocks;
        my $text = ref($content) ? _ollama_content_to_text($content) : ($content // '');
        push @blocks, { type => 'text', text => $text } if length $text;

        if (ref($msg->{tool_calls}) eq 'ARRAY') {
          for my $tc (@{$msg->{tool_calls}}) {
            next unless ref($tc) eq 'HASH';
            my $fn = $tc->{function} || {};
            my $input = {};
            my $args = $fn->{arguments};
            if (ref($args) eq 'HASH') {
              $input = $args;
            } elsif (defined $args && length $args) {
              my $decoded = eval { decode_json($args) };
              $input = $decoded if ref($decoded) eq 'HASH';
            }
            push @blocks, {
              type  => 'tool_use',
              id    => ($tc->{id} // ('toolu_knarr_' . int(rand(1000000)))),
              name  => ($fn->{name} // 'tool'),
              input => $input,
            };
          }
        }

        push @out, { role => 'assistant', content => (@blocks ? \@blocks : '') };
        next;
      }

      if ($role eq 'tool') {
        my $tool_text = ref($content) ? _ollama_content_to_text($content) : ($content // '');
        push @out, {
          role => 'user',
          content => [{
            type        => 'tool_result',
            tool_use_id => ($msg->{tool_call_id} // ''),
            content     => $tool_text,
          }],
        };
        next;
      }

      push @out, {
        role    => $role || 'user',
        content => ref($content) ? _ollama_content_to_text($content) : ($content // ''),
      };
    }
    return \@out;
  }

  return $messages;
}

sub prepare_engine_params {
  my ($class, $engine, $params, $messages) = @_;
  return $params unless $engine;

  my %p = %{$params || {}};
  if (defined $p{num_predict} && !defined $p{max_tokens}) {
    $p{max_tokens} = delete $p{num_predict};
  } else {
    delete $p{num_predict};
  }

  if ($engine->isa('Langertha::Engine::OpenAIBase')) {
    if (ref($p{tools}) eq 'ARRAY') {
      my $canonical = Langertha::Knarr::Input->normalize_tools($p{tools});
      $p{tools} = Langertha::Knarr::Input->to_openai_tools($canonical);
    }

    if (defined $p{tool_choice}) {
      my $canonical_tc = Langertha::Knarr::Input->normalize_tool_choice($p{tool_choice});
      if ($canonical_tc) {
        $p{tool_choice} = Langertha::Knarr::Input->to_openai_tool_choice($canonical_tc);
      }
      if (!defined $p{tool_choice}) {
        delete $p{tool_choice};
      }
    }

    return \%p;
  }

  if ($engine->isa('Langertha::Engine::AnthropicBase')) {
    if (ref($p{tools}) eq 'ARRAY') {
      my $canonical = Langertha::Knarr::Input->normalize_tools($p{tools});
      $p{tools} = Langertha::Knarr::Input->to_anthropic_tools($canonical);
    }

    if (defined $p{tool_choice}) {
      my $canonical_tc = Langertha::Knarr::Input->normalize_tool_choice($p{tool_choice});
      if ($canonical_tc) {
        $p{tool_choice} = Langertha::Knarr::Input->to_anthropic_tool_choice($canonical_tc);
      }
      if (!defined $p{tool_choice}) {
        delete $p{tool_choice};
      }
    }

    return \%p;
  }

  return \%p;
}

sub format_response {
  my ($class, $result, $model) = @_;
  my $content = "$result";

  my %response = (
    model           => $model,
    created_at      => _iso_timestamp(),
    message         => { role => 'assistant', content => $content },
    done            => JSON::MaybeXS->true,
    done_reason     => 'stop',
  );

  if (ref $result && $result->isa('Langertha::Response') && $result->has_usage) {
    $response{prompt_eval_count} = $result->prompt_tokens;
    $response{eval_count}        = $result->completion_tokens;
    $response{model} = $result->model if $result->has_model;
  }

  if (ref $result && $result->isa('Langertha::Response') && $result->has_raw) {
    my $raw = $result->raw;
    if (ref($raw) eq 'HASH') {
      my $meta = Langertha::Knarr::Output->extract_from_raw($raw);
      $response{message}{content} = $meta->{text} if defined $meta->{text};
      if (ref($meta->{tool_calls}) eq 'ARRAY' && @{$meta->{tool_calls}}) {
        $response{message}{tool_calls} = Langertha::Knarr::Output->to_ollama_tool_calls($meta->{tool_calls});
        $response{done_reason} = $meta->{finish_reason} // 'tool_calls';
      } elsif (defined $meta->{finish_reason}) {
        $response{done_reason} = $meta->{finish_reason};
      }
    }
  }

  if (!ref($response{message}{tool_calls}) || !@{$response{message}{tool_calls}}) {
    my ($clean, $calls) = Langertha::Knarr::Output->parse_hermes_calls_from_text($response{message}{content} // '');
    if (@$calls) {
      $response{message}{content} = $clean;
      $response{message}{tool_calls} = Langertha::Knarr::Output->to_ollama_tool_calls($calls);
      $response{done_reason} = 'tool_calls';
    }
  }

  return \%response;
}

sub format_stream_chunk {
  my ($class, $chunk, $model) = @_;

  my %data = (
    model      => $model,
    created_at => _iso_timestamp(),
    message    => { role => 'assistant', content => $chunk->content },
    done       => $chunk->is_final ? JSON::MaybeXS->true : JSON::MaybeXS->false,
  );

  if ($chunk->is_final) {
    $data{done_reason} = 'stop';
    if ($chunk->can('usage') && $chunk->usage) {
      $data{prompt_eval_count} = $chunk->usage->{input} // $chunk->usage->{prompt_tokens} // 0;
      $data{eval_count}        = $chunk->usage->{output} // $chunk->usage->{completion_tokens} // 0;
    }
  }

  my $json = encode_json(\%data);
  return ["$json\n"];
}

sub stream_end_marker { undef }

sub format_error {
  my ($class, $message, $type) = @_;
  return { error => $message };
}

sub format_models_response {
  my ($class, $models) = @_;
  return {
    models => [map {{
      name       => $_->{id},
      model      => $_->{id},
      modified_at => '2024-01-01T00:00:00Z',
      size       => 0,
      digest     => '',
      details    => {
        parent_model       => '',
        format             => 'gguf',
        family             => $_->{engine} // 'unknown',
        parameter_size     => '',
        quantization_level => '',
      },
    }} @$models],
  };
}

sub _iso_timestamp {
  my @t = gmtime;
  return sprintf('%04d-%02d-%02dT%02d:%02d:%02d.%03dZ',
    $t[5]+1900, $t[4]+1, $t[3], $t[2], $t[1], $t[0], 0);
}

sub _ollama_content_to_text {
  my ($content) = @_;
  return '' unless defined $content;
  return "$content" unless ref($content);
  if (ref($content) eq 'ARRAY') {
    my @parts;
    for my $block (@$content) {
      next unless ref($block) eq 'HASH';
      my $type = $block->{type} // '';
      if ($type eq 'text' || $type eq 'input_text') {
        push @parts, ($block->{text} // '');
      }
    }
    return join('', @parts);
  }
  return '';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Proxy::Ollama - Ollama native API format proxy handler

=head1 VERSION

version 0.007

=head1 DESCRIPTION

Handles the Ollama native API format for L<Langertha::Knarr>.

Routes handled:

=over

=item * C<POST /api/chat> — chat (streaming by default unless C<stream: false>)

=item * C<GET /api/tags> — model list

=item * C<GET /api/ps> — running models (always returns empty list)

=back

Streaming uses NDJSON (newline-delimited JSON). There is no separate end
marker — the final chunk includes C<"done": true>. Ollama requests are never
passed through to an upstream server (C<passthrough_format> returns C<undef>).

=head1 SEE ALSO

=over

=item * L<Langertha::Knarr> — Main documentation

=item * L<Langertha::Knarr::Proxy::OpenAI> — OpenAI format handler

=item * L<Langertha::Knarr::Proxy::Anthropic> — Anthropic format handler

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-knarr/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
