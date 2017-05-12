# $Id: 12_manifest.t 116 2009-08-02 20:43:55Z roland $
# $Revision: 116 $
# $HeadURL: svn+ssh://ipenburg.xs4all.nl/srv/svnroot/elaine/trunk/HTML-Hyphenate/t/12_manifest.t $
# $Date: 2009-08-02 22:43:55 +0200 (Sun, 02 Aug 2009) $

use strict;
use warnings;
use utf8;

use Test::More;
if ( !eval { require Test::CheckManifest; 1 } ) {
    plan skip_all => q{Test::CheckManifest required for testing test coverage};
}
Test::CheckManifest::ok_manifest(
    { filter => [qr/(Debian_CPANTS.txt|\.(svn|bak))/] } );
