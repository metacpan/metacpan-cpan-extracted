use 5.010;
use Test::More;
use_ok 'EPL2::Command::N';
my $obj;
#invalid init
ok( $obj = EPL2::Command::N->new, "Create N command" );
is( $obj->string, "\nN\n", 'New N string method' );

done_testing;
