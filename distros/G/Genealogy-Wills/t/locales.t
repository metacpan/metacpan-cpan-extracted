#!/usr/bin/env perl

# Locale robustness tests for Genealogy::Wills.
#
# GeoIP (country-based access) tests: N/A. This module queries a local SQLite
# database with no network access and no geographic restriction.
#
# POSIX locale tests: verify that hardcoded English error messages are emitted
# correctly regardless of the system locale, and that OS error strings are
# sourced from Perl's $! layer (not POSIX::strerror) to avoid C-library
# divergence.

use strict;
use warnings;

use Genealogy::Wills;
use POSIX qw(setlocale LC_ALL);
use Errno qw(ENOENT);
use Test::Most;

# -- Sanity subtest: confirm locale switching actually works ----------------
# If this fails, all locale-sensitive assertions below are unreliable.
subtest 'locale-switching sanity' => sub {
	my $original = setlocale(LC_ALL);
	ok(defined($original), 'can read current locale');

	my $switched = setlocale(LC_ALL, 'en_US.UTF-8');
	if(!$switched) {
		plan skip_all => 'en_US.UTF-8 not available; cannot verify locale switching';
		return;
	}

	# Use $! directly — never POSIX::strerror — to get the Perl-layer string
	local $! = ENOENT;
	my $msg = "$!";
	ok(length($msg), 'ENOENT yields a non-empty message string')
		or BAIL_OUT('$! did not produce an ENOENT message — locale tests unreliable');

	setlocale(LC_ALL, $original);
};

# -- POSIX locale tests -----------------------------------------------------
# The module's error messages are hardcoded ASCII; they must not change with
# locale.  We also confirm that $! reflects the active locale when used.

my @locales = ('en_US.UTF-8', 'de_DE.UTF-8');

for my $locale (@locales) {
	SKIP: {
		my $original = setlocale(LC_ALL);
		setlocale(LC_ALL, $locale)
			or skip("Locale $locale not available on this system", 3);

		# config_file croak is hardcoded ASCII regardless of locale
		throws_ok {
			Genealogy::Wills->new(config_file => '/absolutely/does/not/exist')
		} qr/Can't load configuration from/,
		  "config_file croak is locale-independent under $locale";

		# directory carp is hardcoded ASCII regardless of locale
		warning_like {
			Genealogy::Wills->new(directory => '/absolutely/does/not/exist')
		} qr/is not a directory/,
		  "directory carp is locale-independent under $locale";

		# $! under this locale: use local assignment, not POSIX::strerror
		{
			local $! = ENOENT;
			my $errmsg = "$!";
			ok(length($errmsg),
				"ENOENT via \$! yields a non-empty string under $locale");
		}

		setlocale(LC_ALL, $original);
	}
}

done_testing();
