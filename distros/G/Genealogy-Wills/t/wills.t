#!perl -wT

use strict;
use Test::Most;
use Test::Needs 'Test::HTTPStatus';
use Test::Returns;
use Test::Warnings;

use lib 'lib';
use lib 't/lib';
use MyLogger;

BEGIN {
	use_ok('Genealogy::Wills');
}

SKIP: {
	skip('Database not installed', 8) if(!-r 'lib/Genealogy/Wills/data/wills.sql');

	Test::HTTPStatus->import();

	Database::Abstraction::init('directory' => 'lib/Genealogy/Wills/data');
	if($ENV{'TEST_VERBOSE'}) {
		require Data::Dumper;
		Data::Dumper->import();

		Database::Abstraction::init(logger => MyLogger->new());
	}
	my $search = new_ok('Genealogy::Wills');

	my @cowells = $search->search('Cowell');

	if($ENV{'TEST_VERBOSE'}) {
		diag(Data::Dumper->new([\@cowells])->Dump());
	}

	returns_is(\@cowells, { 'type' => 'arrayref', 'min' => 1 });

	is($cowells[0]->{'last'}, 'Cowell', 'Returned Cowells');
	http_ok($cowells[0]->{'url'}, Test::HTTPStatus::HTTP_OK);

	my @carltons = $search->search({ first => 'Stephen', last => 'Carlton', town => 'Ash, Kent, England' });

	returns_is(\@carltons, { 'type' => 'arrayref', 'min' => 1 });

	cmp_ok(scalar(@carltons), '==', 1, 'Stephen Carlton, Ash, Kent, England');
	http_ok($carltons[0]->{'url'}, Test::HTTPStatus::HTTP_OK);

	@carltons = $search->search(first => 'Stephen', last => 'Carlton');
	returns_is(\@carltons, { 'type' => 'arrayref', 'min' => 4, 'max' => 4 }, 'Stephen Carlton');
	http_ok($carltons[3]->{'url'}, Test::HTTPStatus::HTTP_OK);

	if($ENV{'TEST_VERBOSE'}) {
		diag(Data::Dumper->new([\@carltons])->Dump());
	}
}

done_testing();
