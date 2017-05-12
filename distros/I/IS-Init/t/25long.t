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
$init->tell("hellogrp","long1");
sleep 1;
ok(lines(),1);
ok(lastline(),"long");
$init->tell("hellogrp","long3");
sleep 1;
ok(lines(),1);
ok(lastline(),"long3");
$init->tell("hellogrp","long2");
sleep 1;
ok(lines(),1);
ok(lastline(),"long");
$init->tell("hellogrp","long3");
sleep 1;
ok(lines(),1);
ok(lastline(),"long3");
$init->tell("hellogrp","5");
sleep 1;
ok(lines(),1);
ok(lastline(),"long");

$init->stopall();
ok(1);
