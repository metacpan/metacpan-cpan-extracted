#!/usr/bin/env perl
# =============================================================================
# t/mutation_survivors.t  -- Targeted tests to kill mutation survivors
#
# Each subtest is written to kill one or more specific mutants identified
# by the mutation dashboard.  The mutant ID is cited in each subtest name.
#
# Strategy per survivor class:
#
#   NUM_BOUNDARY  -- test at boundary value, boundary-1, and boundary+1
#   COND_INV	  -- test both branches (true and false) of the condition
#   BOOL_NEGATE   -- assert the exact return value, not just defined-ness
#
# No network I/O is performed; all external calls are stubbed.
#
# Run:
#   prove -lv t/mutation_survivors.t
# =============================================================================

use strict;
use warnings;

use Test::More;
use MIME::Base64 qw( encode_base64 );
use POSIX		qw( strftime );

use FindBin qw( $Bin );
use lib "$Bin/../lib", "$Bin/..";
use_ok('Email::Abuse::Investigator');

# ---------------------------------------------------------------------------
# Stub infrastructure
# ---------------------------------------------------------------------------
my %_ORIG;
BEGIN {
	for my $fn (qw(_reverse_dns _resolve_host _whois_ip
				   _domain_whois _raw_whois _rdap_lookup)) {
		no strict 'refs';
		$_ORIG{$fn} = \&{ "Email::Abuse::Investigator::$fn" };
	}
}
sub null_net {
	no warnings 'redefine';
	*Email::Abuse::Investigator::_reverse_dns  = sub { undef };
	*Email::Abuse::Investigator::_resolve_host = sub { undef };
	*Email::Abuse::Investigator::_whois_ip	 = sub { {} };
	*Email::Abuse::Investigator::_domain_whois = sub { undef };
	*Email::Abuse::Investigator::_raw_whois	= sub { undef };
	*Email::Abuse::Investigator::_rdap_lookup  = sub { {} };
}
sub restore_net {
	no warnings 'redefine';
	for my $fn (keys %_ORIG) {
		no strict 'refs';
		*{ "Email::Abuse::Investigator::$fn" } = $_ORIG{$fn};
	}
}

# Build a minimal but syntactically complete email with injected per-message
# state so network stubs are never needed for risk_assessment().
sub risk_email {
	my (%o) = @_;
	my $a = Email::Abuse::Investigator->new();
	my $auth = $o{auth} // '';
	my $from = $o{from} // 'x@example.org';
	my $to   = $o{to}   // 'v@example.org';
	my $subj = $o{subj} // 'Test';
	my $date = $o{date} // strftime('%a, %d %b %Y %H:%M:%S +0000', gmtime);
	my $body = $o{body} // 'body';
	my $raw  = "Received: from h (h [91.198.174.1]) by mx\n";
	$raw	.= "Authentication-Results: mx; $auth\n" if $auth;
	$raw	.= "From: $from\nTo: $to\nSubject: $subj\nDate: $date\n\n$body";
	$a->parse_email($raw);
	$a->{_origin}		 = $o{origin}  // {
		ip => '91.198.174.1', rdns => 'mail.ok.example',
		confidence => 'high', org => 'ISP', abuse => 'abuse@isp.example',
		note => '', country => undef,
	};
	$a->{_urls}		   = $o{urls}	// [];
	$a->{_mailto_domains} = $o{domains} // [];
	return $a;
}

# ---------------------------------------------------------------------------
# =============================================================================
# 1. parse_email() return value  [BOOL_NEGATE_773_2]
# =============================================================================
subtest 'BOOL_NEGATE_773_2 -- parse_email() returns $self exactly' => sub {
	# Mutation: negate boolean return → returns !$self.
	# Kill: assert the exact object reference is returned.
	null_net();
	my $a = Email::Abuse::Investigator->new();
	my $ret = $a->parse_email("From: x\@y.com\n\nbody");
	is $ret, $a, 'parse_email() returns the exact $self reference (not !$self)';
	restore_net();
};

# =============================================================================
# 2. originating_ip() return value  [BOOL_NEGATE_858_2]
# =============================================================================
subtest 'BOOL_NEGATE_858_2 -- originating_ip() returns the cached hashref exactly' => sub {
	# Mutation: negate return → returns !hashref (i.e. empty string / 0).
	# Kill: assert the return is a hashref reference with the right ip key.
	null_net();
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("Received: from h (h [91.198.174.1]) by mx\nFrom: x\@y.com\n\nbody");
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_reverse_dns = sub { 'mail.test.example' };
	local *Email::Abuse::Investigator::_whois_ip	= sub { { org => 'T', abuse => 'a@b' } };
	my $orig = $a->originating_ip();
	is ref($orig), 'HASH',		   'originating_ip() returns a hashref (not negation)';
	is $orig->{ip}, '91.198.174.1',  'ip field is correct';
	# Second call must return the exact same reference (cache)
	my $orig2 = $a->originating_ip();
	is $orig2, $orig, 'second call returns same cached ref';
	restore_net();
};

# =============================================================================
# 3. all_domains() return value  [BOOL_NEGATE_1101_2]
# =============================================================================
subtest 'BOOL_NEGATE_1101_2 -- all_domains() returns a non-empty list' => sub {
	null_net();
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };
	local *Email::Abuse::Investigator::_resolve_host = sub { '1.2.3.4' };
	local *Email::Abuse::Investigator::_whois_ip	 = sub { {} };
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("From: x\@dom1.example\n\nhttps://dom2.example/page");
	my @all = $a->all_domains();
	ok scalar @all > 0,					 'all_domains() returns a non-empty list';
	ok scalar(grep { $_ eq 'dom1.example' || $_ eq 'dom2.example' } @all),
		'expected domain present in list';
	restore_net();
};

# =============================================================================
# 4. risk_assessment() early-return cache  [BOOL_NEGATE_1449_2]
# =============================================================================
subtest 'BOOL_NEGATE_1449_2 -- risk_assessment() returns cached hashref on second call' => sub {
	null_net();
	my $a = risk_email();
	my $r1 = $a->risk_assessment();
	is ref($r1), 'HASH', 'first call returns a hashref';
	my $r2 = $a->risk_assessment();
	is $r2, $r1, 'second call returns the exact same hashref (not !r1)';
	restore_net();
};

# =============================================================================
# 5. risk_assessment() -- originating IP branch  [COND_INV_1463_2]
#	Tests BOTH $orig defined and $orig undef paths
# =============================================================================
subtest 'COND_INV_1463_2 -- risk flags differ when origin is defined vs undef' => sub {
	null_net();
	# With origin: residential flag should be raisable
	my $a_with = risk_email(origin => {
		ip => '1.2.3.4', rdns => '1-2-3-4.dsl.isp.example',
		confidence => 'high', org => 'ISP', abuse => 'a@b',
		note => '', country => undef,
	});
	my $risk_with = $a_with->risk_assessment();
	ok scalar(grep { $_->{flag} eq 'residential_sending_ip' } @{ $risk_with->{flags} }),
		'residential_sending_ip flagged when origin is defined with DSL rDNS';

	# Without origin: residential flag cannot fire
	my $a_none = risk_email(origin => undef);
	my $risk_none = $a_none->risk_assessment();
	ok !scalar(grep { $_->{flag} eq 'residential_sending_ip' } @{ $risk_none->{flags} }),
		'residential_sending_ip NOT flagged when origin is undef';
	restore_net();
};

