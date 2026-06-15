#!/usr/bin/env perl
# =============================================================================
# t/locales.t  —  Geographic and POSIX locale tests for Email::Abuse::Investigator
# =============================================================================

use strict;
use warnings;

use Test::More;
use Test::Mockingbird qw(mock_scoped);
use POSIX qw( ENOENT EACCES );

use FindBin qw( $Bin );
use lib "$Bin/../lib", "$Bin/..";
use Email::Abuse::Investigator;

# ---------------------------------------------------------------------------
# Helper: build a minimal parseable email with the given originating IP
# ---------------------------------------------------------------------------
sub make_email_with_ip {
	my ($ip) = @_;
	return <<"END_EMAIL";
Received: from mail.example.com ($ip)
 by mx.bandsman.co.uk (Postfix); Mon, 01 Jan 2024 00:00:00 +0000
From: Sender <sender\@example.com>
To: victim\@bandsman.co.uk
Subject: Test
Date: Mon, 01 Jan 2024 00:00:00 +0000
Message-ID: <locales-test\@example.com>

Test body.
END_EMAIL
}

# File-scope guard: keeps all seven network seam stubs active for the entire
# test run; mock_scoped() auto-restores originals when $NETWORK_STUBS goes out
# of scope, removing the need for manual 'no warnings redefine' boilerplate.
# Net::DNS::Resolver->search() inside _analyse_domain is NOT a seam; the sort
# fix in the module ensures deterministic NS selection despite DNS round-robin.
my $NETWORK_STUBS = mock_scoped(
	'Email::Abuse::Investigator',
	_reverse_dns           => sub { '(no reverse DNS)' },
	_resolve_host          => sub { return () },
	_whois_ip              => sub { return {} },
	_rdap_lookup           => sub { return {} },
	_domain_whois          => sub { return undef },
	_raw_whois             => sub { return undef },
	_follow_redirect_chain => sub { return undef },
);

# ============================================================================
# SECTION 1: Geographic / country-code checks
# ============================================================================

subtest 'geo_locale_sanity' => sub {
	# Sanity-gate: if high_spam_country flag detection is broken the rest
	# of the geographic subtests are meaningless.
	my $inv = Email::Abuse::Investigator->new();
	$inv->parse_email(make_email_with_ip('1.2.3.4'));

	# Inject a known high-spam country directly so we test the flag mechanism
	# without depending on live GeoIP data.
	no warnings 'redefine';
	local *Email::Abuse::Investigator::originating_ip = sub {
		return {
			ip         => '1.2.3.4',
			rdns       => 'mail.example.cn',
			confidence => 'high',
			country    => 'CN',
			org        => 'Test Org',
			abuse      => 'abuse@example.com',
		};
	};
	use warnings 'redefine';

	my $risk = $inv->risk_assessment();
	my @country_flags = grep { $_->{flag} eq 'high_spam_country' } @{ $risk->{flags} };

	BAIL_OUT('high_spam_country flag detection is broken -- geographic tests will all fail')
		unless @country_flags;

	pass('high_spam_country flag fires for CN (sanity gate)');
};

subtest 'geo_high_spam_countries' => sub {
	for my $cc (qw( CN RU NG VN IN PK BD )) {
		my $inv = Email::Abuse::Investigator->new();
		$inv->parse_email(make_email_with_ip('1.2.3.4'));

		no warnings 'redefine';
		local *Email::Abuse::Investigator::originating_ip = sub {
			return {
				ip         => '1.2.3.4',
				rdns       => "mail.example.${\lc $cc}",
				confidence => 'high',
				country    => $cc,
				org        => 'Test Org',
				abuse      => 'abuse@example.com',
			};
		};
		use warnings 'redefine';

		my $risk = $inv->risk_assessment();
		my @f = grep { $_->{flag} eq 'high_spam_country' } @{ $risk->{flags} };
		ok(scalar @f, "high_spam_country flag raised for country $cc");
	}
};

