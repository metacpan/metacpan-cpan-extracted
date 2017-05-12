#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'MediaWiki::CleanupHTML' ) || print "Bail out!\n";
}

diag( "Testing MediaWiki::CleanupHTML $MediaWiki::CleanupHTML::VERSION, Perl $], $^X" );