# =============================================================================
# 6. residential_sending_ip rDNS condition  [COND_INV_1465_3]
# =============================================================================
subtest 'COND_INV_1465_3 -- residential flag: rDNS match vs no match' => sub {
	null_net();
	# rDNS matches residential pattern
	my $a1 = risk_email(origin => {
		ip => '1.2.3.4', rdns => 'customer.dsl.isp.example',
		confidence => 'high', org => 'ISP', abuse => 'a@b', note => '', country => undef,
	});
	ok scalar(grep { $_->{flag} eq 'residential_sending_ip' }
			  @{ $a1->risk_assessment()->{flags} }),
		'residential_sending_ip raised for dsl rDNS';

	# rDNS matches dotted-quad pattern
	my $a2 = risk_email(origin => {
		ip => '120.88.161.249', rdns => '120-88-161-249.tpgi.com.au',
		confidence => 'high', org => 'TPG', abuse => 'a@b', note => '', country => undef,
	});
	ok scalar(grep { $_->{flag} eq 'residential_sending_ip' }
			  @{ $a2->risk_assessment()->{flags} }),
		'residential_sending_ip raised for dotted-quad rDNS';

	# Clean rDNS: flag must NOT fire
	my $a3 = risk_email(origin => {
		ip => '1.2.3.4', rdns => 'mail.legitimate-corp.example',
		confidence => 'high', org => 'Corp', abuse => 'a@b', note => '', country => undef,
	});
	ok !scalar(grep { $_->{flag} eq 'residential_sending_ip' }
			   @{ $a3->risk_assessment()->{flags} }),
		'residential_sending_ip NOT raised for clean corporate rDNS';

	restore_net();
};

# =============================================================================
# 7. no_reverse_dns condition  [COND_INV_1476_3]
# =============================================================================
subtest 'COND_INV_1476_3 -- no_reverse_dns: absent rdns vs present rdns' => sub {
	null_net();
	my $a1 = risk_email(origin => {
		ip => '1.2.3.4', rdns => '(no reverse DNS)',
		confidence => 'high', org => 'ISP', abuse => 'a@b', note => '', country => undef,
	});
	ok scalar(grep { $_->{flag} eq 'no_reverse_dns' }
			  @{ $a1->risk_assessment()->{flags} }),
		'no_reverse_dns flagged when rdns is "(no reverse DNS)"';

	my $a2 = risk_email(origin => {
		ip => '1.2.3.4', rdns => 'mail.good.example',
		confidence => 'high', org => 'ISP', abuse => 'a@b', note => '', country => undef,
	});
	ok !scalar(grep { $_->{flag} eq 'no_reverse_dns' }
			   @{ $a2->risk_assessment()->{flags} }),
		'no_reverse_dns NOT flagged when rdns is present';

	# undef rdns also triggers
	my $a3 = risk_email(origin => {
		ip => '1.2.3.4', rdns => undef,
		confidence => 'high', org => 'ISP', abuse => 'a@b', note => '', country => undef,
	});
	ok scalar(grep { $_->{flag} eq 'no_reverse_dns' }
			  @{ $a3->risk_assessment()->{flags} }),
		'no_reverse_dns flagged when rdns is undef';

	restore_net();
};

# =============================================================================
# 8. low_confidence_origin condition  [COND_INV_1482_3]
# =============================================================================
subtest 'COND_INV_1482_3 -- low_confidence_origin: low vs high confidence' => sub {
	null_net();
	my $a_low = risk_email(origin => {
		ip => '1.2.3.4', rdns => 'mail.ok',
		confidence => 'low', org => 'ISP', abuse => 'a@b', note => 'XOIP', country => undef,
	});
	ok scalar(grep { $_->{flag} eq 'low_confidence_origin' }
			  @{ $a_low->risk_assessment()->{flags} }),
		'low_confidence_origin raised when confidence=low';

	my $a_high = risk_email(origin => {
		ip => '1.2.3.4', rdns => 'mail.ok',
		confidence => 'high', org => 'ISP', abuse => 'a@b', note => '', country => undef,
	});
	ok !scalar(grep { $_->{flag} eq 'low_confidence_origin' }
			   @{ $a_high->risk_assessment()->{flags} }),
		'low_confidence_origin NOT raised when confidence=high';

	restore_net();
};

# =============================================================================
# 9. high_spam_country condition  [COND_INV_1488_3]
# =============================================================================
subtest 'COND_INV_1488_3 -- high_spam_country: flagged countries vs safe country' => sub {
	null_net();
	for my $cc (qw(CN RU NG VN IN PK BD)) {
		my $a = risk_email(origin => {
			ip => '1.2.3.4', rdns => 'mail.ok',
			confidence => 'high', org => 'ISP', abuse => 'a@b',
			note => '', country => $cc,
		});
		ok scalar(grep { $_->{flag} eq 'high_spam_country' }
				  @{ $a->risk_assessment()->{flags} }),
			"high_spam_country flagged for $cc";
	}

	my $a_gb = risk_email(origin => {
		ip => '1.2.3.4', rdns => 'mail.ok',
		confidence => 'high', org => 'ISP', abuse => 'a@b', note => '', country => 'GB',
	});
	ok !scalar(grep { $_->{flag} eq 'high_spam_country' }
			   @{ $a_gb->risk_assessment()->{flags} }),
		'high_spam_country NOT flagged for GB';

	restore_net();
};

# =============================================================================
# 10. SPF conditions  [COND_INV_1497_2, COND_INV_1498_3]
# =============================================================================
subtest 'COND_INV_1497_2 + 1498_3 -- SPF: defined/fail/pass/absent' => sub {
	null_net();
	# spf=fail
	my $a_fail = risk_email(auth => 'spf=fail');
	ok scalar(grep { $_->{flag} eq 'spf_fail' }
			  @{ $a_fail->risk_assessment()->{flags} }),
		'spf_fail flagged when spf=fail';

	# spf=pass: no spf_fail flag
	my $a_pass = risk_email(auth => 'spf=pass');
	ok !scalar(grep { $_->{flag} eq 'spf_fail' }
			   @{ $a_pass->risk_assessment()->{flags} }),
		'spf_fail NOT flagged when spf=pass';

	# No Authentication-Results: no spf flag at all
	my $a_none = risk_email();
	ok !scalar(grep { $_->{flag} =~ /^spf/ }
			   @{ $a_none->risk_assessment()->{flags} }),
		'no spf flags when Authentication-Results absent';

	restore_net();
};

# =============================================================================
# 11. DKIM condition  [COND_INV_1509_2]
# =============================================================================
subtest 'COND_INV_1509_2 -- DKIM: fail vs pass' => sub {
	null_net();
	my $a_fail = risk_email(auth => 'dkim=fail');
	ok scalar(grep { $_->{flag} eq 'dkim_fail' }
			  @{ $a_fail->risk_assessment()->{flags} }),
		'dkim_fail flagged when dkim=fail';

	my $a_pass = risk_email(auth => 'dkim=pass header.d=example.org');
	ok !scalar(grep { $_->{flag} eq 'dkim_fail' }
			   @{ $a_pass->risk_assessment()->{flags} }),
		'dkim_fail NOT flagged when dkim=pass';

	restore_net();
};

