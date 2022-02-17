package Math::Sequence::DeBruijn;

use 5.028;
use strict;
use warnings;
no  warnings 'syntax';

use experimental 'signatures';
use experimental 'lexical_subs';
use Exporter ();

our $VERSION = '2022021301';
our @EXPORT  = qw [debruijn];
our @ISA     = qw [Exporter];


#
# This a translation of the Python program given at the Wikipedia
# page on De Bruijn sequences.
# (https://en.wikipedia.org/wiki/De_Bruijn_sequence)
#

sub debruijn ($alphabet, $n) {
    $alphabet = [split // => $alphabet] unless ref $alphabet;
    my $size  = @$alphabet;
    my @a     = (0) x ($size * $n);

    my $sequence = [];

    my sub db ($t, $p) {
        if ($t > $n) {
            push @$sequence => @a [1 .. $p] if $n % $p == 0;
        }
        else {
            $a [$t] = $a [$t - $p];
            __SUB__ -> ($t + 1, $p);
            foreach my $j ($a [$t - $p] + 1 .. ($size - 1)) {
                $a [$t] = $j;
                __SUB__ -> ($t + 1, $t);
            }
        }
    };

    db (1, 1);

    join "" => @$alphabet [@$sequence];
}



1;

__END__

=head1 NAME

Math::Sequence::DeBruijn - Abstract

=head1 SYNOPSIS

 use Math::Sequence::DeBruijn;      # Exports 'debruijn'
 use Math::Sequence::DeBruijn ();   # No exports.

=head1 DESCRIPTION

This module provides a single subroutine, C<debruijn>, which returns
a L<De Bruijn sequence|https://en.wikipedia.org/wiki/De_Bruijn_sequence>
for the given alphabet I<A> and size I<n>. A De Bruijn sequence of an
alphabet I<A> and size I<n> is a I<cyclic> sequence where every substring
of length I<n> over the alphabet I<A> appears exactly once in the sequence.

For instance, if I<A = {0, 1}> and I<n = 3>, a possible De Bruijn sequence
would be I<00010111>, as each possible substring of length 3
(I<000>, I<001>, I<010>, I<011>, I<100>, I<101>, I<110>, and I<111>)
appears exactly once. Note that the sequence is cyclic, so I<110> can
be found by looking at the last two, and first character of the sequence.

C<debruijn> takes two arguments:

=over 2

=item C<$alphabet>

Either an arrayref with the symbols to be used in the alphabet, or a
string witht the same. For binary strings, one would use C<[0, 1]>
or C<"01">.

=item C<$n>

The length of the substrings to consider.

=back

The sequence is returned as a string.

Be aware that the sequence returned has length C<k^n>, where C<k> is
the size of the alphabet. This is the optimal length, so it cannot be
improved, but it does mean both the running time, and memory usage of
the subroutine is exponential in its second argument.

=head1 EXAMPLE

 debruijn ("Perl", 3);

This returns
C<PPPePPrPPlPeePerPelPrePrrPrlPlePlrPlleeereelerrerlelrellrrrlrlll>.

=head1 ACKNOWLEDGEMENT

The code is a port of the Python code given in the
L<Wikipedia article|https://en.wikipedia.org/wiki/De_Bruijn_sequence>
about De Bruijn sequences.

=head1 DEVELOPMENT

The current sources of this module are found on github,
L<< git://github.com/Abigail/Math-Sequence-DeBruijn.git >>.

=head1 AUTHOR

Abigail, L<< mailto:cpan@abigail.freedom.nl >>.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2022 by Abigail.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),   
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=head1 INSTALLATION

To install this module, run, after unpacking the tar-ball, the 
following commands:

   perl Makefile.PL
   make
   make test
   make install

=cut
