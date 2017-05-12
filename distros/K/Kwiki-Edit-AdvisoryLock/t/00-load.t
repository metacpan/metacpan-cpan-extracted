#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Kwiki::Edit::AdvisoryLock' );
}

diag( "Testing Kwiki::Edit::AdvisoryLock $Kwiki::Edit::AdvisoryLock::VERSION, Perl $], $^X" );