subtest 'geo_non_flagged_countries' => sub {
	for my $cc (qw( GB US FR DE AU )) {
		my $inv = Email::Abuse::Investigator->new();
		$inv->parse_email(make_email_with_ip('1.2.3.4'));

		no warnings 'redefine';
		local *Email::Abuse::Investigator::originating_ip = sub {
			return {
				ip         => '1.2.3.4',
				rdns       => "mail.example.${\lc $cc}",
				confidence => 'high',
				country    => $cc,
				org        => 'Test Org',
				abuse      => 'abuse@example.com',
			};
		};
		use warnings 'redefine';

		my $risk = $inv->risk_assessment();
		my @f = grep { $_->{flag} eq 'high_spam_country' } @{ $risk->{flags} };
		ok(!scalar @f, "no high_spam_country flag for country $cc");
	}
};

subtest 'geo_country_code_case_sensitivity' => sub {
	# Lowercase 'cn' must NOT trigger the flag -- the regex requires uppercase
	my $inv = Email::Abuse::Investigator->new();
	$inv->parse_email(make_email_with_ip('1.2.3.4'));

	no warnings 'redefine';
	local *Email::Abuse::Investigator::originating_ip = sub {
		return {
			ip         => '1.2.3.4',
			rdns       => 'mail.example.cn',
			confidence => 'high',
			country    => 'cn',   # intentionally lowercase
			org        => 'Test Org',
			abuse      => 'abuse@example.com',
		};
	};
	use warnings 'redefine';

	my $risk = $inv->risk_assessment();
	my @f = grep { $_->{flag} eq 'high_spam_country' } @{ $risk->{flags} };
	ok(!scalar @f, 'lowercase country code does not trigger high_spam_country flag');
};

subtest 'geo_concurrent_instances' => sub {
	# Two objects with different country codes must not share flag state
	my $inv_cn = Email::Abuse::Investigator->new();
	my $inv_gb = Email::Abuse::Investigator->new();
	$inv_cn->parse_email(make_email_with_ip('1.2.3.4'));
	$inv_gb->parse_email(make_email_with_ip('5.6.7.8'));

	{
		no warnings 'redefine';
		local *Email::Abuse::Investigator::originating_ip = sub {
			my $self = shift;
			# Distinguish by object reference to avoid sharing
			return { ip => '1.2.3.4', rdns => 'mail.cn', confidence => 'high',
			         country => 'CN', org => 'Org', abuse => 'a@b.com' }
				if $self == $inv_cn;
			return { ip => '5.6.7.8', rdns => 'mail.gb', confidence => 'high',
			         country => 'GB', org => 'Org', abuse => 'a@b.com' };
		};

		my $risk_cn = $inv_cn->risk_assessment();
		my $risk_gb = $inv_gb->risk_assessment();

		my @cn_flags = grep { $_->{flag} eq 'high_spam_country' } @{ $risk_cn->{flags} };
		my @gb_flags = grep { $_->{flag} eq 'high_spam_country' } @{ $risk_gb->{flags} };

		ok(scalar @cn_flags,  'CN instance has high_spam_country flag');
		ok(!scalar @gb_flags, 'GB instance does not have high_spam_country flag');
	}
};

# ============================================================================
# SECTION 2: POSIX / system locale tests
# ============================================================================
# We test that error-string paths in the module behave consistently across
# locales.  We deliberately do NOT test the module's own error messages here
# (those are in English by design).  Instead we verify:
#   a) Perl's $! interpolation works the way the module relies on it.
#   b) No hard-coded English errno strings appear in the source.
#
# CRITICAL: use `local $! = ENOENT; my $msg = "$!"` -- NOT POSIX::strerror --
# so the string comes from Perl's own layer, matching what the module sees.

subtest 'posix_locale_errno_en_US' => sub {
	local $ENV{LC_ALL} = 'en_US.UTF-8';
	local $ENV{LANG}   = 'en_US.UTF-8';
	local $! = ENOENT;
	my $msg = "$!";
	ok(length($msg), "ENOENT stringifies under en_US.UTF-8 (got: '$msg')");
	isnt($msg, '', 'ENOENT message is not empty under en_US.UTF-8');
};