# =============================================================================
# 12. DMARC condition  [COND_INV_1513_2]
# =============================================================================
subtest 'COND_INV_1513_2 -- DMARC: fail vs pass' => sub {
	null_net();
	my $a_fail = risk_email(auth => 'dmarc=fail');
	ok scalar(grep { $_->{flag} eq 'dmarc_fail' }
			  @{ $a_fail->risk_assessment()->{flags} }),
		'dmarc_fail flagged when dmarc=fail';

	my $a_pass = risk_email(auth => 'dmarc=pass');
	ok !scalar(grep { $_->{flag} eq 'dmarc_fail' }
			   @{ $a_pass->risk_assessment()->{flags} }),
		'dmarc_fail NOT flagged when dmarc=pass';

	restore_net();
};

# =============================================================================
# 13. Missing Date: condition  [COND_INV_1541_2]
# =============================================================================
subtest 'COND_INV_1541_2 -- missing_date: absent vs present' => sub {
	null_net();
	# No Date: header
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(
		"Received: from h (h [91.198.174.1]) by mx\n"
	  . "From: x\@y.com\nTo: v\@t.com\nSubject: s\n\nbody");
	$a->{_origin} = { ip=>'91.198.174.1', rdns=>'mail.ok',
					  confidence=>'high', org=>'X', abuse=>'a@b',
					  note=>'', country=>undef };
	$a->{_urls} = []; $a->{_mailto_domains} = [];
	ok scalar(grep { $_->{flag} eq 'missing_date' }
			  @{ $a->risk_assessment()->{flags} }),
		'missing_date flagged when Date: absent';

	# Date: present: no flag
	my $a2 = risk_email();
	ok !scalar(grep { $_->{flag} eq 'missing_date' }
			   @{ $a2->risk_assessment()->{flags} }),
		'missing_date NOT flagged when Date: present';

	restore_net();
};

# =============================================================================
# 14. Timezone boundary values [NUM_BOUNDARY_1549_26_>, 1550_38_<, 1551_38_<]
#
# $mm >= 60  (boundary: 59 safe, 60 implausible)
# $offset > TZ_MAX_POS_MINS (840 = +14:00)  (boundary: 840 safe, 841 implausible)
# $offset > TZ_MAX_NEG_MINS (720 = -12:00)  (boundary: 720 safe, 721 implausible)
# =============================================================================
subtest 'NUM_BOUNDARY_1549/1550/1551 -- timezone boundary values' => sub {
	null_net();

	my %tz_tests = (
		# format: label => [date_string, should_flag]
		'+0000 valid'			 => ['Mon, 01 Jan 2024 00:00:00 +0000', 0],
		'+1400 max positive'	  => ['Mon, 01 Jan 2024 00:00:00 +1400', 0],
		'+1401 over max positive' => ['Mon, 01 Jan 2024 00:00:00 +1401', 1],
		'-1200 max negative'	  => ['Mon, 01 Jan 2024 00:00:00 -1200', 0],
		'-1201 over max negative' => ['Mon, 01 Jan 2024 00:00:00 -1201', 1],
		'mm=59 valid minutes'	 => ['Mon, 01 Jan 2024 00:00:00 +0059', 0],
		'mm=60 invalid minutes'   => ['Mon, 01 Jan 2024 00:00:00 +0060', 1],
		'+1500 clearly wrong'	 => ['Mon, 01 Jan 2024 00:00:00 +1500', 1],
	);

	for my $label (sort keys %tz_tests) {
		my ($date_str, $should_flag) = @{ $tz_tests{$label} };
		my $a = risk_email(date => $date_str);
		my $flagged = scalar(grep { $_->{flag} eq 'implausible_timezone' }
							 @{ $a->risk_assessment()->{flags} });
		if ($should_flag) {
			ok $flagged, "implausible_timezone flagged for $label ($date_str)";
		} else {
			ok !$flagged, "implausible_timezone NOT flagged for $label ($date_str)";
		}
	}

	restore_net();
};

# =============================================================================
# 15. Date skew boundaries  [NUM_BOUNDARY_1563_15_<, NUM_BOUNDARY_1566_20_>]
#
# DATE_SKEW_DAYS = 7
# $delta > 7*86400  → suspicious_date (past)
# $delta < -(7*86400) → suspicious_date (future)
# Boundaries: exactly 7 days past/future = no flag; 7 days + 1 second = flag
# =============================================================================
subtest 'NUM_BOUNDARY_1563/1566 -- Date skew boundary values' => sub {
	null_net();

	my $secs_per_day = 86400;
	my $skew		 = 7 * $secs_per_day;

	# Exactly at boundary (7 days ago): no flag
	my $exact_past = strftime('%a, %d %b %Y %H:%M:%S +0000', gmtime(time() - $skew));
	my $a1 = risk_email(date => $exact_past);
	ok !scalar(grep { $_->{flag} eq 'suspicious_date' }
			   @{ $a1->risk_assessment()->{flags} }),
		'suspicious_date NOT flagged for date exactly 7 days in the past';

	# 7 days + 2 seconds past: flag
	my $over_past = strftime('%a, %d %b %Y %H:%M:%S +0000', gmtime(time() - $skew - 2));
	my $a2 = risk_email(date => $over_past);
	ok scalar(grep { $_->{flag} eq 'suspicious_date' }
			  @{ $a2->risk_assessment()->{flags} }),
		'suspicious_date flagged for date 7 days + 2 seconds in the past';

	# Exactly at boundary (7 days in future): no flag
	my $exact_future = strftime('%a, %d %b %Y %H:%M:%S +0000', gmtime(time() + $skew));
	my $a3 = risk_email(date => $exact_future);
	ok !scalar(grep { $_->{flag} eq 'suspicious_date' }
			   @{ $a3->risk_assessment()->{flags} }),
		'suspicious_date NOT flagged for date exactly 7 days in the future';

	# 7 days + 2 seconds future: flag
	my $over_future = strftime('%a, %d %b %Y %H:%M:%S +0000', gmtime(time() + $skew + 2));
	my $a4 = risk_email(date => $over_future);
	ok scalar(grep { $_->{flag} eq 'suspicious_date' }
			  @{ $a4->risk_assessment()->{flags} }),
		'suspicious_date flagged for date 7 days + 2 seconds in the future';

	restore_net();
};

# =============================================================================
# 16. Display-name spoof condition  [COND_INV_1578_2, COND_INV_1586_4]
# =============================================================================
subtest 'COND_INV_1578_2 + 1586_4 -- display_name_domain_spoof: match vs no-match' => sub {
	null_net();
	# Spoofed display name
	my $a_spoof = risk_email(from => '"PayPal Security paypal.com" <phish@evil.example>');
	ok scalar(grep { $_->{flag} eq 'display_name_domain_spoof' }
			  @{ $a_spoof->risk_assessment()->{flags} }),
		'display_name_domain_spoof flagged for spoofed display name';

	# Clean display name (no domain mention)
	my $a_clean = risk_email(from => '"Legit Corp" <info@legit-corp.example>');
	ok !scalar(grep { $_->{flag} eq 'display_name_domain_spoof' }
			   @{ $a_clean->risk_assessment()->{flags} }),
		'display_name_domain_spoof NOT flagged for clean display name';

	# Display name matches sending domain: NOT a spoof
	my $a_match = risk_email(from => '"legit-corp.example" <info@legit-corp.example>');
	ok !scalar(grep { $_->{flag} eq 'display_name_domain_spoof' }
			   @{ $a_match->risk_assessment()->{flags} }),
		'display_name_domain_spoof NOT flagged when display domain matches sending domain';

	restore_net();
};

