# -*- Perl -*-
#
# a minimal PCG random number generator plus some PCG related routines
#
# run perldoc(1) on this file for documentation

package Math::Random::PCG32;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK =
  qw(decay dice irand irand64 irand_in irand_way rand rand_elm rand_idx);

our $VERSION = '0.12';

require XSLoader;
XSLoader::load( 'Math::Random::PCG32', $VERSION );

1;
__END__

=head1 NAME

Math::Random::PCG32 - minimal PCG random number generator

=head1 SYNOPSIS

  use Math::Random::PCG32;
  # ideally use better seeds than this (see e.g. what
  # Math::Random::Secure does)
  my $rng = Math::Random::PCG32->new( 42, 54 );

  $rng->rand;
  $rng->rand(10);
  $rng->irand;
  $rng->irand_in( 1, 100 );
  $rng->rand_idx( \@some_array );
  $rng->rand_elm( \@some_array );

=head1 DESCRIPTION

This module includes a minimal PCG (Permuted Congruential Generator) for
random numbers

L<http://www.pcg-random.org/>

plus utility routines for PCG (Procedural Content Generation).

=head2 A RANDOM BENCHMARK

This pits the (very bad) core C<rand> function against the B<rand>
methods from L<Math::Random::ISAAC>, L<Math::Random::MTwist>,
L<Math::Random::Xorshift>, and this module for C<cmpthese( -5, ...> via
the L<Benchmark> module on my somehow still functional 2009 macbook.

               Rate  isacc  xorsh mtwist    pcg   rand
  isacc    214269/s     --   -92%   -96%   -96%   -99%
  xorsh   2661857/s  1142%     --   -47%   -52%   -88%
  mtwist  5030175/s  2248%    89%     --    -9%   -78%
  pcg     5518583/s  2476%   107%    10%     --   -75%
  rand   22447322/s 10376%   743%   346%   307%     --

=head1 METHODS

Various methods may croak if invalid input is detected. Use B<new> to
obtain an object and then call the others using that.

=over 4

=item B<new> I<initstate> I<initseq>

Makes a new object. No peeking! The two seed values must be 64-bit
unsigned integers. These could be read off of C</dev/random>, e.g.

    use Fcntl;
    my $raw;
    sysopen( my $fh, "/dev/random", O_RDONLY ) or die ...;
    ... = sysread $fh, $raw, 8;
    my $seed = unpack "Q", $raw;

or for a game one might use values from L<Time::HiRes> or provided by
the user with the caveat that C<pcg32_srandom_r> may need to be checked
that it is okay for users to provide whatever they want.

=item B<decay> I<odds> I<min> I<max>

Increments I<min> while successive random values are less than I<odds>
ending should a random value fail or I<max> be reached. I<odds> is
treated as a C<uint32_t> value (as are I<min> and I<max>), so 50% odds
of decay would be C<2147483648>. Returns the value I<min> is
incremented to.

=item B<dice> I<count> I<sides>

Sums the result of rolling the given number of dice.

=item B<irand>

Returns a random number from an object constructed by B<new>. The return
value is a 32-bit unsigned integer.

Used to be called B<rand> in older versions of the module.

=item B<irand64>

Returns a 64-bit unsigned integer, possibly by sticking the result of
two calls to the RNG together.

=item B<irand_in> I<min> I<max>

Returns a random integer in the range of I<min> to I<max>, inclusive.

=item B<irand_way> I<x1> I<y1> I<x2> I<y2>

Returns a new point as a list that will bring the first point (given
by I<x1>, I<y1>) towards the second point or C<undef> if the points
are the same.

Overflows are not checked for; do not use points that will result in
deltas or magnitudes greater than can be handled without overflow by
32-bit values.

=item B<rand> [ I<factor> ]

Returns a floating point value in the range 0.0 <= n < 1.0, or in some
other range if a number is given as a I<factor>.

=item B<rand_elm> I<array-reference>

Returns a random element from the given array, or C<undef> if the array
is empty (or if that is what the array element contained).

=item B<rand_idx> I<array-reference>

Returns a random index from the given array, or C<undef> if the
array is empty.

=back

=head1 MODULO BIAS

B<rand_elm> and B<rand_idx> ignore modulo bias so will become
increasingly unsound as the length of the array approaches
C<UINT32_MAX>. If modulo bias is a concern this module is not
what you need.

=head1 BUGS

=head2 Reporting Bugs

Please report any bugs or feature requests to
C<bug-math-random-pcg32 at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-Random-PCG32>.

Patches might best be applied towards:

L<https://github.com/thrig/Math-Random-PCG32>

=head2 Known Issues

New code, not many features, questionable XS. Probably needs a modern
compiler for the C<stdint> types. Untested on older versions of Perl.
Untested (by me) on 32-bit versions of Perl; C<use64bitint=define> is
now required.

Various tradeoffs have been made to favor speed over safety: modulo bias
is ignored and some methods have integer overflow issues. Using numbers
well below C<INT32_MAX> should avoid these issues.

=head1 SEE ALSO

L<https://github.com/imneme/pcg-c-basic>

L<Math::Random::Secure> for good seed choice.

L<http://xoshiro.di.unimi.it> for a different PRNG and tips on compiler
flags for use during benchmarks.

I<though I must say, those PRNG writers, it feels like they are in a
small scale war with each other at times> -- random chat comment

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Perl module copyright (C) 2018 by Jeremy Mates

Code under src/ directory (c) 2014 M.E. O'Neill / pcg-random.org

Licensed under the Apache License, Version 2.0 (the "License"); you may
not use this file except in compliance with the License. You may obtain
a copy of the License at

    L<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut
