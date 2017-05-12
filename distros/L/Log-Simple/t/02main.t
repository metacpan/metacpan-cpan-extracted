#########################

use Test::More qw( no_plan );

BEGIN { use_ok('Log::Simple', qw( 6 "garbage_for_test::more" ) ) };

set_logger( 2, sub { print STDERR join ( "", @_, "\n") } );

set_logger( 3, sub { print STDERR "$_\n" for @_ } );

logger( 1, "hello" );

my $message = "stupid message";

logger( 7, "this", $message, "never appear" );

logger( 2, "this", "message", "will", "be", "printed", "without", "space" );

logger( 3, "this", "message", "will", "be", "printed", "a", "word", "by", "line" );
