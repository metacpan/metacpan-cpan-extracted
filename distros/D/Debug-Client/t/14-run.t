#!/usr/bin/perl

use 5.010;
use strict;
use warnings FATAL => 'all';

# Turn on $OUTPUT_AUTOFLUSH
local $| = 1;

use t::lib::Debugger;

my ( $dir, $pid ) = start_script('t/eg/02-sub.pl');

use Test::More;
use Test::Deep;

plan( tests => 3 );

my $debugger = start_debugger();

{
	my $out = $debugger->get;

	# Loading DB routines from perl5db.pl version 1.28
	# Editor support available.
	#
	# Enter h or `h h' for help, or `man perldebug' for more help.
	#
	# main::(t/eg/02-sub.pl:4):	$| = 1;
	#   DB<1>

	like( $out, qr/Loading DB routines from perl5db.pl version/, 'loading line' );
	like( $out, qr{main::\(t/eg/02-sub.pl:4\):\s*\$\| = 1;},     'line 4' );
}

{
	my @out = $debugger->step_in;
	cmp_deeply( \@out, [ 'main::', 't/eg/02-sub.pl', 6, 'my $x = 11;' ], 'line 6' )
		or diag( $debugger->get_buffer );
}
{

	# Debugged program terminated.  Use q to quit or R to restart,
	#   use o inhibit_exit to avoid stopping after program termination,
	#   h q, h R or h o to get additional info.
	#   DB<1>
	my $out = $debugger->run;

	# like( $out, qr/Debugged program terminated/ );
}

{
	my $out = $debugger->quit;

	# like( $out, qr/1/, 'debugger quit' );
}

done_testing();

1;

__END__
