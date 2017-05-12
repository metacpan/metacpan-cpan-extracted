use Test;
use Devel::TraceCalls {
    Subs => ["foo","bar"],
} ;
use strict;

BEGIN { eval "use Time::HiRes qw( time )" }

## some test subs
sub foo(;$$$) { "foo" };
sub bar($) { "bar" };

my @tests = (
sub {
    ok foo, "foo"
},

);

plan tests => scalar @tests;

$_->() for @tests;
