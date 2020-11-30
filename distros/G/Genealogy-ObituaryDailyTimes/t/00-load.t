#!perl -T

use strict;

use Test::Most tests => 2;

BEGIN {
	use_ok('Genealogy::ObituaryDailyTimes') || print 'Bail out!';
}

require_ok('Genealogy::ObituaryDailyTimes') || print 'Bail out!';

diag("Testing Genealogy::ObituaryDailyTimes $Genealogy::ObituaryDailyTimes::VERSION, Perl $], $^X");
