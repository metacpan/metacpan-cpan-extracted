#!/usr/bin/perl -w
use strict;
use Test;
require "t/utils.pl";

# BEGIN { plan tests => 14, todo => [3,4] }
BEGIN { plan tests => 12 }

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
$init->tell("foogrp",1);
$init->tell("bazgrp",1);
sleep 1;
ok(lines(),1);
ok(lastline(),"foo1start");
sleep 2;
$init->tell("bargrp",1);
sleep 1;
ok(lines(),1);
ok(lastline(),"bar1start");
sleep 3;
ok(lines(),1);
ok(lastline(),"foo1end");
sleep 3;
ok(lines(),1);
ok(lastline(),"bar1end");
sleep 3;
ok(lines(),1);
ok(lastline(),"baz1");

$init->stopall();
ok(1);

