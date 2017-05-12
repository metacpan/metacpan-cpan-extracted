use Test;
use Devel::TraceCalls;
use strict;

sub f { $_ }

my @tests = (
sub {
    $_ = "HEY!";
    ok f, "HEY!";
},

sub {
    $_ = "HEY!";
    trace_calls "f";
    ok f, "HEY!";
},

);

plan tests => scalar @tests;

$_->() for @tests;
