use Test::More 'no_plan';

use HTTP::Cookies::Chrome;
use File::Spec::Functions;

my $file = catfile( qw( test-corpus Cookies ) );

my $jar = HTTP::Cookies::Chrome->new( File => $file );
isa_ok( $jar, 'HTTP::Cookies::Chrome' );

$jar->save( "$file.save" );
	
