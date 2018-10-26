use strict;
use warnings;

use Test2::V0; no warnings 'void';
use lib 't/lib';
use TestHelper qw(ok_set_action db_continue do_test);
use SampleCode;

$DB::single=1;
our $a = 1;
SampleCode::foo();
is($a, 2, 'Action changed value of $a to 2');

$DB::single=1;  # To pull the null test below off the test queue

sub __tests__ {
    plan tests => 3;

    my $file = 't/lib/SampleCode.pm';
    ok_set_action file => $file, line => 5, code => '$main::a++', 'Create action to increment $a';
    ok_set_action file => $file, line => 5, code => '$main::a=100', inactive => 1, 'Create inactive action';
    db_continue;

    do_test { }; # A null test so the debugger doesn't get disabled due to an empty test queue
}

