use 5.010;
use Test::More;
use_ok 'EPL2::Command::qq';
my $obj;
#invalid init
ok( $obj = EPL2::Command::qq->new, "Create q command" );
is( $obj->string, "q0\n", 'New q string method' );

done_testing;
