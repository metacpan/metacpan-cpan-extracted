#!perl -wT

use strict;
use warnings;
use Test::Most tests => 59;	# 58 below plus the Test::NoWarnings test
use Test::NoWarnings;

BEGIN {
	use_ok('Geo::Location::Point');
}

# Regression: AUTOLOAD decided whether it was reading or writing by testing the
# value (if(my $value = shift)) and it returned $self->{$key} || $self->{ucfirst($key)}.
# A false value could therefore be neither stored nor read back, so a rejected
# match with a confidence of 0 was indistinguishable from no provenance at all.
#
# Section 3.2 of BI-Phase6-Dependency-Specs.md then gave the provenance fields
# accessors of their own, which check what they are given, so the fields that
# Phase 6 reads to decide what a marker claims cannot be a value outside the
# vocabulary.  That is what the VALIDATION block below covers.

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

	# accuracy is validated against a vocabulary, so the empty string is not a
	# value it can hold; the false-value round trip it used to demonstrate is
	# still covered by the unvalidated attributes here (found, city, state) and
	# by the constructor's accuracy => '' in CONSTRUCTOR below
	is($point->accuracy('city'), 'city', 'Setting a level returns it');
	ok(defined($point->accuracy()), 'Setting a level leaves a defined value');
	is($point->accuracy(), 'city', 'A stored level is read back');

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

VALIDATION: {
	my $point = new_ok('Geo::Location::Point' => [
		lat => 51.34,
		long => 1.42
	]);

	# A value the reader cannot trust is a bug where it is set, not something to
	# discover from the map later, so the accessors reject it by name.
	my $error;

	eval { $point->confidence(1.5); 1 } or $error = $@;
	like($error, qr/confidence must be a number from 0 to 1/, 'A confidence above 1 is rejected');

	eval { $point->confidence(-0.5); 1 } or $error = $@;
	like($error, qr/confidence must be a number from 0 to 1/, 'A negative confidence is rejected');

	eval { $point->confidence('high'); 1 } or $error = $@;
	like($error, qr/confidence must be a number from 0 to 1/, 'A confidence that is not a number is rejected');

	eval { $point->accuracy('street address'); 1 } or $error = $@;
	like($error, qr/unknown accuracy/, 'An accuracy outside the vocabulary is rejected');

	eval { $point->accuracy(''); 1 } or $error = $@;
	like($error, qr/unknown accuracy/, 'The empty string is not an accuracy');

	eval { $point->city([]); 1 } or $error = $@;
	like($error, qr/city must be a string/, 'A reference is not a city');

	is($point->confidence('0E0'), '0E0', 'A zero confidence is still a number');
	is($point->confidence(1), 1, 'A confidence of 1 is the top of the range');
	# Every level the module publishes is a level it accepts: ACCURACY_LEVELS is
	# what Geo::Coder::Free::Provenance reads, so a name in it that the accessor
	# refused would be a level a backend could report and no point could hold.
	# One assertion over the whole list rather than one per level, so the plan
	# above does not have to be recounted whenever the vocabulary grows.
	my @levels = @{Geo::Location::Point::ACCURACY_LEVELS()};
	is_deeply([map { $point->accuracy($_) } @levels], \@levels,
		'Every level of ACCURACY_LEVELS is accepted and read back');

	is($point->accuracy('address'), 'address', 'The most precise level is accepted');
	is($point->accuracy('country'), 'country', 'The least precise level is accepted');
	is($point->geocoder('Geo::Coder::Free'), 'Geo::Coder::Free', 'geocoder round-trips');
	is($point->database('OpenAddresses'), 'OpenAddresses', 'database round-trips');
	is($point->country('GB'), 'GB', 'country round-trips');
	is($point->state('KY'), 'KY', 'state round-trips');
	is($point->city('London'), 'London', 'city round-trips');

	# The validated accessors read and write the slot AUTOLOAD would, so the two
	# spellings are interchangeable rather than parallel
	is($point->{'city'}, 'London', 'A validated accessor writes the slot AUTOLOAD uses');
	ok(!defined($point->{'location'}), 'A validated write invalidates the as_string cache');

	$point->confidence(undef);
	ok(!defined($point->confidence()), 'An explicit undef clears a validated attribute');
}
