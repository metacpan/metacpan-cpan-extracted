package Langertha::Knarr::Proxy::Ollama;
our $VERSION = '0.004';
# ABSTRACT: Ollama native API format proxy handler
use strict;
use warnings;
use JSON::MaybeXS qw( encode_json );
use Time::HiRes qw( time );


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
  return \%params;
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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Proxy::Ollama - Ollama native API format proxy handler

=head1 VERSION

version 0.004

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
