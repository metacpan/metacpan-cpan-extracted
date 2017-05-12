
use Test::More tests => 2;

BEGIN {
	use_ok( 'GearmanX::Worker' );
	use_ok( 'GearmanX::Client' );
}

#diag( "Testing GearmanX::Worker $GearmanX::Worker::VERSION, Perl $], $^X" );
