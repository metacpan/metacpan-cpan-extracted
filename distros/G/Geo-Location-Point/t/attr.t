#!perl -wT

use strict;
use warnings;
use Test::Most tests => 39;	# 38 below plus the Test::NoWarnings test
use Test::NoWarnings;

BEGIN {
	use_ok('Geo::Location::Point');
}

# Regression: AUTOLOAD decided whether it was reading or writing by testing the
# value (if(my $value = shift)) and it returned $self->{$key} || $self->{ucfirst($key)}.
# A false value could therefore be neither stored nor read back, so a rejected
# match with a confidence of 0 was indistinguishable from no provenance at all.

READ: {
	my $point = new_ok('Geo::Location::Point' => [
		lat => 51.34,
		long => 1.42
	]);

	ok(!defined($point->confidence()), 'An attribute never set reads as undef');
	ok(!defined($point->found()), 'A boolean attribute never set reads as undef');
}

WRITE: {
	my $point = new_ok('Geo::Location::Point' => [
		lat => 51.34,
		long => 1.42
	]);

	is($point->confidence(0), 0, 'Setting 0 returns 0');
	ok(defined($point->confidence()), 'Setting 0 leaves a defined value');
	is($point->confidence(), 0, 'A stored 0 is read back as 0');
	is($point->{'confidence'}, 0, 'A stored 0 is written to the object');
	ok(!$point->confidence(), 'A stored 0 is still false in boolean context');

	is($point->accuracy(''), '', 'Setting the empty string returns it');
	ok(defined($point->accuracy()), 'Setting the empty string leaves a defined value');
	is($point->accuracy(), '', 'A stored empty string is read back');

	is($point->found('0'), '0', 'Setting the string 0 returns it');
	is($point->found(), '0', 'The string 0 is read back');

	is($point->city('London'), 'London', 'A true value still returns itself');
	is($point->city(), 'London', 'A true value is read back');

	$point->confidence(1);
	is($point->confidence(), 1, 'A true value can replace a false one');
	$point->confidence(0);
	is($point->confidence(), 0, 'A false value can replace a true one');
	is($point->state('DC'), 'DC', 'A true value can be set after a false one');
	$point->state(0);
	is($point->state(), 0, 'An attribute can be emptied with 0');

	$point->accuracy(undef);
	ok(!defined($point->accuracy()), 'An explicit undef clears the value');
}

CONSTRUCTOR: {
	# new() writes the hash directly, so a false value used to be reachable only
	# through the inner hash, never through the accessor
	my $point = new_ok('Geo::Location::Point' => [
		lat => 51.34,
		long => 1.42,
		geocoder => 'OpenAddresses',
		confidence => 0,
		accuracy => '',
		found => 0
	]);

	is($point->geocoder(), 'OpenAddresses', 'A true constructor argument is read back');
	is($point->confidence(), 0, 'confidence => 0 is read back through the accessor');
	ok(defined($point->confidence()), 'confidence => 0 remains defined');
	is($point->accuracy(), '', 'accuracy => "" is read back through the accessor');
	is($point->found(), 0, 'found => 0 is read back through the accessor');
}

CACHE: {
	my $point = new_ok('Geo::Location::Point' => [
		lat => 51.34,
		long => 1.42,
		city => 'London'
	]);

	is($point->as_string(), 'London', 'as_string caches the location');
	is($point->city(''), '', 'Emptying an attribute returns the empty string');
	is($point->as_string(), undef, 'A false write invalidates the as_string cache');
	ok(!defined($point->{'location'}), 'The as_string cache is cleared');
}

CASE: {
	my $point = new_ok('Geo::Location::Point' => [
		lat => 1,
		long => 2,
		'Country' => 'gb'
	]);

	is($point->country(), 'gb', 'A lower case read finds the upper case field');
	is($point->Country(), 'gb', 'The upper case field reads as stored');

	$point->country('');
	is($point->country(), '', 'An emptied field shadows the upper case one');
	ok(defined($point->country()), 'The emptied field is a value, not a fallback');
}
