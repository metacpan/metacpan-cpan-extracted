use strict;
use warnings;

use Test2::V0;  no warnings 'void';
use lib 't/lib';
use TestHelper qw(ok_location db_stepover);

my $x = 1;
$DB::single = 1;
foo() = 1;
11;
sub foo : lvalue {
    $x;
}

sub __tests__ {
    plan tests => 2;

    ok_location line => 10;
    db_stepover;
    ok_location line => 11;
}

