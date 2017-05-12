#! perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88 tests => 4;
use Lingua::EN::Fractions qw/ fraction2words /;
my $skip;
my ($fraction, $as_text);

BEGIN {
    if (eval { require Number::Fraction; }) {
        Number::Fraction->import(':constants');
    }
    else {
        $skip = 1;
    }
}

SKIP: {
    skip("you don't have Number::Fraction installed", 4) if $skip;

    $fraction = '2/3';
    is(ref($fraction), 'Number::Fraction',
       "literal fraction '2/3' should result in an instance of Number::Fraction");
    $as_text  = fraction2words($fraction);
    is($as_text, 'two thirds', "... and that should convert to 'two thirds'");

    $fraction = '6/8';
    is(ref($fraction), 'Number::Fraction',
       "literal fraction '6/8' should result in an instance of Number::Fraction");
    $as_text  = fraction2words($fraction);
    is($as_text, 'three quarters', "... and should be normalised to 'three quarters'");

}