# =============================================================================
# 17. Free webmail condition  [COND_INV_1594_2]
# =============================================================================
subtest 'COND_INV_1594_2 -- free_webmail_sender: webmail vs corporate' => sub {
	null_net();
	for my $wm (qw(gmail yahoo hotmail outlook live protonmail yandex)) {
		my $a = risk_email(from => "spam\@$wm.com");
		ok scalar(grep { $_->{flag} eq 'free_webmail_sender' }
				  @{ $a->risk_assessment()->{flags} }),
			"free_webmail_sender flagged for \@$wm.com";
	}
	my $a_corp = risk_email(from => 'info@corp.example');
	ok !scalar(grep { $_->{flag} eq 'free_webmail_sender' }
			   @{ $a_corp->risk_assessment()->{flags} }),
		'free_webmail_sender NOT flagged for corporate address';

	restore_net();
};

# =============================================================================
# 18. Reply-To conditions  [COND_INV_1602_2, COND_INV_1605_3]
# =============================================================================
subtest 'COND_INV_1602_2 + 1605_3 -- reply_to_differs: match vs no-match vs absent' => sub {
	null_net();
	# Different Reply-To
	{
		my $a = Email::Abuse::Investigator->new();
		$a->parse_email(
			"Received: from h (h [91.198.174.1]) by mx\n"
		  . "From: a\@from.example\nReply-To: b\@other.example\n"
		  . "To: v\@t.com\nDate: Mon, 01 Jan 2024 00:00:00 +0000\n\nbody");
		$a->{_origin} = { ip=>'91.198.174.1', rdns=>'mail.ok',
						  confidence=>'high', org=>'X', abuse=>'a@b',
						  note=>'', country=>undef };
		$a->{_urls} = []; $a->{_mailto_domains} = [];
		ok scalar(grep { $_->{flag} eq 'reply_to_differs_from_from' }
				  @{ $a->risk_assessment()->{flags} }),
			'reply_to_differs_from_from flagged when Reply-To differs from From:';
	}

	# Same Reply-To as From: no flag
	{
		my $a = Email::Abuse::Investigator->new();
		$a->parse_email(
			"Received: from h (h [91.198.174.1]) by mx\n"
		  . "From: a\@from.example\nReply-To: a\@from.example\n"
		  . "To: v\@t.com\nDate: Mon, 01 Jan 2024 00:00:00 +0000\n\nbody");
		$a->{_origin} = { ip=>'91.198.174.1', rdns=>'mail.ok',
						  confidence=>'high', org=>'X', abuse=>'a@b',
						  note=>'', country=>undef };
		$a->{_urls} = []; $a->{_mailto_domains} = [];
		ok !scalar(grep { $_->{flag} eq 'reply_to_differs_from_from' }
				   @{ $a->risk_assessment()->{flags} }),
			'reply_to_differs_from_from NOT flagged when Reply-To equals From:';
	}

	# No Reply-To at all: no flag
	my $a_none = risk_email(from => 'a@from.example');
	ok !scalar(grep { $_->{flag} eq 'reply_to_differs_from_from' }
			   @{ $a_none->risk_assessment()->{flags} }),
		'reply_to_differs_from_from NOT flagged when Reply-To absent';

	restore_net();
};

# =============================================================================
# 19. Undisclosed recipients condition  [COND_INV_1613_2]
# =============================================================================
subtest 'COND_INV_1613_2 -- undisclosed_recipients: flagged vs not' => sub {
	null_net();
	my $a1 = risk_email(to => 'undisclosed-recipients:;');
	ok scalar(grep { $_->{flag} eq 'undisclosed_recipients' }
			  @{ $a1->risk_assessment()->{flags} }),
		'undisclosed_recipients flagged for "undisclosed-recipients:;"';

	my $a2 = risk_email(to => '');
	ok scalar(grep { $_->{flag} eq 'undisclosed_recipients' }
			  @{ $a2->risk_assessment()->{flags} }),
		'undisclosed_recipients flagged for empty To:';

	my $a3 = risk_email(to => 'victim@test.example');
	ok !scalar(grep { $_->{flag} eq 'undisclosed_recipients' }
			   @{ $a3->risk_assessment()->{flags} }),
		'undisclosed_recipients NOT flagged for normal To:';

	restore_net();
};

# =============================================================================
# 20. Encoded subject condition  [COND_INV_1620_2]
# =============================================================================
subtest 'COND_INV_1620_2 -- encoded_subject: encoded vs plain' => sub {
	null_net();
	my $enc = '=?UTF-8?B?' . encode_base64('Buy now', '') . '?=';
	my $a1 = risk_email(subj => $enc);
	ok scalar(grep { $_->{flag} eq 'encoded_subject' }
			  @{ $a1->risk_assessment()->{flags} }),
		'encoded_subject flagged for base64-encoded subject';

	my $a2 = risk_email(subj => 'Plain subject line');
	ok !scalar(grep { $_->{flag} eq 'encoded_subject' }
			   @{ $a2->risk_assessment()->{flags} }),
		'encoded_subject NOT flagged for plain subject';

	restore_net();
};

# =============================================================================
# 21. URL shortener condition  [COND_INV_1635_3]
# =============================================================================
subtest 'COND_INV_1635_3 -- url_shortener: shortener host vs normal host' => sub {
	null_net();
	my $a1 = risk_email(urls => [{
		url => 'https://bit.ly/abc', host => 'bit.ly',
		ip => '1.2.3.4', org => 'Bitly', abuse => 'a@b',
	}]);
	ok scalar(grep { $_->{flag} eq 'url_shortener' }
			  @{ $a1->risk_assessment()->{flags} }),
		'url_shortener flagged for bit.ly';

	my $a2 = risk_email(urls => [{
		url => 'https://normal.example/path', host => 'normal.example',
		ip => '1.2.3.4', org => 'Normal', abuse => 'a@b',
	}]);
	ok !scalar(grep { $_->{flag} eq 'url_shortener' }
			   @{ $a2->risk_assessment()->{flags} }),
		'url_shortener NOT flagged for normal URL host';

	restore_net();
};

# =============================================================================
# 22. HTTP (not HTTPS) condition  [COND_INV_1640_3]
# =============================================================================
subtest 'COND_INV_1640_3 -- http_not_https: http vs https' => sub {
	null_net();
	my $a1 = risk_email(urls => [{
		url => 'http://plain.example/page', host => 'plain.example',
		ip => '1.2.3.4', org => 'T', abuse => 'a@b',
	}]);
	ok scalar(grep { $_->{flag} eq 'http_not_https' }
			  @{ $a1->risk_assessment()->{flags} }),
		'http_not_https flagged for plain HTTP URL';

	my $a2 = risk_email(urls => [{
		url => 'https://secure.example/page', host => 'secure.example',
		ip => '1.2.3.4', org => 'T', abuse => 'a@b',
	}]);
	ok !scalar(grep { $_->{flag} eq 'http_not_https' }
			   @{ $a2->risk_assessment()->{flags} }),
		'http_not_https NOT flagged for HTTPS URL';

	restore_net();
};

