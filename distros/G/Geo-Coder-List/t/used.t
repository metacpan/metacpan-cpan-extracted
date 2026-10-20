#!perl -w

use strict;

use Test::DescribeMe qw(author);
use Test::Needs 'Test::Module::Used';

my $used = Test::Module::Used->new(meta_file => 'MYMETA.yml');
# Geo::Location::Predicate is a recommendation at runtime, not a prerequisite:
# geocode() asks it when it is installed and refuses a reference when it is not,
# and t/reference.t skips the comparisons it cannot make.  The tests are graded
# against it, so it is in TEST_REQUIRES, but a check of the runtime prereqs must
# not expect one.
$used->push_exclude_in_libdir('Geo::Location::Predicate');
# The geocoders, CHI and the throttled user agent are optional for testing:
# each test that uses one skips itself, through Test::Needs or the on-line
# switch, when it is not installed.  Makefile.PL asks for the geocoders only
# when on-line tests are enabled.  IPC::Run3 is the same for t/fuzz.t.
$used->push_exclude_in_testdir(qw(
	CHI
	Geo::Coder::Bing
	Geo::Coder::CA
	Geo::Coder::Free
	Geo::Coder::Free::Local
	Geo::Coder::GeocodeFarm
	Geo::Coder::Google::V3
	Geo::Coder::GooglePlaces::V3
	Geo::Coder::Mapbox
	Geo::Coder::OSM
	Geo::Coder::OpenCage
	Geo::Coder::Ovi
	Geo::Coder::Postcodes
	Geo::Coder::RandMcnally
	Geo::Coder::US
	Geo::Coder::US::Census
	Geo::Coder::XYZ
	Geo::GeoNames
	IPC::Run3
	LWP::UserAgent::Throttled
));
$used->ok();
