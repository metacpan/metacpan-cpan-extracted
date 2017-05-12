use Test::More tests => 2;

BEGIN {
use_ok( 'Digest::ssdeep' );
}


can_ok('Digest::ssdeep', qw(ssdeep_compare ssdeep_hash ssdeep_hash_file));

#my $obj = new_ok( $class );




#diag( "Testing Digest::ssdeep $Digest::ssdeep::VERSION" );
