use Test::Simple tests => 3;
use E2::Interface;

if( $E2::Interface::THREADED ) {
	ok( my $i = new E2::Interface );
	ok( $i->use_threads( 5 ) );
	ok( $i->join_threads == () );
} else {
	ok( 1 );
	ok( 1 );
	ok( 1 );
}