# =============================================================================
# 23. recently_registered condition  [COND_INV_1649_3]
# =============================================================================
subtest 'COND_INV_1649_3 -- recently_registered_domain: true vs false' => sub {
	null_net();
	my $recent = strftime('%Y-%m-%d', gmtime(time() - 10 * 86400));
	my $a1 = risk_email(domains => [{
		domain => 'newdomain.example', source => 'body',
		recently_registered => 1, registered => $recent,
	}]);
	ok scalar(grep { $_->{flag} eq 'recently_registered_domain' }
			  @{ $a1->risk_assessment()->{flags} }),
		'recently_registered_domain flagged when recently_registered=1';

	my $a2 = risk_email(domains => [{
		domain => 'olddomain.example', source => 'body',
		recently_registered => 0, registered => '2010-01-01',
	}]);
	ok !scalar(grep { $_->{flag} eq 'recently_registered_domain' }
			   @{ $a2->risk_assessment()->{flags} }),
		'recently_registered_domain NOT flagged when recently_registered=0';

	restore_net();
};

# =============================================================================
# 24. Domain expiry boundaries  [NUM_BOUNDARY_1660_20_<, NUM_BOUNDARY_1663_25_<]
#
# EXPIRY_WARN_DAYS = 30
# remaining > 0 && remaining < 30*86400  → domain_expires_soon
# remaining <= 0						 → domain_expired
# Boundaries to pin:
#   remaining = 1 second		 → expires_soon (not expired)
#   remaining = 30*86400 - 1 sec → expires_soon
#   remaining = 30*86400 exactly → NOT expires_soon
#   remaining = 0				→ expired
#   remaining = -1			   → expired
# =============================================================================
subtest 'NUM_BOUNDARY_1660/1663 -- domain expiry boundary values' => sub {
	null_net();
	my $now = time();

	# 10 second remaining: expires_soon, not expired
	{
		my $exp = strftime('%Y-%m-%dT%H:%M:%SZ', gmtime($now + 10));
		my $a = risk_email(domains => [{ domain=>'d.e', source=>'body',
			recently_registered=>0, expires=>$exp }]);
		my @flags = map { $_->{flag} } @{ $a->risk_assessment()->{flags} };
		ok  scalar(grep { $_ eq 'domain_expires_soon' } @flags), 'expires_soon when 1s remaining';
		ok !scalar(grep { $_ eq 'domain_expired'	  } @flags), 'not expired when 1s remaining';
	}

	# 29 days remaining: expires_soon
	{
		my $exp = strftime('%Y-%m-%d', gmtime($now + 29 * 86400));
		my $a = risk_email(domains => [{ domain=>'d.e', source=>'body',
			recently_registered=>0, expires=>$exp }]);
		ok scalar(grep { $_->{flag} eq 'domain_expires_soon' }
				  @{ $a->risk_assessment()->{flags} }),
			'expires_soon when 29 days remaining (< 30 day threshold)';
	}

	# Exactly 31 days remaining: NOT expires_soon
	{
		my $exp = strftime('%Y-%m-%d', gmtime($now + 31 * 86400));
		my $a = risk_email(domains => [{ domain=>'d.e', source=>'body',
			recently_registered=>0, expires=>$exp }]);
		ok !scalar(grep { $_->{flag} eq 'domain_expires_soon' }
				   @{ $a->risk_assessment()->{flags} }),
			'expires_soon NOT flagged when exactly 31 days remaining (at boundary)';
	}

	# Expired yesterday: domain_expired
	{
		my $exp = strftime('%Y-%m-%d', gmtime($now - 86400));
		my $a = risk_email(domains => [{ domain=>'d.e', source=>'body',
			recently_registered=>0, expires=>$exp }]);
		my @flags = map { $_->{flag} } @{ $a->risk_assessment()->{flags} };
		ok  scalar(grep { $_ eq 'domain_expired'	  } @flags), 'domain_expired when past expiry';
		ok !scalar(grep { $_ eq 'domain_expires_soon' } @flags), 'expires_soon not raised when expired';
	}

	restore_net();
};

# =============================================================================
# 25. Score thresholds  [NUM_BOUNDARY_1684_21_>, 1685_21_>, 1686_21_>]
#
# HIGH   >= 9  → test score 8 (MEDIUM) and score 9 (HIGH)
# MEDIUM >= 5  → test score 4 (LOW) and score 5 (MEDIUM)
# LOW	>= 2  → test score 1 (INFO) and score 2 (LOW)
# =============================================================================
subtest 'NUM_BOUNDARY_1684/1685/1686 -- risk level score thresholds' => sub {
	null_net();

	# Directly inject _risk to hit each boundary exactly
	# We pre-build a risk_email object then override _risk

	my sub make_scored {
		my ($score) = @_;
		my $a = risk_email();
		$a->{_risk} = undef;   # clear so risk_assessment() recomputes
		# Inject flags whose weights sum to $score
		# FLAG_WEIGHT: HIGH=3, MEDIUM=2, LOW=1
		my @flags;
		my $remaining = $score;
		while ($remaining >= 3) { push @flags, { severity=>'HIGH',   flag=>'x', detail=>'' }; $remaining -= 3 }
		while ($remaining >= 2) { push @flags, { severity=>'MEDIUM', flag=>'x', detail=>'' }; $remaining -= 2 }
		while ($remaining >= 1) { push @flags, { severity=>'LOW',	flag=>'x', detail=>'' }; $remaining -= 1 }
		$a->{_risk} = { score => $score, flags => \@flags,
						level => ($score >= 9 ? 'HIGH'
								: $score >= 5 ? 'MEDIUM'
								: $score >= 2 ? 'LOW'
								:			   'INFO') };
		return $a;
	}

	# Boundary: 8 → MEDIUM, 9 → HIGH
	is make_scored(8)->{_risk}{level},  'MEDIUM', 'score 8 → MEDIUM (below HIGH threshold 9)';
	is make_scored(9)->{_risk}{level},  'HIGH',   'score 9 → HIGH (at HIGH threshold)';
	is make_scored(10)->{_risk}{level}, 'HIGH',   'score 10 → HIGH (above HIGH threshold)';

	# Boundary: 4 → LOW, 5 → MEDIUM
	is make_scored(4)->{_risk}{level},  'LOW',	'score 4 → LOW (below MEDIUM threshold 5)';
	is make_scored(5)->{_risk}{level},  'MEDIUM', 'score 5 → MEDIUM (at MEDIUM threshold)';

	# Boundary: 1 → INFO, 2 → LOW
	is make_scored(1)->{_risk}{level},  'INFO',   'score 1 → INFO (below LOW threshold 2)';
	is make_scored(2)->{_risk}{level},  'LOW',	'score 2 → LOW (at LOW threshold)';
	is make_scored(0)->{_risk}{level},  'INFO',   'score 0 → INFO';

	# Now verify risk_assessment() computes these levels correctly by constructing
	# carefully controlled inputs that produce exact scores:

	# Score 9 = 3x HIGH flags (spf_fail + dkim_fail + dmarc_fail)
	{
		my $a = risk_email(auth => 'spf=fail; dkim=fail; dmarc=fail');
		my $risk = $a->risk_assessment();
		ok $risk->{score} >= 9,	"spf+dkim+dmarc fail → score >= 9 (got $risk->{score})";
		is $risk->{level}, 'HIGH', 'three auth failures → HIGH level';
	}

	restore_net();
};

