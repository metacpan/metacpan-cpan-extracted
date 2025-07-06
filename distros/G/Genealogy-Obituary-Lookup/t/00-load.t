#!perl -T

use strict;

use Test::Most tests => 2;

BEGIN {
	use_ok('Genealogy::Obituary::Lookup') || print 'Bail out!';
}

require_ok('Genealogy::Obituary::Lookup') || print 'Bail out!';

# Smoker testing can do sanity checking without building the database
if((!$ENV{'AUTOMATED_TESTING'}) && (!$ENV{'GITHUB_ACTIONS'}) &&
   (!-r 'lib/Genealogy/Obituary/Lookup/data/obituaries.sql')) {
	foreach my $e(sort keys (%ENV)) {
		diag("$e = $ENV{$e}");
	}
	diag('Database not installed');
	print 'Bail out!';
}

diag("Testing Genealogy::Obituary::Lookup $Genealogy::Obituary::Lookup::VERSION, Perl $], $^X");
