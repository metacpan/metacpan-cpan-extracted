#!/usr/bin/perl

use 5.010;
use strict;
use warnings FATAL => 'all';

# Turn on $OUTPUT_AUTOFLUSH
local $| = 1;

use Test::More;
use Test::Deep;
plan( tests => 3 );


#Top
use t::lib::Debugger;

start_script('t/eg/14-y_zero.pl');
my $debugger;
$debugger = start_debugger();
$debugger->get;
$debugger->set_breakpoint( 't/eg/14-y_zero.pl', '13' );
$debugger->run;


#Body
my $out;
my @out;
foreach ( 1 .. 3 ) {
	$debugger->run();

	my @out;
	@out = $debugger->get_y_zero();
	cmp_deeply( \@out, ["\$line = $_"], "y (0) \$line = $_" ) or diag( $debugger->get_buffer );

}


#Tail
$debugger->quit;
done_testing();

1;

__END__
