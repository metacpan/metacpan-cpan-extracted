package Math::RngStream;

our $VERSION = '0.01';

use strict;
use warnings;

require XSLoader;
XSLoader::load('Math::RngStream', $VERSION);

my $counter = 0;

sub new {
    my $class = shift;
    push @_, "rngstream-".$counter++ unless @_;
    $class->_create_stream(@_);
}


1;
__END__

=head1 NAME

Math::RngStream - Perl wrapper for the RngStreams library

=head1 SYNOPSIS

    use Math::RngStream;

    my $rs = Math::RngStream->new;
    my $n = $rs->rand;
    my $int = $rs->rand_int(10, 20);

=head1 DESCRIPTION

This module wraps the RngStreams library, a package for generating
multiple independent streams of pseudo-random numbers.

=head2 API

This package has an object oriented interface:

=over 4

=item Math::RngStream->set_package_seed($s0, $s1, $s2, $s3, $s4, $s5)

Sets the initial seed of the package RngStreams to the six integers
passed as arguments.

This will be the seed (initial state) of the first stream. If this
procedure is not called, the default initial seed is (12345, 12345,
12345, 12345, 12345, 12345).

The first 3 values of the seed must all be less than 4294967087, and
not all 0; and the last 3 values must all be less than 4294944443, and
not all 0.

=item Math::RngStream->new

=item Math::RngStream->new($name)

Creates a new stream with identifier $name.

its seed is equal to the initial seed of the package given by
set_package_seed if this is the first stream created, otherwise it is
Z steps ahead of that of the most recently created stream.

=item $rngs->reset_start_stream

Reinitializes the stream to its initial state.

=item $rngs->reset_start_substream

Reinitializes the stream to the beginning of its current substream.

=item $rngs->reset_next_substream

Reinitializes the stream to the beginning of its next substream.

=item $rngs->set_antithetic($anti)

If $anti!=0, the stream will start generating antithetic variates,
i.e., 1-U instead of U, until this method is called again with
$anti=0.

By default, the streams are created with $anti=0.

=item $rngs->set_increased_precis($incp)

After calling this procedure with $incp != 0, each call (direct or
indirect) to method C<rand> will advance the state of the stream by 2
steps instead of 1, and will return a number with (roughly) 53 bits of
precision instead of 32 bits.

=item $rngs->set_seed($s0, $s1, $s2, $s3, $s4, $s5)

Sets the initial seed of the stream. The arguments must satisfy the
same conditions as for method C<set_package_seed>.

Usage of this method is discouraged!

=item $rngs->advance_state($e, $c)

Advances the state of stream by $k values, without modifying the
states of other streams, nor the values of Bg and Ig associated with
this stream. If $e>0, then $k=2^$e+$c; if $e<0, then $k=-2^-$e+$c; and
if $e=0, then $k=$c. Note: $c is allowed to take negative values.

Usage of this method is discouraged!

=item @seed = $rngs->get_state

Returns the current state of the stream. This is convenient if we want
to save the state for subsequent use.

=item $rngs->rand

=item $rngs->rand_u01

Returns a (pseudo)random number from the uniform distribution over the
interval (0,1), after advancing the state by one step.  The returned
number has 32 bits of precision in the sense that it is always a
multiple of 1/(2^32-208), unless C<set_increased_precis> has been
called for this stream.

=item $rngs->rand_int($low, $high)

Returns a (pseudo)random number from the discrete uniform distribution
over the integers ($low, $low+1, ..., $high). Makes one call to method
C<rand_u01>.

=back

=head1 SEE ALSO

RngStreams website and documentation:
L<http://statmath.wu-wien.ac.at/software/RngStreams/>

=head1 INSTALLATION

Before installing this module, you have to download, compile and
install the RngStreams library available from its website.

Then, you have to follow the standard Perl module installation
procedure:

   perl Makefile.PL
   make
   make test
   make install

Or if you have installed the C library in a non standard place:

   perl Makefile.PL                                             \
             RNGSTREAMS_INCLUDE=/path/to/rngstreams/include     \
             RNGSTREAMS_LIB=/path/to/rngstreams/lib
   make
   make test
   make install

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Salvador Fandino (sfandino@yahoo.com)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

This module documentation is based on the RngStreams original
documentation Copyright (C) 2003 Pierre L'Ecuyer, DIRO, University of
Montreal.

The RngStreams library is distributed under the GPL. Copyright (C)
2003 Pierre L'Ecuyer, DIRO, University of Montreal.

=cut
