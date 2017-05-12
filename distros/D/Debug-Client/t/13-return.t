#!/usr/bin/perl

use 5.010;
use strict;
use warnings FATAL => 'all';

# Turn on $OUTPUT_AUTOFLUSH
local $| = 1;

use t::lib::Debugger;

my ( $dir, $pid ) = start_script('t/eg/03-return.pl');

use Test::More;
use Test::Deep;

plan( tests => 12 );

my $debugger = start_debugger();
my $perl5db_ver;
{
	my $out = $debugger->get;
	$out =~ m/(?<ver>1.\d{2})(_\d{2})*$/m;
	$perl5db_ver = $+{ver} // 0;

	# Loading DB routines from perl5db.pl version 1.28
	# Editor support available.
	#
	# Enter h or `h h' for help, or `man perldebug' for more help.
	#
	# main::(t/eg/01-add.pl:4):	$| = 1;
	#   DB<1>

	like( $out, qr/Loading DB routines from perl5db.pl version/, 'loading line' );
	like( $out, qr{main::\(t/eg/03-return.pl:4\):\s*\$\| = 1;},  'line 4' );
}

{
	my @out = $debugger->step_in;
	cmp_deeply( \@out, [ 'main::', 't/eg/03-return.pl', 6, 'my $x = 11;' ], 'line 6' )
		or diag( $debugger->get_buffer );
}
{
	my @out = $debugger->step_in;
	cmp_deeply( \@out, [ 'main::', 't/eg/03-return.pl', 7, 'my $q = f("foo\nbar");' ], 'line 7' )
		or diag( $debugger->get_buffer );
}
{
	SKIP: {
		skip( "perl5db v$perl5db_ver dose not support list context", 1 ) unless $perl5db_ver < 1.35;
		my @out = $debugger->step_in;
		cmp_deeply( \@out, [ 'main::f', 't/eg/03-return.pl', 16, '    my ($in) = @_;' ], 'line 16' )
			or diag( $debugger->get_buffer );
	}
}

{
	SKIP: {
		skip( "perl5db v$perl5db_ver dose not support list context", 1 ) unless $perl5db_ver < 1.35;
		my @out = $debugger->step_out;
		cmp_deeply( \@out, [ 'main::', 't/eg/03-return.pl', 8, '$x++;', ], 'line 8' )
			or diag( $debugger->get_buffer );
	}
}
{
	SKIP: {
		skip( "perl5db v$perl5db_ver dose not support list context", 1 ) unless $perl5db_ver < 1.35;
		my @out = $debugger->step_in;
		cmp_deeply( \@out, [ 'main::', 't/eg/03-return.pl', 9, q{my @q = g( 'baz', "foo\nbar", 'moo' );} ], 'line 9' )
			or diag( $debugger->get_buffer );
	}
}
{
	SKIP: {
		skip( "perl5db v$perl5db_ver dose not support list context", 1 ) unless $perl5db_ver < 1.35;
		my @out = $debugger->step_in;
		cmp_deeply( \@out, [ 'main::g', 't/eg/03-return.pl', 22, '    my (@in) = @_;' ], 'line 22' )
			or diag( $debugger->get_buffer );
	}
}

{
	SKIP: {
		skip( "perl5db v$perl5db_ver dose not support list context", 1 ) unless $perl5db_ver < 1.35;
		my @out      = $debugger->step_out;
		my $expected = q(0  'baz'
1  'foo
bar'
2  'moo');
		cmp_deeply( \@out, [ 'main::', 't/eg/03-return.pl', 10, '$x++;' ], 'line 10' ) or diag( $debugger->get_buffer );
	}
}

{
	SKIP: {
		skip( "perl5db v$perl5db_ver dose not support list context", 1 ) unless $perl5db_ver < 1.35;
		my @out = $debugger->step_in;
		cmp_deeply(
			\@out, [ 'main::', 't/eg/03-return.pl', 11, q{my %q = h( bar => "foo\nbar", moo => 42 );} ],
			'line 11'
		) or diag( $debugger->get_buffer );
	}
}

{
	SKIP: {
		skip( "perl5db v$perl5db_ver dose not support list context", 1 ) unless $perl5db_ver < 1.35;
		my @out = $debugger->step_in;
		cmp_deeply( \@out, [ 'main::h', 't/eg/03-return.pl', 28, '    my (%in) = @_;' ], 'line 28' )
			or diag( $debugger->get_buffer );
	}
}
{
	SKIP: {
		skip( "perl5db v$perl5db_ver dose not support list context", 1 ) unless $perl5db_ver < 1.35;
		my @out      = $debugger->step_out;
		my $received = $out[4];
		$out[4] = '';

		# TODO check how to test the return data in this case as it looks like an array

		cmp_deeply( \@out, [ 'main::', 't/eg/03-return.pl', 12, '$x++;', '' ], 'line 12' )
			or diag( $debugger->get_buffer );
	}
}


{

	# Debugged program terminated.  Use q to quit or R to restart,
	#   use o inhibit_exit to avoid stopping after program termination,
	#   h q, h R or h o to get additional info.
	#   DB<1>
	my $out = $debugger->step_in;

	# like( $out, qr/Debugged program terminated/ );
}

{
	my $out = $debugger->quit;

	# like( $out, qr/1/, 'debugger quit' );
}

done_testing();

1;

__END__
