#########################

use Test::More tests => 3;
BEGIN { use_ok('Log::Simple', qw( 2 "garbage_for_test::more" ) ) };

ok( logger( 1, "test" ), "test logged message" );
ok( logger( 3, "test" ), "test unlogged message" );