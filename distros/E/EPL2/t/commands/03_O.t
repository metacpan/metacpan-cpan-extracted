use 5.010;
use Test::More;
use_ok 'EPL2::Command::O';
my $obj;
#invalid init
ok( $obj = EPL2::Command::O->new, "Create O command" );
is( $obj->string, "O\n", 'New O string method' );

done_testing;
