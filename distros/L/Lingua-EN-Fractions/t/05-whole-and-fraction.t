#! perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;
use Lingua::EN::Fractions qw/ fraction2words /;

my @TESTS =
(
    [   ['1 2/3'],      'one and two thirds'        ],
    [   ['1 1/2'],      'one and a half'            ],
    [   ['-1 1/2'],     'minus one and a half'      ],
    [   ['8 1/8'],      'eight and an eighth'       ],
    [   [' 5 5 / 8'],   'five and five eighths'     ],
    [   ['12 3/4'],     'twelve and three quarters' ],
);

plan tests => int(@TESTS);

foreach my $test (@TESTS) {
    my ($argref, $expected) = @$test;
    my $result = fraction2words(@$argref);
    if (!defined($expected)) {
        ok(!defined($result), "'@$argref' should result in undef");
    }
    else {
        is($result, $expected, "'@$argref' should result in '$expected'");
    }
}

