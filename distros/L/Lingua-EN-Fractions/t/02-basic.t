#! perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;
use Lingua::EN::Fractions qw/ fraction2words /;

my @TESTS =
(
    [   ['1/2'],        'one half'              ],
    [   [' 1 / 2 '],    'one half'              ],
    [   ['1/3'],        'one third'             ],
    [   ['2/3'],        'two thirds'            ],
    [   ['3/2'],        'three halves'          ],
    [   ['3/4'],        'three quarters'        ],
    [   ['-2/5'],       'minus two fifths'      ],
    [   ['17/18'],      'seventeen eighteenths' ],
    [   ['5/34'],       'five thirty-fourths'   ],
    [   ['5'],          undef                   ],
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