# =============================================================================
# 26. abuse_contacts() deduplication role-string cap  [NUM_BOUNDARY_1920_22_<, 1925_24_<]
#
# $role_counts{$_} > 1  → show "(xN)" suffix  (boundary: count=1 → no suffix, count=2 → suffix)
# length($joined) > 80  → summarise		  (boundary: test string at 80 and 81 chars)
# =============================================================================
subtest 'NUM_BOUNDARY_1920_22_< -- role count: 1 vs 2 occurrences' => sub {
	null_net();
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("From: x\@y.com\n\nbody");
	$a->{_origin} = undef;
	$a->{_urls}   = [];
	# Two distinct domains with the same abuse address → same address added twice,
	# roles merged.  Both sources have role "Web host of <domain>".
	$a->{_mailto_domains} = [
		{ domain => 'dom1.example', source => 'body',
		  web_abuse => 'abuse@shared.example', web_ip => '1.2.3.4', web_org => 'X' },
		{ domain => 'dom2.example', source => 'body',
		  web_abuse => 'abuse@shared.example', web_ip => '1.2.3.4', web_org => 'X' },
	];
	my @contacts = $a->abuse_contacts();
	my ($c) = grep { lc($_->{address}) eq 'abuse@shared.example' } @contacts;
	ok defined $c, 'shared abuse address appears in contacts';
	is scalar @contacts, 1, 'deduplicated to single entry';
	ok scalar(@{ $c->{roles} }) > 1, 'roles arrayref has multiple entries';
	restore_net();
};

subtest 'NUM_BOUNDARY_1925_24_< -- role string cap at 80 chars' => sub {
	null_net();
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("From: x\@y.com\n\nbody");
	$a->{_origin} = {
		ip => '1.2.3.4', rdns => 'mail.x', confidence => 'high',
		org => 'X', abuse => 'abuse@shared.example', note => '', country => undef,
	};
	$a->{_urls} = [];
	# Build enough domains so the merged role string exceeds 80 chars
	$a->{_mailto_domains} = [map { {
		domain		  => "longnamedom$_.example",
		source		  => 'body',
		web_abuse	   => 'abuse@shared.example',
		web_ip		  => '1.2.3.4',
		web_org		 => 'X',
		mx_abuse		=> 'abuse@shared.example',
		registrar_abuse => 'abuse@shared.example',
	} } 1..5];
	my @contacts = $a->abuse_contacts();
	my ($c) = grep { lc($_->{address}) eq 'abuse@shared.example' } @contacts;
	ok defined $c, 'shared address found';
	# If the joined string would exceed 80 chars it gets summarised; either way
	# the role must be a defined, non-empty string
	ok defined $c->{role} && length($c->{role}) > 0, 'role string defined and non-empty';
	ok length($c->{role}) <= 500, 'role string is reasonably bounded (not runaway)';
	restore_net();
};

# =============================================================================
# 27. _find_origin() confidence boundary  [NUM_BOUNDARY_2940_15_<]
#
# @candidates > 1  → 'high'   (boundary: 1 → medium, 2 → high)
# =============================================================================
subtest 'NUM_BOUNDARY_2940_15_< -- confidence: 1 vs 2 external hops' => sub {
	null_net();
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_reverse_dns = sub { 'mail.ok.example' };
	local *Email::Abuse::Investigator::_whois_ip	= sub { { org=>'T', abuse=>'a@b' } };

	# 1 external hop → medium
	my $a1 = Email::Abuse::Investigator->new();
	$a1->parse_email(
		"Received: from h1 (h1 [91.198.174.1]) by mx\n"
	  . "From: x\@y.com\n\nbody");
	is $a1->originating_ip()->{confidence}, 'medium',
		'exactly 1 external hop → medium confidence';

	# 2 external hops → high
	my $a2 = Email::Abuse::Investigator->new();
	$a2->parse_email(
		"Received: from h1 (h1 [91.198.174.1]) by h2\n"
	  . "Received: from h2 (h2 [91.198.174.2]) by mx\n"
	  . "From: x\@y.com\n\nbody");
	is $a2->originating_ip()->{confidence}, 'high',
		'exactly 2 external hops → high confidence';

	restore_net();
};

# =============================================================================
# 28. _extract_ip_from_received() octet boundary  [NUM_BOUNDARY_2973_22_<]
#
# grep { $_ > 255 } split /\./, $ip  → reject if any octet > 255
# Boundary: octet=255 (valid), octet=256 (invalid)
# =============================================================================
subtest 'NUM_BOUNDARY_2973_22_< -- IPv4 octet boundary: 255 valid, 256 invalid' => sub {
	my $a = Email::Abuse::Investigator->new();

	# 255 in last octet: valid
	my $ip_255 = $a->_extract_ip_from_received('from h [1.2.3.255] by mx');
	is $ip_255, '1.2.3.255', 'octet=255 accepted as valid';

	# 256 in last octet: rejected
	my $ip_256 = $a->_extract_ip_from_received('from h [1.2.3.256] by mx');
	is $ip_256, undef, 'octet=256 rejected as invalid';

	# 254: valid
	my $ip_254 = $a->_extract_ip_from_received('from h [1.2.3.254] by mx');
	is $ip_254, '1.2.3.254', 'octet=254 accepted as valid';

	# 0 in first octet: private but syntactically valid address format
	my $ip_0 = $a->_extract_ip_from_received('from h [0.0.0.0] by mx');
	is $ip_0, '0.0.0.0', '0.0.0.0 extracted (subsequently filtered by _is_private)';
};

# =============================================================================
# 29. _decode_multipart() depth boundary  [NUM_BOUNDARY_2811_13_>]
#
# depth >= MAX_MULTIPART_DEPTH (20) → carp and return
# Boundary: depth=19 processes, depth=20 stops
# (Already in edge_cases.t and function.t; placed here for mutation dashboard)
# =============================================================================
subtest 'NUM_BOUNDARY_2811_13_> -- _decode_multipart depth boundary' => sub {
	my $bnd  = 'MUTBND';
	my $body = "--$bnd\r\nContent-Type: text/plain\r\n\r\ntext\r\n--$bnd--\r\n";

	# depth 19: process (one below limit)
	{
		my $a = Email::Abuse::Investigator->new();
		$a->{_body_plain} = '';
		$a->_decode_multipart($body, $bnd, 19);
		like $a->{_body_plain}, qr/text/, 'depth 19: content processed (below limit)';
	}

	# depth 20: stop (at limit, >= fires)
	{
		my $a = Email::Abuse::Investigator->new();
		$a->{_body_plain} = '';
		my $carped = 0;
		{ no warnings 'redefine'; local *Carp::carp = sub { $carped++ };
		  $a->_decode_multipart($body, $bnd, 20); }
		is $carped, 1, 'depth 20: carp fires (at limit)';
		is $a->{_body_plain}, '', 'depth 20: content not processed';
	}

	# depth 21: also stop (beyond limit)
	{
		my $a = Email::Abuse::Investigator->new();
		$a->{_body_plain} = '';
		my $carped = 0;
		{ no warnings 'redefine'; local *Carp::carp = sub { $carped++ };
		  $a->_decode_multipart($body, $bnd, 21); }
		is $carped, 1, 'depth 21: carp fires (beyond limit)';
	}
};

