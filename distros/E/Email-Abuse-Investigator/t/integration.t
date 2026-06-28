#!/usr/bin/env perl
# =============================================================================
# t/integration.t  —  Black-box, end-to-end integration tests for
#					 Email::Abuse::Investigator
#
# Philosophy
# ----------
# These tests treat the package as a sealed unit.  No internal slots are
# read or written; no private methods are called.  Every subtest:
#
#   1. Constructs a realistic raw email from scratch
#   2. Feeds it to new() + parse_email()
#   3. Calls only the documented public API
#   4. Asserts on the observable output of those calls
#
# Network I/O is replaced with deterministic stubs installed at the package
# level before each subtest and restored afterwards.  The stubs are as
# realistic as possible — they return data shaped exactly like real DNS and
# WHOIS responses, not just empty hashes.
#
# Scenarios are drawn directly from the POD description and Algorithm section.
#
# Run:
#   prove -lv t/integration.t
# =============================================================================

use strict;
use warnings;

use Test::More;
use MIME::Base64	  qw( encode_base64 );
use MIME::QuotedPrint qw( encode_qp );
use POSIX	 qw( strftime );

use FindBin qw( $Bin );
use lib "$Bin/../lib", "$Bin/..";

BEGIN {
	use_ok('Email::Abuse::Investigator');
}

# ---------------------------------------------------------------------------
# Network stub infrastructure
# ---------------------------------------------------------------------------
# Each stub_*() function installs package-level overrides that persist for
# the duration of the enclosing lexical block.  Call restore_stubs() at the
# end of every subtest that calls any stub function.

my %_ORIGINAL;
BEGIN {
	for my $fn (qw(
		_reverse_dns  _resolve_host  _whois_ip
		_domain_whois _raw_whois     _rdap_lookup
		_follow_redirect_chain
	)) {
		no strict 'refs';
		$_ORIGINAL{$fn} = \&{ "Email::Abuse::Investigator::$fn" };
	}
}

sub restore_stubs {
	no warnings 'redefine';
	for my $fn (keys %_ORIGINAL) {
		no strict 'refs';
		*{ "Email::Abuse::Investigator::$fn" } = $_ORIGINAL{$fn};
	}
}

