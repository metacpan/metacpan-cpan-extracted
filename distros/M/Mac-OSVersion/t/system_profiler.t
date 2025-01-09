use Test::More;

my $class  = 'Mac::OSVersion';
my $method = 'system_profiler';

use_ok( $class );
can_ok( $class, $method );

$" = " | ";

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# In scalar context
my $version = $class->$method;
ok( defined $version, "version is defined [$version]" );
#diag( "Got version $version" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# In list context (kernel is last, so it should have six entries)
# This is a fragile test because it depends on order.
{
my @list = $class->$method;
#diag( "Got list @list" );
is( scalar @list, 6, "There are six entries in list" );
my $got_version = join ".", grep { defined } @list[0,1,2];
is( $got_version, $version, "Get same answer as scalar context" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Using it with version
{
my @list = $class->$method( 'system_profiler' );
is( scalar @list, 6, "There are six entries in list" );
}

done_testing();
