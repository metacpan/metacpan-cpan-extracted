use strict;
use warnings;

use Test2::V0; no warnings 'void';
use lib 't/lib';
use TestHelper qw(ok_location db_continue db_stepout);
my $x;
one() = 1;
sub one : lvalue {
    $DB::single=1;
    $x; # 11
}
two() = 2; # 13
sub subtwo : lvalue {
    $DB::single=1;
    $x; # 16
}
sub two : lvalue {
    subtwo() = 22;
    $x;
}
three() = 3;  # 22
sub three : lvalue {
    $DB::single=1;
    25;
    three_three();
    $x;
}
sub three_three : lvalue{
    $x;
}
32;

sub __tests__ {
    plan tests => 6;

    ok_location subroutine => 'main::one', line => 11;
    db_stepout;
    ok_location line => 13;
    db_continue;
    db_stepout;
    ok_location subroutine => 'main::two', line => 20;
    db_stepout;
    ok_location line => 22;
    db_continue;
    ok_location subroutine => 'main::three', line => 25;
    db_stepout;
    ok_location line => 32;
}
