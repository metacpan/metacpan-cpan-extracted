use strict;
use Test::More tests => 6;

# Test the Novelsoft transport ...

BEGIN { 
	use_ok( 'GSM::SMS::Transport::NovelSoft' );
	use_ok( 'GSM::SMS::NBS' );
	use_ok( 'GSM::SMS::Config' );
}

# can we correctly instantiate
my $t = GSM::SMS::Transport::NovelSoft->new(
					-name 		=> 'noveltest',
					-userid 	=> 'userid',
					-password	=> 'password',
					-match		=> 'match'	
				);
isa_ok( $t, 'GSM::SMS::Transport::NovelSoft' );

my $cfg;
# Now we can try to actually send a message ... if configured for serial
SKIP: {
	eval {
		$cfg = GSM::SMS::Config->new( -check => 1 );
	};
	skip( "Config hinders test: $@", 2 ) if ($@);
	
	my $msisdn = $cfg->get_value( 'default', 'testmsisdn' );
	skip( 'No test msisdn', 2 ) unless $msisdn;

	my $cfg = GSM::SMS::Config->new( -check => 1 );
	skip( 'NovelSoft not configured', 2 ) unless $cfg->get_config('NovelSoft');

	my $nbs = GSM::SMS::NBS->new( -transport => 'NovelSoft' );
	
	ok( $nbs, 'NBS stack' );
	ok( $nbs->sendSMSTextMessage( $msisdn, 'Hello World from GSM::SMS (NovelSoft)' ) != 0, 'Sending a text message');
}
