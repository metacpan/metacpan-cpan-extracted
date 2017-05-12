#!/usr/bin/perl

use 5.010;
use strict;
use warnings FATAL => 'all';

# Turn on $OUTPUT_AUTOFLUSH
local $| = 1;

use t::lib::Debugger;

my $pid = start_script('t/eg/02-sub.pl');

use Test::More;
use Test::Deep;

plan( tests => 4 );

my $debugger = start_debugger();
my $perl5db_ver;

{
	my $out = $debugger->get;
	$out =~ m/(?<ver>1.\d{2})(?<index>_\d{2})*$/m;
	$perl5db_ver = $+{ver} // 0;

	like( $out, qr/Loading DB routines from perl5db.pl version/, 'loading line' );
	like( $out, qr{main::\(t/eg/02-sub.pl:4\):\s*\$\| = 1;},     'line 4' );
}

{
	my @out = $debugger->step_in;
	cmp_deeply( \@out, [ 'main::', 't/eg/02-sub.pl', 6, 'my $x = 11;' ], 'line 6' )
		or diag( $debugger->get_buffer );
}

SKIP: {
	skip( "perl5db $] dose not support c [line|sub]", 1 ) if $] =~ m/5.01500(3|4|5)/;
	SKIP: {
		skip( "perl5db v$perl5db_ver dose not support list context", 1 ) if $perl5db_ver == 1.35;
		my @out = $debugger->run('func1');
		cmp_deeply( \@out, [ 'main::func1', 't/eg/02-sub.pl', 16, '  my ( $q, $w ) = @_;' ], 'line 16' )
			or diag( $debugger->get_buffer );
	}
}

{
	$debugger->run;
	$debugger->quit;
}

done_testing();

1;

__END__
