use Test::Simple 'no_plan';
use strict;
use lib './t';
use lib './lib';
use inherit_debug;

my $o = new inherit_debug;

$inherit_debug::DEBUG = 1;

ok( $o->debug_is_on ,'debug is on');


$inherit_debug::DEBUG=0;

ok( !($o->debug_is_on) ,'debug is off');


$inherit_debug::DEBUG=1;

$o->change_callers;




