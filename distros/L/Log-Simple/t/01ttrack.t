#########################

use Test::More tests => 2;
BEGIN { use_ok('Log::Simple', qw( 1 "garbage_for_test::more" ) ) };

ok( time_track(), "time_track" );
