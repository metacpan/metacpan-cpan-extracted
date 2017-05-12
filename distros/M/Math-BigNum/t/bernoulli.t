#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 21;

use Math::BigNum qw(:constant);

# Bernoulli numbers
{
    my %results = qw(
      0   1
      1   1/2
      2   1/6
      3   0
      4   -1/30
      5   0
      6   1/42
      10  5/66
      12  -691/2730
      20  -174611/330
      22  854513/138
      );

    #
    ## bernfrac()
    #
    foreach my $i (keys %results) {
        is(Math::BigNum->new($i)->bernfrac->as_rat, $results{$i});
    }

    is((-2)->bernfrac, NaN);    # make sure we check for even correctly

    is((52)->bernfrac->as_frac, '-801165718135489957347924991853/1590');
    is((106)->bernfrac->as_frac,
        '36373903172617414408151820151593427169231298640581690038930816378281879873386202346572901/642');

    #
    ## bernreal()
    #
    is((-2)->bernreal, NaN);    # check for negative values

    is((1)->bernreal,                0.5);
    is((0)->bernreal,                1);
    is((3)->bernreal,                0);
    is((2)->bernreal->as_float(10),  '0.1666666667');
    is((14)->bernreal->as_float(25), '1.1666666666666666666666667');
    is((52)->bernreal->as_float(10), '-503877810148106891413789303.0522012579');
}
