#! perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88 tests => 2;
use Lingua::EN::Fractions qw/ fraction2words /;

my ($fraction, $as_text);

eval { require Number::Fraction };

SKIP: {
    skip("you don't have Number::Fraction installed", 2) if $@;

    $fraction = Number::Fraction->new(2, 7);
    $as_text  = fraction2words($fraction);
    is($as_text, 'two sevenths', "'2/7' should return 'two sevenths'");

    $fraction = Number::Fraction->new(-1, 3);
    $as_text  = fraction2words($fraction);
    is($as_text, 'minus one third', "'-1/3' should return 'minus one third'");

}
