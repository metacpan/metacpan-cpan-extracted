use strict;
use warnings;

use Test2::V0;  no warnings 'void';
use lib 't/lib';
use TestHelper qw(ok_location ok_at_end db_step);

my $x = 1;
$DB::single=1;
10;
foo() = 2; # 11
12;
sub foo : lvalue {
    $x;   # 14
}

sub __tests__ {
    plan tests => 5;

    ok_location subroutine => 'MAIN', line => 10, filename => __FILE__;
    db_step;
    ok_location subroutine => 'MAIN', line => 11, filename => __FILE__;
    db_step;
    ok_location subroutine => 'main::foo', line => 14, filename => __FILE__;
    db_step;
    ok_location subroutine => 'MAIN', line => 12, filename => __FILE__;
    db_step;
    ok_at_end;
}



