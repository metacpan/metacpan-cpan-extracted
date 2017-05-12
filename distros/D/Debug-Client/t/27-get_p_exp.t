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

start_script('t/eg/14-y_zero.pl');
my $debugger;
$debugger = start_debugger();
$debugger->get;
$debugger->set_breakpoint( 't/eg/14-y_zero.pl', '13' );
$debugger->run;


#Body
foreach ( 1 .. 3 ) {
	$debugger->run();

	ok( $debugger->get_p_exp('$_')    =~ m/$_/, "p \$_ = $_" );
	ok( $debugger->get_p_exp('$line') =~ m/$_/, "p \$line = $_" );
}
ok( $debugger->get_p_exp('2 + 3') == 5, 'p 2 + 3 = 5' );


#Tail
$debugger->quit;
done_testing();

1;

__END__
