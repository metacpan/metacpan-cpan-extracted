use Test::More 'no_plan';

my $class  = 'Mac::OSVersion';
my $method = 'minor_to_name';

use_ok( $class );
can_ok( $class, $method ); 

my $name = $class->$method( '4' );
ok( defined $name, "Name is defined" );
is( $name, 'Tiger', "Tiger is the right version" );
