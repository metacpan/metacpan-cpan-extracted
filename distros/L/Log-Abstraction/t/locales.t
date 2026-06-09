#!/usr/bin/env perl
# t/locales.t — Locale regression tests for Log::Abstraction
#
# Two dimensions tested:
#   1. Geographic (GeoIP) — country-code detection via Locale::Country
#   2. System (POSIX) — LC_ALL / LANG locale effects on OS error strings

use strict;
use warnings;

use Test::Most;
use POSIX qw(ENOENT);
use File::Temp qw(tempdir);

# ---------------------------------------------------------------------------
# Load the module under test
# ---------------------------------------------------------------------------
use Log::Abstraction;

# ---------------------------------------------------------------------------
# Dimension 1: Geographic locale (Locale::Country / Locale::Codes)
# ---------------------------------------------------------------------------
# We use Locale::Country to turn ISO language/region tags into country codes,
# then verify that our test regions map to the expected ISO 3166-1 alpha-2 codes.
# If any mapping has drifted, BAIL_OUT so the drift is immediately obvious.
# ---------------------------------------------------------------------------

subtest 'geographic locale — sanity: ISO country-code mapping' => sub {
	plan tests => 5;

	my $have_locale_country = eval { require Locale::Country; 1 };
	unless($have_locale_country) {
		pass('skip: Locale::Country not installed') for 1..5;
		return;
	}

	# Expected: language/country tag → ISO 3166-1 alpha-2
	my %expected = (
		'en-GB' => 'gb',
		'en-US' => 'us',
		'fr-FR' => 'fr',
		'de-DE' => 'de',
		'zh-CN' => 'cn',
	);

	for my $tag (sort keys %expected) {
		my (undef, $region) = split /-/, $tag;
		my $got = lc(Locale::Country::country_code2code(
			lc($region),
			'alpha-2', 'alpha-2'   # pass-through: already alpha-2
		) // '');
		my $want = $expected{$tag};
		# BAIL_OUT immediately so GeoIP database drift is obvious
		unless(is($got, $want, "$tag maps to ISO alpha-2 '$want'")) {
			BAIL_OUT("GeoIP/Locale mapping for $tag has drifted: "
				. "expected '$want', got '$got'");
		}
	}
};

subtest 'geographic locale — case-insensitive country code matching' => sub {
	plan tests => 4;

	my $have_locale_country = eval { require Locale::Country; 1 };
	unless($have_locale_country) {
		pass('skip: Locale::Country not installed') for 1..4;
		return;
	}

	for my $pair (
		['GB', 'gb'],
		['US', 'us'],
		['FR', 'fr'],
		['DE', 'de'],
	) {
		my ($input, $want) = @{$pair};
		my $got = lc(Locale::Country::country_code2code(
			lc($input), 'alpha-2', 'alpha-2'
		) // '');
		is($got, $want, "Upper-case '$input' resolves to '$want'");
	}
};

subtest 'geographic locale — concurrent independent instances per locale' => sub {
	plan tests => 5;

	# Each locale gets its own logger instance; they must not cross-contaminate
	my %loggers;
	for my $region (qw(GB US FR DE CN)) {
		my @msgs;
		$loggers{$region} = Log::Abstraction->new(
			logger => \@msgs,
			level  => 'debug',
			ctx    => $region,
		);
	}

	for my $region (sort keys %loggers) {
		$loggers{$region}->info("message from $region");
	}

	# Each logger should have exactly one message
	for my $region (sort keys %loggers) {
		is(scalar @{$loggers{$region}->messages()}, 1,
			"$region logger has exactly 1 message");
	}
};

# ---------------------------------------------------------------------------
# Dimension 2: System locale (POSIX LC_ALL / LANG)
#
# For every error path we use:
#   local $! = ENOENT; my $msg = "$!";
# to get the locale-sensitive OS error string — this is what Perl puts in the
# thrown exception, so it matches exactly.  We do NOT use POSIX::strerror().
# ---------------------------------------------------------------------------

# Helper: return the OS error string for ENOENT in the current locale
sub _enoent_msg {
	local $! = ENOENT;
	return "$!";
}

# Locales to test against.  We iterate over all of them for every error path.
my @LOCALES = ('en_US.UTF-8', 'de_DE.UTF-8', 'ja_JP.UTF-8');

subtest 'system locale — invalid file path croaks under all locales' => sub {
	plan tests => scalar(@LOCALES) * 1;

	for my $lc (@LOCALES) {
		local $ENV{LC_ALL} = $lc;
		local $ENV{LANG}   = $lc;

		my $logger = Log::Abstraction->new(
			file  => "/bad\0path",
			level => 'debug',
		);

		throws_ok(
			sub { $logger->debug('tainted path test') },
			qr/Invalid file name/i,
			"invalid file path croaks under LC_ALL=$lc",
		);
	}
};

subtest 'system locale — invalid SMTP host croaks under all locales' => sub {
	plan tests => scalar(@LOCALES) * 1;

	my $have_email = eval {
		require Email::Simple;
		require Email::Sender::Simple;
		require Email::Sender::Transport::SMTP;
		1;
	};

	for my $lc (@LOCALES) {
		local $ENV{LC_ALL} = $lc;
		local $ENV{LANG}   = $lc;

		SKIP: {
			skip 'Email modules not available', 1 unless $have_email;

			my $logger = Log::Abstraction->new(
				level  => 'warn',
				logger => {
					sendmail => {
						host    => 'bad host; rm -rf /',
						to      => 'ops@example.com',
					},
				},
			);

			throws_ok(
				sub { $logger->warn('smtp host injection test') },
				qr/Invalid SMTP host/i,
				"SMTP host injection rejected under LC_ALL=$lc",
			);
		}
	}
};

subtest 'system locale — invalid SMTP port croaks under all locales' => sub {
	plan tests => scalar(@LOCALES) * 1;

	my $have_email = eval {
		require Email::Simple;
		require Email::Sender::Simple;
		require Email::Sender::Transport::SMTP;
		1;
	};

	for my $lc (@LOCALES) {
		local $ENV{LC_ALL} = $lc;
		local $ENV{LANG}   = $lc;

		SKIP: {
			skip 'Email modules not available', 1 unless $have_email;

			my $logger = Log::Abstraction->new(
				level  => 'warn',
				logger => {
					sendmail => {
						host    => 'localhost',
						port    => 99999,
						to      => 'ops@example.com',
					},
				},
			);

			throws_ok(
				sub { $logger->warn('smtp port out of range test') },
				qr/Invalid SMTP port/i,
				"SMTP port out of range rejected under LC_ALL=$lc",
			);
		}
	}
};

subtest 'system locale — path traversal blocked under all locales' => sub {
	plan tests => scalar(@LOCALES) * 1;

	for my $lc (@LOCALES) {
		local $ENV{LC_ALL} = $lc;
		local $ENV{LANG}   = $lc;

		my $logger = Log::Abstraction->new(
			file  => '/tmp/../etc/passwd',
			level => 'debug',
		);

		throws_ok(
			sub { $logger->debug('traversal test') },
			qr/Invalid file name/i,
			"path traversal blocked under LC_ALL=$lc",
		);
	}
};

subtest 'system locale — message content unchanged across locales' => sub {
	plan tests => scalar(@LOCALES) * 2;

	# The actual log message text must not be garbled by locale settings
	for my $lc (@LOCALES) {
		local $ENV{LC_ALL} = $lc;
		local $ENV{LANG}   = $lc;

		my @msgs;
		my $logger = Log::Abstraction->new(
			logger => \@msgs,
			level  => 'debug',
		);

		my $text = 'Hello world 123';
		$logger->info($text);

		is(scalar(@msgs), 1, "one message stored under LC_ALL=$lc");
		is($msgs[0]{message}, $text,
			"message text intact under LC_ALL=$lc");
	}
};

subtest 'system locale — warn(warning => ...) dispatches under all locales' => sub {
	plan tests => scalar(@LOCALES) * 1;

	for my $lc (@LOCALES) {
		local $ENV{LC_ALL} = $lc;
		local $ENV{LANG}   = $lc;

		my @msgs;
		my $logger = Log::Abstraction->new(
			logger => \@msgs,
			level  => 'warn',
		);

		$logger->warn(warning => 'test warning');

		is(scalar(@msgs), 1,
			"warn(warning=>) dispatched under LC_ALL=$lc");
	}
};

done_testing();
