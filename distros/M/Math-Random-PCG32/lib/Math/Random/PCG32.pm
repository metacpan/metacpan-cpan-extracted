# -*- Perl -*-
#
# minimal PCG random number generator
#
# run perldoc(1) on this file for additional documentation

package Math::Random::PCG32;

use warnings;
use strict;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(irand rand rand_elm rand_idx);

our $VERSION = '0.07';

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
  $rng->rand_idx( \@some_array );
  $rng->rand_elm( \@some_array );

=head1 DESCRIPTION

This is a minimal PCG random number generator with a few utility
routines.

L<http://www.pcg-random.org/>

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

=item B<irand>

Returns a random number from an object constructed by B<new>. The return
value is a 32-bit unsigned integer.

Used to be called B<rand> in older versions of the module.

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

=head1 SEE ALSO

L<https://github.com/imneme/pcg-c-basic>

L<Math::Random::Secure> for good seed choice.

L<http://xoshiro.di.unimi.it> for a different PRNG and tips on compiler
flags for use during benchmarks.

  "though I must say, those PRNG writers, it feels like they are in a
  small scale war with each other at times" -- random chat comment

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
