package Langertha::Stream;
# ABSTRACT: Iterator for streaming responses
our $VERSION = '0.304';
use Moose;
use namespace::autoclean;
use Carp qw( croak );


has chunks => (
  is => 'ro',
  isa => 'ArrayRef[Langertha::Stream::Chunk]',
  required => 1,
);


has _position => (
  is => 'rw',
  isa => 'Int',
  default => 0,
);

sub next {
  my ($self) = @_;
  my $pos = $self->_position;
  return undef if $pos >= scalar @{$self->chunks};
  $self->_position($pos + 1);
  return $self->chunks->[$pos];
}


sub has_next {
  my ($self) = @_;
  return $self->_position < scalar @{$self->chunks};
}


sub collect {
  my ($self) = @_;
  my @remaining;
  while (my $chunk = $self->next) {
    push @remaining, $chunk;
  }
  return @remaining;
}


sub content {
  my ($self) = @_;
  return join('', map { $_->content } @{$self->chunks});
}


sub each {
  my ($self, $callback) = @_;
  croak "each() requires a callback" unless ref $callback eq 'CODE';
  while (my $chunk = $self->next) {
    $callback->($chunk);
  }
}


sub reset {
  my ($self) = @_;
  $self->_position(0);
}



__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Stream - Iterator for streaming responses

=head1 VERSION

version 0.304

=head1 SYNOPSIS

    my $stream = $engine->simple_chat_stream_iterator('Tell me a story');

    # Iterate chunk by chunk
    while (my $chunk = $stream->next) {
        print $chunk->content;
    }

    # Or use the callback form
    $stream->reset;
    $stream->each(sub {
        my ($chunk) = @_;
        print $chunk->content;
    });

    # Collect all remaining chunks
    my @chunks = $stream->collect;

    # Get complete content as a string
    my $full_text = $stream->content;

=head1 DESCRIPTION

An iterator object wrapping an array of L<Langertha::Stream::Chunk> objects
returned from a streaming LLM response. Created by
L<Langertha::Role::Chat/simple_chat_stream_iterator>.

The iterator maintains a position cursor so you can step through chunks one
at a time with C<next>, consume them all with C<collect> or C<each>, and
start over with C<reset>.

=head2 chunks

ArrayRef of L<Langertha::Stream::Chunk> objects comprising the full streaming
response. Required.

=head2 next

    while (my $chunk = $stream->next) {
        print $chunk->content;
    }

Returns the next L<Langertha::Stream::Chunk> and advances the cursor, or
C<undef> when all chunks have been consumed.

=head2 has_next

    if ($stream->has_next) { ... }

Returns true if there are more chunks to iterate over.

=head2 collect

    my @chunks = $stream->collect;

Returns all remaining chunks as a list and advances the cursor to the end.

=head2 content

    my $text = $stream->content;

Returns the concatenated C<content> of all chunks in the stream as a single
string, regardless of the current cursor position.

=head2 each

    $stream->each(sub {
        my ($chunk) = @_;
        print $chunk->content;
    });

Iterates over all remaining chunks, calling C<$callback> with each
L<Langertha::Stream::Chunk>. Dies if no callback is provided.

=head2 reset

    $stream->reset;

Resets the cursor to the beginning so the stream can be iterated again.

=head1 SEE ALSO

=over

=item * L<Langertha::Stream::Chunk> - A single streaming chunk

=item * L<Langertha::Role::Chat> - Provides C<simple_chat_stream_iterator> that returns this object

=item * L<Langertha::Role::Streaming> - Stream parsing (SSE / NDJSON)

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
