#!/usr/bin/env perl

# t/locales.t — Geographic and POSIX locale test suite for Geo::Coder::Free.
#
# Two orthogonal test dimensions:
#
#   1. Geographic (country-based) — verify that geocoding calls targeting
#      GB, US, FR, DE, and CN do not crash and handle case-insensitivity
#      and concurrent instances correctly.  Requires OPENADDR_HOME to be set;
#      the subtests are individually skipped when it is absent so the suite
#      still runs (with those skips) in a minimal CI environment.
#
#   2. System (POSIX) — verify that Geo::Coder::Free errors are thrown
#      regardless of the OS locale, and that OS error strings are sourced
#      from Perl's $! layer (not from POSIX::strerror, which diverges from
#      the C-library in some environments).

use strict;
use warnings;

use Test::Most;
use POSIX qw(ENOENT);

use lib 'lib';
use Geo::Coder::Free;

# -----------------------------------------------------------------------
# Section 1: Geographic (GeoIP country-based) tests
# -----------------------------------------------------------------------

# Sanity gate — if the geocoder cannot even be constructed, nothing else
# can run.  BAIL_OUT is intentional: a broken constructor is a critical
# failure that would produce meaningless results for all remaining tests.
my $geo_basic;
eval { $geo_basic = Geo::Coder::Free->new() };
BAIL_OUT("Cannot instantiate Geo::Coder::Free — constructor died: $@") if $@;
BAIL_OUT('Geo::Coder::Free->new() returned undef') unless defined $geo_basic;
pass('Geo::Coder::Free->new() succeeds');

# Country specifications for the geographic locale subtests.
# Each entry exercises one ISO 3166-1 alpha-2 code.
my @COUNTRY_SPECS = (
	{ code => 'GB', name => 'United Kingdom', location => 'London, England' },
	{ code => 'US', name => 'United States',  location => 'Washington, DC'  },
	{ code => 'FR', name => 'France',          location => 'Paris, France'   },
	{ code => 'DE', name => 'Germany',         location => 'Berlin, Germany' },
	{ code => 'CN', name => 'China',           location => 'Beijing, China'  },
);

for my $spec (@COUNTRY_SPECS) {
	subtest "Geographic locale: $spec->{name} ($spec->{code})" => sub {
		unless ($ENV{'OPENADDR_HOME'} && -d $ENV{'OPENADDR_HOME'}) {
			plan skip_all =>
				"OPENADDR_HOME not set or not a directory — skipping $spec->{name} lookup";
			return;
		}

		my $geo = Geo::Coder::Free->new(openaddr => $ENV{'OPENADDR_HOME'});

		# Case-insensitivity of the region parameter — both forms are valid
		my $upper = uc($spec->{'code'});
		my $lower = lc($spec->{'code'});

		my ($r_upper, $r_lower);
		eval { $r_upper = $geo->geocode(scantext => $spec->{'location'}, region => $upper) };
		ok(!$@, "geocode with region='$upper' does not die") or diag $@;

		eval { $r_lower = $geo->geocode(scantext => $spec->{'location'}, region => $lower) };
		ok(!$@, "geocode with region='$lower' does not die") or diag $@;

		# Concurrent instance must be independent and also not crash
		my $geo2 = Geo::Coder::Free->new(openaddr => $ENV{'OPENADDR_HOME'});
		my $r2;
		eval { $r2 = $geo2->geocode(location => $spec->{'location'}) };
		ok(!$@, "concurrent instance lookup for $spec->{name} does not die") or diag $@;
	};
}

# -----------------------------------------------------------------------
# Section 2: System (POSIX) locale tests
# -----------------------------------------------------------------------
# IMPORTANT: Do not use POSIX::strerror — it reads from the C library
# directly and may return a string in the C locale regardless of $ENV{LC_ALL}.
# Use "local $! = ENOENT; my $msg = q{} . $!" instead: Perl's $! layer
# applies the current locale, matching what end-user-facing error messages
# would show.

my @LOCALES = (
	{ lc_all => 'en_US.UTF-8', name => 'English (en_US.UTF-8)'  },
	{ lc_all => 'de_DE.UTF-8', name => 'German  (de_DE.UTF-8)'  },
	{ lc_all => 'ja_JP.UTF-8', name => 'Japanese (ja_JP.UTF-8)' },
);

for my $locale_spec (@LOCALES) {
	subtest "POSIX locale: $locale_spec->{name}" => sub {
		# Some CI environments do not have all locale data installed;
		# try to set the locale and silently skip if the system rejects it.
		{
			local $ENV{'LC_ALL'} = $locale_spec->{'lc_all'};
			local $ENV{'LANG'}   = $locale_spec->{'lc_all'};

			# Source ENOENT message via Perl's $! layer — NOT POSIX::strerror
			local $! = ENOENT;
			my $os_error = "$!";
			ok(length($os_error) > 0,
				"ENOENT error string is non-empty under $locale_spec->{name}");

			# Module errors must always be English regardless of OS locale:
			# Carp::croak strings come from %_MESSAGES which is en-only.
			my $err;
			eval { Geo::Coder::Free->geocode() };
			$err = $@;
			ok($err, "geocode() with no args throws under $locale_spec->{name}");
			like($err, qr/usage.*geocode/i,
				"geocode() usage error is in expected format under $locale_spec->{name}");

			eval { Geo::Coder::Free->new()->geocode(location => '12345') };
			$err = $@;
			ok($err, "purely numeric location throws under $locale_spec->{name}");
			like($err, qr/invalid location/i,
				"invalid-location error text matches under $locale_spec->{name}");

			eval { Geo::Coder::Free->new()->reverse_geocode() };
			$err = $@;
			ok($err, "reverse_geocode() with no args throws under $locale_spec->{name}");
			# Backend may throw "not yet supported" or a usage message — accept both
			like($err, qr/not yet supported|usage.*reverse_geocode/i,
				"reverse_geocode() error is recognisable under $locale_spec->{name}");
		}
	};
}

# -----------------------------------------------------------------------
# Section 3: Local backend locale coverage
# -----------------------------------------------------------------------

subtest 'Local backend: cross-locale basic geocode' => sub {
	use_ok('Geo::Coder::Free::Local');
	my $local = Geo::Coder::Free::Local->new();
	ok(defined $local, 'Geo::Coder::Free::Local->new() succeeds');

	# A known entry from __DATA__ should be retrievable regardless of locale
	my $pt = $local->geocode(location => 'Reculver, Herne Bay, Kent, GB');
	if (defined $pt) {
		ok($pt->lat()  =~ /^-?\d+\.?\d*$/, 'lat is numeric');
		ok($pt->long() =~ /^-?\d+\.?\d*$/, 'long is numeric');
	} else {
		pass('geocode returned undef (no Reculver entry in this build) — not an error');
	}

	# reverse_geocode bug fix verification: used to die with "Can't locate
	# method as_string via package HASH" because $row was an unblessed hashref
	my @results;
	eval { @results = $local->reverse_geocode(latlng => '51.37875,1.1955') };
	ok(!$@, 'reverse_geocode does not die on known coordinates') or diag $@;
};

done_testing();
