use Test2::V0;
use Git::Native::Error;

# throw and catch
eval { Git::Native::Error->throw( code => -3, message => 'object not found' ) };
my $err = $@;
isa_ok( $err, ['Git::Native::Error'], 'threw a Git::Native::Error' );
is( $err->code,    -3,                 'code attribute' );
is( $err->message, 'object not found', 'message attribute' );
is( $err->klass,    0,                 'klass defaults to 0' );

# explicit klass
eval { Git::Native::Error->throw( code => -6, klass => 11, message => 'ref locked' ) };
my $err2 = $@;
is( $err2->klass, 11, 'klass stored' );
is( $err2->code,  -6, 'code stored' );

# default message when none given
eval { Git::Native::Error->throw( code => -1 ) };
like( $@->message, qr/unknown/i, 'default message contains "unknown"' );

# stringify includes message
like( "$err", qr/object not found/, 'stringify includes message' );

done_testing;
