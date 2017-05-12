use Test::More tests => 2;

BEGIN {
use_ok( 'List::Util::Superpositions', qw(all any sum) );
}

diag( "Testing List::Util::Superpositions $List::Util::Superpositions::VERSION" );

if (any(sum(1,2), sum(3,4)) == 7) {
    ok('combo: any + sum');
} else {
    fail('combo: any + sum');
}
