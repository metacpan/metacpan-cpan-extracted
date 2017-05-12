#!perl -T

use Test::More tests => 2;

my $warn;

BEGIN {
	local $SIG{__WARN__} = sub { $warn = $_[0] };
	use_ok( 'IPC::Run::SafeHandles' );
}

like($warn, qr'Use of IPC::Run::SafeHandles without using IPC::Run or IPC::Run3 first');

diag( "Testing IPC::Run::SafeHandles $IPC::Run::SafeHandles::VERSION, Perl $], $^X" );
