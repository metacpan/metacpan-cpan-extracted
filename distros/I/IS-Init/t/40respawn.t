#!/usr/bin/perl -w
use strict;
use Test;
require "t/utils.pl";

# BEGIN { plan tests => 14, todo => [3,4] }
BEGIN { plan tests => 8 }

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


`cat /dev/null > t/out`;
ok(lines(),0);
$init->tell("pidgrp",1);
sleep 1;
ok(lines(),1);
my $pid=lastline();
# warn "$pid";
sleep 1;
ok(kill(9,$pid),1);
sleep 5;
ok(lines(),1);
my $newpid=lastline();
# warn "$pid, $newpid";
ok(sub{return 1 if $pid != $newpid},1);

`cat /dev/null > t/out`;
ok(lines(),0);
warn "\n'respawning too rapidly' message is normal:\n";
$init->tell("hellogrp",2);
sleep 1 while(lines() < 5);
sleep 5;
ok(lines(),5);

$init->stopall();

ok(1);
