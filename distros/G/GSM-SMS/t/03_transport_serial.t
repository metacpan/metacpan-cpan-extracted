use strict;
use Test::More tests => 6;
#use Log::Agent;
#logconfig( -level => 99 );

# Testing the Serial support.

BEGIN { 
	use_ok( 'GSM::SMS::Transport::Serial');
	use_ok( 'GSM::SMS::NBS' );
	use_ok( 'GSM::SMS::Config' );
}

# Now we can try to actually send a message ... if configured for serial
SKIP: {
	my $cfg;

	eval {
		$cfg = GSM::SMS::Config->new( -check => 1 );
	};
	skip( "Config hinders test: $@", 3 ) if ($@);

	my $msisdn = $cfg->get_value( 'default', 'testmsisdn' );
	skip( 'No test msisdn', 3 ) unless $msisdn;
	

	skip( 'Serial not configured', 3 ) unless $cfg->get_config('serial01');
	
	my $serial = $cfg->get_config('serial01');
	my $t = GSM::SMS::Transport::Serial->new(
					-name 		=> $serial->{'name'},
					-match		=> $serial->{'match'},
					-originator => $serial->{'originator'},
					-pin_code	=> $serial->{'pin_code'},
                    -csca       => $serial->{'csca'},
                    -serial_port=> $serial->{'serial_port'},
                    -baud_rate  => $serial->{'baud_rate'},
                    -memorylimit=> $serial->{'memorylimit'}
				);
	isa_ok( $t, 'GSM::SMS::Transport::Serial' );
	if ($t) {
		$t->close;
		$t = undef;
	}
	
	my $nbs = GSM::SMS::NBS->new( -transport => 'serial01' );
	
	ok( $nbs, 'NBS stack' );
	ok( $nbs->sendSMSTextMessage( $msisdn, 'Hello World from GSM::SMS (serial)' ) != 0, 'Sending a text message');
	$nbs = undef;
}
