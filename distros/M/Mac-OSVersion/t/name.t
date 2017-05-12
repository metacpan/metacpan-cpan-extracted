use Test::More 'no_plan';

my $class  = 'Mac::OSVersion';
my $method = 'name';

use_ok( $class );
can_ok( $class, $method );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# What does default think?
my ($major, $minor, $point, $name ) = $class->version;

is( $class->$method, $name, "Name matches [$name]" );
