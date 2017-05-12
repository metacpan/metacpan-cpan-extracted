#!/usr/bin/perl -w
use strict;
use Test;
require "t/utils.pl";

# BEGIN { plan tests => 14, todo => [3,4] }
BEGIN { plan tests => 1 }

use IS::Init;

unless (fork())
{
  my $init = new IS::Init (
      'config' => 't/isinittab',
      'socket' => 't/isinit.s'
			  );
  exit;
}

sleep 1;

my $init = new IS::Init (
    'config' => 't/isinittab',
    'socket' => 't/isinit.s'
			);


$init->stopall();

ok(1);
