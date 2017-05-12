#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 85;

use ok 'Lingua::TLH::Numbers', qw( :all );

are_num2tlh(
    # integers
    [       0, "pagh"            ],
    [       9, "Hut"             ],
    [      10, "wa'maH"          ],
    [      90, "HutmaH"          ],
    [      99, "HutmaH Hut"      ],
    [     100, "wa'vatlh"        ],
    [     109, "wa'vatlh Hut"    ],
    [     110, "wa'vatlh wa'maH" ],
    [     190, "wa'vatlh HutmaH" ],
    [     900, "Hutvatlh"        ],
    [    1000, "wa'SaD"          ],
    [    9000, "HutSaD"          ],
    [   10000, "wa'netlh"        ],
    [   11000, "wa'netlh wa'SaD" ],
    [   19000, "wa'netlh HutSaD" ],
    [   90000, "Hutnetlh"        ],
    [  100000, "wa'bIp"          ],
    [  110000, "wa'bIp wa'netlh" ],
    [  190000, "wa'bIp Hutnetlh" ],
    [  900000, "HutbIp"          ],
    [ 1000000, "wa''uy'"         ],
    [ 9999999, "Hut'uy' HutbIp Hutnetlh HutSaD Hutvatlh HutmaH Hut" ],

    # floating point numbers
    [ 0.0,   "pagh"                   ],
    [ 0.9,   "pagh vI' Hut"           ],
    [ 0.09,  "pagh vI' pagh Hut"      ],
    [ 0.009, "pagh vI' pagh pagh Hut" ],
    [ 0.99,  "pagh vI' Hut Hut"       ],
    [ 9.0,   "Hut"                    ],
    [ 9.9,   "Hut vI' Hut"            ],

    # strings
    [   '.0'   => "vI' pagh"               ],
    [  '0.'    => "pagh"                   ],
    [  '0.0'   => "pagh vI' pagh"          ],
    [   '.9'   => "vI' Hut"                ],
    [  '9'     => "Hut"                    ],
    [  '9.'    => "Hut"                    ],
    [  '9.0'   => "Hut vI' pagh"           ],
    [  '9.000' => "Hut vI' pagh pagh pagh" ],
    [ '+9'     => "Hut"                    ],
    [ '+9.0'   => "Hut vI' pagh"           ],
);

# ordinals
are_num2tlh_ordinal(
    [    "+9", "HutDIch"             ],
    [       0, "paghDIch"            ],
    [       9, "HutDIch"             ],
    [      10, "wa'maHDIch"          ],
    [      90, "HutmaHDIch"          ],
    [      99, "HutmaH HutDIch"      ],
    [     100, "wa'vatlhDIch"        ],
    [     109, "wa'vatlh HutDIch"    ],
    [     110, "wa'vatlh wa'maHDIch" ],
    [     190, "wa'vatlh HutmaHDIch" ],
    [     900, "HutvatlhDIch"        ],
    [    1000, "wa'SaDDIch"          ],
    [    9000, "HutSaDDIch"          ],
    [   10000, "wa'netlhDIch"        ],
    [   11000, "wa'netlh wa'SaDDIch" ],
    [   19000, "wa'netlh HutSaDDIch" ],
    [   90000, "HutnetlhDIch"        ],
    [  100000, "wa'bIpDIch"          ],
    [  110000, "wa'bIp wa'netlhDIch" ],
    [  190000, "wa'bIp HutnetlhDIch" ],
    [  900000, "HutbIpDIch"          ],
    [ 1000000, "wa''uy'DIch"         ],
    [ 9999999, "Hut'uy' HutbIp Hutnetlh HutSaD Hutvatlh HutmaH HutDIch" ],
);

# negative tests
ok !num2tlh(undef), 'undef fails';
ok !num2tlh( q{} ), 'empty string fails';
for my $test ('abc', '1a', 'a1', '1.2.3', '1,2,3') {
    ok !num2tlh($test), "$test fails";
}

TODO: {
    our $TODO = 'negative numbers not implemented';

    for my $test (-9, -9.0, -0.9, '-9', '-9.0') {
        ok num2tlh($test), "$test returns value";
    }
}

TODO: {
    our $TODO = 'special values inf and NaN not implemented';

    for my $test (qw< inf +inf -inf NaN >) {
        ok num2tlh($test), "$test returns value";
    }
}

TODO: {
    our $TODO = 'exponential notation in strings not implemented';

    for my $test (qw<  5e5  5E5  5.5e5  5e-5  -5e5  -5e-5  >) {
        ok num2tlh($test), "$test returns value";
    }
}

sub are_num2tlh {
    my (@tests) = @_;

    for my $test (@tests) {
        my ($num, $word) = @{$test};
        is num2tlh($num), $word, "$num -> $word";
    }
}

sub are_num2tlh_ordinal {
    my (@tests) = @_;

    for my $test (@tests) {
        my ($num, $word) = @{$test};
        is num2tlh_ordinal($num), $word, "$num -> $word";
    }
}
