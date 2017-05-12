#!/usr/bin/env perl
package Test::InnerTodo;
use strict;
use warnings;

use Fennec;

describe outer => (
    todo => 'foo',
    code => sub {
        ok( 0, "outer: This should be todo" );

        tests outer_tests => sub {
            ok( 0, "outer_test: This should be todo" );
        };

        describe inner => sub {
            ok( 0, "inner: This should be todo" );

            tests inner_tests => sub {
                ok( 0, "inner_test: This should be todo" );
            };
        };
    },
);

tests outside => (
    todo => 'foo',
    code => sub {
        ok( 0, "outside_test: This should be todo" );
    },
);

tests not_todo => sub {
    ok( 1, "Not todo" );
};

done_testing;