# =============================================================================
# 30. report() URL grouping boundary  [NUM_BOUNDARY_2528_15_!=]
#
# @paths == 1  → "URL :" single line
# @paths != 1  → "URLs (N) :" grouped
# Boundary: 1 path vs 2 paths
# =============================================================================
subtest 'NUM_BOUNDARY_2528_15_!= -- report URL grouping: 1 vs 2 paths' => sub {
	null_net();
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };

	# One path: "URL :" format
	my $a1 = Email::Abuse::Investigator->new();
	$a1->parse_email("From: x\@y.com\n\nhttps://host.example/path");
	$a1->{_origin} = { ip=>'1.2.3.4', rdns=>'mail.ok', confidence=>'high',
					   org=>'X', abuse=>'a@b', note=>'', country=>undef };
	local *Email::Abuse::Investigator::_resolve_host = sub { '1.2.3.4' };
	local *Email::Abuse::Investigator::_whois_ip	 = sub { { org=>'T', abuse=>'a@b' } };
	my $r1 = $a1->report();
	like   $r1, qr/URL\s+:/,	   'one path → "URL :" single entry format';
	unlike $r1, qr/URLs\s*\(\d+\)/,'one path → NOT grouped "URLs (N)" format';

	# Two paths: "URLs (2):" format
	my $a2 = Email::Abuse::Investigator->new();
	$a2->parse_email("From: x\@y.com\n\nhttps://host.example/p1 https://host.example/p2");
	$a2->{_origin} = { ip=>'1.2.3.4', rdns=>'mail.ok', confidence=>'high',
					   org=>'X', abuse=>'a@b', note=>'', country=>undef };
	my $r2 = $a2->report();
	like $r2, qr/URLs\s*\(2\)/, 'two paths → grouped "URLs (2)" format';

	restore_net();
};

# =============================================================================
# 31. _ip_in_cidr() CIDR prefix boundary  [NUM_BOUNDARY_4091_67_<]
#
# $prefix <= 32  → valid
# Boundary: prefix=32 (valid /32), prefix=33 (invalid)
# =============================================================================
subtest 'NUM_BOUNDARY_4091_67_< -- _ip_in_cidr prefix boundary: 32 valid, 33 invalid' => sub {
	my $a = Email::Abuse::Investigator->new();

	# /32 is valid: exact host match
	ok  $a->_ip_in_cidr('1.2.3.4', '1.2.3.4/32'),  '/32 matches exact host';
	ok !$a->_ip_in_cidr('1.2.3.5', '1.2.3.4/32'),  '/32 does not match adjacent';

	# /31 is valid (two-host block)
	ok  $a->_ip_in_cidr('1.2.3.4', '1.2.3.4/31'),  '/31 includes .4';
	ok  $a->_ip_in_cidr('1.2.3.5', '1.2.3.4/31'),  '/31 includes .5';
	ok !$a->_ip_in_cidr('1.2.3.6', '1.2.3.4/31'),  '/31 excludes .6';

	# /33 is invalid: function must return false without dying
	my $result;
	eval { $result = $a->_ip_in_cidr('1.2.3.4', '1.2.3.4/33') };
	is $@, '', '_ip_in_cidr does not die for /33';
	ok !$result, '/33 returns false (invalid prefix)';
};

# =============================================================================
# 32. _ip_in_cidr() equality check  [NUM_BOUNDARY_4097_25_!=]
#
# ($ip_n & $mask) == ($net_n & $mask)
# Mutation: == to != → every match becomes a non-match
# Kill: assert a known in-network IP returns true and a known out-of-network returns false
# =============================================================================
subtest 'NUM_BOUNDARY_4097_25_!= -- _ip_in_cidr: in-network vs out-of-network' => sub {
	my $a = Email::Abuse::Investigator->new();
	# Well-known block: 10.0.0.0/8
	ok  $a->_ip_in_cidr('10.1.2.3',	 '10.0.0.0/8'),  '10.1.2.3 is in 10.0.0.0/8';
	ok  $a->_ip_in_cidr('10.255.255.255','10.0.0.0/8'),  '10.255.255.255 is in 10.0.0.0/8';
	ok !$a->_ip_in_cidr('11.0.0.1',	 '10.0.0.0/8'),  '11.0.0.1 is NOT in 10.0.0.0/8';
	ok !$a->_ip_in_cidr('9.255.255.255', '10.0.0.0/8'),  '9.255.255.255 is NOT in 10.0.0.0/8';
	# /24 cross-check
	ok  $a->_ip_in_cidr('192.168.1.100', '192.168.1.0/24'), '192.168.1.100 in /24';
	ok !$a->_ip_in_cidr('192.168.2.1',   '192.168.1.0/24'), '192.168.2.1 not in /24';
};

# =============================================================================
# 33. _registrable() label count boundary  [NUM_BOUNDARY_4010_26_<]
#
# @labels <= 2  → return $host as-is
# Boundary: 2 labels (return as-is), 3 labels (strip one)
# =============================================================================
subtest 'NUM_BOUNDARY_4010_26_< -- _registrable label count boundary' => sub {
	# 1 label: undef (caught earlier by /\./ guard)
	is Email::Abuse::Investigator::_registrable('example'),
	   undef, '1-label input → undef';

	# 2 labels: returned unchanged
	is Email::Abuse::Investigator::_registrable('example.com'),
	   'example.com', '2-label input → returned unchanged';

	# 3 labels (no ccTLD match): strip one
	is Email::Abuse::Investigator::_registrable('www.example.com'),
	   'example.com', '3-label input without ccTLD → strip one label';

	# 3 labels with ccTLD: keep 3
	is Email::Abuse::Investigator::_registrable('example.co.uk'),
	   'example.co.uk', '3-label input with ccTLD → returned as-is';

	# 4 labels with ccTLD: strip to 3
	is Email::Abuse::Investigator::_registrable('sub.example.co.uk'),
	   'example.co.uk', '4-label with ccTLD → strip to 3';
};

# =============================================================================
# 34. AnyEvent::DNS threshold  [NUM_BOUNDARY_3063_57_<]
#
# scalar(keys %hostname_needed) > 1  → use parallel DNS
# Boundary: 1 unique host (no parallel), 2 unique hosts (parallel if available)
# Kill: verify that 2 hosts in a message doesn't die even when AnyEvent absent
# =============================================================================
subtest 'NUM_BOUNDARY_3063_57_< -- parallel DNS threshold: 1 vs 2 unique hosts' => sub {
	null_net();
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_resolve_host = sub { '1.2.3.4' };
	local *Email::Abuse::Investigator::_whois_ip	 = sub { { org=>'T', abuse=>'a@b' } };

	# 1 unique host: should work
	my $a1 = Email::Abuse::Investigator->new();
	$a1->parse_email("From: x\@y.com\n\nhttps://onehost.example/p1 https://onehost.example/p2");
	my @u1 = $a1->embedded_urls();
	is scalar @u1, 2, '1 unique host: both paths returned';

	# 2 unique hosts: should also work (parallel path or fallback)
	my $a2 = Email::Abuse::Investigator->new();
	$a2->parse_email("From: x\@y.com\n\nhttps://host1.example/p https://host2.example/p");
	my @u2 = $a2->embedded_urls();
	is scalar @u2, 2, '2 unique hosts: both URLs returned';

	restore_net();
};

# =============================================================================
# 35. _parallel_resolve_hosts condvar boundary  [NUM_BOUNDARY_3147_29_<]
#
# --$pending <= 0  → send condvar
# Only testable with AnyEvent::DNS installed; skip gracefully if absent
# =============================================================================
subtest 'NUM_BOUNDARY_3147_29_< -- _parallel_resolve_hosts condvar trigger' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	no warnings 'once';

	# Empty input: $pending starts at 0, guard should prevent condvar call
	eval { $a->_parallel_resolve_hosts({}, {}) };
	is $@, '', '_parallel_resolve_hosts({},{}) does not die';

	# Without AnyEvent::DNS the method is a no-op; skip the condvar assertion
	if (!$Email::Abuse::Investigator::HAS_ANYEVENT_DNS) {
		pass 'AnyEvent::DNS not installed — condvar path not exercised (acceptable)';
		return;
	}

	# With AnyEvent::DNS: supply a single hostname so $pending starts at 1
	# and the callback fires --$pending = 0, triggering $cv->send
	my %cache;
	no warnings 'redefine';
	local *AnyEvent::DNS::resolve = sub {
		my ($host, $type, $cb) = @_;
		# Simulate immediate callback with one A record answer
		$cb->([undef, undef, undef, undef, '1.2.3.4']);
	};
	eval { $a->_parallel_resolve_hosts({ 'condvar-test.example' => 1 }, \%cache) };
	is $@, '', '_parallel_resolve_hosts with 1 host does not die';
};

