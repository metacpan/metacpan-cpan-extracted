#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 58;

use ok 'Lingua::TokiPona::Numbers', qw( :all );

are_num2tokipona(
    # integers
    [ -100, 'mute ala' ],
    [   -3, 'mute ala' ],
    [   -2, 'tu ala'   ],
    [   -1, 'wan ala'  ],
    [    0, 'ala'      ],
    [    1, 'wan'      ],
    [    2, 'tu'       ],
    [    3, 'mute'     ],
    [    4, 'mute'     ],
    [   10, 'mute'     ],
    [   99, 'mute'     ],
    [  100, 'mute'     ],
    [ 1000, 'mute'     ],

    # floating point numbers
    [ -0.1, 'wan ala' ],
    [  0.0, 'ala'     ],
    [  0.1, 'wan'     ],
    [  1.0, 'wan'     ],
    [  1.1, 'tu'      ],
    [  2.1, 'mute'    ],
    [ 99.1, 'mute'    ],

    # strings
    [ '-1'   => 'wan ala' ],
    [ '-1.0' => 'wan ala' ],
    [   '.0' => 'ala'     ],
    [  '0.'  => 'ala'     ],
    [  '0.0' => 'ala'     ],
    [   '.1' => 'wan'     ],
    [  '1'   => 'wan'     ],
    [  '1.'  => 'wan'     ],
    [ '+1'   => 'wan'     ],
    [ '+1.0' => 'wan'     ],

    # special values
    [  'inf' => 'ale'     ],
    [ '+inf' => 'ale'     ],
    [ '-inf' => 'ale ala' ],
    [  'NaN' => 'ala'     ],
);

# ordinals
are_num2tokipona_ordinal(
    [    0, 'nanpa ala'  ],
    [    1, 'nanpa wan'  ],
    [    2, 'nanpa tu'   ],
    [    3, 'nanpa mute' ],
    [    4, 'nanpa mute' ],
    [   10, 'nanpa mute' ],
    [   99, 'nanpa mute' ],
    [  100, 'nanpa mute' ],
    [ 1000, 'nanpa mute' ],
);

# negative tests
ok !num2tokipona(undef), 'undef fails';
ok !num2tokipona( q{} ), 'empty string fails';
for my $test ('abc', '1a', 'a1', '1.2.3', '1,2,3', '1,2') {
    ok !num2tokipona($test), "$test fails";
}

TODO: {
    our $TODO = 'exponential notation in strings not implemented';

    for my $test (qw<  5e5  5E5  5.5e5  5e-5  -5e5  -5e-5  >) {
        ok num2tokipona($test), "$test returns value";
    }
}

sub are_num2tokipona {
    my (@tests) = @_;

    for my $test (@tests) {
        my ($num, $word) = @{$test};
        is num2tokipona($num), $word, "$num -> $word";
    }
}

sub are_num2tokipona_ordinal {
    my (@tests) = @_;

    for my $test (@tests) {
        my ($num, $word) = @{$test};
        is num2tokipona_ordinal($num), $word, "$num -> $word";
    }
}
