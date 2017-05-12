use Test::More tests => 2;

BEGIN {
use_ok( 'List::Util::Superpositions', 'any' );
}

diag( "Testing List::Util::Superpositions $List::Util::Superpositions::VERSION" );

if (any(2,4,6) == 4) {
    ok('any: ==');
} else {
    fail('any: ==');
}
