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
sleep 1;
ok(lines(),1);
ok(lastline(),"foo1start");
sleep 3;
$init->tell("foogrp",2);
sleep 3;
ok(lines(),1);
ok(lastline(),"foo1end");

$init->tell("foogrp",0);
sleep 1;
$init->tell("foogrp",1);
sleep 1;
ok(lines(),1);
ok(lastline(),"foo1start");
$init->tell("foogrp",3);
sleep 2;
ok(lines(),1);
ok(lastline(),"foo3");
sleep 7;
ok(lines(),1);
ok(lastline(),"foo3");

$init->stopall();
ok(1);

__END__
