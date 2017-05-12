use 5.010;
use Test::More;
use_ok 'EPL2::Command::P';
my $obj;
#invalid init
ok( $obj = EPL2::Command::P->new, "Create P command" );
is( $obj->string, "P1\n", 'New P string method' );

done_testing;
