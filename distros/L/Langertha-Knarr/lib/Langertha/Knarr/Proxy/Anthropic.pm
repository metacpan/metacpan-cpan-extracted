package Langertha::Knarr::Proxy::Anthropic;
our $VERSION = '0.004';
# ABSTRACT: Anthropic Messages API format proxy handler
use strict;
use warnings;
use JSON::MaybeXS qw( encode_json );
use Time::HiRes qw( time );


sub format_name { 'anthropic' }

sub passthrough_format { 'anthropic' }

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
  my @messages;
  if ($body->{system}) {
    push @messages, { role => 'system', content => $body->{system} };
  }
  push @messages, @{$body->{messages} // []};
  return \@messages;
}

sub extract_params {
  my ($class, $body) = @_;
  my %params;
  $params{max_tokens}   = $body->{max_tokens}   if defined $body->{max_tokens};
  $params{temperature}  = $body->{temperature}  if defined $body->{temperature};
  $params{top_p}        = $body->{top_p}        if defined $body->{top_p};
  $params{stream}       = $body->{stream}       if defined $body->{stream};
  return \%params;
}

sub format_response {
  my ($class, $result, $model) = @_;
  my $content = "$result";
  my $id = 'msg-knarr-' . int(time * 1000);

  my %response = (
    id      => $id,
    type    => 'message',
    role    => 'assistant',
    model   => $model,
    content => [{
      type => 'text',
      text => $content,
    }],
    stop_reason => 'end_turn',
  );

  if (ref $result && $result->isa('Langertha::Response') && $result->has_usage) {
    $response{usage} = {
      input_tokens  => $result->prompt_tokens,
      output_tokens => $result->completion_tokens,
    };
    $response{model} = $result->model if $result->has_model;
  }

  return \%response;
}

sub format_stream_chunk {
  my ($class, $chunk, $model) = @_;
  my @lines;

  if ($chunk->content ne '') {
    my %data = (
      type  => 'content_block_delta',
      index => 0,
      delta => {
        type => 'text_delta',
        text => $chunk->content,
      },
    );
    my $json = encode_json(\%data);
    push @lines, "event: content_block_delta\ndata: $json\n\n";
  }

  if ($chunk->is_final) {
    my %stop_data = (
      type  => 'message_delta',
      delta => { stop_reason => 'end_turn' },
    );
    if ($chunk->can('usage') && $chunk->usage) {
      $stop_data{usage} = {
        output_tokens => $chunk->usage->{output} // $chunk->usage->{completion_tokens} // 0,
      };
    }
    my $stop_json = encode_json(\%stop_data);
    push @lines, "event: message_delta\ndata: $stop_json\n\n";
  }

  return \@lines;
}

sub stream_end_marker { "event: message_stop\ndata: {}\n\n" }

sub format_error {
  my ($class, $message, $type) = @_;
  return {
    type  => 'error',
    error => {
      type    => $type // 'server_error',
      message => $message,
    },
  };
}

sub format_models_response {
  my ($class, $models) = @_;
  return {
    data    => [map {{
      id           => $_->{id},
      type         => 'model',
      display_name => $_->{id},
      created_at   => '2024-01-01T00:00:00Z',
    }} @$models],
    has_more => JSON::MaybeXS->false,
    first_id => $models->[0]{id},
    last_id  => $models->[-1]{id},
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Proxy::Anthropic - Anthropic Messages API format proxy handler

=head1 VERSION

version 0.004

=head1 DESCRIPTION

Handles the Anthropic Messages API format for L<Langertha::Knarr>.

Routes handled:

=over

=item * C<POST /v1/messages> — chat completions (streaming and non-streaming)

=back

The Anthropic format extracts an optional C<system> field from the request body
and prepends it to the messages list as a C<system> role message. Streaming
uses SSE with C<event: message_stop> as the end marker. Passthrough format name
is C<anthropic>, forwarding to C<https://api.anthropic.com> when passthrough
is enabled.

=head1 SEE ALSO

=over

=item * L<Langertha::Knarr> — Main documentation

=item * L<Langertha::Knarr::Proxy::OpenAI> — OpenAI format handler

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
