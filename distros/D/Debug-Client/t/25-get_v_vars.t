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
$debugger->set_breakpoint( 't/eg/14-y_zero.pl', '14' );
$debugger->run;


#Body
ok( $debugger->get_v_vars('$0') =~ m/14-y_zero.pl/, 'V $0' );
ok( $debugger->get_v_vars()     =~ m/14-y_zero.pl/, 'V' );


#Tail
$debugger->quit;
done_testing();

1;

__END__
