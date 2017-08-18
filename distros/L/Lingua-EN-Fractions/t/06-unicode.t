#! perl

use 5.008;
use strict;
use warnings;
use utf8;

use open ':std', ':encoding(utf8)';
use Test::More 0.88;
use Lingua::EN::Fractions qw/ fraction2words /;

my @TESTS =
(
    [   ['1½'],         'one and a half'            ],
    [   [' 1 ½ '],      'one and a half'            ],
    [   ['-1¼'],        'minus one and a quarter'   ],
    [   ['-1 1/2'],     'minus one and a half'      ],
    [   ['⅜'],          'three eighths'             ],
    [   ['-⅚'],         'minus five sixths'         ],
    [   ['- ⅓'],        'minus one third'           ],
    [   [' - ⅔'],       'minus two thirds'          ],
    [   [' - ⅔'],       'minus two thirds'          ],
    [   ['-1⅘'],        'minus one and four fifths' ],

    # These use the Unicode character FRACTION SLASH (U+2044)
    [   ['3⁄4'],        'three quarters'            ],
    [   ['1 2⁄5'],      'one and two fifths'        ],

    # These use the Unicode character MINUS SIGN (U+2212)
    [   ['−5/6'],       'minus five sixths'         ],
    [   ['−⅚'],         'minus five sixths'         ],

    [   ['⅑'],          'one ninth'                 ], 
    [   ['⅟10'],        'one tenth'                 ],
    [   ['↉'],          'zero thirds'               ], 
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

