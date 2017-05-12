#!/usr/bin/perl -w
use strict;
use Test;
require "t/utils.pl";

# BEGIN { plan tests => 14, todo => [3,4] }
BEGIN { plan tests => 6 }

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
`mv t/isinittab t/isinittab.sav` if -s "t/isinittab";
`touch t/isinittab`;
$init->tell(0,0);
sleep 3;
my $pide=lastline();
ok($pide,$pid);
sleep 10;
my $pidf=lastline();
ok($pide,$pidf);
`mv t/isinittab.sav t/isinittab` if -s "t/isinittab.sav";
$init->tell("pidgrp",1);
sleep 1;
my $pidg=lastline();
ok(kill(0,$pidg),1);

$init->stopall();

ok(1);
