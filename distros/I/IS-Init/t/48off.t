#!/usr/bin/perl -w
use strict;
use Test;
require "t/utils.pl";

# BEGIN { plan tests => 14, todo => [3,4] }
BEGIN { plan tests => 5 }

use IS::Init;

my %parms = (
    'config' => 't/isinittab',
    'socket' => 't/isinit.s'
	    );

unless (fork())
{
  my $init = new IS::Init (%parms);
  exit;
}

sleep 1;

my $init = new IS::Init (%parms);


`echo 'offgrp:off1:1:once:echo \$\$ > t/out; sleep 30' > t/isinittab`;
$init->tell("offgrp",1);
sleep 1;
ok(lines(),1);
my $pid=lastline();
ok(kill(0,$pid),1);
sleep 1;
`echo 'offgrp:off1:1:off:echo \$\$ > t/out; sleep 30' > t/isinittab`;
$init->tell(0,0);
sleep 3;
my $pidb=lastline();
ok($pidb,$pid);
ok(kill(0,$pid),0);
`cp t/isinittab.master t/isinittab`;

$init->stopall();

ok(1);
