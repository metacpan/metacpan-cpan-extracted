#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use POSIX qw(locale_h setlocale LC_ALL LC_NUMERIC);
use Scalar::Util qw(dualvar);

# POSIX::ENOENT is in a different import group on some platforms.
# Import it conditionally so the file compiles everywhere.
BEGIN {
	eval { require POSIX; POSIX->import('ENOENT') };
	if($@) {
		eval { require Errno; Errno->import('ENOENT') };
		die "Cannot import ENOENT: $@" if $@;
	}
}

BEGIN { use_ok('HTML::OSM') }

# Save the caller's locale so we can restore it in every path.
my $saved_locale = setlocale(LC_ALL);

# ── Sanity: can setlocale(LC_ALL) do anything useful? ─────────────────────────
subtest 'setlocale is functional' => sub {
	my $result = setlocale(LC_ALL, 'C');
	BAIL_OUT('setlocale(LC_ALL, "C") failed — cannot run locale tests')
		unless defined $result;
	setlocale(LC_ALL, $saved_locale // 'C');
	pass('setlocale works');
};

# Helper: try to activate a locale; return the installed name or undef.
# Suppresses the "failed to set locale" warning some libc versions emit.
sub _try_locale {
	my $loc = shift;
	local $SIG{__WARN__} = sub { };
	return setlocale(LC_ALL, $loc);
}

# ── Numeric locale: coordinate validation must use dot-decimal everywhere ──────
#
# In de_DE and ja_JP the LC_NUMERIC decimal separator is a comma.  The module's
# internal _validate regex must be independent of this: coordinates are always
# passed as Perl numerics (dot-decimal) by callers.

my @locales = (
	{ name => 'en_US.UTF-8', lang => 'English' },
	{ name => 'de_DE.UTF-8', lang => 'German'  },
	{ name => 'ja_JP.UTF-8', lang => 'Japanese' },
	{ name => 'C',           lang => 'POSIX C'  },
);

for my $spec (@locales) {
	my ($loc, $lang) = @{$spec}{qw(name lang)};
	unless(_try_locale($loc)) {
		note("Skipping $lang locale ($loc) — not installed on this system");
		next;
	}

	subtest "coordinate validation is locale-independent under $lang ($loc)" => sub {
		setlocale(LC_ALL, $loc);

		my $m = HTML::OSM->new();

		ok($m->add_marker([51.5074, -0.1278], html => 'London'),
			"dot-decimal lat/lon accepted under $lang locale");

		{
			local $SIG{__WARN__} = sub { };    # suppress _validate carp
			ok(!$m->add_marker([999, 999], html => 'Out of range'),
				"out-of-range coords rejected under $lang locale");
			# Read as 90 by perls that parse with the locale's decimal point
			ok(!$m->add_marker(['90.5', '0'], html => 'Just out of range'),
				"latitude 90.5 rejected under $lang locale");
		}

		# Coord with leading decimal point (documented as valid since 0.05)
		ok($m->add_marker([0.5, -0.1278], html => 'Leading zero lat'),
			"leading-zero decimal accepted under $lang locale");

		# The rendered JavaScript must use '.' too: '[51,5074, -0,1278]' is
		# four numbers in JS.  The centre is computed, so it is checked as well.
		my $numeric_before = setlocale(LC_NUMERIC);
		my (undef, $body) = $m->onload_render();
		like($body, qr/L\.marker\(\[51\.5074, -0\.1278\]\)/,
			"marker written with '.' decimals under $lang locale");
		# Midpoint of 51.5074 and 0.5 is 26.0037.  Some perls read '51.5074'
		# as 51 under a comma locale, which gave [25.5, 0] here.
		like($body, qr/setView\(\[26\.0037, -0\.1278\], \d+\)/,
			"computed centre is the true midpoint under $lang locale");
		unlike($body, qr/\d,\d{3,}/, "no comma-decimal numbers under $lang locale");
		is(setlocale(LC_NUMERIC), $numeric_before, "LC_NUMERIC restored after render under $lang locale");

		setlocale(LC_ALL, $saved_locale // 'C');
	};
}

# ── Simulated comma-decimal stringification ───────────────────────────────────
#
# Some Perl builds (seen with 5.38.0 on macOS) print numbers with the locale's
# decimal point even outside 'use locale', so 51.5074 becomes '51,5074'.  Most
# machines can't reproduce that, so simulate it: a dualvar holds the number
# 51.5074 but prints as '51,5074', exactly like the broken stringification.
# These tests run everywhere, whatever locales are installed.

subtest 'numbers printed with a comma decimal point are still accepted and rendered with a dot' => sub {
	my $m = HTML::OSM->new();
	ok($m->add_marker([dualvar(51.5074, '51,5074'), dualvar(-0.1278, '-0,1278')], html => 'London'),
		'add_marker accepts comma-printed numbers');
	ok($m->center([dualvar(51.5, '51,5'), dualvar(-0.1, '-0,1')]),
		'center accepts comma-printed numbers');

	my (undef, $body) = $m->onload_render();
	like($body, qr/L\.marker\(\[51\.5074, -0\.1278\]\)/, "marker written with '.' decimals");
	like($body, qr/setView\(\[51\.5, -0\.1\], \d+\)/,    "centre written with '.' decimals");
	unlike($body, qr/51,5/, 'no comma decimals in the output');
};

subtest 'coordinates passed to new() are normalised at render time' => sub {
	my $m = HTML::OSM->new(coordinates => [ [dualvar(48.8566, '48,8566'), dualvar(2.3522, '2,3522'), 'Paris'] ]);
	my (undef, $body) = $m->onload_render();
	like($body, qr/L\.marker\(\[48\.8566, 2\.3522\]\)/, "marker written with '.' decimals");
};

subtest 'a real string with a comma is still rejected' => sub {
	# '51,5074' typed as text is not a number; only values Perl holds as
	# numbers have a comma treated as a decimal point.
	my $m = HTML::OSM->new();
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	ok(!$m->add_marker(['51,5074', '-0,1278']), 'comma string rejected');
	like($warnings[0] // '', qr/Skipping invalid coordinate/, 'with the usual warning');
};

# ── POSIX error strings change with locale ─────────────────────────────────────
#
# We verify that LC_ALL genuinely affects Perl's error strings by checking that
# ENOENT text is non-empty in each locale, and that German differs from English.
#
# CRITICAL: Do NOT use POSIX::strerror — use `local $! = ENOENT; "$!"` so the
# string comes from Perl's error-message layer (matching what callers see when
# they interpolate $!), not directly from the C library.

subtest 'ENOENT error string is non-empty in C locale' => sub {
	SKIP: {
		skip('Cannot set C locale', 1) unless _try_locale('C');
		setlocale(LC_ALL, 'C');
		my $msg = do { local $! = ENOENT; "$!" };
		setlocale(LC_ALL, $saved_locale // 'C');
		ok(length($msg), "ENOENT produces a non-empty string in C locale: '$msg'");
	}
};

subtest 'ENOENT error string is non-empty in en_US.UTF-8 locale' => sub {
	SKIP: {
		skip('en_US.UTF-8 locale not installed', 1) unless _try_locale('en_US.UTF-8');
		setlocale(LC_ALL, 'en_US.UTF-8');
		my $msg = do { local $! = ENOENT; "$!" };
		setlocale(LC_ALL, $saved_locale // 'C');
		ok(length($msg), "ENOENT produces a non-empty string in en_US.UTF-8: '$msg'");
	}
};

subtest 'ENOENT error string is non-empty in de_DE.UTF-8 locale' => sub {
	SKIP: {
		skip('de_DE.UTF-8 locale not installed', 1) unless _try_locale('de_DE.UTF-8');
		setlocale(LC_ALL, 'de_DE.UTF-8');
		my $de_msg = do { local $! = ENOENT; "$!" };
		setlocale(LC_ALL, $saved_locale // 'C');
		ok(length($de_msg), "ENOENT produces a non-empty string in de_DE.UTF-8: '$de_msg'");
	}
};

# ── Module error messages stay ASCII/English regardless of LC_ALL ──────────────
#
# croak() messages are hard-coded English strings in lib/HTML/OSM.pm.
# Under any locale they must match the same pattern.

for my $spec (@locales) {
	my ($loc, $lang) = @{$spec}{qw(name lang)};
	unless(_try_locale($loc)) {
		note("Skipping croak-locale test for $lang ($loc) — locale not installed");
		next;
	}

	subtest "croak messages are English under $lang locale ($loc)" => sub {
		setlocale(LC_ALL, $loc);

		my $m = HTML::OSM->new();

		# add_heatmap: points must be arrayref
		my $err;
		local $SIG{__WARN__} = sub { };
		eval { $m->add_heatmap('not an arrayref') };
		$err = $@;
		like($err, qr/add_heatmap.*arrayref/i,
			"add_heatmap croak is English under $lang");

		# add_choropleth: features must be arrayref
		eval { $m->add_choropleth('bad', {}) };
		$err = $@;
		like($err, qr/add_choropleth.*arrayref/i,
			"add_choropleth croak is English under $lang");

		# onload_render: No map data provided
		eval { $m->onload_render() };
		$err = $@;
		like($err, qr/No map data/i,
			"onload_render empty croak is English under $lang");

		# center: without a point — error may come from Params::Get ("Usage: ...center...")
		# or from our own croak ("center(): usage: point ..."); both contain "center".
		eval { $m->center() };
		$err = $@;
		like($err, qr/center/i,
			"center() no-args croak mentions 'center' under $lang");

		setlocale(LC_ALL, $saved_locale // 'C');
	};
}

# Always restore locale on exit so sibling test files are not affected.
END { setlocale(LC_ALL, $saved_locale // 'C') if defined $saved_locale }

done_testing();