# Install a complete, coherent set of network stubs.
# Parameters (all optional):
#   rdns		 => sub($ip)		 | string  — rDNS result
#   resolve	  => sub($host)	   | hashref | string — A-record result
#   whois_ip	 => sub($ip)		 | hashref — IP WHOIS result
#   domain_whois => sub($dom)		| string  — raw domain WHOIS text
sub install_stubs {
	my (%ov) = @_;
	no warnings 'redefine';

	*Email::Abuse::Investigator::_reverse_dns = ref($ov{rdns}) eq 'CODE'
		? $ov{rdns}
		: sub { $ov{rdns} // undef };

	*Email::Abuse::Investigator::_resolve_host = ref($ov{resolve}) eq 'CODE'
		? $ov{resolve}
		: sub {
			my (undef, $host) = @_;
			return $host if $host =~ /^\d{1,3}(?:\.\d{1,3}){3}$/;
			my $r = $ov{resolve};
			return undef unless defined $r;
			return ref $r eq 'HASH' ? ($r->{$host} // undef) : $r;
		};

	*Email::Abuse::Investigator::_whois_ip = ref($ov{whois_ip}) eq 'CODE'
		? $ov{whois_ip}
		: sub {
			my (undef, $ip) = @_;
			my $w = $ov{whois_ip};
			return {} unless defined $w;
			return ref $w eq 'HASH' ? $w : {};
		};

	*Email::Abuse::Investigator::_domain_whois = ref($ov{domain_whois}) eq 'CODE'
		? $ov{domain_whois}
		: sub { $ov{domain_whois} // undef };

	# These are never needed in integration tests (covered by the above)
	*Email::Abuse::Investigator::_raw_whois            = sub { undef };
	*Email::Abuse::Investigator::_rdap_lookup          = sub { {} };

	# Redirect-following: default to no-op (undef = no redirect found).
	# Tests that exercise redirect chain behaviour supply their own stub via
	# the 'follow_redirect' key.
	*Email::Abuse::Investigator::_follow_redirect_chain = ref($ov{follow_redirect}) eq 'CODE'
		? $ov{follow_redirect}
		: sub { undef };

	# Suppress the AnyEvent::DNS parallel resolver so no real DNS queries
	# are fired when multiple URL hostnames appear in an email body.
	*Email::Abuse::Investigator::_parallel_resolve_hosts = sub {};
}

# ---------------------------------------------------------------------------
# Helper: reload Email::Abuse::Investigator with named optional modules blocked.
#
# Mechanism:
#   1. Blocks the named modules via Test::Without::Module so that any
#      require() attempt for them fails during the forced reload.
#   2. Saves and removes their %INC entries, then deletes the main module
#      from %INC and force-requires it so its $HAS_* flags are re-evaluated
#      with the missing dependencies.
#   3. Executes $code — the caller is responsible for calling install_stubs()
#      and restore_stubs() inside $code as usual.
#   4. Unblocks the modules, restores %INC, and reloads the main module a
#      second time so $HAS_* flags return to their original compile-time
#      values for subsequent subtests.
#
# If Test::Without::Module is not installed each surrounding subtest is
# declared skip_all so it appears as a proper skip rather than a failure.
# ---------------------------------------------------------------------------
sub without_optionals {
	my ($blocked_ref, $code) = @_;

	unless (eval { require Test::Without::Module; 1 }) {
		Test::More::plan(skip_all => 'Test::Without::Module not installed');
		return;
	}

	# Flush the global CHI Memory store before each OD test.  The module uses
	# CHI->new(driver=>'Memory', global=>1), which shares a process-wide hash
	# across all instances.  Without this flush, dom:/url:/whois_ip: entries
	# written by earlier subtests survive the module reload and override the
	# fresh stubs installed by the OD test, producing wrong field values.
	eval {
		require CHI;
		CHI->new(driver => 'Memory', global => 1, expires_in => 3600)->clear();
	};

	# Save and purge %INC entries for every module we are about to block.
	my %saved_inc;
	for my $mod (@$blocked_ref) {
		(my $key = "$mod.pm") =~ s{::}{/}g;
		$saved_inc{$key} = delete $INC{$key};   # undef when module not installed
	}

	# Activate the blocker and force-reload the analyser module so that the
	# eval{} probes inside its BEGIN block see the missing dependencies and
	# set the corresponding $HAS_* flags to undef/false.
	Test::Without::Module->import(@$blocked_ref);
	delete $INC{'Email/Abuse/Investigator.pm'};
	{ no warnings 'redefine'; require Email::Abuse::Investigator; }

	$code->();

	# Remove the block, restore %INC, and reload with full dependencies so
	# that $HAS_* flags are correct for all subsequent subtests.
	Test::Without::Module->unimport(@$blocked_ref);
	for my $key (keys %saved_inc) {
		$INC{$key} = $saved_inc{$key} if defined $saved_inc{$key};
	}
	delete $INC{'Email/Abuse/Investigator.pm'};
	{ no warnings 'redefine'; require Email::Abuse::Investigator; }
}

# ---------------------------------------------------------------------------
# Helper: build a raw RFC 2822 email string
# ---------------------------------------------------------------------------
sub make_raw_email {
	my (%h) = @_;

	# Received: chain — pass an arrayref for multiple hops (most-recent first)
	my @rcvd = ref($h{received}) eq 'ARRAY'
		? @{ $h{received} }
		: ($h{received} // 'from ext.mail.example (ext.mail.example [91.198.174.42]) by mx.test (Postfix); Mon, 01 Jan 2024 00:00:00 +0000');

	my $from		= $h{from}		// 'Spammer <spammer@spam.example>';
	my $reply_to	= $h{reply_to};
	my $return_path = $h{return_path} // '<spammer@spam.example>';
	my $to		  = $h{to}		  // 'victim@test.example';
	my $subject	 = $h{subject}	 // 'Integration test message';
	my $date		= $h{date}		// POSIX::strftime('%a, %d %b %Y %H:%M:%S +0000', gmtime);
	my $mid		 = $h{message_id}  // '<inttest@spam.example>';
	my $ct		  = $h{ct}		  // 'text/plain; charset=us-ascii';
	my $cte		 = $h{cte}		 // '7bit';
	my $auth		= $h{auth}		// '';
	my $xoip		= $h{xoip};
	my $body		= $h{body}		// 'Buy our products now!';

	my $hdrs = '';
	$hdrs .= "Received: $_\n" for @rcvd;
	$hdrs .= "Authentication-Results: $auth\n" if $auth;
	$hdrs .= "Return-Path: $return_path\n";
	$hdrs .= "From: $from\n";
	$hdrs .= "Reply-To: $reply_to\n"			if defined $reply_to;
	$hdrs .= "To: $to\n";
	$hdrs .= "Subject: $subject\n";
	$hdrs .= "Date: $date\n";
	$hdrs .= "Message-ID: $mid\n";
	$hdrs .= "Content-Type: $ct\n";
	$hdrs .= "Content-Transfer-Encoding: $cte\n";
	$hdrs .= "X-Originating-IP: $xoip\n"		if defined $xoip;

	return "$hdrs\n$body";
}

# ---------------------------------------------------------------------------
# Scenario 1 — Classic direct-to-MX spam
#
# POD question 1: "Where did the message really come from?"
# A single external Received: hop from a known bad IP; no private relays.
# All five public pipeline methods are exercised in concert.
# ---------------------------------------------------------------------------
subtest 'Scenario 1: direct-to-MX spam — full pipeline' => sub {
	restore_stubs();
	install_stubs(
		rdns	=> 'mail.badactor.example',
		resolve => { 'spamsite.example' => '91.198.174.99' },
		whois_ip => {
			org	 => 'Rogue Hosting Corp',
			abuse   => 'abuse@rogue-hosting.example',
			country => 'RU',
		},
		domain_whois => sub {
			my (undef, $dom) = @_;
			return undef unless $dom eq 'spamsite.example';
			my $reg = strftime('%Y-%m-%d', gmtime(time() - 60  * 86400));
			my $exp = strftime('%Y-%m-%d', gmtime(time() + 305 * 86400));
			return "Registrar: Dodgy Registrar Inc\n"
				 . "Registrar Abuse Contact Email: abuse\@dodgy-reg.example\n"
				 . "Creation Date: $reg\n"
				 . "Registry Expiry Date: $exp\n";
		},
	);

	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(make_raw_email(
		received => 'from badactor (badactor [91.198.174.42]) by mx.test',
		from	 => 'Deals <deals@spamsite.example>',
		body	 => 'Visit https://spamsite.example/offer to claim your prize.',
	));

	# --- originating_ip() ---
	my $orig = $a->originating_ip();
	ok defined $orig,						   'originating_ip returns a value';
	is $orig->{ip},		 '91.198.174.42',	'correct originating IP extracted';
	is $orig->{rdns},	   'mail.badactor.example', 'rDNS resolved';
	is $orig->{confidence}, 'medium',		   'single hop → medium confidence';
	like $orig->{org},	  qr/Rogue Hosting/,  'org from IP WHOIS';
	like $orig->{abuse},	qr/abuse\@/,		'abuse contact from IP WHOIS';

	# --- embedded_urls() ---
	my @urls = $a->embedded_urls();
	is scalar @urls, 1,						 'one URL found';
	is $urls[0]{host}, 'spamsite.example',	  'correct URL host';
	is $urls[0]{ip},   '91.198.174.99',		 'URL host resolved to IP';
	like $urls[0]{org}, qr/Rogue Hosting/,	  'URL host org from WHOIS';

	# --- mailto_domains() ---
	my @doms = $a->mailto_domains();
	my ($spam_dom) = grep { $_->{domain} eq 'spamsite.example' } @doms;
	ok defined $spam_dom,					   'spamsite.example in mailto_domains';
	is $spam_dom->{registrar},
		'Dodgy Registrar Inc',				  'registrar from domain WHOIS';
	is $spam_dom->{registrar_abuse},
		'abuse@dodgy-reg.example',			  'registrar abuse contact from WHOIS';
	is $spam_dom->{recently_registered}, 1,	 'recently_registered flag set';

	# --- all_domains() ---
	my @all = $a->all_domains();
	ok scalar(grep { $_ eq 'spamsite.example' } @all),
		'spamsite.example appears in all_domains';
	my %seen; $seen{$_}++ for @all;
	ok !scalar(grep { $seen{$_} > 1 } @all), 'no duplicates in all_domains';

	# --- risk_assessment() ---
	my $risk = $a->risk_assessment();
	ok $risk->{level} ne 'INFO',				'risk level is not INFO for clear spam';
	ok $risk->{score} > 0,					  'non-zero risk score';
	my @flag_names = map { $_->{flag} } @{ $risk->{flags} };
	ok scalar(grep { $_ eq 'recently_registered_domain' } @flag_names),
		'recently_registered_domain flagged';

	# --- abuse_contacts() ---
	my @contacts = $a->abuse_contacts();
	ok @contacts > 0,						   'at least one abuse contact';
	my @addrs = map { lc $_->{address} } @contacts;
	ok scalar(grep { $_ eq 'abuse@rogue-hosting.example' } @addrs),
		'sending ISP abuse contact present';
	ok scalar(grep { $_ eq 'abuse@dodgy-reg.example' } @addrs),
		'registrar abuse contact present';
	# Every contact has the required fields
	for my $c (@contacts) {
		ok $c->{address} =~ /\@/, "contact $c->{address} has valid address";
		ok $c->{via} =~ /^(?:ip-whois|domain-whois|provider-table|rdap)$/,
			"contact via '$c->{via}' is a documented value";
	}

	# --- report() ---
	my $report = $a->report();
	like $report, qr/91.198.174.42/,			'originating IP in report';
	like $report, qr/spamsite\.example/,		'spam domain in report';
	like $report, qr/RECENTLY REGISTERED/,	  'recently registered warning in report';
	like $report, qr/https:\/\/spamsite\.example/, 'URL in report';
	like $report, qr/abuse\@rogue-hosting\.example/, 'hosting abuse in report';
	like $report, qr/abuse\@dodgy-reg\.example/, 'registrar abuse in report';

	# --- abuse_report_text() ---
	my $art = $a->abuse_report_text();
	like $art, qr/RISK LEVEL/,		   'RISK LEVEL in abuse_report_text';
	like $art, qr/ORIGINATING IP/,	   'ORIGINATING IP in abuse_report_text';
	like $art, qr/ORIGINAL MESSAGE HEADERS/, 'headers section in abuse_report_text';
	like $art, qr/received:/i,		   'Received: header included';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 2 — Webmail-sent spam (Gmail origin)
#
# POD description item 1: "Walks the Received: chain, skips private/trusted
# IPs, and identifies the first external hop."
# The chain contains private relays that must be skipped.
# The sending account is Gmail → provider-table contact expected.
# ---------------------------------------------------------------------------
subtest 'Scenario 2: Gmail-sent spam through internal relays' => sub {
	restore_stubs();
	install_stubs(
		rdns	=> 'mail-ej1-f67.google.com',
		resolve => sub {
			my (undef, $host) = @_;
			return '209.85.218.67' if $host =~ /google/;
			return undef;
		},
		whois_ip => {
			org	 => 'Google LLC',
			abuse   => 'network-abuse@google.com',
			country => 'US',
		},
		domain_whois => undef,
	);

	my $a = Email::Abuse::Investigator->new(
		trusted_relays => ['172.31.0.0/16'],   # simulate internal AWS relay
	);
	$a->parse_email(make_raw_email(
		received => [
			# Most-recent (top): our MTA received from Google
			'from mail-ej1-f67.google.com (mail-ej1-f67.google.com [209.85.218.67]) by mx.test',
			# Older (bottom): internal relay — must be skipped
			'from internal-relay.corp (internal-relay.corp [172.31.5.10]) by smtp-out.corp',
		],
		auth => 'mx.test; spf=pass smtp.mailfrom=gmail.com; dkim=pass header.d=gmail.com; dmarc=pass',
		from => 'SM Investments <fakeco@gmail.com>',
		to   => 'undisclosed-recipients:;',
		body => 'Dear Sir/Madam, please contact vendor@supplierco.example',
	));

	# The private internal relay must be skipped; Google's IP is the origin
	my $orig = $a->originating_ip();
	is $orig->{ip}, '209.85.218.67', 'internal relay skipped; Google IP is origin';
	like $orig->{rdns}, qr/google\.com/, 'rDNS points to Google';

	# SPF/DKIM/DMARC all passed — authentication checks should not fire
	my $risk = $a->risk_assessment();
	my @auth_flags = grep { $_->{flag} =~ /^(?:spf|dkim|dmarc)_fail$/ }
					 @{ $risk->{flags} };
	is scalar @auth_flags, 0, 'no auth-fail flags when SPF/DKIM/DMARC pass';

	# Gmail From: → free_webmail_sender flag
	ok scalar(grep { $_->{flag} eq 'free_webmail_sender' } @{ $risk->{flags} }),
		'free_webmail_sender flagged for Gmail sender';

	# undisclosed-recipients → undisclosed_recipients flag
	ok scalar(grep { $_->{flag} eq 'undisclosed_recipients' } @{ $risk->{flags} }),
		'undisclosed_recipients flagged';

	# Provider-table gives Google's abuse address
	my @contacts = $a->abuse_contacts();
	ok scalar(grep { lc($_->{address}) eq 'abuse@google.com' } @contacts),
		'abuse@google.com in contacts via provider table';
	ok scalar(grep { $_->{via} eq 'provider-table' } @contacts),
		'at least one contact discovered via provider-table';

	# Contact domain in body captured
	my @doms = $a->mailto_domains();
	ok scalar(grep { $_->{domain} eq 'supplierco.example' } @doms),
		'bare-address domain from body captured';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 3 — Phishing via display-name spoofing
#
# POD risk_assessment flags: display_name_domain_spoof.
# From: display name says "PayPal Security paypal.com" but the actual
# sending address is at an unrelated domain.
# reply_to_differs_from_from is also triggered.
# ---------------------------------------------------------------------------
subtest 'Scenario 3: display-name spoofing and reply-to misdirection' => sub {
	restore_stubs();
	install_stubs(
		rdns	 => 'mail.phishhost.example',
		resolve  => '91.198.174.77',
		whois_ip => { org => 'Phish Host LLC', abuse => 'abuse@phishhost.example' },
		domain_whois => undef,
	);

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_raw_email(
		received  => 'from phishhost (phishhost [91.198.174.77]) by mx.test',
		from	  => '"PayPal Security paypal.com" <noreply@ph1sh-paypal.example>',
		reply_to  => 'collect@harvester.example',
		body	  => 'Your account is limited. Verify at https://ph1sh-paypal.example/verify',
	));

	my $risk = $a->risk_assessment();
	my @flag_names = map { $_->{flag} } @{ $risk->{flags} };

	# POD-documented flag: display_name_domain_spoof
	ok scalar(grep { $_ eq 'display_name_domain_spoof' } @flag_names),
		'display_name_domain_spoof flagged';

	# POD-documented flag: reply_to_differs_from_from
	ok scalar(grep { $_ eq 'reply_to_differs_from_from' } @flag_names),
		'reply_to_differs_from_from flagged';

	# Risk level must be HIGH or MEDIUM for a phishing email
	ok $risk->{level} =~ /^(?:HIGH|MEDIUM)$/,
		"risk level is HIGH or MEDIUM for phishing email (got $risk->{level})";

	# The lookalike domain ph1sh-paypal.example should trigger lookalike_domain
	ok scalar(grep { $_ eq 'lookalike_domain' } @flag_names),
		'lookalike_domain flagged for ph1sh-paypal.example';

	# The URL in the body should be found and its host resolved
	my @urls = $a->embedded_urls();
	is scalar @urls, 1, 'one URL found in phishing body';
	is $urls[0]{host}, 'ph1sh-paypal.example', 'phishing URL host correct';

	# Full report mentions both the IP and the deceptive domain
	my $report = $a->report();
	like $report, qr/91.198.174.77/,			'phishing source IP in report';
	like $report, qr/ph1sh-paypal\.example/,	'lookalike domain in report';
	like $report, qr/paypal/i,				  'PayPal reference appears in report';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 4 — Residential broadband sender (no mail infrastructure)
#
# POD description item 1: "Walks the Received: chain … identifies the first
# external hop."
# rDNS matches the broadband/residential pattern → residential_sending_ip flag.
# ---------------------------------------------------------------------------
subtest 'Scenario 4: residential broadband sender triggers risk flags' => sub {
	restore_stubs();
	install_stubs(
		rdns	 => '120-88-161-249.tpgi.com.au',
		resolve  => undef,
		whois_ip => { org => 'TPG Internet Pty Ltd', abuse => 'abuse@tpg.com.au', country => 'AU' },
		domain_whois => undef,
	);

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_raw_email(
		received => 'from 120-88-161-249.tpgi.com.au (120.88.161.249) by mx.test',
		from	 => '"eharmony Partner" <peacelight@firmluminary.example>',
		subject  => 'Ready to Find Someone Special?',
		body	 => 'Find love today.',
	));

	my $orig = $a->originating_ip();
	is $orig->{ip},  '120.88.161.249',		   'broadband IP identified';
	like $orig->{rdns}, qr/tpgi\.com\.au/,	   'broadband rDNS present';
	is $orig->{confidence}, 'medium',			 'single hop confidence';

	my $risk = $a->risk_assessment();
	ok scalar(grep { $_->{flag} eq 'residential_sending_ip' } @{ $risk->{flags} }),
		'residential_sending_ip flagged for tpgi.com.au rDNS';

	# Provider table has TPG → abuse@tpg.com.au
	my @contacts = $a->abuse_contacts();
	ok scalar(grep { lc($_->{address}) eq 'abuse@tpg.com.au' } @contacts),
		'TPG abuse contact found via provider table';

	# report() mentions the residential IP
	my $report = $a->report();
	like $report, qr/120\.88\.161\.249/, 'residential IP in report';
	like $report, qr/tpgi\.com\.au/,	'residential rDNS in report';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 5 — URL shortener hiding destination
#
# POD risk_assessment: url_shortener flag.
# Multiple URLs all under bit.ly; plus one legitimate-looking URL.
#
# NOTE on the WHOIS-call-count subtest:
# The module maintains a cross-message CHI cache keyed by IP/hostname.  To
# guarantee that _whois_ip is called exactly once per unique host we must use
# hostnames that have not been seen in any earlier subtest in this run.  We
# therefore use unique hostnames (bit-ly-test-S5.example and legit-S5.example)
# rather than bit.ly and legit.example, which may already be in the cache.
# ---------------------------------------------------------------------------
subtest 'Scenario 5: URL shortener hides real destination' => sub {
	restore_stubs();
	install_stubs(
		rdns	=> 'mail.sender.example',
		resolve => {
			'bit.ly'		 => '67.199.248.10',
			'legit.example'  => '192.0.2.50',
		},
		whois_ip => sub {
			my (undef, $ip) = @_;
			return { org => 'Bitly Inc',   abuse => 'abuse@bitly.example'  }
				if $ip eq '67.199.248.10';
			return { org => 'Legit Corp',  abuse => 'abuse@legit.example'  };
		},
		domain_whois => undef,
	);

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_raw_email(
		received => 'from sender (sender [91.198.174.1]) by mx.test',
		body	 => 'Click https://bit.ly/abc123 or https://bit.ly/xyz789 '
				  . 'or visit https://legit.example/page for info.',
	));

	# All three URLs returned
	my @urls = $a->embedded_urls();
	is scalar @urls, 3, 'three URLs found';

	# Hosts correctly identified
	my %hosts = map { $_->{host} => 1 } @urls;
	ok $hosts{'bit.ly'},		 'bit.ly identified as URL host';
	ok $hosts{'legit.example'},  'legit.example identified as URL host';

	# --- WHOIS call-count subtest ---
	# Use hostnames that cannot be in the cross-message cache from prior subtests.
	# Each hostname is unique to this counting block (suffix -s5cnt).
	my $whois_calls = 0;
	{
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_whois_ip = sub {
			$whois_calls++;
			return { org => 'Test', abuse => 'a@b' };
		};
		# Also stub _resolve_host for the fresh hostnames
		local *Email::Abuse::Investigator::_resolve_host = sub {
			my (undef, $host) = @_;
			return '67.199.248.11' if $host eq 'bit-ly-cnt-s5.example';
			return '192.0.2.51'   if $host eq 'legit-cnt-s5.example';
			return undef;
		};

		# Re-parse using hostnames that are guaranteed cache-cold
		$a->parse_email(make_raw_email(
			received => 'from sender (sender [91.198.174.1]) by mx.test',
			body	 => 'https://bit-ly-cnt-s5.example/abc123 '
					  . 'and https://bit-ly-cnt-s5.example/xyz789 '
					  . 'and https://legit-cnt-s5.example/page',
		));
		my @u2 = $a->embedded_urls();
		is scalar @u2,   3, 're-parsed: three URLs';
		is $whois_calls, 2, 'WHOIS called once per unique host (2 unique hosts)';
	}

	# Restore the real stub so risk_assessment works with the original URLs
	install_stubs(
		rdns	=> 'mail.sender.example',
		resolve => { 'bit.ly' => '67.199.248.10', 'legit.example' => '192.0.2.50' },
		whois_ip => { org => 'Test', abuse => 'a@b' },
		domain_whois => undef,
	);
	$a->parse_email(make_raw_email(
		received => 'from sender (sender [91.198.174.1]) by mx.test',
		body	 => 'https://bit.ly/abc123 and https://legit.example/page',
	));

	my $risk = $a->risk_assessment();
	ok scalar(grep { $_->{flag} eq 'url_shortener' } @{ $risk->{flags} }),
		'url_shortener flagged for bit.ly';
	# Should not flag legit.example as a shortener
	my @shortener_details = grep { $_->{flag} eq 'url_shortener' }
							@{ $risk->{flags} };
	ok !scalar(grep { $_->{detail} =~ /legit\.example/ } @shortener_details),
		'legit.example not flagged as shortener';

	# Report mentions the shortener warning
	my $report = $a->report();
	like $report, qr/URL SHORTENER/, 'URL SHORTENER warning in report';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 5b — Cloud-storage redirect cloaker (GCS bucket → phishing page)
#
# The email body contains only a GCS URL.  The GCS page hosts a meta-refresh
# to the real phishing domain.  The module should follow the redirect and
# surface both the GCS host and the final phishing host in embedded_urls(),
# then flag redirect_cloaker for the GCS URL and report abuse contacts for
# both parties.
# ---------------------------------------------------------------------------
subtest 'Scenario 5b: cloud-storage redirect cloaker resolved to phishing destination' => sub {
	restore_stubs();
	install_stubs(
		rdns	=> 'mail.sender.example',
		resolve => {
			'storage.googleapis.com' => '142.250.80.112',
			'www.phishingsite.example' => '198.51.100.99',
		},
		whois_ip => sub {
			my (undef, $ip) = @_;
			return { org => 'Google LLC',     abuse => 'google-cloud-compliance@google.com' }
				if $ip eq '142.250.80.112';
			return { org => 'Evil Hosting',   abuse => 'abuse@evilhost.example' };
		},
		domain_whois => undef,
		follow_redirect => sub {
			my (undef, $url) = @_;
			return 'https://www.phishingsite.example/login?ref=123'
				if $url =~ m{storage\.googleapis\.com};
			return undef;
		},
	);

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_raw_email(
		received => 'from sender (sender [91.198.174.1]) by mx.test',
		body     => 'Click here: https://storage.googleapis.com/fakebucket/redirect',
	));

	my @urls  = $a->embedded_urls();
	my %hosts = map { $_->{host} => 1 } @urls;

	is scalar @urls, 2, 'two URLs found: GCS original + phishing destination';
	ok $hosts{'storage.googleapis.com'},   'GCS host present';
	ok $hosts{'www.phishingsite.example'}, 'phishing destination resolved and present';

	# Risk assessment should flag the redirect cloaker
	my $risk = $a->risk_assessment();
	ok scalar(grep { $_->{flag} eq 'redirect_cloaker' } @{ $risk->{flags} }),
		'redirect_cloaker flag raised for GCS host';

	# Abuse contacts should include both Google and the phishing host's ISP
	my @contacts  = $a->abuse_contacts();
	my @addresses = map { $_->{address} } @contacts;
	ok scalar(grep { defined $_ && /google-cloud-compliance/ } @addresses),
		'Google Cloud abuse contact present';
	ok scalar(grep { defined $_ && /evilhost\.example/       } @addresses),
		'phishing host abuse contact present';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 6 — Mailto-only spam (no HTTP links)
#
# POD description item 3: domains extracted from mailto: links and bare
# addresses.  This scenario has zero HTTP/HTTPS URLs — only email addresses
# appear in the body (like the real SM Investments spam).
# The domain pipeline (A→WHOIS, WHOIS) still runs on those domains.
# ---------------------------------------------------------------------------
subtest 'Scenario 6: mailto-only spam — no HTTP URLs, all contact via email' => sub {
	restore_stubs();
	install_stubs(
		rdns	 => 'mail-ej1-f67.google.com',
		resolve  => { 'sminvestmentsupplychain.example' => '104.21.0.1' },
		whois_ip => { org => 'Cloudflare Inc', abuse => 'abuse@cloudflare.com', country => 'US' },
		domain_whois => sub {
			my (undef, $dom) = @_;
			return undef unless $dom eq 'sminvestmentsupplychain.example';
			my $reg = strftime('%Y-%m-%d', gmtime(time() - 60  * 86400));
			my $exp = strftime('%Y-%m-%d', gmtime(time() + 305 * 86400));
			return "Registrar: NameCheap Inc.\n"
				 . "Registrar Abuse Contact Email: abuse\@namecheap.com\n"
				 . "Creation Date: $reg\n"
				 . "Registry Expiry Date: $exp\n";
		},
	);

	my $bnd = 'SMTP_BOUNDARY_001';
	my $mp  = "--$bnd\r\nContent-Type: text/plain; charset=\"UTF-8\"\r\n\r\n"
			. "Contact us at Onboarding\@sminvestmentsupplychain.example\r\n"
			. "--$bnd\r\nContent-Type: text/html; charset=\"UTF-8\"\r\n\r\n"
			. '<a href="mailto:Onboarding@sminvestmentsupplychain.example">'
			. 'Onboarding@sminvestmentsupplychain.example</a>'
			. "\r\n--$bnd--\r\n";

	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(make_raw_email(
		received => 'from mail-ej1-f67.google.com (mail-ej1-f67.google.com [209.85.218.67]) by mx.test',
		auth	 => 'mx.test; spf=pass; dkim=pass header.d=gmail.com',
		from	 => 'SM Investments <denatabradley01@gmail.com>',
		to	   => 'undisclosed-recipients:;',
		subject  => 'Invitation to Register as a Vendor',
		ct	   => qq{multipart/alternative; boundary="$bnd"},
		body	 => $mp,
	));

	# No HTTP/HTTPS URLs
	my @urls = $a->embedded_urls();
	is scalar @urls, 0, 'no HTTP/HTTPS URLs — mailto-only spam';

	# The supply-chain domain captured from both mailto: and bare address in body
	my @doms = $a->mailto_domains();
	my ($dom) = grep { $_->{domain} eq 'sminvestmentsupplychain.example' } @doms;
	ok defined $dom,								'supply chain domain found';
	is $dom->{web_ip}, '104.21.0.1',			   'A record resolved for domain';
	like $dom->{web_org}, qr/Cloudflare/,		   'web hosting org identified';
	is $dom->{registrar}, 'NameCheap Inc.',		 'registrar from WHOIS';
	is $dom->{registrar_abuse}, 'abuse@namecheap.com', 'registrar abuse from WHOIS';
	is $dom->{recently_registered}, 1,			  'recently registered flag set';

	# all_domains includes the supply-chain domain
	my @all = $a->all_domains();
	ok scalar(grep { $_ eq 'sminvestmentsupplychain.example' } @all),
		'supply chain domain in all_domains';

	# Abuse contacts include Cloudflare (web host) and NameCheap (registrar)
	my @contacts = $a->abuse_contacts();
	my @addrs	= map { lc $_->{address} } @contacts;
	ok scalar(grep { $_ eq 'abuse@cloudflare.com'  } @addrs),
		'Cloudflare web-host abuse in contacts';
	ok scalar(grep { $_ eq 'abuse@namecheap.com'   } @addrs),
		'NameCheap registrar abuse in contacts';
	ok scalar(grep { $_ eq 'abuse@google.com'	  } @addrs),
		'Google account-provider abuse in contacts (gmail From:)';

	# Report contains all relevant information
	my $report = $a->report();
	like $report, qr/209\.85\.218\.67/,				 'Google IP in report';
	like $report, qr/sminvestmentsupplychain\.example/, 'supply chain domain in report';
	like $report, qr/RECENTLY REGISTERED/,			  'recently registered warning';
	like $report, qr/none found/i,					  '"none found" for URLs section';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 7 — Authentication failures (SPF/DKIM/DMARC all fail)
#
# POD risk_assessment flags: spf_fail, dkim_fail, dmarc_fail.
# Tests that auth results flow from Authentication-Results: header through
# risk_assessment() and into report() and abuse_report_text().
# ---------------------------------------------------------------------------
subtest 'Scenario 7: authentication failures — SPF, DKIM, DMARC all fail' => sub {
	restore_stubs();
	install_stubs(
		rdns	 => 'mail.forgeddomain.example',
		resolve  => undef,
		whois_ip => { org => 'Spammer ISP', abuse => 'abuse@spammisp.example' },
		domain_whois => undef,
	);

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_raw_email(
		received => 'from forged (forged [91.198.174.5]) by mx.test',
		auth	 => 'mx.test; spf=fail; dkim=fail; dmarc=fail action=reject',
		from	 => 'Fake Bank <security@real-bank.example>',
		body	 => 'Your account requires verification.',
	));

	my $risk = $a->risk_assessment();
	my @flag_names = map { $_->{flag} } @{ $risk->{flags} };

	ok scalar(grep { $_ eq 'spf_fail'   } @flag_names), 'spf_fail flagged';
	ok scalar(grep { $_ eq 'dkim_fail'  } @flag_names), 'dkim_fail flagged';
	ok scalar(grep { $_ eq 'dmarc_fail' } @flag_names), 'dmarc_fail flagged';

	# Three HIGH-severity auth failures → score ≥ 9 → HIGH level
	is $risk->{level}, 'HIGH', 'three auth failures → HIGH risk level';
	ok $risk->{score} >= 9,	'score ≥ 9 for three HIGH-severity flags';

	# Each auth flag has the right severity
	for my $fn (qw(spf_fail dkim_fail dmarc_fail)) {
		my ($f) = grep { $_->{flag} eq $fn } @{ $risk->{flags} };
		is $f->{severity}, 'HIGH', "$fn has HIGH severity";
	}

	# abuse_report_text includes the flag details
	my $art = $a->abuse_report_text();
	like $art, qr/RED FLAGS IDENTIFIED/, 'RED FLAGS section in abuse_report_text';
	like $art, qr/spf/i,				'SPF result mentioned in abuse_report_text';

	# report() shows risk assessment section with HIGH
	my $report = $a->report();
	like $report, qr/RISK ASSESSMENT:\s*HIGH/, 'HIGH risk level in report';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 8 — Trusted relay excluded; two external hops → high confidence
#
# POD description item 1: "skips private/trusted IPs".
# Also exercises the trusted_relays constructor option.
# ---------------------------------------------------------------------------
subtest 'Scenario 8: trusted relay excluded; two external hops give high confidence' => sub {
	restore_stubs();
	install_stubs(
		rdns	=> sub {
			my (undef, $ip) = @_;
			return 'mail.attacker.example'	if $ip eq '91.198.174.10';
			return 'relay.legitrelay.example' if $ip eq '62.105.128.5';
			return undef;
		},
		whois_ip => { org => 'Attacker ISP', abuse => 'abuse@attacker-isp.example' },
		domain_whois => undef,
	);

	my $a = Email::Abuse::Investigator->new(
		trusted_relays => ['62.105.128.0/24'],  # our own relay
	);
	$a->parse_email(make_raw_email(
		received => [
			# Top (most recent): our trusted relay accepted from external relay
			'from relay.legitrelay.example (relay.legitrelay.example [62.105.128.5]) by mx.test',
			# Middle: an external relay accepted from the attacker
			'from mail.attacker.example (mail.attacker.example [91.198.174.10]) by relay.legitrelay.example',
			# Bottom: the attacker sent directly from this IP
			'from attacker (attacker [91.198.174.10]) by mail.attacker.example',
		],
		from => 'attacker@attacker.example',
		body => 'Spam content here.',
	));

	my $orig = $a->originating_ip();

	# The trusted relay (62.105.128.5) must be excluded
	ok $orig->{ip} ne '62.105.128.5', 'trusted relay IP excluded from origin';

	# Two non-trusted hops (91.198.174.10 appears twice) → high confidence
	is $orig->{confidence}, 'high',		 'two external hops → high confidence';
	is $orig->{ip}, '91.198.174.10',		'attacker IP identified as origin';

	# Abuse contact for the attacker's IP present
	my @contacts = $a->abuse_contacts();
	ok scalar(grep { lc($_->{address}) eq 'abuse@attacker-isp.example' } @contacts),
		'attacker ISP abuse contact in contacts';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 9 — MIME-encoded headers decoded in report()
#
# POD synopsis: the full pipeline with MIME-encoded From: and Subject:.
# Verifies that report() shows decoded text, not raw encoded-word strings.
# ---------------------------------------------------------------------------
subtest 'Scenario 9: MIME-encoded From: and Subject: decoded in report' => sub {
	restore_stubs();
	install_stubs(
		rdns	 => 'mail.sender.example',
		resolve  => undef,
		whois_ip => { org => 'Sender ISP', abuse => 'abuse@sender-isp.example' },
		domain_whois => undef,
	);

	my $enc_from = '=?UTF-8?B?' . encode_base64('eharmony Partner', '') . '?=';
	my $enc_subj = '=?UTF-8?B?' . encode_base64('Ready to Find Someone Special?', '') . '?=';

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_raw_email(
		received => 'from sender (sender [91.198.174.1]) by mx.test',
		from	 => qq{"$enc_from" <peacelight\@firmluminary.example>},
		subject  => $enc_subj,
		body	 => 'Find the joy of real love today.',
	));

	my $report = $a->report();

	# Decoded display name appears in report
	like $report, qr/eharmony Partner/,			'decoded From: display name in report';
	like $report, qr/Ready to Find Someone Special/, 'decoded Subject in report';

	# The decoded form leads; raw encoding appears in brackets after
	like $report, qr/eharmony Partner.*\[encoded:/s,
		'decoded form appears before the bracketed raw encoded value';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 10 — Domain intelligence pipeline (POD Algorithm section)
#
# POD: "For each unique non-infrastructure domain … A record → web hosting,
#	   MX record → mail hosting, NS record → DNS hosting, WHOIS → registrar"
# Simulates a domain whose web host, MX host, and NS host are all different
# companies — verifying that all three are independently reported.
# ---------------------------------------------------------------------------
subtest 'Scenario 10: domain intelligence pipeline — web/MX/NS all different' => sub {
	restore_stubs();
	install_stubs(
		rdns	=> 'mail.sender.example',
		resolve => sub {
			my (undef, $host) = @_;
			my %map = (
				'spamdom.example'	  => '104.21.0.1',
				'mail.spamdom.example' => '74.125.0.1',
				'ns1.spamdom.example'  => '198.41.0.1',
			);
			return $map{$host};
		},
		whois_ip => sub {
			my (undef, $ip) = @_;
			my %data = (
				'104.21.0.1'   => { org => 'Cloudflare Inc',  abuse => 'abuse@cloudflare.com' },
				'74.125.0.1'   => { org => 'Google LLC',	  abuse => 'network-abuse@google.com' },
				'198.41.0.1'   => { org => 'VeriSign Inc',	abuse => 'abuse@verisign.example' },
				'91.198.174.1' => { org => 'Sender ISP',	  abuse => 'abuse@sender.example' },
			);
			return $data{$ip} // {};
		},
		domain_whois => sub {
			my (undef, $dom) = @_;
			return undef unless $dom eq 'spamdom.example';
			return <<'WHOIS';
Registrar: GoDaddy.com LLC
Registrar Abuse Contact Email: abuse@godaddy.com
Creation Date: 2020-01-15
Registry Expiry Date: 2030-01-15
WHOIS
		},
	);

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_raw_email(
		received => 'from sender (sender [91.198.174.1]) by mx.test',
		from	 => 'Spammer <spam@spamdom.example>',
		body	 => 'Contact us at info@spamdom.example',
	));

	# Pre-populate the domain cache with fully resolved data
	# (simulates what _analyse_domain would produce with Net::DNS present)
	$a->{_domain_info}{'spamdom.example'} = {
		web_ip   => '104.21.0.1',
		web_org  => 'Cloudflare Inc',
		web_abuse => 'abuse@cloudflare.com',
		mx_host  => 'mail.spamdom.example',
		mx_ip	=> '74.125.0.1',
		mx_org   => 'Google LLC',
		mx_abuse => 'network-abuse@google.com',
		ns_host  => 'ns1.spamdom.example',
		ns_ip	=> '198.41.0.1',
		ns_org   => 'VeriSign Inc',
		ns_abuse => 'abuse@verisign.example',
		registrar	   => 'GoDaddy.com LLC',
		registrar_abuse => 'abuse@godaddy.com',
		registered	  => '2020-01-15',
		expires		 => '2030-01-15',
		recently_registered => 0,
	};

	my @contacts = $a->abuse_contacts();
	my @addrs = map { lc $_->{address} } @contacts;

	# All four distinct parties must appear independently
	ok scalar(grep { $_ eq 'abuse@cloudflare.com'	  } @addrs),
		'Cloudflare web-host abuse contact present';
	ok scalar(grep { $_ eq 'network-abuse@google.com'  } @addrs),
		'Google MX-host abuse contact present';
	ok scalar(grep { $_ eq 'abuse@verisign.example'	} @addrs),
		'VeriSign NS-host abuse contact present';
	# GoDaddy is form-only — suppressed from abuse_contacts(), surfaced via form_contacts()
	ok scalar(grep { $_->{form} =~ /godaddy/i } $a->form_contacts()),
		'GoDaddy registrar appears in form_contacts() (form-only provider)';

	# All addresses are distinct — no collapsing
	my %addr_seen;
	my @dups = grep { $addr_seen{$_}++ } @addrs;
	is scalar @dups, 0, 'all party addresses are distinct (no deduplication collapse)';

	# report() shows all three hosting sections for the domain
	my $report = $a->report();
	like $report, qr/Web host/,  'web host section in report';
	like $report, qr/MX host/,   'MX host section in report';
	like $report, qr/NS host/,   'NS host section in report';
	like $report, qr/Registrar/, 'Registrar section in report';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 11 — Re-parsing with a different email resets all state
#
# POD parse_email: "Accepts a scalar or scalar-ref."
# Tests that a second call to parse_email on the same object completely
# replaces all analysis state — no leakage from the first email.
# ---------------------------------------------------------------------------
subtest 'Scenario 11: re-parsing replaces all state — no leakage between emails' => sub {
	restore_stubs();
	install_stubs(
		rdns	=> 'mail.first.example',
		resolve => { 'firstsite.example' => '91.198.174.10' },
		whois_ip => { org => 'First ISP', abuse => 'abuse@first.example' },
		domain_whois => undef,
	);

	my $a = Email::Abuse::Investigator->new();

	# First email: has URL, high-risk sender
	$a->parse_email(make_raw_email(
		received => 'from first (first [91.198.174.10]) by mx.test',
		from	 => 'Spammer <bad@gmail.com>',
		body	 => 'Visit https://firstsite.example/buy now!',
	));

	my $orig1  = $a->originating_ip();
	my @urls1  = $a->embedded_urls();
	my $risk1  = $a->risk_assessment();

	is $orig1->{ip}, '91.198.174.10', 'first email: correct origin';
	is scalar @urls1, 1,			  'first email: one URL';
	ok $risk1->{score} > 0,		   'first email: non-zero risk score';

	# Second email: clean, no URLs, different sender
	install_stubs(
		rdns	=> 'mail.clean.example',
		resolve => undef,
		whois_ip => { org => 'Clean ISP', abuse => 'abuse@clean.example' },
		domain_whois => undef,
	);

	$a->parse_email(make_raw_email(
		received => 'from clean (clean [62.105.128.1]) by mx.test',
		from	 => 'Newsletter <news@cleanorg.example>',
		body	 => 'Monthly newsletter — no links.',
	));

	my $orig2  = $a->originating_ip();
	my @urls2  = $a->embedded_urls();
	my $risk2  = $a->risk_assessment();

	# Origin completely replaced
	is $orig2->{ip}, '62.105.128.1',   're-parse: new origin IP';
	ok $orig2->{ip} ne $orig1->{ip},   're-parse: origin differs from first email';

	# URLs cleared
	is scalar @urls2, 0, 're-parse: no URLs in second email';

	# Risk cache cleared — second risk is independent of first
	isnt $risk2, $risk1, 're-parse: risk_assessment result is a new object';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 12 — Clean, benign email scores INFO
#
# POD risk_assessment: level is INFO when score < 2.
# ---------------------------------------------------------------------------
subtest 'Scenario 12: clean legitimate email scores INFO — no false positives' => sub {
	restore_stubs();
	install_stubs(
		rdns	 => 'mail.verifiedcorp.example',
		resolve  => undef,
		whois_ip => { org => 'Verified Corp ISP', abuse => 'abuse@vcorp-isp.example' },
		domain_whois => undef,
	);

	my $a = Email::Abuse::Investigator->new(
		trusted_relays => ['62.105.128.0/24'],
	);
	$a->parse_email(make_raw_email(
		received	 => 'from mail.verifiedcorp.example (mail.verifiedcorp.example [62.105.128.10]) by mx.test',
		auth		 => 'mx.test; spf=pass; dkim=pass header.d=verifiedcorp.example; dmarc=pass',
		from		 => 'Newsletter <news@verifiedcorp.example>',
		return_path  => '<news@verifiedcorp.example>',
		to		   => 'subscriber@test.example',
		subject	  => 'Monthly Update',
		message_id   => '<monthly-001@verifiedcorp.example>',
		body		 => 'Please find the monthly update attached. No links.',
	));

	my $risk = $a->risk_assessment();
	is $risk->{level}, 'INFO', 'clean email scores INFO';
	ok $risk->{score} < 2,	 'INFO-level score is less than 2';

	my @flag_names = map { $_->{flag} } @{ $risk->{flags} };
	ok !scalar(grep { /^(?:spf|dkim|dmarc)_fail$/ } @flag_names),
		'no auth-failure flags on clean email';
	ok !scalar(grep { /^(?:url_shortener|http_not_https)$/ } @flag_names),
		'no URL flags on email with no URLs';

	my @all = $a->all_domains();
	ok !scalar(grep { $_ ne 'verifiedcorp.example' } @all),
		'all_domains contains only the sender domain for a clean single-sender email';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 13 — abuse_contacts() deduplication across all routes
#
# POD abuse_contacts: same address discovered through multiple routes
# appears exactly once; roles are merged.
# ---------------------------------------------------------------------------
subtest 'Scenario 13: abuse_contacts() deduplication across all discovery routes' => sub {
	restore_stubs();
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_raw_email(
		from => 'x@example.org',
		body => 'https://cf-site.example/page',
	));

	# Cloudflare appears as URL host, web host, NS host, and MX host
	$a->{_origin} = undef;
	$a->{_urls}   = [{
		url   => 'https://cf-site.example/page',
		host  => 'cf-site.example',
		ip	=> '104.21.0.1',
		org   => 'CLOUDFLARENET',
		abuse => 'abuse@cloudflare.com',
	}];
	$a->{_mailto_domains} = [{
		domain	=> 'cf-site.example',
		source	=> 'URL',
		web_abuse => 'abuse@cloudflare.com',
		web_ip	=> '104.21.0.1',
		web_org   => 'CLOUDFLARENET',
		mx_abuse  => 'abuse@cloudflare.com',
		mx_host   => 'mx.cf-site.example',
		mx_ip	 => '104.21.0.2',
		mx_org	=> 'CLOUDFLARENET',
		ns_abuse  => 'abuse@cloudflare.com',
		ns_host   => 'ns1.cf-site.example',
		ns_ip	 => '104.21.0.3',
		ns_org	=> 'CLOUDFLARENET',
		registrar_abuse => 'abuse@registrar.example',
		registrar	   => 'Some Registrar',
	}];

	my @contacts	= $a->abuse_contacts();
	my @cf_contacts = grep { lc($_->{address}) eq 'abuse@cloudflare.com' } @contacts;

	is scalar @cf_contacts, 1,
		'abuse@cloudflare.com appears exactly once despite 4 discovery routes';

	my @reg_contacts = grep { lc($_->{address}) eq 'abuse@registrar.example' } @contacts;
	is scalar @reg_contacts, 1, 'registrar abuse address appears exactly once';

	# Roles arrayref must be present and populated when multiple routes merged
	my ($cf) = @cf_contacts;
	ok ref($cf->{roles}) eq 'ARRAY',	'merged contact has roles arrayref';
	ok scalar(@{ $cf->{roles} }) > 1,   'roles arrayref contains multiple entries';

	# Total distinct addresses — no address appears more than once
	my %addr_count;
	$addr_count{ lc $_->{address} }++ for @contacts;
	ok !scalar(grep { $addr_count{$_} > 1 } keys %addr_count),
		'no address appears more than once across all contacts';
};

# ---------------------------------------------------------------------------
# Scenario 14 — report() and abuse_report_text() are consistent
#
# Both methods called on the same object; they must reference the same
# underlying analysis.  The abuse contacts listed in abuse_report_text() must
# be a subset of those returned by abuse_contacts().
# ---------------------------------------------------------------------------
subtest 'Scenario 14: report() and abuse_report_text() consistent on same object' => sub {
	restore_stubs();
	install_stubs(
		rdns	 => 'mail.spam.example',
		resolve  => { 'spammer.example' => '91.198.174.55' },
		whois_ip => { org => 'Spam ISP', abuse => 'abuse@spam-isp.example' },
		domain_whois => undef,
	);

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_raw_email(
		received => 'from spam (spam [91.198.174.55]) by mx.test',
		from	 => 'Offers <offers@spammer.example>',
		body	 => 'Big savings at https://spammer.example/deals',
	));

	my $report   = $a->report();
	my $art	  = $a->abuse_report_text();
	my @contacts = $a->abuse_contacts();
	my $risk	 = $a->risk_assessment();

	# Both texts share the same risk level
	like $report, qr/RISK ASSESSMENT:\s*$risk->{level}/,
		'report() shows same risk level as risk_assessment()';
	like $art, qr/RISK LEVEL:\s*$risk->{level}/,
		'abuse_report_text() shows same risk level';

	# Every contact address from abuse_contacts() must appear in at least one text
	for my $c (@contacts) {
		my $addr	 = $c->{address};
		my $in_either = ($report =~ /\Q$addr\E/) || ($art =~ /\Q$addr\E/);
		ok $in_either, "contact address '$addr' appears in report() or abuse_report_text()";
	}

	# The originating IP appears in both
	my $orig = $a->originating_ip();
	if (defined $orig) {
		like $report, qr/\Q$orig->{ip}\E/, 'originating IP in report()';
		like $art,	qr/\Q$orig->{ip}\E/, 'originating IP in abuse_report_text()';
	}

	# Calling all methods a second time returns identical results (idempotent)
	my $report2 = $a->report();
	is $report2, $report, 'report() is idempotent on same object';

	my $art2 = $a->abuse_report_text();
	is $art2, $art, 'abuse_report_text() is idempotent on same object';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 15 — Multipart HTML spam with tracking pixel and unsubscribe link
#
# POD embedded_urls: "Extracts every http:// and https:// URL from both
# plain-text and HTML parts."
# ---------------------------------------------------------------------------
subtest 'Scenario 15: multipart HTML spam — tracking pixel, click link, unsubscribe' => sub {
	restore_stubs();
	my $whois_calls = 0;
	install_stubs(
		rdns	=> 'mail.mailer.example',
		resolve => { 'www.firmluminary.example' => '104.21.13.60' },
		whois_ip => sub {
			$whois_calls++;
			return { org => 'CLOUDFLARENET', abuse => 'abuse@cloudflare.com', country => 'US' };
		},
		domain_whois => undef,
	);

	my $bnd = 'FRM_BOUND';
	my $html_raw = '<a href="https://www.firmluminary.example/c/link1">Click</a>'
				 . '<a href="https://www.firmluminary.example/u/unsub">Unsubscribe</a>'
				 . '<img src="https://www.firmluminary.example/o/track">';
	my $mp = "--$bnd\r\nContent-Type: text/plain\r\n\r\nPlain version.\r\n"
		   . "--$bnd\r\nContent-Type: text/html; charset=utf-8\r\n"
		   . "Content-Transfer-Encoding: quoted-printable\r\n\r\n"
		   . encode_qp($html_raw, '')
		   . "\r\n--$bnd--\r\n";

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_raw_email(
		received => 'from 120-88-161-249.tpgi.com.au (120.88.161.249) by mx.test',
		from	 => '"eharmony Partner" <peacelight@firmluminary.example>',
		subject  => 'Ready to Find Someone Special?',
		ct	   => qq{multipart/alternative; boundary="$bnd"},
		body	 => $mp,
	));

	my @urls = $a->embedded_urls();

	# All three URLs found
	is scalar @urls, 3, 'three URLs extracted (click, unsubscribe, tracking pixel)';

	# All on the same host
	my @hosts = do { my %h; grep { !$h{$_}++ } map { $_->{host} } @urls };
	is scalar @hosts, 1,						  'all three URLs on single host';
	is $hosts[0], 'www.firmluminary.example',	 'correct host identified';

	# WHOIS called once despite three URLs
	is $whois_calls, 1, 'WHOIS queried once for the shared host';

	# report() groups them as "URLs (3)"
	my $report = $a->report();
	like $report, qr/URLs \(3\)/, 'three URLs shown as grouped count in report';
	my @host_lines = ($report =~ /Host\s*:\s*www\.firmluminary\.example/g);
	is scalar @host_lines, 1, 'host shown only once despite three URLs';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 16 — X-Originating-IP webmail fallback
#
# POD originating_ip: falls back to X-Originating-IP when all Received:
# hops are private, with confidence 'low'.
# ---------------------------------------------------------------------------
subtest 'Scenario 16: webmail origin — X-Originating-IP fallback at low confidence' => sub {
	restore_stubs();
	install_stubs(
		rdns	 => 'webmail.bigprovider.example',
		whois_ip => { org => 'Big Provider', abuse => 'abuse@bigprovider.example' },
		domain_whois => undef,
	);

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_raw_email(
		received => [
			'from webmail.bigprovider.example (webmail.bigprovider.example [10.0.0.1]) by mx.test',
			'from localhost (localhost [127.0.0.1]) by webmail.bigprovider.example',
		],
		xoip => '62.105.128.200',
		from => 'Webmail User <user@bigprovider.example>',
		body => 'Webmail spam content.',
	));

	my $orig = $a->originating_ip();
	ok defined $orig,						 'originating_ip returns a value';
	is $orig->{ip},		 '62.105.128.200', 'X-Originating-IP used as origin';
	is $orig->{confidence}, 'low',			'confidence is low for XOIP fallback';
	like $orig->{note}, qr/X-Originating-IP/i,
		'note mentions X-Originating-IP source';

	# Low confidence triggers low_confidence_origin risk flag
	my $risk = $a->risk_assessment();
	ok scalar(grep { $_->{flag} eq 'low_confidence_origin' } @{ $risk->{flags} }),
		'low_confidence_origin risk flag raised';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 17 — all_domains() is the union, no method order dependency
#
# POD all_domains: "Union of every domain seen across HTTP URLs and
# mailto/reply domains."
# Calls all_domains() before embedded_urls() and mailto_domains() to confirm
# lazy evaluation triggers both pipelines correctly.
# ---------------------------------------------------------------------------
subtest 'Scenario 17: all_domains() triggers both pipelines regardless of call order' => sub {
	restore_stubs();
	install_stubs(
		rdns	=> 'mail.sender.example',
		resolve => {
			'urlhost.example'  => '91.198.174.1',
			'mailhost.example' => '91.198.174.2',
		},
		whois_ip => { org => 'Test ISP', abuse => 'abuse@test.example' },
		domain_whois => undef,
	);

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_raw_email(
		from => 'x@mailhost.example',
		body => 'Visit https://urlhost.example/page and contact info@mailhost.example',
	));

	# Call all_domains() FIRST — before embedded_urls() or mailto_domains()
	my @all = $a->all_domains();

	ok scalar(grep { $_ eq 'urlhost.example'  } @all),
		'URL host in all_domains when called before embedded_urls()';
	ok scalar(grep { $_ eq 'mailhost.example' } @all),
		'email domain in all_domains when called before mailto_domains()';

	# Now call the individual methods — must return consistent data
	my @urls  = $a->embedded_urls();
	my @mdoms = $a->mailto_domains();

	ok scalar(grep { $_->{host} eq 'urlhost.example'	} @urls),
		'embedded_urls() consistent after all_domains() was called first';
	ok scalar(grep { $_->{domain} eq 'mailhost.example' } @mdoms),
		'mailto_domains() consistent after all_domains() was called first';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 18 — unresolved_contacts() surfaces parties with no abuse address
#
# POD unresolved_contacts: returns domains and URL hosts for which no abuse
# contact could be determined.  Spoofable-header-only sources are excluded.
# ---------------------------------------------------------------------------
subtest 'Scenario 18: unresolved_contacts() surfaces uncontactable parties' => sub {
	restore_stubs();
	install_stubs(
		rdns	 => 'mail.sender.example',
		resolve  => { 'mystery-host.example' => '5.5.5.5' },
		# Deliberately return no abuse address for mystery-host
		whois_ip => { org => 'Unknown Corp', abuse => undef },
		domain_whois => undef,
	);

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_raw_email(
		received => 'from sender (sender [91.198.174.1]) by mx.test',
		from	 => 'Spammer <spam@mystery-host.example>',
		body	 => 'Click https://mystery-host.example/buy now',
	));

	my @unresolved = $a->unresolved_contacts();

	# mystery-host.example should appear — it has no abuse contact
	ok scalar(grep { $_->{domain} eq 'mystery-host.example' } @unresolved),
		'mystery-host.example surfaces as unresolved contact';

	# Every unresolved entry has required keys
	for my $u (@unresolved) {
		ok defined $u->{domain}, 'unresolved entry has domain';
		ok defined $u->{type},   'unresolved entry has type';
		ok defined $u->{source}, 'unresolved entry has source';
		ok $u->{type} =~ /^(?:url_host|domain)$/, "type is url_host or domain";
	}

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 19 — sending_software() extracts X-PHP-Originating-Script
#
# POD sending_software: shared-hosting platforms inject X-PHP-Originating-
# Script to identify the responsible script and Unix account.
# ---------------------------------------------------------------------------
subtest 'Scenario 19: sending_software() fingerprints shared-hosting scripts' => sub {
	restore_stubs();
	install_stubs(
		rdns	 => 'mail.sharedhost.example',
		whois_ip => { org => 'Shared Host', abuse => 'abuse@sharedhost.example' },
		domain_whois => undef,
	);

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_raw_email(
		received   => 'from sharedhost (sharedhost [91.198.174.1]) by mx.test',
		from	   => 'Spammer <spam@sharedhost.example>',
		body	   => 'Buy now.',
	) . "X-PHP-Originating-Script: 1000:mailer.php\nX-Mailer: PHPMailer 6.0\n"
	);

	# parse_email is called with trailing headers after the body separator —
	# those won't be parsed (correct RFC 2822 behaviour).  Instead inject
	# via a proper raw email with extra headers before the body separator.
	my $raw = "Received: from sh (sh [91.198.174.1]) by mx.test\n"
			. "From: Spammer <spam\@sharedhost.example>\n"
			. "To: victim\@test.example\n"
			. "Subject: Buy now\n"
			. "Date: Mon, 01 Jan 2024 00:00:00 +0000\n"
			. "Message-ID: <sw-test\@sh.example>\n"
			. "Content-Type: text/plain\n"
			. "X-PHP-Originating-Script: 1000:mailer.php\n"
			. "X-Mailer: PHPMailer 6.0\n"
			. "X-Source: /home/user/public_html/contact.php\n"
			. "\n"
			. "Buy now.\n";

	$a->parse_email($raw);

	my @sw = $a->sending_software();
	ok @sw > 0, 'sending_software() returns entries when headers present';

	my ($php) = grep { $_->{header} eq 'x-php-originating-script' } @sw;
	ok defined $php,								 'X-PHP-Originating-Script found';
	is $php->{value}, '1000:mailer.php',			 'PHP script value correct';
	like $php->{note}, qr/shared hosting/i,		  'PHP script note mentions hosting';

	my ($mailer) = grep { $_->{header} eq 'x-mailer' } @sw;
	ok defined $mailer,							  'X-Mailer found';
	is $mailer->{value}, 'PHPMailer 6.0',			'mailer value correct';

	# Headers are returned in alphabetical order
	my @names = map { $_->{header} } @sw;
	my @sorted = sort @names;
	is_deeply \@names, \@sorted, 'sending_software() returns headers in alphabetical order';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 20 — received_trail() extracts hop tracking data
#
# POD received_trail: returns per-hop session IDs and envelope recipients
# that ISP postmasters need to look up the SMTP session in their logs.
# ---------------------------------------------------------------------------
subtest 'Scenario 20: received_trail() captures per-hop session IDs' => sub {
	restore_stubs();
	install_stubs(
		rdns	 => 'mail.relay.example',
		whois_ip => { org => 'Relay ISP', abuse => 'abuse@relay.example' },
		domain_whois => undef,
	);

	my $raw = "Received: from relay2 (relay2 [91.198.174.2]) by mx.test"
			. " with ESMTP id ABC123XYZ for <victim\@test.example>\n"
			. "Received: from attacker (attacker [91.198.174.1]) by relay2"
			. " with ESMTP id ZZZ999AAA\n"
			. "From: attacker\@evil.example\n"
			. "To: victim\@test.example\n"
			. "Subject: Trail test\n"
			. "Date: Mon, 01 Jan 2024 00:00:00 +0000\n"
			. "Message-ID: <trail\@evil.example>\n"
			. "Content-Type: text/plain\n"
			. "\n"
			. "Spam content.\n";

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email($raw);

	my @trail = $a->received_trail();
	ok @trail > 0, 'received_trail() returns at least one hop';

	# At least one hop has a session ID
	ok scalar(grep { defined $_->{id} } @trail),
		'at least one hop has a session ID';

	# At least one hop has an envelope recipient
	ok scalar(grep { defined $_->{for} } @trail),
		'at least one hop has an envelope recipient';

	# Hops are in oldest-first order (bottom of header block first)
	my @with_id = grep { defined $_->{id} } @trail;
	ok scalar(grep { $_->{id} eq 'ZZZ999AAA' } @with_id),
		'oldest hop session ID ZZZ999AAA present';

	# Every hop has a received field (the raw header value)
	ok !scalar(grep { !defined $_->{received} } @trail),
		'all trail hops have the raw received header';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 21 — Stateful: parse_email() called on a scalar reference
#
# POD parse_email: "A scalar reference is accepted as an alternative."
# Verifies that a scalar reference input produces identical results to a
# plain scalar, without modifying the original variable.
# ---------------------------------------------------------------------------
subtest 'Scenario 21: scalar-reference input to parse_email()' => sub {
	restore_stubs();
	install_stubs(
		rdns	 => 'mail.scalarref.example',
		whois_ip => { org => 'ScalarRef ISP', abuse => 'abuse@scalarref.example' },
		domain_whois => undef,
	);

	my $raw = make_raw_email(
		received => 'from sr (sr [91.198.174.1]) by mx.test',
		from	 => 'x@scalarref.example',
		body	 => 'Test message.',
	);
	my $original = $raw;  # save a copy

	my $a = Email::Abuse::Investigator->new();
	my $b = Email::Abuse::Investigator->new();

	$a->parse_email($raw);		  # plain scalar
	$b->parse_email(\$raw);		 # scalar reference

	# Original must not be modified
	is $raw, $original, 'original scalar not modified by scalar-ref parse';

	# Both produce the same headers
	is_deeply $a->{_headers}, $b->{_headers},
		'scalar and scalar-ref input produce identical headers';

	# Both produce the same originating IP determination
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_reverse_dns = sub { 'mail.scalarref.example' };
	local *Email::Abuse::Investigator::_whois_ip	= sub { { org => 'Test', abuse => 'a@b' } };
	my $oa = $a->originating_ip();
	my $ob = $b->originating_ip();
	is $oa->{ip}, $ob->{ip}, 'scalar and scalar-ref produce same originating IP';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 22 — form_contacts() surfaces form-only providers
#
# POD form_contacts: providers with only a 'form' key (like GoDaddy and
# MarkMonitor) must appear in form_contacts(), not abuse_contacts().
# ---------------------------------------------------------------------------
subtest 'Scenario 22: form_contacts() surfaces form-only providers correctly' => sub {
	restore_stubs();
	install_stubs(
		rdns	 => 'mail.test.example',
		resolve  => { 'godaddy-hosted.example' => '1.2.3.4' },
		whois_ip => { org => 'GoDaddy', abuse => 'abuse@godaddy.com' },
		domain_whois => sub {
			# Return a WHOIS response where registrar is GoDaddy
			return "Registrar: GoDaddy.com LLC\n"
				 . "Registrar Abuse Contact Email: abuse\@godaddy.com\n"
				 . "Creation Date: 2020-01-01\n"
				 . "Registry Expiry Date: 2099-01-01\n";
		},
	);

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_raw_email(
		received => 'from test (test [91.198.174.1]) by mx.test',
		from	 => 'spam@godaddy-hosted.example',
		body	 => 'Spam from GoDaddy hosted site.',
	));

	my @email_contacts = $a->abuse_contacts();
	my @form_cs		= $a->form_contacts();

	# GoDaddy must NOT appear as an email contact
	ok !scalar(grep { lc($_->{address}) =~ /godaddy/ } @email_contacts),
		'GoDaddy not in email abuse_contacts (form-only provider)';

	# GoDaddy MUST appear as a form contact
	ok scalar(grep { $_->{form} =~ /godaddy/i } @form_cs),
		'GoDaddy appears in form_contacts()';

	# Every form contact has required fields
	for my $c (@form_cs) {
		ok defined $c->{form},  "form contact has form URL ($c->{role})";
		ok $c->{form} =~ m{^https?://}, 'form URL starts with http(s)://';
		ok defined $c->{role},  'form contact has role';
		ok defined $c->{via},   'form contact has via';
	}

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 23 — SPF softfail generates MEDIUM flag, not HIGH
#
# POD risk_assessment: spf_softfail is MEDIUM (weight 2), not HIGH (weight 3).
# ---------------------------------------------------------------------------
subtest 'Scenario 23: SPF softfail produces MEDIUM severity flag' => sub {
	restore_stubs();
	install_stubs(
		rdns	 => 'mail.softfail.example',
		whois_ip => { org => 'Softfail ISP', abuse => 'abuse@softfail.example' },
		domain_whois => undef,
	);

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_raw_email(
		received => 'from sf (sf [91.198.174.1]) by mx.test',
		auth	 => 'mx.test; spf=softfail',
		from	 => 'test@softfail-sender.example',
		body	 => 'Softfail test.',
	));

	my $risk = $a->risk_assessment();
	my ($sf_flag) = grep { $_->{flag} eq 'spf_softfail' } @{ $risk->{flags} };

	ok defined $sf_flag,					'spf_softfail flag raised';
	is $sf_flag->{severity}, 'MEDIUM',	  'spf_softfail is MEDIUM severity';

	# spf_fail (HIGH) must NOT be raised alongside softfail
	ok !scalar(grep { $_->{flag} eq 'spf_fail' } @{ $risk->{flags} }),
		'spf_fail not raised when result is softfail';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 24 — Date header checks: missing, past, future, bad timezone
#
# POD risk_assessment flags: missing_date, suspicious_date,
# implausible_timezone.
# ---------------------------------------------------------------------------
subtest 'Scenario 24: Date: header checks — missing, past, future, bad timezone' => sub {
	restore_stubs();
	install_stubs(
		rdns	 => 'mail.datetest.example',
		whois_ip => { org => 'Date Test ISP', abuse => 'abuse@datetest.example' },
		domain_whois => undef,
	);

	# Missing Date:
	{
		my $a = Email::Abuse::Investigator->new();
		my $raw = "Received: from dt (dt [91.198.174.1]) by mx.test\n"
				. "From: x\@datetest.example\n"
				. "To: y\@test.example\n"
				. "Subject: No date\n"
				. "Content-Type: text/plain\n"
				. "\n"
				. "No date header.\n";
		$a->parse_email($raw);
		$a->{_urls} = []; $a->{_mailto_domains} = [];
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_reverse_dns = sub { 'mail.dt.example' };
		local *Email::Abuse::Investigator::_whois_ip	= sub { {} };
		my $risk = $a->risk_assessment();
		ok scalar(grep { $_->{flag} eq 'missing_date' } @{ $risk->{flags} }),
			'missing_date flagged when Date: absent';
	}

	# Date more than 7 days in the past
	{
		my $old_date = strftime('%a, %d %b %Y %H:%M:%S +0000',
								gmtime(time() - 20 * 86400));
		my $a = Email::Abuse::Investigator->new();
		$a->parse_email(make_raw_email(
			received => 'from dt (dt [91.198.174.1]) by mx.test',
			date	 => $old_date,
		));
		$a->{_urls} = []; $a->{_mailto_domains} = [];
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_reverse_dns = sub { 'mail.dt.example' };
		local *Email::Abuse::Investigator::_whois_ip	= sub { {} };
		my $risk = $a->risk_assessment();
		ok scalar(grep { $_->{flag} eq 'suspicious_date' } @{ $risk->{flags} }),
			'suspicious_date flagged for date 20 days in the past';
	}

	# Implausible timezone offset (+1500 — beyond +14:00)
	{
		my $a = Email::Abuse::Investigator->new();
		$a->parse_email(make_raw_email(
			received => 'from dt (dt [91.198.174.1]) by mx.test',
			date	 => 'Mon, 01 Jan 2024 00:00:00 +1500',
		));
		$a->{_urls} = []; $a->{_mailto_domains} = [];
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_reverse_dns = sub { 'mail.dt.example' };
		local *Email::Abuse::Investigator::_whois_ip	= sub { {} };
		my $risk = $a->risk_assessment();
		ok scalar(grep { $_->{flag} eq 'implausible_timezone' } @{ $risk->{flags} }),
			'implausible_timezone flagged for +1500 offset';
	}

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 25 — Multipart recursion guard at MAX_MULTIPART_DEPTH
#
# POD _decode_multipart: nesting depth is capped at MAX_MULTIPART_DEPTH (20)
# to prevent stack exhaustion on pathological messages.  The module must
# not die and must still return a usable (possibly partial) result.
# ---------------------------------------------------------------------------
subtest 'Scenario 25: deeply nested multipart message does not die' => sub {
	restore_stubs();
	install_stubs(
		rdns	 => 'mail.deep.example',
		whois_ip => { org => 'Deep ISP', abuse => 'abuse@deep.example' },
		domain_whois => undef,
	);

	# Build a 25-deep multipart/alternative nest
	my $depth = 25;
	my $inner = "Content-Type: text/plain\r\n\r\nDeep text content.\r\n";
	for my $i (1..$depth) {
		my $bnd = "DEEP_BND_$i";
		$inner  = "Content-Type: multipart/alternative; boundary=\"$bnd\"\r\n\r\n"
				. "--$bnd\r\n"
				. $inner
				. "--$bnd--\r\n";
	}

	my $raw = "Received: from deep (deep [91.198.174.1]) by mx.test\n"
			. "From: deep\@deep.example\n"
			. "To: victim\@test.example\n"
			. "Subject: Deep nesting test\n"
			. "Date: Mon, 01 Jan 2024 00:00:00 +0000\n"
			. "Message-ID: <deep\@deep.example>\n"
			. "Content-Type: multipart/alternative; boundary=\"DEEP_BND_0\"\n"
			. "\n"
			. "--DEEP_BND_0\r\n"
			. $inner
			. "--DEEP_BND_0--\r\n";

	my $a = Email::Abuse::Investigator->new();

	# Silence the expected depth-limit carp() messages during this subtest.
	# carp() is a plain function; replacing it locally with a no-op suppresses
	# the 20 "nesting depth limit exceeded" warnings that would otherwise clutter
	# the test output.  The local() unwinds automatically at the end of the block.
	{
		no warnings 'redefine';
		local *Carp::carp = sub {};   # no-op: swallow expected carp output

		# The module must not die on a deeply nested message
		eval { $a->parse_email($raw) };
		is $@, '', 'parse_email() does not die on deeply nested multipart';
	}

	# Public methods must still work and return safe values
	my @urls  = eval { $a->embedded_urls() };
	my @doms  = eval { $a->mailto_domains() };
	my $risk  = eval { $a->risk_assessment() };
	is $@, '', 'public methods work after deeply nested parse';
	ok defined $risk, 'risk_assessment() returns a defined value';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 26 — Object::Configure integration
#
# new() calls Object::Configure::configure($class, $params) and applies any
# values it returns as overlays.  These tests stub configure() to confirm the
# call is made with the correct arguments and that overlaid values take effect.
# ---------------------------------------------------------------------------
subtest 'Scenario 26a: Object::Configure — configure() called with correct args' => sub {
	restore_stubs();

	my @calls;
	{
		no warnings 'redefine';
		local *Object::Configure::configure = sub {
			push @calls, { class => $_[0], params => $_[1] };
			return $_[1];   # pass through unchanged
		};

		Email::Abuse::Investigator->new(timeout => 15);
		ok scalar @calls > 0,
			'Object::Configure::configure() called during new()';
		is $calls[0]{class}, 'Email::Abuse::Investigator',
			'configure() receives the correct class name';
		is ref($calls[0]{params}), 'HASH',
			'configure() receives a hashref of constructor params';
		is $calls[0]{params}{timeout}, 15,
			'constructor param timeout=15 passed through to configure()';
	}

	restore_stubs();
};

subtest 'Scenario 26b: Object::Configure — overlaid values applied by new()' => sub {
	restore_stubs();

	{
		no warnings 'redefine';
		local *Object::Configure::configure = sub {
			# Simulate a config file that overrides timeout to 99
			return { %{ $_[1] }, timeout => 99 };
		};

		my $a = Email::Abuse::Investigator->new();
		is $a->{timeout}, 99,
			'timeout overlaid to 99 by Object::Configure::configure()';
	}

	restore_stubs();
};

subtest 'Scenario 26c: Object::Configure — passthrough preserves constructor defaults' => sub {
	restore_stubs();

	{
		no warnings 'redefine';
		local *Object::Configure::configure = sub { return $_[1] };

		my $a = Email::Abuse::Investigator->new();
		is $a->{timeout}, 10,  'default timeout 10 preserved with passthrough configure';
		is $a->{verbose},  0,  'default verbose 0 preserved with passthrough configure';
		is_deeply $a->{trusted_relays}, [], 'default trusted_relays [] preserved';
	}

	restore_stubs();
};

# =============================================================================
# Object::Configure integration contract
# =============================================================================
subtest 'new() — Object::Configure::configure() is called' => sub {
	my @calls;
	{
		no warnings 'redefine';
		local *Object::Configure::configure = sub {
			push @calls, { class => $_[0], params => $_[1] };
			return $_[1];
		};
		my $a = Email::Abuse::Investigator->new(timeout => 7);
		ok scalar @calls > 0, 'Object::Configure::configure() called during new()';
		is $calls[0]{class}, 'Email::Abuse::Investigator',
			'configure() receives correct class name';
		is ref($calls[0]{params}), 'HASH', 'configure() receives hashref';
	}
};

subtest 'new() — Object::Configure overlay takes effect' => sub {
	{
		no warnings 'redefine';
		local *Object::Configure::configure = sub {
			return { %{ $_[1] }, timeout => 42, verbose => 1 };
		};
		my $a = Email::Abuse::Investigator->new();
		is $a->{timeout}, 42, 'configure() overlay applied to timeout';
		is $a->{verbose},  1, 'configure() overlay applied to verbose';
	}
};


# ---------------------------------------------------------------------------
# Scenario 27 — CHI cross-message cache: WHOIS not repeated across objects
#
# When CHI is installed, the second object analysing the same IP should hit
# the class-level cache and not repeat the WHOIS lookup.
# ---------------------------------------------------------------------------
subtest 'Scenario 27: CHI cross-message cache — WHOIS result shared between objects' => sub {
	restore_stubs();

	# Only meaningful when CHI is available
	my $cache_available = defined $Email::Abuse::Investigator::_cache;
	if (!$cache_available) {
		pass 'CHI not installed — skipping cross-object cache scenario';
		return;
	}

	# Use a unique IP that cannot already be in the cache from other subtests
	my $unique_ip = '91.198.174.' . (50 + ($$ % 100));
	my $whois_calls = 0;

	install_stubs(
		rdns	 => 'mail.chi-test.example',
		resolve  => sub { $unique_ip },
		whois_ip => sub { $whois_calls++; { org => 'CHI Test', abuse => 'abuse@chi.example' } },
		domain_whois => undef,
	);

	# First object: populates the CHI cache for $unique_ip
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_raw_email(
		received => "from h (h [$unique_ip]) by mx.test",
		body	 => "https://chi-test-$$.example/page",
	));
	$a->originating_ip();	# triggers WHOIS
	my $calls_after_first = $whois_calls;

	# Second object on the same IP: should hit the CHI cache
	my $b = Email::Abuse::Investigator->new();
	$b->parse_email(make_raw_email(
		received => "from h (h [$unique_ip]) by mx.test",
		body	 => "https://chi-test-$$.example/page",
	));
	$b->originating_ip();

	ok $whois_calls <= $calls_after_first + 1,
		'second object WHOIS call count does not increase (CHI cache hit)';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 28 — _resolve_host AAAA fallback (IPv6 DNS)
#
# When A query fails, _resolve_host should return an IPv6 address from AAAA.
# We stub the method to simulate the A-fail / AAAA-success path.
# ---------------------------------------------------------------------------
subtest 'Scenario 28: _resolve_host AAAA fallback when A query fails' => sub {
	restore_stubs();

	# Stub _resolve_host to simulate the AAAA fallback path
	{
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_resolve_host = sub {
			my (undef, $host) = @_;
			return $host if $host =~ /^\d/;
			return '2a00:1450:4001::1' if $host =~ /ipv6-aaaa-only/;
			return '1.2.3.4';		  # IPv4 for all other hosts
		};
		local *Email::Abuse::Investigator::_whois_ip = sub { { org => 'T', abuse => 'a@b' } };
		local *Email::Abuse::Investigator::_reverse_dns = sub { 'mail.ipv6.example' };
		local *Email::Abuse::Investigator::_domain_whois = sub { undef };

		my $a = Email::Abuse::Investigator->new();
		$a->parse_email(make_raw_email(
			from => 'x@ipv6-aaaa-only.example',
			body => 'https://ipv6-aaaa-only.example/page',
		));
		my @doms = $a->mailto_domains();
		my ($dom) = grep { $_->{domain} eq 'ipv6-aaaa-only.example' } @doms;
		ok defined $dom, 'domain with AAAA-only resolution found in mailto_domains';
		is $dom->{web_ip}, '2a00:1450:4001::1',
			'AAAA fallback IPv6 address stored in web_ip';

		# IPv4 path still works for normal hosts
		my @urls = $a->embedded_urls();
		my ($url) = grep { $_->{host} eq 'ipv6-aaaa-only.example' } @urls;
		ok defined $url, 'URL with AAAA-only host extracted';
	}

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 29 — Domain::PublicSuffix integration via _registrable()
#
# _registrable() must never die regardless of whether Domain::PublicSuffix is
# installed, and must return a dotted string for all common domain patterns.
# ---------------------------------------------------------------------------
subtest 'Scenario 29: Domain::PublicSuffix — _registrable() does not die on any input' => sub {
	restore_stubs();

	my @cases = (
		[ 'www.example.com',		  'example.com'  ],
		[ 'sub.example.co.uk',		'example.co.uk' ],
		[ 'a.b.c.example.org',		'example.org'  ],
		[ 'deep.sub.example.io',	  'example.io'   ],
		[ 'sub.example.com.au',	   'example.com.au' ],
		# Uncommon ccTLD — heuristic may differ from PSL but must not die
		[ 'sub.example.ltd.uk',	   undef		  ],  # result not asserted, just no-die
	);

	for my $tc (@cases) {
		my ($host, $expected) = @$tc;
		my $result;
		eval { $result = Email::Abuse::Investigator::_registrable($host) };
		is $@, '', "_registrable('$host') does not die";
		if (defined $expected) {
			is $result, $expected, "_registrable('$host') = '$expected'";
		} else {
			ok !defined($result) || $result =~ /\./,
				"_registrable('$host') returns undef or dotted string";
		}
	}

	# Specific invariants that hold regardless of PSL availability
	is Email::Abuse::Investigator::_registrable('no-dot'), undef,
		'no-dot input returns undef';
	is Email::Abuse::Investigator::_registrable('com'),	undef,
		'bare TLD returns undef';
	is Email::Abuse::Investigator::_registrable(undef),	undef,
		'undef input returns undef';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 30 — Concurrent objects: no state leakage between instances
#
# Two independent Email::Abuse::Investigator objects analyse different emails
# in the same process.  Methods on each object must reflect only that object's
# email, proving that no state is shared at the class level.
# ---------------------------------------------------------------------------
subtest 'Scenario 30: two concurrent objects — independent state, no cross-contamination' => sub {
	restore_stubs();
	install_stubs(
		rdns => sub {
			my (undef, $ip) = @_;
			return 'mail.first.example'  if $ip eq '91.198.174.101';
			return 'mail.second.example' if $ip eq '91.198.174.102';
			return undef;
		},
		resolve => sub {
			my (undef, $host) = @_;
			return '91.198.174.11' if $host =~ /first-url/;
			return '91.198.174.12' if $host =~ /second-url/;
			return undef;
		},
		whois_ip => sub {
			my (undef, $ip) = @_;
			return { org => 'First ISP',  abuse => 'abuse@first-isp.example'  }
				if $ip =~ /^91\.198\.174\.10/;
			return { org => 'Second ISP', abuse => 'abuse@second-isp.example' };
		},
		domain_whois => undef,
	);

	my $a = Email::Abuse::Investigator->new();
	my $b = Email::Abuse::Investigator->new();

	# Parse different emails on each object
	$a->parse_email(make_raw_email(
		received => 'from first (first [91.198.174.101]) by mx.test',
		from	 => 'spammer-a@first-sender.example',
		subject  => 'First email subject',
		body	 => 'Click https://first-url.example/offer to claim your prize.',
	));
	$b->parse_email(make_raw_email(
		received => 'from second (second [91.198.174.102]) by mx.test',
		from	 => 'spammer-b@second-sender.example',
		subject  => 'Second email subject',
		body	 => 'Visit https://second-url.example/deals for savings.',
	));

	# originating_ip() must reflect each object's email independently
	my $orig_a = $a->originating_ip();
	my $orig_b = $b->originating_ip();
	is $orig_a->{ip}, '91.198.174.101', 'object A: correct originating IP';
	is $orig_b->{ip}, '91.198.174.102', 'object B: correct originating IP';
	isnt $orig_a->{ip}, $orig_b->{ip},  'objects A and B have different origin IPs';

	# embedded_urls() must reflect each object's email independently
	my @urls_a = $a->embedded_urls();
	my @urls_b = $b->embedded_urls();
	is scalar @urls_a, 1, 'object A: one URL';
	is scalar @urls_b, 1, 'object B: one URL';
	is $urls_a[0]{host}, 'first-url.example',  'object A: correct URL host';
	is $urls_b[0]{host}, 'second-url.example',  'object B: correct URL host';

	# header_value() must reflect each object's headers independently
	is $a->header_value('subject'), 'First email subject',
		'object A: correct Subject header';
	is $b->header_value('subject'), 'Second email subject',
		'object B: correct Subject header';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 31 — Date more than 7 days in the future triggers suspicious_date
#
# POD risk_assessment: "date more than DATE_SKEW_DAYS (7) in the future"
# triggers the suspicious_date LOW flag — same flag as a date far in the past.
# ---------------------------------------------------------------------------
subtest 'Scenario 31: date header in the future triggers suspicious_date flag' => sub {
	restore_stubs();
	install_stubs(
		rdns	 => 'mail.datetest.example',
		whois_ip => { org => 'Date ISP', abuse => 'abuse@datetest.example' },
		domain_whois => undef,
	);

	# A date 30 days in the future — beyond the 7-day tolerance window
	my $future_date = strftime('%a, %d %b %Y %H:%M:%S +0000',
	                            gmtime(time() + 30 * 86400));

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_raw_email(
		received => 'from dt (dt [91.198.174.1]) by mx.test',
		date	 => $future_date,
		body	 => 'No links.',
	));

	my $risk = $a->risk_assessment();
	ok scalar(grep { $_->{flag} eq 'suspicious_date' } @{ $risk->{flags} }),
		'suspicious_date flagged for a date 30 days in the future';

	# The suspicious_date flag should be LOW severity
	my ($date_flag) = grep { $_->{flag} eq 'suspicious_date' } @{ $risk->{flags} };
	is $date_flag->{severity}, 'LOW', 'suspicious_date flag has LOW severity';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 32 — Plain HTTP (not HTTPS) URL triggers http_not_https LOW flag
#
# POD risk_assessment: a URL linked over http:// (no TLS) raises the
# http_not_https LOW flag once per unique host.
# ---------------------------------------------------------------------------
subtest 'Scenario 32: plain HTTP URL triggers http_not_https LOW risk flag' => sub {
	restore_stubs();
	install_stubs(
		rdns	=> 'mail.http-test.example',
		resolve => { 'plain-http.example' => '91.198.174.50' },
		whois_ip => { org => 'HTTP ISP', abuse => 'abuse@http-isp.example' },
		domain_whois => undef,
	);

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_raw_email(
		received => 'from ht (ht [91.198.174.50]) by mx.test',
		body	 => 'Order now at http://plain-http.example/buy — no link encryption.',
	));

	my $risk = $a->risk_assessment();
	ok scalar(grep { $_->{flag} eq 'http_not_https' } @{ $risk->{flags} }),
		'http_not_https flag raised for plain http:// URL';

	my ($http_flag) = grep { $_->{flag} eq 'http_not_https' } @{ $risk->{flags} };
	is $http_flag->{severity}, 'LOW', 'http_not_https has LOW severity';
	like $http_flag->{detail}, qr/plain-http\.example/, 'detail names the host';

	# The URL itself must be found and correctly catalogued
	my @urls = $a->embedded_urls();
	my ($u)  = grep { $_->{host} eq 'plain-http.example' } @urls;
	ok defined $u, 'plain-http.example URL extracted';
	like $u->{url}, qr{^http://}, 'URL retains the original http:// scheme';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 33 — DKIM signing domain mismatch
#
# When the DKIM-Signature d= domain differs from the From: domain:
#   a) DKIM pass + different registrable → INFO dkim_domain_mismatch (ESP normal)
#   b) DKIM fail + different registrable → MEDIUM dkim_domain_mismatch (suspicious)
# ---------------------------------------------------------------------------
subtest 'Scenario 33a: DKIM pass from third-party sender → INFO dkim_domain_mismatch' => sub {
	restore_stubs();
	install_stubs(
		rdns	 => 'mail.esp.example',
		whois_ip => { org => 'ESP ISP', abuse => 'abuse@esp-isp.example' },
		domain_whois => undef,
	);

	# DKIM signed by mailchimp.com, From: is @brand.example — ESP scenario
	my $raw = "Received: from esp.example (esp.example [91.198.174.1]) by mx.test\n"
	        . "Authentication-Results: mx.test; dkim=pass header.d=mailchimp.com\n"
	        . "DKIM-Signature: v=1; a=rsa-sha256; d=mailchimp.com; s=k1;\n"
	        . " h=from:to:subject; b=fakebase64==\n"
	        . "From: Brand Newsletter <newsletter\@brand-corp.example>\n"
	        . "To: subscriber\@test.example\n"
	        . "Subject: Monthly news\n"
	        . "Date: Mon, 01 Jan 2024 00:00:00 +0000\n"
	        . "Message-ID: <dkim-info\@brand-corp.example>\n"
	        . "Content-Type: text/plain\n"
	        . "\n"
	        . "Newsletter content.\n";
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email($raw);

	my $risk       = $a->risk_assessment();
	my @flag_names = map { $_->{flag} } @{ $risk->{flags} };

	ok scalar(grep { $_ eq 'dkim_domain_mismatch' } @flag_names),
		'dkim_domain_mismatch flagged when DKIM signer differs from From: domain';

	my ($mismatch) = grep { $_->{flag} eq 'dkim_domain_mismatch' } @{ $risk->{flags} };
	is $mismatch->{severity}, 'INFO',
		'DKIM pass with different registrable domain → INFO severity (normal ESP)';

	restore_stubs();
};

subtest 'Scenario 33b: DKIM fail with domain mismatch → MEDIUM dkim_domain_mismatch' => sub {
	restore_stubs();
	install_stubs(
		rdns	 => 'mail.impersonator.example',
		whois_ip => { org => 'Impersonator ISP', abuse => 'abuse@imp-isp.example' },
		domain_whois => undef,
	);

	# DKIM fail + signing domain different from From: = possible impersonation
	my $raw = "Received: from imp.example (imp.example [91.198.174.2]) by mx.test\n"
	        . "Authentication-Results: mx.test; dkim=fail\n"
	        . "DKIM-Signature: v=1; a=rsa-sha256; d=evilsigner.example; s=k1;\n"
	        . " h=from:to:subject; b=brokenbase64==\n"
	        . "From: Legit Corp <support\@legit-corp.example>\n"
	        . "To: victim\@test.example\n"
	        . "Subject: Urgent account notice\n"
	        . "Date: Mon, 01 Jan 2024 00:00:00 +0000\n"
	        . "Message-ID: <dkim-medium\@legit-corp.example>\n"
	        . "Content-Type: text/plain\n"
	        . "\n"
	        . "Your account needs verification.\n";
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email($raw);

	my $risk       = $a->risk_assessment();
	my @flag_names = map { $_->{flag} } @{ $risk->{flags} };

	ok scalar(grep { $_ eq 'dkim_domain_mismatch' } @flag_names),
		'dkim_domain_mismatch flagged when DKIM fails with a different signing domain';

	my ($mismatch) = grep { $_->{flag} eq 'dkim_domain_mismatch' } @{ $risk->{flags} };
	is $mismatch->{severity}, 'MEDIUM',
		'DKIM fail with domain mismatch → MEDIUM severity (suspicious impersonation)';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 34 — sending_software() fingerprints appear in report()
#
# When X-PHP-Originating-Script (or X-Mailer) headers are present,
# report() must contain the "SENDING SOFTWARE / INFRASTRUCTURE CLUES" section.
# ---------------------------------------------------------------------------
subtest 'Scenario 34: sending_software() data reflected in report() output' => sub {
	restore_stubs();
	install_stubs(
		rdns	 => 'mail.sharedhost.example',
		whois_ip => { org => 'Shared Host', abuse => 'abuse@sharedhost.example' },
		domain_whois => undef,
	);

	my $raw = "Received: from sh (sh [91.198.174.1]) by mx.test\n"
	        . "From: Spammer <spam\@sharedhost.example>\n"
	        . "To: victim\@test.example\n"
	        . "Subject: PHP spam\n"
	        . "Date: Mon, 01 Jan 2024 00:00:00 +0000\n"
	        . "Message-ID: <php-report\@sh.example>\n"
	        . "Content-Type: text/plain\n"
	        . "X-PHP-Originating-Script: 2000:mailer_script.php\n"
	        . "X-Source: /home/shareduser/public_html/send.php\n"
	        . "\n"
	        . "Buy cheap goods now.\n";

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email($raw);

	# Verify sending_software() found the headers
	my @sw = $a->sending_software();
	ok @sw >= 2, 'at least two sending software entries found';
	my @hdrs = map { $_->{header} } @sw;
	ok scalar(grep { $_ eq 'x-php-originating-script' } @hdrs),
		'X-PHP-Originating-Script in sending_software()';
	ok scalar(grep { $_ eq 'x-source' } @hdrs),
		'X-Source in sending_software()';

	# Verify report() contains the sending software section
	my $report = $a->report();
	like $report, qr/SENDING SOFTWARE/i,
		'report() contains SENDING SOFTWARE section heading';
	like $report, qr/x-php-originating-script/i,
		'report() contains X-PHP-Originating-Script header';
	like $report, qr/2000:mailer_script\.php/,
		'report() contains the PHP script value';
	like $report, qr/shared hosting/i,
		'report() contains the hosting note for PHP script';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 35 — received_trail() tracking IDs appear in report()
#
# When Received: headers contain session IDs and envelope recipients,
# report() must contain the "RECEIVED CHAIN TRACKING IDs" section with
# the hop data that postmasters need to trace the session in their logs.
# ---------------------------------------------------------------------------
subtest 'Scenario 35: received_trail() hop data reflected in report() output' => sub {
	restore_stubs();
	install_stubs(
		rdns	 => 'mail.relay.example',
		whois_ip => { org => 'Relay ISP', abuse => 'abuse@relay-isp.example' },
		domain_whois => undef,
	);

	my $raw = "Received: from relay.example (relay.example [91.198.174.1])"
	        . " by mx.test with ESMTP id MSGID999ZZZ"
	        . " for <postmaster-check\@test.example>;"
	        . " Mon, 01 Jan 2024 12:00:00 +0000\n"
	        . "From: spam\@relay.example\n"
	        . "To: victim\@test.example\n"
	        . "Subject: Trail test\n"
	        . "Date: Mon, 01 Jan 2024 12:00:00 +0000\n"
	        . "Message-ID: <trail-report\@relay.example>\n"
	        . "Content-Type: text/plain\n"
	        . "\n"
	        . "Spam body.\n";

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email($raw);

	# Verify received_trail() found the tracking data
	my @trail = $a->received_trail();
	ok @trail > 0, 'received_trail() returns at least one hop';
	my ($hop) = grep { defined $_->{id} && $_->{id} =~ /MSGID999ZZZ/ } @trail;
	ok defined $hop, 'tracking ID MSGID999ZZZ found in trail';

	# Verify report() contains the tracking section
	my $report = $a->report();
	like $report, qr/RECEIVED CHAIN TRACKING/i,
		'report() contains RECEIVED CHAIN TRACKING section';
	like $report, qr/MSGID999ZZZ/,
		'report() contains the specific session ID from Received: header';
	like $report, qr/postmaster-check\@test\.example/,
		'report() contains the envelope recipient from Received: header';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 36 — form_contacts() surfaced via URL host route
#
# When an embedded URL's host is a form-only provider (GoDaddy), that
# provider must appear in form_contacts() and NOT in abuse_contacts().
# This tests the URL-host route (Route 2) in form_contacts().
# ---------------------------------------------------------------------------
subtest 'Scenario 36: form_contacts() triggered by URL host (form-only provider)' => sub {
	restore_stubs();
	install_stubs(
		rdns	 => 'mail.test.example',
		resolve  => { 'www.godaddy.com' => '72.167.20.43' },
		whois_ip => { org => 'GoDaddy', abuse => 'abuse@godaddy.com' },
		domain_whois => undef,
	);

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_raw_email(
		received => 'from test (test [91.198.174.1]) by mx.test',
		# From: sender NOT a godaddy address — only the URL host should trigger
		from	 => 'Spammer <spam@otherdomain.example>',
		body	 => 'Manage your domain at https://www.godaddy.com/dns for info.',
	));

	my @email_cs = $a->abuse_contacts();
	my @form_cs  = $a->form_contacts();

	# GoDaddy must appear in form_contacts() via URL host route
	my @gd_forms = grep { $_->{form} =~ /godaddy/i } @form_cs;
	ok @gd_forms > 0, 'GoDaddy form contact found via URL host route';
	is $gd_forms[0]{via}, 'provider-table', 'form contact via is provider-table';
	like $gd_forms[0]{role}, qr/URL host/i, 'role indicates URL host discovery';

	# GoDaddy must NOT appear as an email abuse_contacts() entry
	ok !scalar(grep { lc($_->{address}) =~ /godaddy/ } @email_cs),
		'GoDaddy not in email abuse_contacts (form-only, no email)';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 37 — high_spam_country INFO flag for known spam-volume countries
#
# POD risk_assessment: when the originating IP is in CN, RU, NG, VN, IN, PK,
# or BD, the 'high_spam_country' INFO flag is raised.
# ---------------------------------------------------------------------------
subtest 'Scenario 37: high_spam_country INFO flag raised for IP in CN/RU/NG' => sub {
	restore_stubs();

	for my $country (qw(CN RU NG)) {
		install_stubs(
			rdns	 => "mail.host.${\lc $country}.example",
			whois_ip => { org => "ISP in $country", abuse => "abuse\@isp-${\lc $country}.example",
			              country => $country },
			domain_whois => undef,
		);

		my $a = Email::Abuse::Investigator->new();
		$a->parse_email(make_raw_email(
			received => 'from h (h [91.198.174.200]) by mx.test',
			body	 => 'Spam content.',
		));

		my $risk       = $a->risk_assessment();
		my @flag_names = map { $_->{flag} } @{ $risk->{flags} };

		ok scalar(grep { $_ eq 'high_spam_country' } @flag_names),
			"high_spam_country flag raised for IP in $country";

		my ($hsf) = grep { $_->{flag} eq 'high_spam_country' } @{ $risk->{flags} };
		is $hsf->{severity}, 'INFO', "high_spam_country is INFO severity for $country";
		like $hsf->{detail}, qr/$country/, "detail mentions country code $country";
	}

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 38 — parse_email(text => ...) named-arg form works end-to-end
#
# POD parse_email: "Accept both positional string and named 'text' argument."
# The full pipeline (originating_ip, embedded_urls, risk_assessment, report)
# must produce identical output regardless of whether a scalar or named arg
# is used.
# ---------------------------------------------------------------------------
subtest 'Scenario 38: parse_email(text => ...) named-arg form works end-to-end' => sub {
	restore_stubs();
	install_stubs(
		rdns	 => 'mail.named-arg.example',
		resolve  => { 'namedarg.example' => '91.198.174.77' },
		whois_ip => { org => 'Named ISP', abuse => 'abuse@named-isp.example' },
		domain_whois => undef,
	);

	my $raw = make_raw_email(
		received => 'from na (na [91.198.174.77]) by mx.test',
		from	 => 'Spammer <spam@namedarg.example>',
		body	 => 'Buy at https://namedarg.example/offer for the best deal.',
	);

	# Parse using the named-argument form
	my $a = Email::Abuse::Investigator->new();
	my $ret = $a->parse_email(text => $raw);
	is $ret, $a, 'parse_email(text => ...) returns $self for chaining';

	# Full pipeline must work identically to positional-arg form
	my $orig = $a->originating_ip();
	is $orig->{ip}, '91.198.174.77', 'named-arg: originating IP correct';

	my @urls = $a->embedded_urls();
	is scalar @urls, 1, 'named-arg: one URL found';
	is $urls[0]{host}, 'namedarg.example', 'named-arg: correct URL host';

	my $report = $a->report();
	like $report, qr/namedarg\.example/, 'named-arg: domain in report';

	# Compare with positional-arg form — results must be identical
	my $b = Email::Abuse::Investigator->new();
	$b->parse_email($raw);
	is_deeply $a->{_headers}, $b->{_headers},
		'named-arg and positional-arg produce identical parsed headers';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 39 — abuse_report_text() shows WEB-FORM REPORTS section
#
# When form_contacts() returns form-only providers, abuse_report_text() must
# include a "WEB-FORM REPORTS REQUIRED:" section describing the manual action.
# ---------------------------------------------------------------------------
subtest 'Scenario 39: abuse_report_text() includes WEB-FORM REPORTS section for form contacts' => sub {
	restore_stubs();
	install_stubs(
		rdns	 => 'mail.test.example',
		whois_ip => { org => 'Test ISP', abuse => 'abuse@test-isp.example' },
		domain_whois => undef,
	);

	# GoDaddy as the From: account provider — a form-only provider
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_raw_email(
		received => 'from test (test [91.198.174.1]) by mx.test',
		from	 => 'Registrar Abuse <abuse@godaddy.com>',
		body	 => 'Domain registration spam.',
	));
	# Clear origin and URLs so only the From: contact route fires
	$a->{_origin}         = undef;
	$a->{_urls}           = [];
	$a->{_mailto_domains} = [];

	my @forms = $a->form_contacts();
	ok @forms > 0, 'GoDaddy form contact found (precondition)';

	my $art = $a->abuse_report_text();
	like $art, qr/WEB-FORM REPORTS REQUIRED/i,
		'abuse_report_text() contains WEB-FORM REPORTS REQUIRED section';
	like $art, qr/godaddy/i,
		'GoDaddy form URL appears in abuse_report_text()';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 40 — MIME-encoded Subject triggers encoded_subject LOW flag
#
# POD risk_assessment: a Base64 or QP encoded Subject header raises the
# 'encoded_subject' LOW flag because it may be filter evasion.
# ---------------------------------------------------------------------------
subtest 'Scenario 40: MIME-encoded Subject triggers encoded_subject LOW flag' => sub {
	restore_stubs();
	install_stubs(
		rdns	 => 'mail.enc-subj.example',
		whois_ip => { org => 'Enc ISP', abuse => 'abuse@enc-isp.example' },
		domain_whois => undef,
	);

	# Base64-encoded Subject that decodes to plain ASCII
	my $enc_subj = '=?UTF-8?B?' . encode_base64('Win a free prize today!', '') . '?=';

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_raw_email(
		received => 'from enc (enc [91.198.174.1]) by mx.test',
		subject  => $enc_subj,
		body	 => 'No links here.',
	));

	my $risk       = $a->risk_assessment();
	my @flag_names = map { $_->{flag} } @{ $risk->{flags} };

	ok scalar(grep { $_ eq 'encoded_subject' } @flag_names),
		'encoded_subject flag raised for MIME-encoded Subject';

	my ($es_flag) = grep { $_->{flag} eq 'encoded_subject' } @{ $risk->{flags} };
	is $es_flag->{severity}, 'LOW', 'encoded_subject has LOW severity';
	like $es_flag->{detail}, qr/Win a free prize today!/,
		'flag detail contains the decoded subject text';

	# The report should decode and display the subject
	my $report = $a->report();
	like $report, qr/Win a free prize today!/, 'decoded Subject appears in report';

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 41 — unresolved_contacts() in full pipeline integration
#
# Exercises the unresolved_contacts() method as part of a real end-to-end
# pipeline: no internal state injection, all data flows from parse_email().
# Verifies that a domain with no WHOIS abuse contact surfaces as unresolved
# while a domain with a known abuse contact does not.
# ---------------------------------------------------------------------------
subtest 'Scenario 41: unresolved_contacts() full pipeline — unknown vs. known abuse' => sub {
	restore_stubs();
	install_stubs(
		rdns	 => 'mail.sender.example',
		resolve  => sub {
			my (undef, $host) = @_;
			return '91.198.174.10' if $host eq 'known-abuse.example';
			return '91.198.174.11' if $host eq 'unknown-abuse.example';
			return undef;
		},
		whois_ip => sub {
			my (undef, $ip) = @_;
			return { org => 'Known Corp',   abuse => 'abuse@known-abuse.example'  }
				if $ip eq '91.198.174.10';
			return { org => 'Unknown Corp', abuse => undef }
				if $ip eq '91.198.174.11';
			return {};
		},
		domain_whois => sub { undef },
	);

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_raw_email(
		received => 'from sender (sender [91.198.174.1]) by mx.test',
		# Both domains appear in the body so they are not From: spoofable sources
		from	 => 'spammer@sender.example',
		body	 => 'Visit https://unknown-abuse.example/buy '
		          . 'and https://known-abuse.example/page for our offers.',
	));

	my @unresolved = $a->unresolved_contacts();

	# unknown-abuse.example has no abuse contact → must be in unresolved
	ok scalar(grep { $_->{domain} eq 'unknown-abuse.example' } @unresolved),
		'unknown-abuse.example appears in unresolved_contacts()';

	# known-abuse.example has an abuse contact → must NOT be in unresolved
	ok !scalar(grep { $_->{domain} eq 'known-abuse.example' } @unresolved),
		'known-abuse.example does NOT appear in unresolved_contacts()';

	# All returned entries conform to the documented type values
	for my $u (@unresolved) {
		ok $u->{type} =~ /^(?:url_host|domain)$/,
			"type '$u->{type}' is a documented value";
	}

	restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 42 — all_domains() union is stable across repeated calls
#
# all_domains() must return the same set on repeated calls (idempotent) and
# contain no duplicates even when the same domain appears as both a URL host
# and a mailto domain.
# ---------------------------------------------------------------------------
subtest 'Scenario 42: all_domains() is idempotent and deduplicates URL+mailto overlap' => sub {
	restore_stubs();
	install_stubs(
		rdns	 => 'mail.overlap.example',
		resolve  => { 'overlap.example' => '91.198.174.20' },
		whois_ip => { org => 'Overlap ISP', abuse => 'abuse@overlap.example' },
		domain_whois => undef,
	);

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_raw_email(
		received => 'from ov (ov [91.198.174.20]) by mx.test',
		from	 => 'Sender <sender@overlap.example>',
		body	 => 'Click https://overlap.example/offer and reply to info@overlap.example',
	));

	my @first  = $a->all_domains();
	my @second = $a->all_domains();

	# Results are stable
	is scalar @second, scalar @first, 'all_domains() returns same count on second call';
	is_deeply \@first, \@second, 'all_domains() returns identical results on second call';

	# overlap.example appears in both URL hosts and mailto domains but should be listed once
	my @occurrences = grep { $_ eq 'overlap.example' } @first;
	is scalar @occurrences, 1,
		'overlap.example (URL host AND mailto domain) appears exactly once in all_domains()';

	restore_stubs();
};

# ===========================================================================
# Optional dependency graceful-degradation scenarios
#
# Each subtest uses without_optionals() to reload Email::Abuse::Investigator
# with specific $HAS_* flags cleared, then verifies the module's observable
# fallback behaviour through the public API only.
#
# Optional dependencies identified in the module:
#   Net::DNS          — MX / NS record lookups for domains
#   LWP::UserAgent    — RDAP enrichment + redirect-chain following
#   LWP::ConnCache    — LWP connection keep-alive (auxiliary to LWP::UserAgent)
#   HTML::LinkExtor   — Structural HTML link extraction (href/src/action attrs)
#   CHI               — Cross-message in-process WHOIS/RDAP cache
#   IO::Socket::IP    — IPv6-capable WHOIS socket (falls back to IO::Socket::INET)
#   Domain::PublicSuffix — PSL-based eTLD+1 normalisation
#   AnyEvent::DNS     — Parallel async DNS resolution
# ===========================================================================

# ---------------------------------------------------------------------------
# OD-1: Without Net::DNS
#
# Net::DNS provides MX and NS lookups inside _analyse_domain().  Without it
# the $HAS_NET_DNS guard prevents those lookups; the returned hashrefs must
# have no mx_* or ns_* keys.  All other domain fields (web_ip, registrar,
# etc.) still come from stubs and must remain present.
# ---------------------------------------------------------------------------
subtest 'OD-1: Without Net::DNS — mailto_domains() omits MX/NS keys, other fields intact' => sub {
	without_optionals(['Net::DNS'], sub {
		install_stubs(
			rdns     => 'mx.test.example',
			resolve  => { 'spammer.example' => '91.198.174.50' },
			whois_ip => { org => 'Bad ISP', abuse => 'abuse@badisp.example', country => 'XX' },
			domain_whois => sub {
				my (undef, $dom) = @_;
				return undef unless $dom eq 'spammer.example';
				return "Registrar: EvilReg Inc\n"
				     . "Registrar Abuse Contact Email: reg\@evilreg.example\n";
			},
		);

		my $a = Email::Abuse::Investigator->new();
		$a->parse_email(make_raw_email(
			received => 'from bad (bad [91.198.174.50]) by mx.test',
			from     => 'Phisher <crook@spammer.example>',
			body     => 'Send money.',
		));

		my @doms = $a->mailto_domains();
		ok scalar(@doms), 'mailto_domains() returns results without Net::DNS';

		my ($d) = grep { $_->{domain} eq 'spammer.example' } @doms;
		ok defined $d, 'spammer.example present in mailto_domains()';
		diag('Domain hashref keys: ' . join(', ', sort keys %$d)) if $ENV{TEST_VERBOSE};

		# MX keys must be absent — the $HAS_NET_DNS guard skips those lookups
		ok !exists $d->{mx_host},  'no mx_host key without Net::DNS';
		ok !exists $d->{mx_ip},    'no mx_ip key without Net::DNS';
		ok !exists $d->{mx_org},   'no mx_org key without Net::DNS';
		ok !exists $d->{mx_abuse}, 'no mx_abuse key without Net::DNS';

		# NS keys must also be absent
		ok !exists $d->{ns_host},  'no ns_host key without Net::DNS';
		ok !exists $d->{ns_ip},    'no ns_ip key without Net::DNS';
		ok !exists $d->{ns_org},   'no ns_org key without Net::DNS';
		ok !exists $d->{ns_abuse}, 'no ns_abuse key without Net::DNS';

		# Non-DNS fields still populated from stubs
		is $d->{domain},          'spammer.example',      'domain field present';
		is $d->{web_ip},          '91.198.174.50',        'web_ip from _resolve_host stub';
		is $d->{registrar_abuse}, 'reg@evilreg.example',  'registrar_abuse from domain_whois stub';

		# Module does not die and produces a report
		my $report = $a->report();
		ok defined $report && length($report), 'report() completes without Net::DNS';

		restore_stubs();
	});
};

# ---------------------------------------------------------------------------
# OD-2: Without HTML::LinkExtor
#
# HTML::LinkExtor parses HTML attributes and returns decoded URLs (e.g.
# &amp; → &).  Without it only the plain-text regex pass runs, which matches
# the raw attribute value including HTML entities.
#
# Observable differences:
#   • With LinkExtor:    2 URL entries for the same host (decoded + raw entity)
#   • Without LinkExtor: 1 URL entry (raw entity form only)
#   • The URL string found without LinkExtor contains the literal '&amp;'
# ---------------------------------------------------------------------------
subtest 'OD-2: Without HTML::LinkExtor — HTML entity URLs not decoded; count differs' => sub {
	without_optionals(['HTML::LinkExtor'], sub {
		install_stubs(
			rdns    => 'mail.test.example',
			resolve => { 'example.com' => '91.198.174.51' },
			whois_ip => { org => 'Some ISP', abuse => 'abuse@someisp.example' },
			domain_whois => undef,
		);

		# HTML-only email: the href contains HTML-entity-encoded parameters.
		# The plain-text regex finds the raw attribute value (with &amp;).
		# HTML::LinkExtor would also find the entity-decoded form (&).
		my $html_body = '<a href="https://example.com/page?ref=1&amp;src=email">click</a>';
		my $a = Email::Abuse::Investigator->new();
		$a->parse_email(make_raw_email(
			received => 'from bad (bad [91.198.174.51]) by mx.test',
			ct       => 'text/html; charset=us-ascii',
			body     => $html_body,
		));

		my @urls = $a->embedded_urls();
		diag('URLs found: ' . join(', ', map { $_->{url} } @urls)) if $ENV{TEST_VERBOSE};

		# Without LinkExtor only the plain-text-regex result is present
		is scalar(@urls), 1,
			'without HTML::LinkExtor: only plain-text regex result (raw entity form)';

		like $urls[0]->{url}, qr/&amp;/,
			'URL contains raw HTML entity &amp; (not decoded by LinkExtor)';

		unlike $urls[0]->{url}, qr/ref=1&src=/,
			'decoded form absent without HTML::LinkExtor';

		is $urls[0]->{host}, 'example.com', 'host correctly extracted despite entity';

		restore_stubs();
	});
};

# With HTML::LinkExtor present the decoded form is ALSO found, giving 2 entries.
# This subtest only runs when LinkExtor IS available.
SKIP: {
	skip 'HTML::LinkExtor not installed', 1 unless eval { require HTML::LinkExtor; 1 };

	subtest 'OD-2b: With HTML::LinkExtor — entity-decoded AND raw-entity URLs both found' => sub {
		restore_stubs();
		install_stubs(
			rdns    => 'mail.test.example',
			resolve => { 'example.com' => '91.198.174.51' },
			whois_ip => { org => 'Some ISP', abuse => 'abuse@someisp.example' },
			domain_whois => undef,
		);

		my $html_body = '<a href="https://example.com/page?ref=1&amp;src=email">click</a>';
		my $a = Email::Abuse::Investigator->new();
		$a->parse_email(make_raw_email(
			received => 'from bad (bad [91.198.174.51]) by mx.test',
			ct       => 'text/html; charset=us-ascii',
			body     => $html_body,
		));

		my @urls = $a->embedded_urls();
		diag('URLs with LinkExtor: ' . join(', ', map { $_->{url} } @urls)) if $ENV{TEST_VERBOSE};

		is scalar(@urls), 2,
			'with HTML::LinkExtor: 2 URL entries — decoded and raw-entity forms';

		my @decoded = grep { $_->{url} =~ /ref=1&src=/ } @urls;
		my @raw     = grep { $_->{url} =~ /&amp;/     } @urls;
		ok scalar(@decoded), 'decoded URL (& not &amp;) present with LinkExtor';
		ok scalar(@raw),     'raw entity URL (&amp;) also present from plain-text regex';

		restore_stubs();
	};
}

# ---------------------------------------------------------------------------
# OD-3: Without LWP::UserAgent (and LWP::ConnCache)
#
# LWP::UserAgent is required by _follow_redirect_chain() (redirect cloaker
# resolution) and _rdap_lookup() (IP enrichment).  Without it:
#   • _follow_redirect_chain() returns undef immediately ($HAS_LWP = false)
#   • Redirect-cloaker URLs are found in embedded_urls() but their phishing
#     destination is NOT appended — only the original cloud-storage URL appears.
#
# We capture the reloaded _follow_redirect_chain before install_stubs()
# overwrites it with the default sub{undef}, then restore it so the real
# no-LWP code path is exercised rather than the generic stub.
# ---------------------------------------------------------------------------
subtest 'OD-3: Without LWP::UserAgent — redirect cloaker not resolved, module stable' => sub {
	without_optionals(['LWP::UserAgent', 'LWP::ConnCache'], sub {
		# Capture the reloaded (no-LWP) implementation before install_stubs overwrites it
		my $real_follow_redirect;
		{ no strict 'refs'; $real_follow_redirect = \&Email::Abuse::Investigator::_follow_redirect_chain; }

		install_stubs(
			rdns    => 'mail.test.example',
			resolve => { 'storage.googleapis.com' => '142.250.80.112' },
			whois_ip => sub {
				my (undef, $ip) = @_;
				return { org => 'Google LLC', abuse => 'google-cloud-compliance@google.com' }
					if $ip eq '142.250.80.112';
				return {};
			},
			domain_whois => undef,
		);

		# Restore the real no-LWP _follow_redirect_chain so the $HAS_LWP=false
		# code path is exercised, not the generic sub{undef} stub.
		{ no warnings 'redefine';
		  *Email::Abuse::Investigator::_follow_redirect_chain = $real_follow_redirect; }

		my $a = Email::Abuse::Investigator->new();
		$a->parse_email(make_raw_email(
			received => 'from bad (bad [91.198.174.99]) by mx.test',
			body     => 'Click: https://storage.googleapis.com/fakebucket/redir.html',
		));

		my @urls = $a->embedded_urls();
		diag('URLs without LWP: ' . join(', ', map { $_->{host} } @urls)) if $ENV{TEST_VERBOSE};

		# GCS URL is found (URL parsing does not require LWP)
		is scalar(grep { $_->{host} eq 'storage.googleapis.com' } @urls), 1,
			'redirect-cloaker URL present in embedded_urls() without LWP';

		# Redirect not followed — only the one original URL
		is scalar(@urls), 1,
			'phishing destination absent: _follow_redirect_chain returns undef without LWP';

		# Core pipeline methods are unaffected
		my $origin = $a->originating_ip();
		ok defined $origin, 'originating_ip() works without LWP';

		my $risk = $a->risk_assessment();
		ok defined $risk && defined $risk->{level}, 'risk_assessment() works without LWP';

		# redirect_cloaker flag still raised (detection based on hostname, not HTTP)
		ok scalar(grep { $_->{flag} eq 'redirect_cloaker' } @{ $risk->{flags} }),
			'redirect_cloaker risk flag raised despite no LWP (detection is host-based)';

		my $report = $a->report();
		ok defined $report && length($report), 'report() completes without LWP';

		restore_stubs();
	});
};

# ---------------------------------------------------------------------------
# OD-4: Without CHI
#
# CHI provides a cross-message in-process cache keyed on IP/domain.  Without
# it each new object performs fresh lookups against the installed stubs.
#
# Observable test: switch the _whois_ip stub between two objects for the SAME
# IP address.  Without CHI the second object sees ISP-Beta (its own fresh
# stub), not ISP-Alpha cached from the first object.
# ---------------------------------------------------------------------------
subtest 'OD-4: Without CHI — cross-message cache absent, each object uses its own stubs' => sub {
	without_optionals(['CHI'], sub {
		# Object 1 — same IP resolves to ISP-Alpha
		install_stubs(
			rdns    => 'mail.alpha.example',
			resolve => { 'phish.example' => '91.198.174.100' },
			whois_ip => { org => 'ISP-Alpha', abuse => 'abuse@alpha.example' },
			domain_whois => undef,
		);

		my $obj1 = Email::Abuse::Investigator->new();
		$obj1->parse_email(make_raw_email(
			received => 'from a (a [91.198.174.100]) by mx.test',
			body     => 'Visit https://phish.example/',
		));

		my @urls1 = $obj1->embedded_urls();
		my ($u1)  = grep { $_->{host} eq 'phish.example' } @urls1;
		is $u1->{org}, 'ISP-Alpha', 'object 1 gets ISP-Alpha';

		# Object 2 — same IP now resolves to ISP-Beta via a different stub
		install_stubs(
			rdns    => 'mail.beta.example',
			resolve => { 'phish.example' => '91.198.174.100' },
			whois_ip => { org => 'ISP-Beta', abuse => 'abuse@beta.example' },
			domain_whois => undef,
		);

		my $obj2 = Email::Abuse::Investigator->new();
		$obj2->parse_email(make_raw_email(
			received => 'from b (b [91.198.174.100]) by mx.test',
			body     => 'Visit https://phish.example/',
		));

		my @urls2 = $obj2->embedded_urls();
		my ($u2)  = grep { $_->{host} eq 'phish.example' } @urls2;

		# Without CHI: obj2 makes a fresh lookup and gets the current stub (ISP-Beta)
		is $u2->{org}, 'ISP-Beta',
			'without CHI: object 2 makes a fresh lookup and gets ISP-Beta (not cached ISP-Alpha)';

		# Object 1 result is unchanged (per-object slot cache still active)
		is $u1->{org}, 'ISP-Alpha', 'object 1 result unchanged after object 2 lookup';

		# Both objects produce complete reports
		ok length($obj1->report()), 'obj1 report() non-empty';
		ok length($obj2->report()), 'obj2 report() non-empty';

		restore_stubs();
	});
};

# ---------------------------------------------------------------------------
# OD-5: Without Domain::PublicSuffix
#
# Domain::PublicSuffix provides PSL-based eTLD+1 normalisation via
# _registrable().  Without it the module falls back to a built-in heuristic
# that handles common ccTLD second-level patterns (co.uk, com.au, etc.).
#
# Observable: a URL with a ccTLD+2 host (sub.bad.co.uk) is still found and
# its eTLD+1 is correctly extracted as 'bad.co.uk' by the heuristic.
# ---------------------------------------------------------------------------
subtest 'OD-5: Without Domain::PublicSuffix — heuristic ccTLD normalisation still correct' => sub {
	without_optionals(['Domain::PublicSuffix'], sub {
		install_stubs(
			rdns    => 'mail.test.example',
			resolve => { 'sub.bad.co.uk' => '91.198.174.50' },
			whois_ip => { org => 'UK ISP', abuse => 'abuse@ukisp.example' },
			domain_whois => sub {
				my (undef, $dom) = @_;
				return undef unless $dom =~ /bad\.co\.uk/;
				return "Registrar: UK Reg Ltd\n"
				     . "Registrar Abuse Contact Email: abuse\@ukreg.example\n";
			},
		);

		my $a = Email::Abuse::Investigator->new();
		$a->parse_email(make_raw_email(
			received => 'from bad (bad [91.198.174.50]) by mx.test',
			body     => 'Visit https://sub.bad.co.uk/evil/',
		));

		my @urls = $a->embedded_urls();
		my ($u)  = grep { $_->{host} eq 'sub.bad.co.uk' } @urls;
		ok defined $u, 'ccTLD subdomain URL host found without Domain::PublicSuffix';

		diag("org=$u->{org} abuse=$u->{abuse}") if $ENV{TEST_VERBOSE};
		ok $u->{org},   'org populated via WHOIS stub';
		ok $u->{abuse}, 'abuse contact populated';

		# report() must not die and must mention the URL host
		my $report = $a->report();
		ok defined $report && length($report), 'report() completes without Domain::PublicSuffix';
		like $report, qr/sub\.bad\.co\.uk/, 'URL host appears in report output';

		restore_stubs();
	});
};

# ---------------------------------------------------------------------------
# OD-6: Without AnyEvent::DNS
#
# AnyEvent::DNS provides parallel async DNS resolution for multiple URL hosts.
# Without it _parallel_resolve_hosts() is a no-op and resolution falls back
# to a sequential per-host loop.  Results must be identical to the parallel path.
# ---------------------------------------------------------------------------
subtest 'OD-6: Without AnyEvent::DNS — sequential DNS fallback resolves all hosts correctly' => sub {
	without_optionals(['AnyEvent::DNS', 'AnyEvent'], sub {
		my %host_ip = (
			'site1.example' => '91.198.174.10',
			'site2.example' => '91.198.174.11',
			'site3.example' => '91.198.174.12',
		);

		install_stubs(
			rdns    => 'mail.test.example',
			resolve => sub {
				my (undef, $h) = @_;
				return $host_ip{$h};
			},
			whois_ip => sub {
				my (undef, $ip) = @_;
				my ($last) = $ip =~ /(\d+)$/;
				return { org => "ISP-$last", abuse => "abuse\@isp$last.example" };
			},
			domain_whois => undef,
		);

		my $a = Email::Abuse::Investigator->new();
		$a->parse_email(make_raw_email(
			received => 'from bad (bad [91.198.174.10]) by mx.test',
			body     => 'Visit https://site1.example/ and https://site2.example/ '
			          . 'and https://site3.example/ for spam.',
		));

		my @urls = $a->embedded_urls();
		is scalar(@urls), 3,
			'all 3 URLs resolved via sequential fallback without AnyEvent::DNS';

		for my $host (sort keys %host_ip) {
			my ($u) = grep { $_->{host} eq $host } @urls;
			ok defined $u,            "$host found";
			is $u->{ip}, $host_ip{$host}, "$host IP correct from sequential DNS";
		}

		restore_stubs();
	});
};

# ---------------------------------------------------------------------------
# OD-7: Without Net::DNS + LWP::UserAgent (combined pair)
#
# Tests the combined fallback: no MX/NS records AND no redirect following.
# A redirect-cloaker URL in the body is found but not resolved; domain
# results lack all MX/NS keys.
# ---------------------------------------------------------------------------
subtest 'OD-7: Without Net::DNS + LWP::UserAgent — combined fallback correct' => sub {
	without_optionals(['Net::DNS', 'LWP::UserAgent', 'LWP::ConnCache'], sub {
		# Capture the no-LWP _follow_redirect_chain before install_stubs replaces it
		my $real_follow;
		{ no strict 'refs'; $real_follow = \&Email::Abuse::Investigator::_follow_redirect_chain; }

		install_stubs(
			rdns    => 'mail.combined.example',
			resolve => {
				'storage.googleapis.com' => '142.250.80.112',
				'sender.example'         => '91.198.174.55',
			},
			whois_ip => sub {
				my (undef, $ip) = @_;
				return { org => 'Google LLC', abuse => 'google-cloud-compliance@google.com' }
					if $ip eq '142.250.80.112';
				return { org => 'Sender ISP', abuse => 'abuse@senderisp.example' };
			},
			domain_whois => undef,
		);

		# Use the real no-LWP redirect implementation
		{ no warnings 'redefine';
		  *Email::Abuse::Investigator::_follow_redirect_chain = $real_follow; }

		my $a = Email::Abuse::Investigator->new();
		$a->parse_email(make_raw_email(
			received => 'from bad (bad [91.198.174.55]) by mx.test',
			from     => 'Phisher <crook@sender.example>',
			body     => 'Click: https://storage.googleapis.com/bucket/page.html',
		));

		# Redirect not followed (no LWP)
		my @urls = $a->embedded_urls();
		is scalar(@urls), 1, 'only original GCS URL, no redirect destination (no LWP)';
		is $urls[0]->{host}, 'storage.googleapis.com', 'GCS URL present';

		# Domain results have no MX/NS (no Net::DNS)
		my @doms = $a->mailto_domains();
		my ($d)  = grep { $_->{domain} eq 'sender.example' } @doms;
		ok defined $d, 'sender.example in mailto_domains()';
		ok !exists $d->{mx_host}, 'no mx_host (no Net::DNS)';
		ok !exists $d->{ns_host}, 'no ns_host (no Net::DNS)';

		# Risk and report still work
		my $risk = $a->risk_assessment();
		ok defined $risk->{level}, 'risk_assessment() works in combined-fallback mode';
		ok length($a->report()),   'report() produces output in combined-fallback mode';

		restore_stubs();
	});
};

# ---------------------------------------------------------------------------
# OD-8: Without ALL optional dependencies
#
# Every $HAS_* flag is cleared.  The module must process a rich email and
# return coherent results for every public method using only stubs for the
# seven network seams.  This is the "bare minimum" baseline.
# ---------------------------------------------------------------------------
subtest 'OD-8: Without all optional deps — basic email analysis degrades gracefully' => sub {
	without_optionals([qw(
		Net::DNS  LWP::UserAgent  LWP::ConnCache  HTML::LinkExtor
		CHI  IO::Socket::IP  Domain::PublicSuffix  AnyEvent::DNS  AnyEvent
	)], sub {
		install_stubs(
			rdns    => 'mail.fallback.example',
			resolve => { 'phishing.example' => '91.198.174.77' },
			whois_ip => sub {
				return { org => 'Phish Hosting Co', abuse => 'abuse@phishhost.example' };
			},
			domain_whois => sub {
				my (undef, $dom) = @_;
				return "Registrar: BadReg\n"
				     . "Registrar Abuse Contact Email: reg\@badreg.example\n"
				     if $dom eq 'phishing.example';
				return undef;
			},
		);

		my $a = Email::Abuse::Investigator->new();
		$a->parse_email(make_raw_email(
			received => 'from ext (ext [91.198.174.77]) by mx.test',
			from     => 'Phisher <bad@phishing.example>',
			reply_to => 'bad@phishing.example',
			body     => 'Click https://phishing.example/lure and send cash.',
		));

		# originating_ip() — pure header parsing, no optional deps required
		my $origin = $a->originating_ip();
		ok defined $origin,              'originating_ip() works without any optional dep';
		is $origin->{ip}, '91.198.174.77', 'correct IP extracted';

		# embedded_urls() — no parallel DNS, no HTML linkextor, no RDAP, no redirect
		my @urls = $a->embedded_urls();
		ok scalar(@urls), 'embedded_urls() returns results without any optional dep';
		my ($u) = grep { $_->{host} eq 'phishing.example' } @urls;
		ok defined $u,        'phishing.example URL found';
		ok !exists $u->{mx_host}, 'no mx_host enrichment without Net::DNS';

		# mailto_domains() — no MX/NS keys
		my @doms = $a->mailto_domains();
		ok scalar(@doms), 'mailto_domains() returns results without any optional dep';
		my ($d) = grep { $_->{domain} eq 'phishing.example' } @doms;
		ok defined $d,        'phishing.example in mailto_domains()';
		ok !exists $d->{mx_host}, 'no mx_host without Net::DNS';

		# risk_assessment() — runs with reduced signal set
		my $risk = $a->risk_assessment();
		ok defined $risk,                   'risk_assessment() runs without optional deps';
		ok defined $risk->{level},          'risk level present';
		ok ref($risk->{flags}) eq 'ARRAY',  'flags arrayref present';

		# abuse_contacts() — uses stubs, not optional deps
		my @contacts = $a->abuse_contacts();
		ok scalar(@contacts), 'abuse_contacts() returns results';

		# all_domains() — union of URL hosts + mailto domains
		my @all = $a->all_domains();
		ok scalar(@all), 'all_domains() returns results';

		# report() — full output, no crash
		my $report = $a->report();
		ok defined $report && length($report), 'report() produces non-empty output';
		like $report, qr/91\.198\.174\.77/,    'originating IP in report';
		like $report, qr/phishing\.example/,   'domain in report';

		diag("Risk level: $risk->{level}") if $ENV{TEST_VERBOSE};
		diag("Report length: " . length($report) . " chars") if $ENV{TEST_VERBOSE};

		restore_stubs();
	});
};

done_testing();
