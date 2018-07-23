use strict;
use warnings;
use utf8;

use Test::More;
if ( !eval { require Test::CheckManifest; 1 } ) {
    plan skip_all => q{Test::CheckManifest required for testing test coverage};
}
Test::CheckManifest::ok_manifest(
    { filter => [qr/(Debian_CPANTS.txt|\.(svn|bak))/] } );
