use strict;
use warnings;

use Test::More tests => 1;                      # last test to print


BEGIN {
    use_ok( 'MediaWikiUtils' ) || print "Bail out";
}

diag( "Testing MediaWikiUtils $MediaWikiUtils::VERSION, Perl $], $^X" );
