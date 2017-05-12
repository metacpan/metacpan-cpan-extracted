# Hey Emacs, this is -*- perl -*-
use Test::More tests => 1;

BEGIN {
	use_ok( 'JIRA::Client' );
}

diag( "Testing JIRA::Client $JIRA::Client::VERSION, Perl $], $^X" );
