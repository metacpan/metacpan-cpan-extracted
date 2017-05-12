use Test::More 'no_plan';

my $class  = 'Mac::OSVersion';
my $method = 'major';

use_ok( $class );
can_ok( $class, $method );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# What does default think?
my ($major, $minor, $point, $name ) = $class->version;

is( $class->$method, $major, "Major matches [$major]" );
