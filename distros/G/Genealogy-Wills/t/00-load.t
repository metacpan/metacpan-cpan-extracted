#!perl -T

use strict;

use Test::Most tests => 2;

BEGIN {
	use_ok('Genealogy::Wills') || print 'Bail out!';
}

require_ok('Genealogy::Wills') || print 'Bail out!';

if(my $reporter = $ENV{'PERL_CPAN_REPORTER_CONFIG'}) {
	# https://www.cpantesters.org/cpan/report/ef9905ca-3a1c-11ef-a8e6-11166e8775ea
	if($reporter =~ /smoker/i) {
		diag('AUTOMATED_TESTING added for you');
		$ENV{'AUTOMATED_TESTING'} = 1;
	}
}

# Smoker testing can do sanity checking without building the database
if((!$ENV{'AUTOMATED_TESTING'}) && (!$ENV{'GITHUB_ACTIONS'}) &&
   (!-r 'lib/Genealogy/Wills/data/wills.sql')) {
	diag('Database not installed');
	print 'Bail out!';
}

diag("Testing Genealogy::Wills $Genealogy::Wills::VERSION, Perl $], $^X");
