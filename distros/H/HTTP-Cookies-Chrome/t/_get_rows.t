use Test::More 'no_plan';

use File::Spec::Functions;

my $class  = 'HTTP::Cookies::Chrome';
my $method = '_get_rows';
my $file   = catfile( 'test-corpus/cookies.db' );

my $password = '1fFTtVFyMq/J03CMJvPLDg==';

use_ok( $class );
can_ok( $class, $method );

my $cookies = $class->new(
	chrome_safe_storage_password => $password,
	ignore_discard => 1,
	);
isa_ok( $cookies, $class );
can_ok( $cookies, $method );

my $rows = $cookies->$method( $file );
isa_ok( $rows, ref [], "$method returns an array reference" );
is( scalar @$rows, 23, "$method returns 14 rows" );

foreach my $row ( @$rows ) {
	isa_ok( $row, 'HTTP::Cookies::Chrome::Record' );
	}
