package Langertha::Knarr::Proxy::OpenAI;
our $VERSION = '0.007';
# ABSTRACT: OpenAI API format proxy handler
use strict;
use warnings;
use JSON::MaybeXS qw( encode_json decode_json );
use Time::HiRes qw( time );
use Langertha::Knarr::Input;
use Langertha::Knarr::Output;


sub format_name { 'openai' }

sub passthrough_format { 'openai' }

sub streaming_content_type { 'text/event-stream' }

sub extract_model {
  my ($class, $body) = @_;
  return $body->{model} // 'default';
}

sub extract_stream {
  my ($class, $body) = @_;
  return $body->{stream} ? 1 : 0;
}

sub extract_messages {
  my ($class, $body) = @_;
  return $body->{messages} // [];
}

sub extract_params {
  my ($class, $body) = @_;
  my %params;
  $params{temperature}  = $body->{temperature}  if defined $body->{temperature};
  $params{max_tokens}   = $body->{max_tokens}    if defined $body->{max_tokens};
  $params{top_p}        = $body->{top_p}         if defined $body->{top_p};
  $params{stream}       = $body->{stream}        if defined $body->{stream};
  $params{input}        = $body->{input}         if defined $body->{input};
  $params{tools}        = $body->{tools}         if defined $body->{tools};
  $params{tool_choice}  = $body->{tool_choice}   if defined $body->{tool_choice};
  return \%params;
}

sub prepare_engine_messages {
  my ($class, $engine, $messages, $params) = @_;
  return $messages unless $engine && $engine->isa('Langertha::Engine::AnthropicBase');

  my @out;
  for my $msg (@{$messages || []}) {
    next unless ref($msg) eq 'HASH';
    my $role = $msg->{role} // '';
    my $content = $msg->{content};

    if ($role eq 'system' || $role eq 'user') {
      push @out, {
        role    => $role,
        content => ref($content) ? _openai_content_to_text($content) : ($content // ''),
      };
      next;
    }

    if ($role eq 'assistant') {
      my @blocks;
      my $text = ref($content) ? _openai_content_to_text($content) : ($content // '');
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

      if (@blocks) {
        push @out, { role => 'assistant', content => \@blocks };
      } else {
        push @out, { role => 'assistant', content => '' };
      }
      next;
    }

    if ($role eq 'tool') {
      my $tool_text = ref($content) ? _openai_content_to_text($content) : ($content // '');
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
      content => ref($content) ? _openai_content_to_text($content) : ($content // ''),
    };
  }

  return \@out;
}

sub prepare_engine_params {
  my ($class, $engine, $params, $messages) = @_;
  return $params unless $engine && $engine->isa('Langertha::Engine::AnthropicBase');

  my %p = %{$params || {}};

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

sub format_response {
  my ($class, $result, $model) = @_;
  my $content = "$result";
  my $id = 'chatcmpl-knarr-' . int(time * 1000);

  my %response = (
    id      => $id,
    object  => 'chat.completion',
    created => int(time),
    model   => $model,
    choices => [{
      index         => 0,
      message       => { role => 'assistant', content => $content },
      finish_reason => 'stop',
    }],
  );

  if (ref $result && $result->isa('Langertha::Response')) {
    if ($result->has_usage) {
      $response{usage} = {
        prompt_tokens     => $result->prompt_tokens,
        completion_tokens => $result->completion_tokens,
        total_tokens      => $result->total_tokens,
      };
    }
    $response{model} = $result->model if $result->has_model;

    if ($result->has_raw) {
      my $raw = $result->raw;
      if (ref($raw) eq 'HASH') {
        my $meta = Langertha::Knarr::Output->extract_from_raw($raw);
        $response{choices}[0]{message}{content} = $meta->{text} if defined $meta->{text};
        if (ref($meta->{tool_calls}) eq 'ARRAY' && @{$meta->{tool_calls}}) {
          $response{choices}[0]{message}{tool_calls}
            = Langertha::Knarr::Output->to_openai_tool_calls($meta->{tool_calls});
          $response{choices}[0]{finish_reason} = 'tool_calls';
        }
      }
    }
  }

  if (!ref($response{choices}[0]{message}{tool_calls}) || !@{$response{choices}[0]{message}{tool_calls}}) {
    my ($clean, $calls) = Langertha::Knarr::Output->parse_hermes_calls_from_text(
      $response{choices}[0]{message}{content} // ''
    );
    if (@$calls) {
      $response{choices}[0]{message}{content} = $clean;
      $response{choices}[0]{message}{tool_calls}
        = Langertha::Knarr::Output->to_openai_tool_calls($calls);
      $response{choices}[0]{finish_reason} = 'tool_calls';
    }
  }

  return \%response;
}

sub format_stream_chunk {
  my ($class, $chunk, $model) = @_;
  my $id = 'chatcmpl-knarr-' . int(time * 1000);

  my %data = (
    id      => $id,
    object  => 'chat.completion.chunk',
    created => int(time),
    model   => $model,
    choices => [{
      index => 0,
      delta => { content => $chunk->content },
      finish_reason => $chunk->is_final ? 'stop' : undef,
    }],
  );

  my $json = encode_json(\%data);
  return ["data: $json\n\n"];
}

sub stream_end_marker { "data: [DONE]\n\n" }

sub format_error {
  my ($class, $message, $type) = @_;
  return {
    error => {
      message => $message,
      type    => $type // 'server_error',
    },
  };
}

sub format_models_response {
  my ($class, $models) = @_;
  return {
    object => 'list',
    data   => [map {{
      id       => $_->{id},
      object   => 'model',
      created  => int(time),
      owned_by => 'knarr:' . ($_->{engine} // 'unknown'),
    }} @$models],
  };
}

sub _openai_content_to_text {
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

Langertha::Knarr::Proxy::OpenAI - OpenAI API format proxy handler

=head1 VERSION

version 0.007

=head1 DESCRIPTION

Handles the OpenAI Chat Completions API format for L<Langertha::Knarr>.

Routes handled:

=over

=item * C<POST /v1/chat/completions> — chat completions (streaming and non-streaming)

=item * C<POST /v1/embeddings> — embeddings

=item * C<GET /v1/models> — model list

=back

Streaming uses SSE (Server-Sent Events) with C<data: [DONE]> as the end marker.
Passthrough format name is C<openai>, forwarding to C<https://api.openai.com>
when passthrough is enabled.

=head1 SEE ALSO

=over

=item * L<Langertha::Knarr> — Main documentation

=item * L<Langertha::Knarr::Proxy::Anthropic> — Anthropic format handler

=item * L<Langertha::Knarr::Proxy::Ollama> — Ollama format handler

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
