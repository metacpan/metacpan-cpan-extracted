use Test::More tests => 4;

my $class  = 'Mac::OSVersion';
my $method = 'gestalt';

use_ok( $class );
can_ok( $class, $method ); 

$" = " | ";

SKIP: {
skip "Need Mac::Gestlat for these tests", 2 unless 
	eval{ require 'Mac::Gestalt' };

my @list = eval{ $class->$method };
#diag( "Got @list" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Scalar context
my $version = eval { $class->$method };
ok( defined $version, 
	"Got something in version [$version] for scalar context" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Calling it directly
my @list1 = eval{ $class->$method };
#diag( "Got @list1" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Explicitly specifying a method
my @list2 = eval { $class->version( $method ) };
#diag( "Got @list2" );

is_deeply( \@list1, \@list2, 
	"$method() and version() return the same thing" );
}
