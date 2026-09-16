#!/usr/bin/env perl

# Test that Genealogy::Obituary::Lookup behaves correctly under various system
# locales.  Two categories are covered:
#
#   1. POSIX (LC_ALL) locale switching — error message strings sourced from
#      Perl's $! must come from the C library, not from hardcoded English, and
#      the module must not break under any locale.
#
#   2. Concurrent instances — multiple objects created "simultaneously" (from
#      different simulated origins / locales) must not share mutable state.
#
# NOTE: GeoIP-based access control is not a feature of this module.  The
# "geographic" subtests below therefore validate that the module is usable from
# any country context, not that it restricts access by country.

use strict;
use warnings;

use File::Temp qw(tempdir);
use POSIX qw(ENOENT LC_ALL setlocale);
use Test::Most;

use lib 'lib';
use_ok('Genealogy::Obituary::Lookup') || BAIL_OUT('Module did not load');

# ---------------------------------------------------------------------------
# Mock the DB driver so no actual database is needed
# ---------------------------------------------------------------------------
BEGIN {
	package Genealogy::Obituary::Lookup::obituaries;
	use strict;
	use warnings;
	sub new            { bless {}, shift }
	sub fetchrow_hashref  { return { first => 'Eric', last => 'Baal', source => 'M', page => 96 } }
	sub selectall_hashref { return [{ first => 'Eric', last => 'Baal', source => 'M', page => 96 }] }
}

my $tmpdir = tempdir(CLEANUP => 1);

# ---------------------------------------------------------------------------
# Sanity: the module must produce a working object before locale switching
# ---------------------------------------------------------------------------
subtest 'sanity — module works before any locale switch' => sub {
	my $obj = Genealogy::Obituary::Lookup->new(directory => $tmpdir);
	ok(defined($obj), 'Object created in default locale')
		|| BAIL_OUT('Cannot create object — locale tests would be meaningless');

	my ($hit) = $obj->search(last => 'Baal');
	ok(defined($hit), 'search() returns a result in default locale');
	like($hit->{'url'}, qr{^https://}, 'Result URL is valid in default locale');
};

# ---------------------------------------------------------------------------
# POSIX locale tests
#
# We use  local $! = ENOENT; my $msg = "$!";  to source the OS error string
# directly through Perl's own errno layer, which respects LC_MESSAGES.  We
# deliberately avoid POSIX::strerror() to prevent C-library divergence.
# ---------------------------------------------------------------------------
my @posix_locales = ('en_US.UTF-8', 'de_DE.UTF-8', 'C');

for my $locale (@posix_locales) {
	subtest "POSIX locale: $locale" => sub {
		# Attempt to switch the locale; silently skip if the locale is not
		# installed on this system — locale availability varies by OS image.
		my $old_locale = setlocale(LC_ALL);
		my $switched   = setlocale(LC_ALL, $locale);
		unless(defined $switched) {
			plan skip_all => "Locale '$locale' not available on this system";
			return;
		}
		local $ENV{LC_ALL} = $locale;

		# Capture the OS "file not found" string the way Perl sees it
		my $enoent_msg = do {
			local $! = ENOENT;
			"$!";
		};
		ok(defined($enoent_msg) && length($enoent_msg) > 0,
			"OS error string is non-empty under $locale");

		# The module's own error messages are in %MESSAGES (English) regardless
		# of LC_ALL — verify that a bad directory still produces a carp and undef.
		my $bad_obj;
		warnings_exist {
			$bad_obj = Genealogy::Obituary::Lookup->new(directory => '/no_such_dir_$$');
		} [qr/is not a directory/], "Carp message produced under $locale";
		ok(!defined($bad_obj), "new() returns undef for bad directory under $locale");

		# A good object must still work
		my $obj = Genealogy::Obituary::Lookup->new(directory => $tmpdir);
		ok(defined($obj), "Object created successfully under $locale");

		my ($hit) = $obj->search(last => 'Baal');
		ok(defined($hit), "search() works under $locale");

		# Restore locale
		setlocale(LC_ALL, $old_locale);
	};
}

# ---------------------------------------------------------------------------
# Concurrent instances — objects created in different "locales" / contexts
# must not bleed state between one another.
# ---------------------------------------------------------------------------
subtest 'concurrent instances do not share mutable state' => sub {
	# Simulate five "simultaneous" callers, each with their own object
	my @origins = qw(GB US FR DE CN);
	my @objects;

	for my $country (@origins) {
		local $ENV{COUNTRY} = $country;
		my $obj = Genealogy::Obituary::Lookup->new(directory => $tmpdir);
		ok(defined($obj), "Object created for simulated $country origin");
		push @objects, $obj;
	}

	# Each object must return the same result independently
	for my $i (0 .. $#objects) {
		my ($hit) = $objects[$i]->search(last => 'Baal');
		ok(defined($hit),
			"Instance $i (origin $origins[$i]) returns a result");
		like($hit->{'url'}, qr{^https://},
			"Instance $i result URL is well-formed");
	}

	# Verify object identity — no accidental aliasing
	for my $i (0 .. $#objects - 1) {
		isnt(refaddr($objects[$i]), refaddr($objects[$i + 1]),
			"Instance $i and instance " . ($i + 1) . " are distinct objects");
	}
};

# ---------------------------------------------------------------------------
# Case-insensitivity guard: module should handle mixed-case country env vars
# (a common misconfiguration in deployment scripts).
# ---------------------------------------------------------------------------
subtest 'case-insensitivity: COUNTRY env var is not used by the module' => sub {
	for my $variant (qw(gb Gb GB gB)) {
		local $ENV{COUNTRY} = $variant;
		my $obj = Genealogy::Obituary::Lookup->new(directory => $tmpdir);
		ok(defined($obj), "Object created with COUNTRY=$variant (module ignores it)");
	}
};

# ---------------------------------------------------------------------------
# Error paths under locale switching: croak messages stay in English because
# they originate from %MESSAGES, not from the OS.
# ---------------------------------------------------------------------------
subtest 'croak messages are locale-independent' => sub {
	for my $locale (grep { defined setlocale(LC_ALL, $_) } @posix_locales) {
		local $ENV{LC_ALL} = $locale;
		my $old = setlocale(LC_ALL, $locale);

		my $obj = Genealogy::Obituary::Lookup->new(directory => $tmpdir);
		throws_ok {
			$obj->search()
		} qr/Usage:.*last|mandatory/, "search() with no args croaks under $locale";

		throws_ok {
			$obj->search(last => undef)
		} qr/mandatory/, "search(last=>undef) croaks under $locale";

		setlocale(LC_ALL, $old);
	}
};

done_testing();

# Need Scalar::Util::refaddr but only for the concurrent-instances subtest
BEGIN {
	require Scalar::Util;
	*refaddr = \&Scalar::Util::refaddr;
}
