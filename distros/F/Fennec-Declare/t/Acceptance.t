#!/usr/bin/perl
package Declare::Test;
use strict;
use warnings;

use Fennec::Declare;

tests foo {
    ok( 1, "Declarative test!" );
}

tests old => sub {
    ok( 1, "old style" );
};

describe blah {
    tests group_a { ok( 1, 'a' )}
    tests group_b { ok( 1, 'b' )}
    tests group_c { ok( 1, 'c' )}
    tests group_d { ok( 1, 'd' )}
    tests group_e { ok( 1, 'e' )}
    describe foo {
        tests group_x { ok( 1, 'x' )}
    }
};

tests todo_group (todo => "This is a todo group") {
    ok( 0, "This should fail, no worries" )
}

tests should_fail (should_fail => 1) {
    die "You should not see this!"
}

tests skip_group (skip => "This is a skip group") {
    ok( 0, "You should not see this!" )
}

1;
