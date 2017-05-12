#!/usr/bin/perl -w
use strict;
use Test;
require "t/utils.pl";

# BEGIN { plan tests => 14, todo => [3,4] }
BEGIN { plan tests => 4 }

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
$init->tell("pidgrp",0);
sleep 3;
my $pide=lastline();
sleep 10;
my $pidf=lastline();
ok($pide,$pidf);

$init->stopall();

ok(1);
