use Test::More tests => 4;

BEGIN {
use_ok( 'Flickr::Tools' );
use_ok( 'Flickr::Tools::Cameras' );

use_ok( 'Flickr::Roles::Permissions' );
use_ok( 'Flickr::Types::Tools' );
}

diag( "Testing Flickr::Tools $Flickr::Tools::VERSION" );

exit;

__END__

# Local Variables:
# mode: Perl
# End:
