use Test::More tests => 6;

BEGIN {
use_ok( 'Debian::Copyright' );
use_ok( 'Debian::Copyright::Stanza' );
use_ok( 'Debian::Copyright::Stanza::Header' );
use_ok( 'Debian::Copyright::Stanza::Files' );
use_ok( 'Debian::Copyright::Stanza::License' );
use_ok( 'Debian::Copyright::Stanza::OrSeparated' );
}

diag( "Testing $Debian::Copyright::VERSION" );
