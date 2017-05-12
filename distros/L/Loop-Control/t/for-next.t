#!/usr/bin/env perl
use warnings;
use strict;
use Loop::Control;
use Test::More tests => 1;
use Test::Differences;
my $output = '';
sub record { $output .= join '' => @_ }
record "before the loop\n";

for my $x (1 .. 4) {
    NEXT { record "reap A iteration $x\n" };
    record "begin iteration $x\n";
    NEXT { record "reap B iteration $x\n" };
    next;
    record "end iteration $x\n";
}
record "after the loop\n";
eq_or_diff $output, <<EOEXPECT, 'output';
before the loop
begin iteration 1
reap B iteration 1
reap A iteration 1
begin iteration 2
reap B iteration 2
reap A iteration 2
begin iteration 3
reap B iteration 3
reap A iteration 3
begin iteration 4
reap B iteration 4
reap A iteration 4
after the loop
EOEXPECT
