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

my $isinit="perl -w -I lib ./isinit -c $parms{config} -s $parms{socket}"; 

`cat /dev/null > t/out`;
ok(lines(),0);
unless (fork())
{
  `$isinit pidgrp 1`;
  exit;
}
sleep 3;
ok(lines(),1);
my $pid=lastline();
`mv t/isinittab t/isinittab.sav` if -s "t/isinittab";
`touch t/isinittab`;
`$isinit`; 
sleep 3;
my $pide=lastline();
ok($pide,$pid);
sleep 10;
my $pidf=lastline();
ok($pide,$pidf);
`mv t/isinittab.sav t/isinittab` if -s "t/isinittab.sav";
`$isinit pidgrp 1`; 
sleep 1;
my $pidg=lastline();
ok(kill(0,$pidg),1);
`$isinit -k`; 
sleep 4;
my $pidh=lastline();
ok($pidg,$pidh);
ok(kill(0,$pidg),0);

ok(1);

