#!perl -T

use strict;

use Test::Most tests => 11;

my @modules = (
	'Geo::Coder::Free',
	'Geo::Coder::Free::Config',
	'Geo::Coder::Free::Local',
	'Geo::Coder::Free::MaxMind',
	'Geo::Coder::Free::OpenAddresses',
	'Geo::Coder::Free::DB::MaxMind::admin1',
	'Geo::Coder::Free::DB::MaxMind::admin',
	'Geo::Coder::Free::DB::MaxMind::cities',
	'Geo::Coder::Free::DB::MaxMind::admin2',
	'Geo::Coder::Free::DB::OpenAddr',
	'Geo::Coder::Free::DB::openaddresses',
	# These are only needed when setting up a website
	# 'Geo::Coder::Free::Display',
	# 'Geo::Coder::Free::Display::query',
	# 'Geo::Coder::Free::Display::index',
	# 'Geo::Coder::Free::Utils',
);

BEGIN {
	foreach my $module(@modules) {
		use_ok($module) || print 'Bail out!';
	}
}

foreach my $module(@modules) {
	require_ok($module) || print 'Bail out!';
}

diag("Testing Geo::Coder::Free $Geo::Coder::Free::VERSION, Perl $], $^X");
