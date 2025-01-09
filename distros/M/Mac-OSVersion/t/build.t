use Test::More;

my $class  = 'Mac::OSVersion';
my $method = 'build';

use_ok( $class );
can_ok( $class, $method );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# What does default think?
my ($major, $minor, $point, $name, $build, $kernel ) = $class->version;

is( $class->$method, $build, "Build matches [$build]" );

done_testing();
