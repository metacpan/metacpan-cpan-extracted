#!perl -T

use Test::More tests => 1;

BEGIN {
  use_ok( 'MediaWiki::API' );
}

diag( "Testing MediaWiki::API $MediaWiki::API::VERSION, Perl $], $^X" );
