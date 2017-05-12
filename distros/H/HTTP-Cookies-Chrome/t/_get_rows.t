use Test::More 'no_plan';

use File::Spec::Functions;

my $class  = 'HTTP::Cookies::Chrome';
my $method = '_get_rows';
my $file   = catfile( 'test-corpus/Cookies' );

use_ok( $class );
can_ok( $class, $method );

my $cookies = $class->new;
isa_ok( $cookies, $class );

my $rows = $cookies->$method( $file );
isa_ok( $rows, ref [], "$method returns an array reference" );
is( scalar @$rows, 14, "$method returns 14 rows" );

foreach my $row ( @$rows )
	{
	isa_ok( $row, 'HTTP::Cookies::Chrome::Record' );
	}
