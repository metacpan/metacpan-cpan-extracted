use Test::More 'no_plan';

my $class  = 'Mac::OSVersion';
my $method = 'uname';

use_ok( $class );
can_ok( $class, $method ); 

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# In scalar context
my $kernel = $class->$method;
ok( defined $kernel, "kernel is defined [$kernel]" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# In list context (kernel is last, so it should have six entries)
# This is a fragile test because it depends on order.
{
my @list = $class->$method;
is( scalar @list, 6, "There are six entries in list" );
is( $list[-1], $kernel, "Get same answer as scalar context" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Using it with version
{
my @list = $class->version( 'uname' );
is( scalar @list, 6, "There are six entries in list" );
is( $list[-1], $kernel, "Get same answer as scalar context" );
}