subtest 'posix_locale_errno_de_DE' => sub {
	local $ENV{LC_ALL} = 'de_DE.UTF-8';
	local $ENV{LANG}   = 'de_DE.UTF-8';
	local $! = ENOENT;
	my $msg = "$!";
	ok(length($msg), "ENOENT stringifies under de_DE.UTF-8 (got: '$msg')");
	isnt($msg, '', 'ENOENT message is not empty under de_DE.UTF-8');
};

subtest 'posix_locale_errno_east_asian' => sub {
	# Use C.UTF-8 as a portable stand-in when a full East Asian locale is
	# absent; the key property being tested is that Perl's $! never returns ''.
	local $ENV{LC_ALL} = 'C.UTF-8';
	local $ENV{LANG}   = 'C.UTF-8';
	local $! = ENOENT;
	my $msg = "$!";
	ok(length($msg), "ENOENT stringifies under C.UTF-8 (got: '$msg')");
	isnt($msg, '', 'ENOENT message is not empty under C.UTF-8');
};

subtest 'posix_locale_eacces' => sub {
	# ENOENT and EACCES must produce distinct messages in every locale
	for my $locale (qw( en_US.UTF-8 de_DE.UTF-8 C.UTF-8 )) {
		local $ENV{LC_ALL} = $locale;
		local $ENV{LANG}   = $locale;
		local $! = ENOENT;
		my $enoent_msg = "$!";
		local $! = EACCES;
		my $eacces_msg = "$!";
		isnt($enoent_msg, $eacces_msg,
			"ENOENT != EACCES under $locale ('$enoent_msg' vs '$eacces_msg')");
	}
};

subtest 'posix_no_hardcoded_english_errno' => sub {
	# The module source must not hard-code English errno phrases like
	# "No such file" or "Permission denied" -- those belong to the OS layer.
	my $src_file = "$Bin/../lib/Email/Abuse/Investigator.pm";
	open my $fh, '<', $src_file
		or BAIL_OUT("Cannot open module source '$src_file': $!");
	my $src = do { local $/; <$fh> };
	close $fh;

	my @hardcoded;
	for my $phrase ('No such file or directory', 'Permission denied',
	                'File exists', 'Is a directory', 'Not a directory') {
		# Allow the phrase only inside comments or POD
		my @lines = grep { /\Q$phrase\E/ } split /\n/, $src;
		my @non_pod_comment = grep { !/^\s*#/ && !/^=/ } @lines;
		push @hardcoded, "'$phrase'" if @non_pod_comment;
	}

	ok(!@hardcoded,
		'No hard-coded English errno strings in module source'
		. (@hardcoded ? ' (found: ' . join(', ', @hardcoded) . ')' : ''));
};

# ============================================================================
# SECTION 3: Output locale stability
# ============================================================================

subtest 'output_locale_stable' => sub {
	# report() output must not change based on LC_ALL; all analyst text is
	# hard-coded English, so switching locale must produce identical output.
	#
	# We use a single object and call parse_email() + report() twice: once
	# under each locale.  Using one object eliminates cross-instance DNS
	# divergence — the CHI cache (or per-object cache) ensures domain lookups
	# return the same data on the second parse.  The sort fix in _analyse_domain
	# additionally guarantees deterministic NS selection even without CHI.
	my $email = make_email_with_ip('91.198.174.42');

	my $inv = Email::Abuse::Investigator->new();

	my $report_en;
	{
		local $ENV{LC_ALL} = 'en_US.UTF-8';
		local $ENV{LANG}   = 'en_US.UTF-8';
		$inv->parse_email($email);
		$report_en = $inv->report();
	}

	my $report_de;
	{
		local $ENV{LC_ALL} = 'de_DE.UTF-8';
		local $ENV{LANG}   = 'de_DE.UTF-8';
		$inv->parse_email($email);
		$report_de = $inv->report();
	}

	is($report_en, $report_de,
		'report() output is identical under en_US.UTF-8 and de_DE.UTF-8');
};

done_testing();
