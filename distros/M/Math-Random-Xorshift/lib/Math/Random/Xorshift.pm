package Math::Random::Xorshift;

use 5.008000;
use strict;
use warnings;
use Exporter::Lite;

our $VERSION = '0.05';
our @EXPORT_OK = qw/srand rand irand/;

require XSLoader;
XSLoader::load('Math::Random::Xorshift', $VERSION);

1;
__END__

=head1 NAME

Math::Random::Xorshift - a fast PRNG

=head1 SYNOPSIS

 my @seeds = (123_456_789, 362_436_069, 521_288_629, 88_675_123);
 
 # OO interface
 use Math::Random::Xorshift;
 my $rng = Math::Random::Xorshift->new(@seeds);
 $rng->srand(@seeds);
 my $n = $rng->rand;
 my $i = $rng->irand;
 
 # Functional interface
 use Math::Random::Xorshift qw/srand irand rand/;
 srand(@seeds);
 $n = rand(10);
 $i = irand;

=head1 DESCRIPTION

This module is a straight forward implementation of Xorshift PRNG proposed by G. Marsaglia in 2003.

Note that the algorithm is extremely fast and passes the L<Diehard test|http://www.stat.fsu.edu/pub/diehard/> though, is not reliable enough statistically (see L</SEE ALSO> section). I think however this module is useful for games and suchlike usages.

If you want rather more reliability than fastness, I recommend L<Math::Random::MT>.

=head2 EXPORT

None by default. You can import C<srand>, C<rand> and C<irand> to replace Perl's builtins. These functions manupilate static PRNG object in C level. So these are about 3-4x faster than OO interface, since there's no method resolution overhead.

=head1 METHOD

=head2 new([$seed | @seeds])

Constructor. You can specify up to 4 seed(s). At least 1 seed value must not be zero.
If no seeds are given, return value of C<time(3)> is used.

=head2 srand([$seed | @seeds])

Resets seeds.

=head2 irand()

Returns unsigned random integer in range of [0, UINT32_MAX).

=head2 rand([$upper_limit = 1.0])

Returns random real number in range of [0, $upper_limit). C<$upper_limit> should be positive.

=head1 BENCHMARK

Here is a benchmark result on my Macbook(Core 2 Duo 2.4 GHz/4GB DDR3 RAM).
Competitors are L<Math::Random::MT>, L<Math::Random::ISAAC>, and Perl's builtin C<rand()>.

You can run bench.pl included in this distribution to benchmark on your machine.

                            Rate M::R::ISAAC#irand M::R::MT#rand M::R::ISAAC#rand M::R::Xorshift#rand M::R::Xorshift#irand M::R::Xorshift::irand M::R::Xorshift::rand CORE::rand
M::R::ISAAC#irand       910221/s                --           -2%              -3%                -64%                 -66%                  -89%                 -90%       -96%
M::R::MT#rand           927943/s                2%            --              -1%                -63%                 -66%                  -89%                 -90%       -96%
M::R::ISAAC#rand        936228/s                3%            1%               --                -63%                 -65%                  -89%                 -90%       -96%
M::R::Xorshift#rand    2502283/s              175%          170%             167%                  --                  -8%                  -71%                 -73%       -88%
M::R::Xorshift#irand   2706501/s              197%          192%             189%                  8%                   --                  -68%                 -71%       -87%
M::R::Xorshift::irand  8485586/s              832%          814%             806%                239%                 214%                    --                  -8%       -59%
M::R::Xorshift::rand   9175040/s              908%          889%             880%                267%                 239%                    8%                   --       -56%
CORE::rand            20852364/s             2191%         2147%            2127%                733%                 670%                  146%                 127%         --

=head1 SEE ALSO

=over 2

=item L<Math::Random::MT> - The Mersenne Twister PRNG

=item G. Marsaglia, 2003, L<"Xorshift PRNGs"|http://www.jstatsoft.org/v08/i14/paper> - Original paper

=item F. Panneton and P. L'ecuyer, 2005, L<"On the xorshift random number generators"|http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.63.7497&rep=rep1&type=pdf> - According to this paper, Xorshift is not reliable

=back

=head1 AUTHOR

Koichi SATOH, E<lt>r.sekia@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

The MIT License

Copyright (C) 2010 by Koichi SATOH

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut
