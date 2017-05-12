#!/usr/bin/perl

use 5.010;
use strict;
use warnings FATAL => 'all';

# Turn on $OUTPUT_AUTOFLUSH
local $| = 1;

use Test::More;
use Test::Deep;
plan( tests => 2 );


#Top
use t::lib::Debugger;

start_script('t/eg/14-y_zero.pl');
my $debugger;
$debugger = start_debugger();
$debugger->get;


#Body
my $out;

$out = $debugger->get_h_var();
like( $out, qr/Control script execution/s, 'h -> help menu' );

$out = $debugger->get_h_var('h');
like( $out, qr/Help.is.currently.only.available.for.the.new.5.8.command.set/s, 'h h -> 5.8 command set' );


#Tail
$debugger->quit;
done_testing();

1;

__END__



use strict;
use warnings;

# Turn on $OUTPUT_AUTOFLUSH
$| = 1;

use t::lib::Get_h_var;

# run all the test methods in Example::Test
Test::Class->runtests;
