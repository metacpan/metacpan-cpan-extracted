use 5.010;
use Test::More;
use_ok 'EPL2::Command::Q';
my $obj;
#invalid init
ok( $obj = EPL2::Command::Q->new, "Create Q command" );
is( $obj->string, "Q0,0\n", 'New Q string method' );

ok( $obj = EPL2::Command::Q->new( continuous => 0 ), "Create Q command (non-continuous)" );
is( $obj->string, "Q0\n", 'New Q string method' );
done_testing;
