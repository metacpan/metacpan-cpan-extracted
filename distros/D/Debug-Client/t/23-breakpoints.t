#!/usr/bin/perl

use 5.010;
use strict;
use warnings FATAL => 'all';

# Turn on $OUTPUT_AUTOFLUSH
local $| = 1;

use Test::More;
use Test::Deep;
plan( tests => 7 );


#Top
use t::lib::Debugger;

start_script('t/eg/03-return.pl');
my $debugger;
$debugger = start_debugger();
my $out = $debugger->get;


#Body
$debugger->step_in;

ok( $debugger->set_breakpoint( 't/eg/03-return.pl', 'g' ), 'set_breakpoint' );

ok( $debugger->show_breakpoints() =~ m{t/eg/03-return.pl:}, 'show_breakpoints' );

$debugger->run;

#lets ask debugger where we are then :)
like( $debugger->show_line(), qr/return.pl:22/, 'check breakpoint' );

ok( $debugger->remove_breakpoint( 't/eg/03-return.pl', 'g' ), 'remove breakpoint' );

ok( $debugger->show_breakpoints() =~ m{t/eg/03-return.pl:}, 'show_breakpoints' );

ok( !$debugger->set_breakpoint( 't/eg/03-return.pl', 'missing' ), 'set_breakpoint against missing sub' );

ok( !$debugger->set_breakpoint( 't/eg/03-return.pl', '03' ), 'set_breakpoint line not breakable' );


#Tail
$debugger->quit;
done_testing();

1;

__END__
