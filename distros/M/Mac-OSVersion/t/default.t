use Test::More;

my $class  = 'Mac::OSVersion';
my $method = 'default';

use_ok( $class );
can_ok( $class, $method );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Without specifying a method
my $version = $class->$method;
ok( defined $version, "Got something in version [$version] for scalar context" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Without specifying a method
my @list1 = $class->$method;
#diag( "Got @list1" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Explicitly specifying a method
my @list2 = $class->version( 'default' );
#diag( "Got @list1" );

is_deeply( \@list1, \@list2, "No method and 'default' return the same thing" );

done_testing();
