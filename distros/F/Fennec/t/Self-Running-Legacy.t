#!/usr/bin/perl
package Fennec::Test::SelfRunning;
use strict;
use warnings;

use Fennec;

ok( !__PACKAGE__->can($_), "$_ not imported" ) for qw/run_tests/;

describe blah => sub {
    tests group_a => code => sub { ok( 1, 'a' ) };
    tests group_b => sub { ok( 1, 'b' ) };
    tests group_c => sub { ok( 1, 'c' ) };
    tests group_d => sub { ok( 1, 'd' ) };
    tests group_e => sub { ok( 1, 'e' ) };
    describe foo  => sub {
        tests group_x => sub { ok( 1, 'x' ) };
    };
};

tests todo_group => (
    code => sub { ok( 0, "This should fail, no worries" ) },
    todo => "This is a todo group",
);

tests should_fail => (
    should_fail => 1,
    code        => sub { die "You should not see this!" },
);

tests skip_group => (
    skip => "This is a skip group",
    code => sub { ok( 0, "You should not see this!" ) },
);

1
