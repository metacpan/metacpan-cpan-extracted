#!/usr/bin/perl -w
use strict;
use Test;
require "t/utils.pl";

# BEGIN { plan tests => 14, todo => [3,4] }
BEGIN { plan tests => 4 }

use IS::Init;

my $init = new IS::Init (
    'config' => 't/isinittab',
    'socket' => 't/isinit.s'
			);

ok($init);
ok($init->{'config'},"t/isinittab");
ok($init->{'socket'},"t/isinit.s");

$init->stopall();

ok(1);
