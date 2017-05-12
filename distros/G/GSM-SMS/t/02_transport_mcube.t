use strict;
use Test::More tests => 6;

# Testing the MCube support.

BEGIN {
	use_ok( 'GSM::SMS::Transport::MCube' );
	use_ok( 'GSM::SMS::NBS' );
	use_ok( 'GSM::SMS::Config' );
}

# can we correctly instantiate
my $t = GSM::SMS::Transport::MCube->new(
				-name		=> 'mcubetest',
				-userid		=> 'userid',
				-password	=> 'password',
				-match		=> 'match'
			);
isa_ok( $t, 'GSM::SMS::Transport::MCube' );

my $cfg;

# Try to send an actual message
SKIP: {
	eval {
		$cfg = GSM::SMS::Config->new( -check => 1 );
	};
	skip( "Config hinders test: $@", 2 ) if ($@);
	
	my $msisdn = $cfg->get_value( 'default', 'testmsisdn' );
	skip( 'No test msisdn', 2 ) unless $msisdn;

	skip( 'MCube not configured', 2 ) unless $cfg->get_config( 'MCube' );

	my $nbs = GSM::SMS::NBS->new( -transport => 'MCube' );

	ok($nbs, 'NBS stack');
	ok( $nbs->sendSMSTextMessage( $msisdn, 'Hello World from GSM::SMS (MCube)' ) != 0, 'sending a text message');
}
