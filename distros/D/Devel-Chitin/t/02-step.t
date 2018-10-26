use strict;
use warnings;

use Test2::V0;  no warnings 'void';
use lib 't/lib';
use TestHelper qw(ok_location ok_at_end db_step);

$DB::single=1;
9;
foo(); # 10
11;
sub foo {
    13;
}

sub __tests__ {
    plan tests => 5;

    ok_location subroutine => 'MAIN', line => 9, filename => __FILE__;
    db_step;
    ok_location subroutine => 'MAIN', line => 10, filename => __FILE__;
    db_step;
    ok_location subroutine => 'main::foo', line => 13, filename => __FILE__;
    db_step;
    ok_location subroutine => 'MAIN', line => 11, filename => __FILE__;
    db_step;
    ok_at_end;
}



