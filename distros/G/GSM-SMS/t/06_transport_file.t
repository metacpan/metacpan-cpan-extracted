use strict;
use Test::More tests => 5;

# Test the FIle transport ...

BEGIN { 
	use_ok( 'GSM::SMS::Transport::File' );
	use_ok( 'GSM::SMS::NBS' );
	use_ok( 'GSM::SMS::Config' );
}

# can we correctly instantiate
my $t = GSM::SMS::Transport::File->new(
					-name 		=> 'file',
					-match		=> 'match',
					-out_directory => '/tmp'
				);
isa_ok( $t, 'GSM::SMS::Transport::File' );

my $cfg;
# Now we can try to actually send a message ... if configured for file
SKIP: {
	eval {
		$cfg = GSM::SMS::Config->new( -check => 1 );
	};
	skip( "Config hinders test: $@", 2 ) if ($@);
	
	my $msisdn = $cfg->get_value( 'default', 'testmsisdn' );
	skip( 'No test msisdn', 2 ) unless $msisdn;

	my $cfg = GSM::SMS::Config->new( -check => 1 );
	skip( 'File not configured', 2 ) unless $cfg->get_config('File');

	my $nbs = GSM::SMS::NBS->new( -transport => 'File' );
	
	ok( $nbs, 'NBS stack' );
	ok( $nbs->sendSMSTextMessage( $msisdn, 'Hello World from GSM::SMS (File)' ) != 0, 'Sending a text message');
}
