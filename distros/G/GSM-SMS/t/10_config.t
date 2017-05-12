use strict;
use Test::More tests => 8;

# test the GSM::SMS::Config class
BEGIN { use_ok( 'GSM::SMS::Config' ) }

# can we correctly instantiate
my $config = GSM::SMS::Config->new();
isa_ok( $config, 'GSM::SMS::Config' );

# read in the config file
ok( $config->read_config( 't/configtest.config', 1 ),
		'Read a config file' );

# test some desfult settings
is( $config->get_value( undef, 'spooldir' ), '/tmp', 
		'Test default section value' );

# test some transport values
is( $config->get_value( 'Transport', 'a' ), 'b',
		'Get value 1' );
is( $config->get_value( 'Transport', 'c' ), 'd',
		'Get value 2' );

# try the default config
SKIP: {
	eval {
		$config = GSM::SMS::Config->new( -check => 1 );
	};
	skip( "Default config contains no transport definitions! Provide our own in production!", 2 ) if ($@);

	isa_ok( $config, 'GSM::SMS::Config' );

	# test some desfult settings
	ok( defined($config->get_value( undef, 'spooldir' )),
		'Test spooldir' );
}
