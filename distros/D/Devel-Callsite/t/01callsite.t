#!/usr/bin/env perl
use strict; use warnings;
use Test::More;
use B;

eval { require Devel::Callsite };
ok(!$@, "loading module");
eval { import Devel::Callsite };
ok(!$@, "running import");
my ($callsite1, $callsite2);
my $site = sub { ${shift()} = callsite();};
$site->(\$callsite1);
$site->(\$callsite2);
ok($callsite1, "Valid first call");
ok($callsite2, "Valid second call");
ok($callsite1 != $callsite2, "Two separate calls");

my $op;
if ($] > 5.026) {
    $op = addr_to_op($callsite1);
    ok $op->isa("B::OP"), "converted $op to to B::OP";
    is $$op, $callsite1, "$op converts back the same address";
}

sub foo { callsite(1) }
sub bar { callsite(), foo(), callsite(0) }

my @nest = bar();
is $nest[1], $nest[0], "Nested callsite";
is $nest[2], $nest[0], "Callsite defaults to level 0";

my @toofar = callsite(1);
is @toofar, 0, "Going too far returns empty list";

my $toofar = callsite(1);
ok !defined $toofar, "Going too far returns undef";

sub doloop { for (1) { callsite(1) } }
sub loop {
    my $x;
    for (1) { $x = doloop() }
    callsite(), doloop(), $x
}

my @loop = loop();
is $nest[1], $nest[0], "Nested callsite inside loop";
is $nest[2], $nest[0], "Callsite inside two loops";

sub deep1 { callsite(3) }
sub deep2 { deep1 }
sub deep3 { deep2 }
sub deep { callsite(), deep3() }

my @deep = deep();
is $deep[1], $deep[0], "Deeply nested callsite";

if ($] > 5.026) {
    my $get_op = sub { return caller_nextop() };
    $op = $get_op->();
    ok $op->isa("B::OP"), "caller_nextop returns a B::OP";
}


done_testing;
