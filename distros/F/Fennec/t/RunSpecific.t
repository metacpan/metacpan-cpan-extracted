#!/usr/bin/perl
use strict;
use warnings;

use Fennec;

$ENV{FENNEC_TEST} = "only_these";

tests only_these => sub {
    ok( 1, "Should see this" );
};

describe foo => sub {
    my $check = 0;

    before_each check => sub {
        $check = 1;
    };

    tests only_these => sub {
        ok( $check, "Should see this" );
    };

    describe foo => sub {
        my $check = 0;

        before_each check => sub {
            $check = 1;
        };

        tests only_these => sub {
            ok( $check, "Should see this" );
        };
    };

    describe bar => sub {
        before_each no => sub {
            ok( 0, "Should not run" );
        };

        tests blah => sub {
            ok( 0, "blah" );
        };
    };
};

describe bar => sub {
    before_each no => sub {
        ok( 0, "Should not run" );
    };

    tests blah => sub {
        ok( 0, "blah" );
    };
};

done_testing;
