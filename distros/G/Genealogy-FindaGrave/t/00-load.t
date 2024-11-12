#!perl -T

use strict;

use Test::Most tests => 2;

BEGIN {
	if(-e 't/online.enabled') {
		use_ok('Genealogy::FindaGrave') || print 'Bail out!';
	} else {
		SKIP: {
			diag('You must be on-line to test Genealogy::FindaGrave');
			skip('You must be on-line to test Genealogy::FindaGrave', 1);
			# Allow cheating for some tests
			unless(defined($ENV{'GITHUB_ACTION'}) || defined($ENV{'CIRCLECI'}) || defined($ENV{'TRAVIS_PERL_VERSION'}) || defined($ENV{'APPVEYOR'})) {
				print 'Bail out!';
			}
		}
	}
}

require_ok('Genealogy::FindaGrave') || print 'Bail out!';

diag("Testing Genealogy::FindaGrave $Genealogy::FindaGrave::VERSION, Perl $], $^X");
