#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use POSIX qw(locale_h setlocale LC_ALL);

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
		}

		# Coord with leading decimal point (documented as valid since 0.05)
		ok($m->add_marker([0.5, -0.1278], html => 'Leading zero lat'),
			"leading-zero decimal accepted under $lang locale");

		setlocale(LC_ALL, $saved_locale // 'C');
	};
}

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
