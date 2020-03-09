# -*- Perl -*-
#
# a minimal PCG random number generator plus some PCG related routines
#
# run perldoc(1) on this file for documentation

package Math::Random::PCG32;

our $VERSION = '0.17';

use strict;
use warnings;
use Exporter qw(import);
our @EXPORT_OK = qw(coinflip decay irand irand64 irand_in irand_way
  rand rand_elm rand_from rand_idx roll);
require XSLoader;
XSLoader::load('Math::Random::PCG32', $VERSION);

1;
__END__

=head1 NAME

Math::Random::PCG32 - minimal PCG random number generator

=head1 SYNOPSIS

  use Math::Random::PCG32;

  # probably want a better seed, see Math::Random::Secure
  # a game by contrast could want the seed given by YYYYMMDD
  my $rng = Math::Random::PCG32->new( 42, 54 );

  $rng->coinflip;                   # 0,1

  $rng->decay( 2147483648, 1, 20 ); # 50% odds decay from 1 out to 20
                                    # (results closer to 1 than 20)

  $rng->irand;                  # 32-bit unsigned int
  $rng->irand_in( 1, 100 );     # 1..100 result (biased)

  $rng->rand;                   # float [0..1) (biased)
  $rng->rand(10);               # previous multiplied by ...

  $rng->rand_elm( \@a );        # random element of array (biased)
  $rng->rand_from( \@a );       # splice out a random element "
  $rng->rand_idx( \@a );        # random index of array       "

  $rng->roll( 3, 6 );           # 3d6 (biased)

=head1 DESCRIPTION

This module includes a minimal PCG (Permuted Congruential Generator) for
random numbers

L<http://www.pcg-random.org/>

and some utility routines for PCG (Procedural Content Generation).

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
obtain an object and then call the others using that. Note that many of
these are biased, as this module favors speed and is expected to deal
only with small numbers.

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
the user. I<initstate> and I<initseq> are documented at:

L<https://www.pcg-random.org/using-pcg-c-basic.html>

=item B<coinflip>

Returns C<0> or C<1>.

I<Since version 0.17.>

=item B<decay> I<odds> I<min> I<max>

Increments I<min> while successive random values are less than I<odds>
ending should a random value fail or I<max> be reached. I<odds> is
treated as a C<uint32_t> value (as are I<min> and I<max>), so 50% odds
of decay would be C<2147483648>. Returns the value I<min> is
incremented to.

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
is empty (or if that is what the array element contained). The reference
is not modified.

=item B<rand_from> I<array-reference>

Like B<rand_elm> but cuts the element out of the array reference before
returning it. Pretty similar to C<splice> with a random index:

    $rng->rand_from(\@seed);
    splice @seed, rand @seed, 1;

I<Since version 0.17.>

=item B<rand_idx> I<array-reference>

Returns a random index from the given array, or C<undef> if the
array is empty.

=item B<roll> I<count> I<sides>

Sums the result of rolling the given number of dice.

I<Since version 0.17.> Prior to that was called B<dice>. Prior to
version 0.10 did not exist.

=back

=head1 CAVEATS

This module MUST NOT be used for anything cryptographic or security
related. It probably should not be used for any analysis that needs
non-biased pseudo random numbers.

Various routines are subject to various forms of modulo bias so will
become increasingly unsound as the values used approach
C<UINT32_MAX>. If modulo bias is a concern this module is B<not> what
you need. More reading:

L<https://www.pcg-random.org/posts/bounded-rands.html>

This module does use C<%> (which is biased) in various routines; there
are apparently faster methods (or ones more suitable for larger inputs)
though benchmarking

  uint32_t byinteger(uint32_t max) {
      uint32_t x = rand();
      uint64_t m = (uint64_t) x * (uint64_t) max;
      return m >> 32;
  }

against

  uint32_t bymodulus(uint32_t max) { return rand() % max; }

did not show any notable speed gain for me (though perhaps my benchmark
was flawed, or compiler too old? YMMV).

=head1 BUGS

=head2 Reporting Bugs

Patches might best be applied towards:

L<https://github.com/thrig/Math-Random-PCG32>

=head2 Known Issues

Probably needs a modern compiler for the C<stdint> types. Untested on
older versions of Perl. Untested (by me) on 32-bit versions of Perl;
C<use64bitint=define> is now required.

Various tradeoffs have been made to always favor speed over safety:
modulo bias is ignored and some methods have integer overflow issues.
Using numbers well below C<INT32_MAX> should avoid these issues.

=head1 SEE ALSO

L<https://www.pcg-random.org/using-pcg-c-basic.html>

L<https://github.com/imneme/pcg-c-basic>

L<Math::Random::Secure> for good seed choice.

L<http://xoshiro.di.unimi.it> for a different PRNG and tips on compiler
flags for use during benchmarks.

  "though I must say, those PRNG writers, it feels like they are in a
  small scale war with each other at times"
    -- random chat comment

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jeremy.mates at gmail.com> >>

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
