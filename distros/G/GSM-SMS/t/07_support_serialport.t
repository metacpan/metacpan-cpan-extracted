use strict;
use Test::More tests => 3;
# use Log::Agent;
# logconfig( -level => 99 );

# Testing SerialPort support ...

BEGIN {
	use_ok( 'GSM::SMS::Support::SerialPort' );
	use_ok( 'GSM::SMS::Config' );
}

my $class = "Device::SerialPort";
if ($^O =~ /^MSWin/) {
	$class = "Win32::SerialPort";
}

SKIP: {
	my $cfg;
	eval {
		$cfg = GSM::SMS::Config->new( -check => 1 );
	};
	skip( "Config hinders test: $@", 1 ) if ($@);
	skip( 'Serial not configured', 1 ) unless $cfg->get_config('serial01');

	my $port = $cfg->get_config('serial01')->{'serial_port'};
	skip( 'Could not find a serial device in the config', 1 ) unless $port;	

	my $po = GSM::SMS::Support::SerialPort->new( $port );
	
	isa_ok( $po, $class);
	$po->close;
	$po = undef;
}
