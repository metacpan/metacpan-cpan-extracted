# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/test.t'

#########################

use v5.12;
use strict;
use warnings;

use Test2::Tools::Basic;

plan(8);

use Linux::loadavg ':all';

ok(sub {loadavg() == 3},'loadavg()');
ok(sub {loadavg(1) == 1},'loadavg(1)');
ok(sub {loadavg(2) == 2},'loadavg(2)');
ok(sub {loadavg(3) == 3},'loadavg(3)');
ok(LOADAVG_1MIN()==0,'Export: LOADAVG_1MIN');
ok(LOADAVG_5MIN()==1,'Export: LOADAVG_5MIN');
ok(LOADAVG_15MIN()==2,'Export: LOADAVG_15MIN');
ok(sub {sleep 10; 1}, 'Repeat (a lot!)');

diag(sprintf("The current load is: (%s)\n",join(',',loadavg)));

done_testing;
