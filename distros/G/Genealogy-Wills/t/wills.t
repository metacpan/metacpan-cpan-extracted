#!perl -wT

use strict;
use Test::HTTPStatus;
use Test::Most tests => 10;
use Test::Warnings;

use lib 'lib';
use lib 't/lib';
use MyLogger;

BEGIN {
	use_ok('Genealogy::Wills');
}

SKIP: {
	skip('Database not installed', 8) if(!-r 'lib/Genealogy/Wills/data/wills.sql');

	Database::Abstraction::init('directory' => 'lib/Genealogy/Wills/data');
	if($ENV{'TEST_VERBOSE'}) {
		use Data::Dumper;
		Database::Abstraction::init(logger => MyLogger->new());
	}
	my $search = new_ok('Genealogy::Wills');

	my @cowells = $search->search('Cowell');

	if($ENV{'TEST_VERBOSE'}) {
		diag(Data::Dumper->new([\@cowells])->Dump());
	}

	ok(scalar(@cowells) >= 1);
	is($cowells[0]->{'last'}, 'Cowell', 'Returned Cowells');
	http_ok($cowells[0]->{'url'}, HTTP_OK);

	my @carltons = $search->search({ first => 'Stephen', last => 'Carlton', town => 'Ash, Kent, England' });
	cmp_ok(scalar(@carltons), '==', 1, 'Stephen Carlton, Ash, Kent, England');
	http_ok($carltons[0]->{'url'}, HTTP_OK);

	@carltons = $search->search(first => 'Stephen', last => 'Carlton');
	cmp_ok(scalar(@carltons), '==', 4, 'Stephen Carlton');
	http_ok($carltons[3]->{'url'}, HTTP_OK);

	if($ENV{'TEST_VERBOSE'}) {
		diag(Data::Dumper->new([\@carltons])->Dump());
	}
}
