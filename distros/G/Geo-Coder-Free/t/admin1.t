#!perl -wT

# Check the admin 1 database is sensible

use strict;
use warnings;
use Test::Most tests => 5;
use lib 't/lib';
use MyLogger;

BEGIN {
	use_ok('Geo::Coder::Free::DB::MaxMind::admin1');
}

CITIES: {
	Geo::Coder::Free::DB::init(directory => 'lib/Geo/Coder/Free/MaxMind/databases');
	my $admin1 = new_ok('Geo::Coder::Free::DB::MaxMind::admin1' => [logger => new_ok('MyLogger'), no_entry => 1]);

	my $england = $admin1->fetchrow_hashref({ concatenated_codes => 'GB.ENG' });
	is($england->{asciiname}, 'England');

	$england = $admin1->fetchrow_hashref({ asciiname => 'England' });
	is($england->{concatenated_codes}, 'GB.ENG');
}
