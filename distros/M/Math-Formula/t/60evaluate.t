#!/usr/bin/env perl
  
use warnings;
use strict;
use utf8;

use Math::Formula ();
use Test::More;

my $expr = Math::Formula->new(test => 1);

sub run($$)
{   my ($expression, $expect) = @_;
    $expr->_test($expression);
    $expr->evaluate({}, expect => $expect)->value;
}

my $run0 = run '1+2', 'MF::INTEGER';
ok defined $run0, 'compute integer';
cmp_ok $run0, '==', 3;

my $run1 = run '1+2-3', 'MF::INTEGER';
ok defined $run1, '... multi op';
cmp_ok $run1, '==', 0;

my $run2 = run '1+2*3-4', 'MF::INTEGER';
ok defined $run2, '... with priority';
cmp_ok $run2, '==', 3;

my $run3 = run "true ? 2 : 3", "MF::INTEGER";
ok defined $run3, 'ternary';
cmp_ok $run3, '==', 2, '... true';

my $run4 = run "false ? 2 : 3", "MF::INTEGER";
ok defined $run4;
cmp_ok $run4, '==', 3, '... false';

my $run5 = run "true or false ? 2 : 3", "MF::INTEGER";
ok defined $run5;
cmp_ok $run5, '==', 2, '...prio condition';

my $run6 = run "true ? 2+3 : 4+5", "MF::INTEGER";
ok defined $run6, '... prio then';
cmp_ok $run6, '==', 5;

my $run7 = run "false ? 2+3 : 4+5", "MF::INTEGER";
ok defined $run7, '... prio else';
cmp_ok $run7, '==', 9;

my $run8 = run "false ? 2 : false ? 3 : 4", "MF::INTEGER";
ok defined $run8, '... stacked';
cmp_ok $run8, '==', 4;

done_testing;
