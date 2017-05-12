use strict;
use warnings FATAL => 'all';

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

use Term::ReadLine;
if ( $OSNAME eq 'MSWin32' ) {
	$ENV{TERM} = 'dumb';
	local $ENV{PERL_RL} = ' ornaments=0';
}

if ( $OSNAME eq 'MSWin32' ) {
	require Win32::Process;
	require Win32;
	use constant NORMALPRIORITYCLASS => 0x00000020;
}

use Test::More tests => 4;
use Test::Deep;

use File::Temp qw(tempdir);
my ( $host, $port, $porto, $listen, $reuse_addr );
SCOPE: {
	$host       = '127.0.0.1';
	$port       = 24_642 + int rand(1000);
	$porto      = 'tcp';
	$listen     = 1;
	$reuse_addr = 1;
	my ( $dir, $pid ) = run_perl5db( 't/eg/05-io.pl', $host, $port );
	require Debug::Client;
	ok( my $debugger = Debug::Client->new(
			host   => $host,
			port   => $port,
			porto  => $porto,
			listen => $listen,
			reuse  => $reuse_addr
		),
		'initialize with prams'
	);
	$debugger->run;

	sleep 1;

	ok( $debugger->quit, 'quit with prams' );
	if ( $OSNAME eq 'MSWin32' ) {
		$pid->Kill(0) or die "Cannot kill '$pid'";
	}
}

SCOPE: {
	$host = '127.0.0.1';
	$port = 24_642;
	my ( $dir, $pid ) = run_perl5db( 't/eg/05-io.pl', $host, $port );
	require Debug::Client;
	ok( my $debugger = Debug::Client->new(), 'initialize without prams' );
	$debugger->run;

	sleep 1;

	ok( $debugger->quit, 'quit witout prams' );
	if ( $OSNAME eq 'MSWin32' ) {
		$pid->Kill(0) or die "Cannot kill '$pid'";
	}
}

sub run_perl5db {
	my ( $file, $host, $port ) = @_;
	my $dir = tempdir( CLEANUP => 0 );
	my $path = $dir;
	my $pid;
	if ( $OSNAME eq 'MSWin32' ) {
		$path = Win32::GetLongPathName($path);
		local $ENV{PERLDB_OPTS} = "RemotePort=$host:$port";

		sleep 1;

		Win32::Process::Create(
			$pid, $EXECUTABLE_NAME,    qq(perl -d $file ),
			1,    NORMALPRIORITYCLASS, '.',
		) or die Win32::FormatMessage( Win32::GetLastError() );
	} else {
		my $pid = fork();
		die if not defined $pid;
		if ( not $pid ) {
			local $ENV{PERLDB_OPTS} = "RemotePort=$host:$port";

			sleep 1;

			exec qq($EXECUTABLE_NAME -d $file > "$path/out" 2> "$path/err");
			exit 0;
		}
	}
	return ( $dir, $pid );
}

done_testing();

__END__

Info: 06-initialize.t is effectively testing the win32/(linux, osx) bits of t/lib/Debugger.pm
