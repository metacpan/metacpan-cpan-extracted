use Test::More tests => 5;
use Test::Data qw(Scalar);

use Mac::Path::Util;

my $Not_startup = 'Puck';

my $util = Mac::Path::Util->new();
isa_ok( $util, 'Mac::Path::Util' );

my $Startup = $util->_get_startup;
defined_ok( $Startup );

$Not_startup .= "1984" if $Startup eq $Not_startup;
isnt( $Not_startup, $Startup, "Wrong and right names are different" );

is( $util->_is_startup( $Not_startup ), 'false',
	"Wrong name correctly fails" );
is( $util->_is_startup( $Startup ), 'true',
	"Right name correctly succeeds" );
