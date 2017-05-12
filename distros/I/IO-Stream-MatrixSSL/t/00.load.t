use Test::More tests => 3;

BEGIN {
use_ok( 'IO::Stream::MatrixSSL' );
use_ok( 'IO::Stream::MatrixSSL::Client' );
use_ok( 'IO::Stream::MatrixSSL::Server' );
}

diag( "Testing IO::Stream::MatrixSSL $IO::Stream::MatrixSSL::VERSION" );
