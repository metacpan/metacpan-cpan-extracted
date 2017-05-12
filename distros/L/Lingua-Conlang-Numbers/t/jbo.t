#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 87;

use ok 'Lingua::JBO::Numbers', qw( :all );

are_num2jbo(
    # integers
    [      -9, "ni'uso"         ],
    [       0, "no"             ],
    [       9, "so"             ],
    [      10, "pano"           ],
    [      90, "sono"           ],
    [      99, "soso"           ],
    [     100, "panono"         ],
    [     109, "panoso"         ],
    [     110, "papano"         ],
    [     190, "pasono"         ],
    [     900, "sonono"         ],
    [    1000, "panonono"       ],
    [    9000, "sononono"       ],
    [   10000, "panononono"     ],
    [   11000, "papanonono"     ],
    [   19000, "pasononono"     ],
    [   90000, "sonononono"     ],
    [  100000, "panonononono"   ],
    [  110000, "papanononono"   ],
    [  190000, "pasonononono"   ],
    [  900000, "sononononono"   ],
    [  999999, "sosososososo"   ],
    [ 1000000, "panononononono" ],

    # floating point numbers
    [ -9.0,   "ni'uso"     ],
    [ -0.9,   "ni'unopiso" ],
    [  0.0,   "no"         ],
    [  0.9,   "nopiso"     ],
    [  0.09,  "nopinoso"   ],
    [  0.009, "nopinonoso" ],
    [  0.99,  "nopisoso"   ],
    [  9.0,   "so"         ],
    [  9.9,   "sopiso"     ],

    # strings
    [ '-9'     => "ni'uso"     ],
    [ '-9.0'   => "ni'usopino" ],
    [   '.0'   => "pino"       ],
    [  '0.'    => "no"         ],
    [  '0.0'   => "nopino"     ],
    [   '.9'   => "piso"       ],
    [  '9'     => "so"         ],
    [  '9.'    => "so"         ],
    [ '+9'     => "ma'uso"     ],
    [ '+9.0'   => "ma'usopino" ],
    [  '9.0'   => "sopino"     ],
    [  '9.000' => "sopinonono" ],

    # special values
    [  'inf' => "ci'i"     ],
    [ '+inf' => "ma'uci'i" ],
    [ '-inf' => "ni'uci'i" ],
    [  'NaN' => "na namcu" ],
);

# ordinals
are_num2jbo_ordinal(
    [    '+9', "ma'usomoi"         ],
    [      -9, "ni'usomoi"         ],
    [       0, "nomoi"             ],
    [       9, "somoi"             ],
    [      10, "panomoi"           ],
    [      90, "sonomoi"           ],
    [      99, "sosomoi"           ],
    [     100, "panonomoi"         ],
    [     109, "panosomoi"         ],
    [     110, "papanomoi"         ],
    [     190, "pasonomoi"         ],
    [     900, "sononomoi"         ],
    [    1000, "panononomoi"       ],
    [    9000, "sonononomoi"       ],
    [   10000, "panonononomoi"     ],
    [   11000, "papanononomoi"     ],
    [   19000, "pasonononomoi"     ],
    [   90000, "sononononomoi"     ],
    [  100000, "panononononomoi"   ],
    [  110000, "papanonononomoi"   ],
    [  190000, "pasononononomoi"   ],
    [  900000, "sonononononomoi"   ],
    [  999999, "sosososososomoi"   ],
    [ 1000000, "panonononononomoi" ],
);

# negative tests
ok !num2jbo(undef), 'undef fails';
ok !num2jbo( q{} ), 'empty string fails';
for my $test ('abc', '1a', 'a1', '1.2.3', '1,2,3', '1,2') {
    ok !num2jbo($test), "$test fails";
}

TODO: {
    our $TODO = 'exponential notation in strings not implemented';

    for my $test (qw<  5e5  5E5  5.5e5  5e-5  -5e5  -5e-5  >) {
        ok num2jbo($test), "$test returns value";
    }
}

sub are_num2jbo {
    my (@tests) = @_;

    for my $test (@tests) {
        my ($num, $word) = @{$test};
        is num2jbo($num), $word, "$num -> $word";
    }
}

sub are_num2jbo_ordinal {
    my (@tests) = @_;

    for my $test (@tests) {
        my ($num, $word) = @{$test};
        is num2jbo_ordinal($num), $word, "$num -> $word";
    }
}
