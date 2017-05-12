#!/usr/bin/perl

use 5.010;
use strict;
use warnings FATAL => 'all';

# Turn on $OUTPUT_AUTOFLUSH
local $| = 1;

use Test::More tests => 10;
use Test::Deep;
use t::lib::Debugger;

# Testing step_in (s) and show_line (.) on a simple script

my ( $dir, $pid ) = start_script('t/eg/01-add.pl');

# diag("PID $pid");
my $debugger = start_debugger();
isa_ok( $debugger, 'Debug::Client' );


{
	my $out = $debugger->get;

	# Loading DB routines from perl5db.pl version 1.28
	# Editor support available.
	#
	# Enter h or `h h' for help, or `man perldebug' for more help.
	#
	# main::(t/eg/01-add.pl:4):	$| = 1;
	#   DB<1>

	# Loading DB routines from perl5db.pl version 1.32
	# Editor support available.
	#
	# Enter h or `h h' for help, or `man perldebug' for more help.
	#
	# main::(01-add.pl:4):	$| = 1;
	#   DB<1>

	# Loading DB routines from perl5db.pl version 1.33
	# Editor support available.
	#
	# Enter h or `h h' for help, or `man perldebug' for more help.
	#
	# main::(01-add.pl:4):	$| = 1;
	#	DB<1>

	like( $out, qr{Loading DB routines from perl5db.pl version}, 'loading line' );
	like( $out, qr{main::\(t/eg/01-add.pl:4\):\s*\$\| = 1;},     'line 4' );
}


{
	my @out = $debugger->step_in;

	# diag("@out");
	# cmp_deeply( \@out, [ 'main::', 't/eg/01-add.pl', 6, 'my $x = 1;' ], 'line 6' )
	# or diag( $debugger->get_buffer );
}

{
	my $out = $debugger->step_in;
	ok( $out =~ s/DB<\d+> $/DB<> /, 'replace number as it can be different on other versions of perl' );
	is( $out, "main::(t/eg/01-add.pl:7):\tmy \$y = 2;\n  DB<> ", 'step_in line 7' ) or do {
		$out =~ s/ /S/g;
		diag($out);
		}
}

{
	my $out = $debugger->show_line;

	# diag($out);
	is( $out, "main::(t/eg/01-add.pl:7):\tmy \$y = 2;", 'show_line line 7' )
		or diag( $debugger->get_buffer );
}

{
	my $out = $debugger->show_view;

	# diag($out);
	is( $out, "4:	\$| = 1;
5 	
6:	my \$x = 1;
7==>	my \$y = 2;
8:	my \$z = \$x + \$y;
9 	
10:	1;
11 	
12 	__END__", 'show_view8'
	) or diag( $debugger->get_buffer );
}

{
	my $out = $debugger->get_h_var;
	like( $out, qr{List/search source lines:}, 'get_h_var' );
}

{
	my @out = $debugger->step_in;
	cmp_deeply( \@out, [ 'main::', 't/eg/01-add.pl', 8, 'my $z = $x + $y;' ], 'line 8' )
		or diag( $debugger->get_buffer );
}

{
	my $out = $debugger->quit;
	like( $out, qr/1/, 'debugger quit' );
}

done_testing();

1;

__END__
