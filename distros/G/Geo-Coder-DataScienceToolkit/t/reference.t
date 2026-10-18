#!/usr/bin/env perl

# Shared by the six geocoder distributions that each carry the "could this be a
# location?" rule - Geo::Coder::CA, Geo::Coder::DataScienceToolkit,
# Geo::Coder::GeoApify, Geo::Coder::List, Geo::Coder::Postcodes and
# Geo::Coder::XYZ.  The file is the same in every one of their t/ directories:
# it works out which distribution it is running in from that distribution's
# lib/, so there is nothing to edit when it is copied.
#
# A reference is not a location.  A test that looks at the string a reference
# turns into - "ARRAY(0x...)", "My::Row=HASH(0x...)" - finds a non-digit, decides
# the value is a place, and builds a query out of it, which is how all six used
# to behave.  These tests ask for a refusal instead, and check that Geo::Coder::Free::Validate
# is the rule being consulted when it is installed.
#
# Nothing here talks to the network: the user agent below dies the moment a
# lookup is attempted, so "let through" shows up as that death.

use strict;
use warnings;

use FindBin qw($Bin);
use File::Basename qw(basename);
use File::Spec;
use Test::More;

# The distribution this file was installed in: a Geo::Coder module in its lib/.
my $root = File::Spec->catdir($Bin, File::Spec->updir);
my @modules;
for my $file (glob(File::Spec->catfile($root, 'lib', 'Geo', 'Coder', '*.pm'))) {
	(my $name = basename($file)) =~ s/\.pm$//;
	push @modules, "Geo::Coder::$name";
}
plan skip_all => "Cannot find the distribution's module in $root/lib/Geo/Coder"
	unless @modules == 1;

my $MODULE = $modules[0];
(my $module_file = $MODULE) =~ s{::}{/}g;
unshift @INC, File::Spec->catdir($root, 'lib');
require "$module_file.pm";

# ---------------------------------------------------------------------------
# A user agent that is never allowed to make a request
# ---------------------------------------------------------------------------

package Reference::UA;

sub new { return bless { calls => 0 }, shift }

# Reaching this means the value was accepted: the module is about to look it up.
sub get
{
	$_[0]->{'calls'}++;
	die "REFERENCE_TEST_REACHED_LOOKUP\n";
}

# Construction of some of the modules pokes at these.
sub default_header { return $_[0] }
sub env_proxy      { return $_[0] }
sub ssl_opts       { return $_[0] }
sub DESTROY        { }

# ---------------------------------------------------------------------------
# References whose string form would look like a location
# ---------------------------------------------------------------------------

package Reference::Plain;

sub new { return bless {}, shift }

package Reference::String;

use overload '""' => sub { $_[0]->{'string'} }, fallback => 1;

sub new
{
	my ($class, $string) = @_;

	return bless { string => $string }, $class;
}

package Reference::False;

use overload '""' => sub { $_[0]->{'string'} }, 'bool' => sub { 0 }, fallback => 1;

sub new
{
	my ($class, $string) = @_;

	return bless { string => $string }, $class;
}

package main;

# ---------------------------------------------------------------------------
# The values
# ---------------------------------------------------------------------------

my @CASES = (
	['an array reference',                             [1, 2, 3]],
	['a hash reference',                               { location => 'London' }],
	['a plain object',                                 Reference::Plain->new()],
	['an object that prints as a location',            Reference::String->new('London')],
	['an object that prints as digits',                Reference::String->new('0044')],
	['a false object that prints as a location',       Reference::False->new('London')],
);

# ---------------------------------------------------------------------------
# One geocoder, wired to the stub agent
# ---------------------------------------------------------------------------

sub build
{
	my $ua = Reference::UA->new();

	my $geocoder = eval { $MODULE->new(ua => $ua, host => 'localhost', apiKey => 'test') };
	if(!$geocoder) {
		# Geo::Coder::DataScienceToolkit->new() takes no arguments, so anything
		# that rejects them gets a bare object and the agent put in directly.
		$geocoder = eval { $MODULE->new() };
		$geocoder->{'ua'} = $ua if $geocoder;
	}

	return ($geocoder, $ua);
}

# What happened when these arguments were handed to geocode().
sub attempt
{
	my ($geocoder, @arguments) = @_;

	my $error = '';
	{
		local $SIG{__WARN__} = sub { };	# Geo::Coder::List carps as it refuses
		eval { $geocoder->geocode(@arguments); 1 } or $error = $@;
	}

	return $error;
}

my ($geocoder, $ua) = build();
plan skip_all => "Cannot construct $MODULE" unless $geocoder;

# ---------------------------------------------------------------------------
# Every reference is refused before anything is looked up
# ---------------------------------------------------------------------------

for my $case (@CASES) {
	my ($label, $value) = @$case;

	my ($coder, $agent) = build();
	my $error = attempt($coder, location => $value);

	like($error, qr/invalid input/, "$label is refused");
	is($agent->{'calls'}, 0, "$label never reaches the lookup");
}

# ...and the refusals have not made the rule stricter than it was.
{
	my ($coder, $agent) = build();
	my $error = attempt($coder, location => 'London');

	unlike($error, qr/invalid input/, 'a location is still looked up');
}

{
	my ($coder, $agent) = build();
	my $error = attempt($coder, location => '0044');

	like($error, qr/invalid input/, 'a string of digits is still refused');
}

# A scalar reference is one of the ways of passing the string it points at, so
# it is not a reference by the time the rule is asked.  That is not the hole
# these tests are about, and it has to keep working in both calling forms.
for my $arguments (['a scalar reference', \'London'], ['a named scalar reference', (location => \'London')]) {
	my ($label, @arguments) = @{$arguments};
	my ($coder, $agent) = build();
	my $error = attempt($coder, @arguments);

	unlike($error, qr/invalid input/, "$label to a location is passed through");
}

# ---------------------------------------------------------------------------
# Geo::Coder::Free::Validate is the rule, when it is installed
# ---------------------------------------------------------------------------

my $HAVE_VALIDATE = eval {
	require Geo::Coder::Free::Validate;
	Geo::Coder::Free::Validate->can('_valid_location') ? 1 : 0;
};

SKIP: {
	skip('Geo::Coder::Free::Validate is not installed', 2 + scalar(@CASES))
		unless $HAVE_VALIDATE;

	for my $case (@CASES) {
		ok(!Geo::Coder::Free::Validate::_valid_location($case->[1]),
			"the rule refuses $case->[0]");
	}

	# Swap the rule for one that accepts the value: a module that consults it
	# will let the value through, a module carrying its own copy will refuse it.
	# This is what proves the check is the shared rule and not a second copy.
	my $asked = 0;
	{
		no warnings 'redefine';
		local *Geo::Coder::Free::Validate::_valid_location = sub {
			$asked++;
			return 1;
		};

		my ($coder, $agent) = build();
		my $error = attempt($coder, location => [1, 2, 3]);

		is($asked, 1, 'the reference is checked against Geo::Coder::Free::Validate');
		unlike($error, qr/invalid input/, 'the rule decides, not a private copy of it');
	}
}

done_testing();
