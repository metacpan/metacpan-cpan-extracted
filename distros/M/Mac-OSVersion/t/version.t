use Test::More;

my $class  = 'Mac::OSVersion';
my $method = 'version';

use_ok( $class );
can_ok( $class, $method );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Scalar context
my $version = $class->$method;
ok( defined $version, "Got something in version [$version] for scalar context" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Without specifying a method
my @list1 = $class->version;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Explicitly specifying a method
my @list2 = $class->version( 'default' );

is_deeply( \@list1, \@list2, "No method and 'default' return the same thing" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Specifying a method that isn't there
eval{ $class->version( 'no_way_jose' ) };
ok( defined $@, "version with unknown method croaks" );

done_testing();
