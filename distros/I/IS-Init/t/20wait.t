#!/usr/bin/perl -w
use strict;
use Test;
require "t/utils.pl";

# BEGIN { plan tests => 14, todo => [3,4] }
BEGIN { plan tests => 11 }

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
$init->tell("hellogrp",1);
sleep 1;
ok(lines(),1);
$init->tell("hellogrp","3");
sleep 1;
ok($init->status(group=>"hellogrp",level=>"3"),"start");
ok(lines(),1);
sleep 3;
ok(lines(),1);
sleep 3;
ok($init->status(group=>"hellogrp",level=>"3"),"run");
ok(lines(),0);
print `cat t/out`;
$init->tell("hellogrp",1);
sleep 1;
ok(lines(),1);
`cat /dev/null > t/out`;
ok(lines(),0);
$init->tell("hellogrp",1);
sleep 1;
ok(lines(),0);

$init->stopall();
ok(1);
