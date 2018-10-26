use strict;
use warnings;

use Test2::V0;  no warnings 'void';
use lib 't/lib';
use TestHelper qw(ok_location db_stepover);

$DB::single = 1;
foo();
10;
sub foo {
    12;
}

sub __tests__ {
    plan tests => 2;

    ok_location line => 9;
    db_stepover;
    ok_location line => 10;
}

