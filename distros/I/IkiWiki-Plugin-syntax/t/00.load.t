use strict;
use warnings;

use Test::More tests => 1;
use lib qw(t t/lib);

use_ok( 'IkiWiki::Plugin::syntax' );

diag( "Testing IkiWiki::Plugin::syntax $IkiWiki::Plugin::syntax::VERSION" );
