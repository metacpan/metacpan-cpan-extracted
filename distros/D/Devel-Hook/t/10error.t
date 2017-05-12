
use Test::More tests => 10;

use Devel::Hook ();

eval { Devel::Hook->push_BEGIN_hook( 1 ) };
like( $@, qr/\ABEGIN blocks must be CODE references/, 'bad BEGIN blocks cause errors' );

eval { Devel::Hook->unshift_BEGIN_hook( undef ) };
like( $@, qr/\ABEGIN blocks must be CODE references/, 'bad BEGIN blocks cause errors' );

SKIP: {
    skip 'UNITCHECK not supported', 2 unless Devel::Hook->_has_support_for( 'UNITCHECK' );

    eval { Devel::Hook->push_UNITCHECK_hook( 1 ) };
    like( $@, qr/\AUNITCHECK blocks must be CODE references/, 'bad UNITCHECK blocks cause errors' );

    eval { Devel::Hook->unshift_UNITCHECK_hook( sub {}, \*STDOUT ) };
    like( $@, qr/\AUNITCHECK blocks must be CODE references/, 'bad UNITCHECK blocks cause errors' );

}

eval { Devel::Hook->push_CHECK_hook( "" ) };
like( $@, qr/\ACHECK blocks must be CODE references/, 'bad CHECK blocks cause errors' );

eval { Devel::Hook->unshift_CHECK_hook( sub {}, "" ) };
like( $@, qr/\ACHECK blocks must be CODE references/, 'bad CHECK blocks cause errors' );

eval { Devel::Hook->push_INIT_hook( sub {}, [] ) };
like( $@, qr/\AINIT blocks must be CODE references/, 'bad INIT blocks cause errors' );

eval { Devel::Hook->unshift_INIT_hook( {} ) };
like( $@, qr/\AINIT blocks must be CODE references/, 'bad INIT blocks cause errors' );

eval { Devel::Hook->push_END_hook( sub {}, 1, sub {} ) };
like( $@, qr/\AEND blocks must be CODE references/, 'bad END blocks cause errors' );

eval { Devel::Hook->unshift_END_hook( sub {}, sub {}, *STDOUT ) };
like( $@, qr/\AEND blocks must be CODE references/, 'bad END blocks cause errors' );



