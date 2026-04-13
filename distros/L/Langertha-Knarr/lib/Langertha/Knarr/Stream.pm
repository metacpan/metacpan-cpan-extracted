package Langertha::Knarr::Stream;
# ABSTRACT: Async chunk iterator returned by streaming Knarr handlers
our $VERSION = '1.001';
use Moose;
use Future;


# Two ways to construct:
#  1) generator => sub { ... }     — sync coderef returning next string or undef
#  2) source    => sub { ... }     — coderef returning a Future[string|undef]
has generator => ( is => 'ro', isa => 'Maybe[CodeRef]' );
has source    => ( is => 'ro', isa => 'Maybe[CodeRef]' );

sub next_chunk_f {
  my ($self) = @_;
  if ( my $g = $self->generator ) {
    my $v = $g->();
    return Future->done($v);
  }
  if ( my $s = $self->source ) {
    return $s->();
  }
  return Future->done(undef);
}

# Convenience: build a stream from a fixed list of chunks
sub from_list {
  my ($class, @chunks) = @_;
  my @queue = @chunks;
  return $class->new( generator => sub { @queue ? shift @queue : undef } );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Stream - Async chunk iterator returned by streaming Knarr handlers

=head1 VERSION

version 1.001

=head1 SYNOPSIS

    use Langertha::Knarr::Stream;

    # From a fixed list of strings
    my $stream = Langertha::Knarr::Stream->from_list('hel', 'lo');

    # From a sync generator
    my @parts = ('hel', 'lo');
    my $stream = Langertha::Knarr::Stream->new(
        generator => sub { @parts ? shift @parts : undef },
    );

    # From a future-yielding source (real async)
    my $stream = Langertha::Knarr::Stream->new(
        source => sub { $next_chunk_future },
    );

    # Drain it
    while ( defined( my $chunk = $stream->next_chunk_f->get ) ) {
        print $chunk;
    }

=head1 DESCRIPTION

The chunk iterator that streaming Knarr handlers return. Supports two
construction modes: a sync C<generator> coderef that returns the next
chunk string each call (or C<undef> for end), or a C<source> coderef
that returns a L<Future> resolving to the next chunk string. The
Future form is the one real async backends like L<Net::Async::HTTP>
use; the generator form is for tests and simple cases.

=head2 generator

Optional. CodeRef returning the next chunk synchronously.

=head2 source

Optional. CodeRef returning a L<Future> that resolves to the next
chunk.

=head2 next_chunk_f

Returns a L<Future> resolving to the next chunk string, or C<undef>
when the stream is exhausted.

=head2 from_list

    my $stream = Langertha::Knarr::Stream->from_list(@chunks);

Convenience constructor that builds a stream from a fixed list of
chunk strings.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-knarr/issues>.

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
