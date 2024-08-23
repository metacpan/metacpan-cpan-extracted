# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/test.t'

#########################

use v5.12;
use strict;
use warnings;

use Test::Simple tests => 8;

use Linux::loadavg ':all';

my @a;

ok(@a = loadavg() && @a == 3,'loadavg()');
ok(@a = loadavg(1) && @a == 1,'loadavg(1)');
ok(@a = loadavg(2) && @a == 2,'loadavg(2)');
ok(@a = loadavg(3) && @a == 3,'loadavg(3)');
ok(LOADAVG_1MIN()==0,'Export: LOADAVG_1MIN');
ok(LOADAVG_5MIN()==1,'Export: LOADAVG_5MIN');
ok(LOADAVG_15MIN()==2,'Export: LOADAVG_15MIN');
ok(repeatN(1_000_000), 'Repeat 1,000,000 times');

sub repeatN {
  @a = loadavg() for (1..shift);
  @a == 3;
}