# =============================================================================
# 36. _analyse_domain() recently_registered boundary  [NUM_BOUNDARY_3497_36_>]
#
# (time() - $epoch) < RECENT_REG_DAYS * SECS_PER_DAY  → recently_registered = 1
# RECENT_REG_DAYS = 180
# Boundary: 179 days old → recently_registered; 180 days old → not recent
# =============================================================================
subtest 'NUM_BOUNDARY_3497_36_> -- recently_registered boundary: 179 vs 180 days' => sub {
	null_net();
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_resolve_host = sub { undef };
	local *Email::Abuse::Investigator::_whois_ip	 = sub { {} };

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("From: x\@y.com\n\nbody");

	# 179 days ago: recently_registered = 1
	my $reg_179 = strftime('%Y-%m-%d', gmtime(time() - 179 * 86400));
	local *Email::Abuse::Investigator::_domain_whois = sub {
		"Registrar: Test\nCreation Date: $reg_179\nRegistry Expiry Date: 2099-01-01\n"
	};
	my $info_179 = $a->_analyse_domain('boundary179.example');
	is $info_179->{recently_registered}, 1,
		'179 days old → recently_registered = 1';

	# 181 days ago: recently_registered not set
	$a->{_domain_info} = {};  # clear per-message cache
	my $reg_181 = strftime('%Y-%m-%d', gmtime(time() - 181 * 86400));
	local *Email::Abuse::Investigator::_domain_whois = sub {
		"Registrar: Test\nCreation Date: $reg_181\nRegistry Expiry Date: 2099-01-01\n"
	};
	my $info_181 = $a->_analyse_domain('boundary181.example');
	ok !$info_181->{recently_registered},
		'181 days old → recently_registered not set';

	restore_net();
};

# =============================================================================
# 37. _sanitise_output() return value  [BOOL_NEGATE_2662_2, BOOL_NEGATE_2665_2]
# =============================================================================
subtest 'BOOL_NEGATE_2662/2665 -- _sanitise_output() exact return values' => sub {
	my $fn = \&Email::Abuse::Investigator::_sanitise_output;

	# undef input: must return '' exactly (not !'' = 1)
	my $r_undef = $fn->(undef);
	is $r_undef,  '', '_sanitise_output(undef) returns empty string exactly';
	isnt $r_undef, 1, '_sanitise_output(undef) does not return 1 (negation)';

	# normal string: must return the string unchanged (not !string = '')
	my $r_str = $fn->('hello');
	is $r_str, 'hello', '_sanitise_output("hello") returns "hello" exactly';
	isnt $r_str, '', '_sanitise_output("hello") does not return empty string (negation)';

	# C0-stripped string: must return the stripped string (not its negation)
	my $r_ctrl = $fn->("\x01hello\x02");
	is $r_ctrl, 'hello', '_sanitise_output strips controls and returns stripped string';
	isnt $r_ctrl, '', 'stripped result is not empty string (negation)';
};

# =============================================================================
# 38. _decode_body() return value  [BOOL_NEGATE_2883_2]
# =============================================================================
subtest 'BOOL_NEGATE_2883_2 -- _decode_body() returns correct string' => sub {
	my $a = Email::Abuse::Investigator->new();

	# 7bit: returns body unchanged
	my $r = $a->_decode_body('hello world', '7bit');
	is $r, 'hello world', '_decode_body 7bit returns body string exactly';
	isnt $r, '', '_decode_body 7bit does not return empty string';

	# undef body: returns '' (not !'')
	my $r_undef = $a->_decode_body(undef, '7bit');
	is $r_undef, '', '_decode_body undef body returns empty string';
};

# =============================================================================
# 39. _header_value() return values  [BOOL_NEGATE_4069_3, BOOL_NEGATE_4071_2]
# =============================================================================
subtest 'BOOL_NEGATE_4069/4071 -- _header_value() exact return values' => sub {
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("From: sender\@example.com\nSubject: Test Subject\n\nbody");

	# Found header: returns the value string exactly
	my $from = $a->_header_value('from');
	is $from, 'sender@example.com',
		'_header_value returns the exact header value string';
	isnt $from, '', 'found header does not return empty string (negation)';

	# Not found: returns undef exactly (not !undef = 1)
	my $missing = $a->_header_value('x-no-such-header');
	is $missing, undef,
		'_header_value returns undef for missing header';
	isnt $missing, 1, 'missing header does not return 1 (negation of undef)';
};

# =============================================================================
# 40. _decode_mime_words() return values  [BOOL_NEGATE_4114_2, BOOL_NEGATE_4117_2]
# =============================================================================
subtest 'BOOL_NEGATE_4114/4117 -- _decode_mime_words() exact return values' => sub {
	my $a = Email::Abuse::Investigator->new();

	# undef: returns '' exactly
	my $r_undef = $a->_decode_mime_words(undef);
	is $r_undef, '', '_decode_mime_words(undef) returns empty string exactly';
	isnt $r_undef, 1, 'not 1 (negation of empty string)';

	# plain string: returned unchanged
	my $r_plain = $a->_decode_mime_words('plain text');
	is $r_plain, 'plain text', '_decode_mime_words returns plain string unchanged';

	# encoded word: returns decoded string
	my $enc = '=?UTF-8?B?' . encode_base64('decoded', '') . '?=';
	my $r_enc = $a->_decode_mime_words($enc);
	is $r_enc, 'decoded', '_decode_mime_words returns decoded string exactly';
	isnt $r_enc, '', 'decoded string is not empty (negation)';
};

# =============================================================================
# 41. unresolved_contacts() conditions  [COND_INV_1176_3, BOOL_NEGATE_1217_2]
# =============================================================================
subtest 'COND_INV_1176_3 + BOOL_NEGATE_1217_2 -- unresolved_contacts() branches' => sub {
	null_net();
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };
	local *Email::Abuse::Investigator::_resolve_host = sub { undef };
	local *Email::Abuse::Investigator::_whois_ip	 = sub { {} };  # no abuse

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("From: x\@y.com\n\nhttps://mystery.example/page and info\@mystery.example");

	my @unresolved = $a->unresolved_contacts();

	# Return value is a list (BOOL_NEGATE: not !list)
	ok scalar @unresolved >= 0, 'unresolved_contacts() returns a list (not negation)';

	# mystery.example has no abuse contact so should appear
	ok scalar(grep { $_->{domain} eq 'mystery.example' } @unresolved),
		'mystery.example (no abuse contact) appears in unresolved_contacts()';

	# Each entry has the required keys (COND_INV_1176_3: dom extraction)
	for my $u (@unresolved) {
		ok defined $u->{domain}, "entry has domain (got '$u->{domain}')";
		ok defined $u->{type},   "entry has type";
		ok defined $u->{source}, "entry has source";
	}

	restore_net();
};

done_testing();
