use Test::More tests => 2;

BEGIN {
use_ok( 'List::Util::Superpositions', 'all' );
}

diag( "Testing List::Util::Superpositions $List::Util::Superpositions::VERSION" );

if (all(1,1)) {
    ok('all: and');
} else {
    fail('all: and');
}
