use Test::More;

my $class  = 'Mac::OSVersion';
my $method = 'minor';

use_ok( $class );
can_ok( $class, $method );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# What does default think?
my ($major, $minor, $point, $name ) = $class->version;

is( $class->minor, $minor, "Minor matches [$minor]" );

done_testing();
