package Langertha::Role::Streaming;
# ABSTRACT: Role for streaming support
our $VERSION = '0.402';
use Moose::Role;

requires qw(
  json
  parse_stream_chunk
  stream_format
);

use Langertha::Stream;
use Langertha::Stream::Chunk;


sub parse_sse_line {
  my ($self, $line) = @_;

  return undef if !defined $line || $line eq '';
  return undef if $line =~ /^:\s*/; # SSE comment

  if ($line =~ /^data:\s*(.*)$/) {
    my $data = $1;
    return { type => 'done' } if $data eq '[DONE]';
    return undef if $data eq '';
    return { type => 'data', data => $self->json->decode($data) };
  }

  if ($line =~ /^event:\s*(.*)$/) {
    return { type => 'event', event => $1 };
  }

  return undef;
}


sub parse_ndjson_line {
  my ($self, $line) = @_;

  return undef if !defined $line || $line eq '';

  my $data = $self->json->decode($line);
  return { type => 'data', data => $data };
}


sub process_stream_data {
  my ($self, $data, $chunk_callback) = @_;

  my @chunks;
  my $format = $self->stream_format;
  my $buffer = '';
  my $current_event = undef;

  my @lines = split /\r?\n/, $data;

  for my $line (@lines) {
    if ($format eq 'sse') {
      if ($line eq '') {
        # Empty line marks end of SSE event
        next;
      }

      my $parsed = $self->parse_sse_line($line);
      next unless $parsed;

      if ($parsed->{type} eq 'event') {
        $current_event = $parsed->{event};
      } elsif ($parsed->{type} eq 'done') {
        # Stream complete
        last;
      } elsif ($parsed->{type} eq 'data') {
        my $chunk = $self->parse_stream_chunk($parsed->{data}, $current_event);
        if ($chunk) {
          push @chunks, $chunk;
          $chunk_callback->($chunk) if $chunk_callback;
        }
        $current_event = undef;
      }
    } elsif ($format eq 'ndjson') {
      next if $line eq '';

      my $parsed = $self->parse_ndjson_line($line);
      next unless $parsed && $parsed->{type} eq 'data';

      my $chunk = $self->parse_stream_chunk($parsed->{data});
      if ($chunk) {
        push @chunks, $chunk;
        $chunk_callback->($chunk) if $chunk_callback;
      }
    }
  }

  return \@chunks;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::Streaming - Role for streaming support

=head1 VERSION

version 0.402

=head1 SYNOPSIS

    # Synchronous streaming via Role::HTTP
    my $chunks = $engine->execute_streaming_request($request, sub {
        my ($chunk) = @_;
        print $chunk->content;
    });

    # Streaming with iterator
    my $stream = $engine->simple_chat_stream_iterator('Tell me a story');
    while (my $chunk = $stream->next) {
        print $chunk->content;
    }

=head1 DESCRIPTION

Provides stream parsing for server-sent events (SSE) and newline-delimited JSON
(NDJSON) streaming responses from LLM APIs. Engines composing this role must
implement C<parse_stream_chunk> and C<stream_format>. Works together with
L<Langertha::Role::HTTP> for synchronous streaming and L<Langertha::Role::Chat>
for the higher-level streaming API.

=head2 parse_sse_line

    my $parsed = $engine->parse_sse_line($line);

Parses a single Server-Sent Events line. Returns C<undef> for empty lines and
SSE comments. Returns a HashRef with C<type> set to C<'done'>, C<'data'>, or
C<'event'>. Data lines have their JSON decoded under the C<data> key.

=head2 parse_ndjson_line

    my $parsed = $engine->parse_ndjson_line($line);

Parses a single newline-delimited JSON line. Returns C<undef> for empty lines.
Returns a HashRef with C<type =E<gt> 'data'> and the decoded C<data>.

=head2 process_stream_data

    my $chunks = $engine->process_stream_data($raw_body, $chunk_callback);
    my $chunks = $engine->process_stream_data($raw_body);

Parses a complete streaming response body according to the engine's
C<stream_format> (C<'sse'> or C<'ndjson'>). Calls C<parse_stream_chunk> on
each data event and optionally calls C<$chunk_callback> with each resulting
L<Langertha::Stream::Chunk>. Returns an ArrayRef of all chunks.

=head1 SEE ALSO

=over

=item * L<Langertha::Role::Chat> - Chat streaming methods (uses this role)

=item * L<Langertha::Role::HTTP> - HTTP execution of streaming requests

=item * L<Langertha::Stream> - Stream iterator object

=item * L<Langertha::Stream::Chunk> - Individual stream chunk

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
