#!/usr/bin/perl -w
use strict;

use Data::FormValidator;
use Test::More tests => 32;
use Labyrinth::Constraints;
use Labyrinth::Variables;

Labyrinth::Variables::init();   # initial standard variable values

my %rules = (
    optional => [qw{ test_date test_url }],
    validator_packages => [qw(  Labyrinth::Constraints )],
    msgs => {prefix=> 'err_'},      # set a custom error prefix
    missing_optional_valid => 1,
    constraint_methods => {
        url         => \&url,
        ddmmyy      => \&ddmmyy
    },
    constraints => {
        test_date => { constraint_method => 'ddmmyy' },
        test_url  => { constraint_method => 'url' },
    }
);


my @example_dates = (
    [ undef,        0, undef        ],
    [ '',           0, undef        ],
    [ '12-12-2013', 1, '12-12-2013' ],
    [ '2013-02-08', 0, undef        ],
    [ '05022013',   0, undef        ],
);

for my $ex (@example_dates) {
    is(valid_ddmmyy(undef,$ex->[0]), $ex->[1],  "'" . (defined $ex->[0] ? $ex->[0] : 'undef') ."' validates as expected for ddmmyy"     );
    is(match_ddmmyy(undef,$ex->[0]), $ex->[2],  "'" . (defined $ex->[0] ? $ex->[0] : 'undef') ."' matches as expected for ddmmyy"       );

    my $result = Data::FormValidator->check({
            test_date => $ex->[0]
        }, \%rules
    );

    if($ex->[1]) {
        ok ( $result->valid('test_date'), "'" . (defined $ex->[0] ? $ex->[0] : 'undef') ."' is valid as expected");
    } elsif($ex->[0]) {
        ok ( $result->invalid('test_date'), "'" . (defined $ex->[0] ? $ex->[0] : 'undef') ."' is invalid as expected");
    }
}

my @example_urls = (
    [ undef,                0, undef                    ],
    [ '',                   0, undef                    ],
    [ 'http://test.com',    1, 'http://test.com'        ],
    [ 'http://',            0, undef                    ],
    [ 'xyz://test.com',     0, undef                    ],
    [ 'test.com',           1, 'http://test.com'        ],
    [ 'www.test.com',       1, 'http://www.test.com'    ],
);

for my $ex (@example_urls) {
    is(valid_url(undef,$ex->[0]), $ex->[1],  "'" . (defined $ex->[0] ? $ex->[0] : 'undef') ."' validates as expected for url"   );
    is(match_url(undef,$ex->[0]), $ex->[2],  "'" . (defined $ex->[0] ? $ex->[0] : 'undef') ."' matches as expected for url"     );

    my $result = Data::FormValidator->check({
            test_url => $ex->[0]
        }, \%rules
    );

    if($ex->[1]) {
        ok ( $result->valid('test_url'), "'" . (defined $ex->[0] ? $ex->[0] : 'undef') ."' is valid as expected");
    } elsif($ex->[0]) {
        ok ( $result->invalid('test_url'), "'" . (defined $ex->[0] ? $ex->[0] : 'undef') ."' is invalid as expected");
    }
}
