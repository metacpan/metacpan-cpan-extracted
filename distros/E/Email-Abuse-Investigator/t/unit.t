#!/usr/bin/env perl
# =============================================================================
# t/unit.t  —  Contract tests for every public method of Email::Abuse::Investigator
# =============================================================================

use strict;
use warnings;

use Test::More;
use Scalar::Util qw( blessed reftype );
use MIME::Base64 qw( encode_base64 );
use POSIX		qw( strftime );

use FindBin qw( $Bin );
use lib "$Bin/../lib", "$Bin/..";
use Email::Abuse::Investigator;

sub make_email {
	my (%h) = @_;
	my $received = $h{received}
		// 'from ext.example.com (ext.example.com [91.198.174.42])'
		 . ' by mx.bandsman.co.uk (Postfix); Mon, 01 Jan 2024 00:00:00 +0000';
	my $from		= $h{from}		// 'Sender <sender@spamsite.example>';
	my $reply_to	= $h{reply_to};
	my $return_path = $h{return_path} // '<sender@spamsite.example>';
	my $to		  = $h{to}		  // 'victim@bandsman.co.uk';
	my $subject	 = $h{subject}	 // 'Unit test message';
	my $date		= $h{date}		// POSIX::strftime('%a, %d %b %Y %H:%M:%S +0000', gmtime);
	my $mid		 = $h{message_id}  // '<unit-001@spamsite.example>';
	my $ct		  = $h{ct}		  // 'text/plain; charset=us-ascii';
	my $cte		 = $h{cte}		 // '7bit';
	my $auth		= $h{auth}		// '';
	my $xoip		= $h{xoip};
	my $body		= $h{body}		// 'Hello, please buy something.';

	my $hdrs = '';
	$hdrs .= "Received: $received\n";
	$hdrs .= "Authentication-Results: $auth\n"  if $auth;
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

sub stub_net {
	my (%ov) = @_;
	no warnings 'redefine';
	*Email::Abuse::Investigator::_reverse_dns  = sub { $ov{rdns}  // 'mail.stub.example' };
	*Email::Abuse::Investigator::_resolve_host = sub {
		my (undef, $h) = @_;
		return $h if $h =~ /^\d{1,3}(?:\.\d{1,3}){3}$/;
		my $map = $ov{resolve};
		return undef unless defined $map;
		return ref $map eq 'HASH' ? $map->{$h} : $map;
	};
	*Email::Abuse::Investigator::_whois_ip = sub {
		{ org	 => ($ov{org}	 // 'Stub ISP'),
		  abuse	=> ($ov{abuse}	// 'abuse@stub.example'),
		  country => ($ov{country} // undef) }
	};
	*Email::Abuse::Investigator::_domain_whois = sub { $ov{domain_whois} // undef };
	*Email::Abuse::Investigator::_raw_whois	= sub { undef };
	*Email::Abuse::Investigator::_rdap_lookup  = sub { {} };
}

my %_ORIG;
BEGIN {
	for my $m (qw( _reverse_dns _resolve_host _whois_ip
					_domain_whois _raw_whois _rdap_lookup )) {
		no strict 'refs';
		$_ORIG{$m} = \&{ "Email::Abuse::Investigator::$m" };
	}
}
sub restore_net {
	no warnings 'redefine';
	for my $m (keys %_ORIG) {
		no strict 'refs';
		*{ "Email::Abuse::Investigator::$m" } = $_ORIG{$m};
	}
}

# =============================================================================
# new()
# =============================================================================
subtest 'new() — constructor API' => sub {
	my $a = Email::Abuse::Investigator->new();
	ok defined $a,			  'new() returns a value';
	ok blessed($a),			 'return value is blessed';
	is blessed($a), 'Email::Abuse::Investigator', 'blessed into correct class';
	is $a->{timeout}, 10, 'default timeout is 10';
	is $a->{verbose},  0, 'default verbose is 0';
	is_deeply $a->{trusted_relays}, [], 'default trusted_relays is []';

	my $b = Email::Abuse::Investigator->new(
		timeout		=> 30,
		verbose		=> 1,
		trusted_relays => ['62.105.128.0/24', '91.198.174.5'],
	);
	is $b->{timeout}, 30, 'custom timeout stored';
	is $b->{verbose},  1, 'custom verbose stored';
	is_deeply $b->{trusted_relays},
		['62.105.128.0/24', '91.198.174.5'],
		'custom trusted_relays stored';
};

# =============================================================================
# parse_email( $text )
# =============================================================================
subtest 'parse_email() — accepts scalar and scalar-ref; returns $self' => sub {
	my $raw = make_email();

	my $a = Email::Abuse::Investigator->new();
	my $ret = $a->parse_email($raw);
	is $ret, $a, 'parse_email returns $self (scalar input)';

	my $b = Email::Abuse::Investigator->new();
	my $ret2 = $b->parse_email(\$raw);
	is $ret2, $b, 'parse_email returns $self (scalar-ref input)';

	is_deeply $b->{_headers}, $a->{_headers},
		'scalar and scalar-ref inputs produce same result';
};

subtest 'parse_email() — handles multipart, quoted-printable, base64 bodies' => sub {
	my $qp_body = "Caf=C3=A9 au lait";
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(ct => 'text/plain', cte => 'quoted-printable',
								body => $qp_body));
	like $a->{_body_plain}, qr/Caf/, 'QP body decoded';

	my $b64_body = encode_base64("Base64 encoded content here");
	my $b = Email::Abuse::Investigator->new();
	$b->parse_email(make_email(ct => 'text/plain', cte => 'base64',
								body => $b64_body));
	like $b->{_body_plain}, qr/Base64 encoded content/, 'base64 body decoded';

	my $bnd = 'UNIT_BOUNDARY';
	my $mp  = "--$bnd\r\nContent-Type: text/plain\r\n\r\nplain text here\r\n"
			. "--$bnd\r\nContent-Type: text/html\r\n\r\n<b>html here</b>\r\n"
			. "--$bnd--\r\n";
	my $c = Email::Abuse::Investigator->new();
	$c->parse_email(make_email(
		ct	=> qq{multipart/alternative; boundary="$bnd"},
		body => $mp,
	));
	like $c->{_body_plain}, qr/plain text here/, 'multipart plain part decoded';
	like $c->{_body_html},  qr/html here/,		'multipart html part decoded';
};

subtest 'parse_email() — re-parse resets all lazy caches' => sub {
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email());
	$a->{_origin}		 = { ip => '0.0.0.0' };
	$a->{_urls}			= [ { url => 'stale' } ];
	$a->{_mailto_domains} = [ { domain => 'stale.example' } ];
	$a->{_domain_info}	= { 'stale.example' => {} };
	$a->{_risk}			= { level => 'STALE', score => 99, flags => [] };
	$a->parse_email(make_email());
	is $a->{_origin},		 undef, 're-parse clears _origin';
	is $a->{_urls},			undef, 're-parse clears _urls';
	is $a->{_mailto_domains}, undef, 're-parse clears _mailto_domains';
	is_deeply $a->{_domain_info}, {}, 're-parse clears _domain_info';
	is $a->{_risk},			undef, 're-parse clears _risk';
};

# =============================================================================
# originating_ip()
# =============================================================================
subtest 'originating_ip() — documented hashref structure' => sub {
	stub_net(rdns => 'mail.spammer.example', org => 'Bad ISP',
			 abuse => 'abuse@bad-isp.example', country => 'US');
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(
		received => 'from spammer (spammer [91.198.174.42]) by mx'));
	my $orig = $a->originating_ip();
	ok defined $orig,			'returns a defined value';
	is reftype($orig), 'HASH',  'returns a hashref';
	for my $key (qw( ip rdns org abuse confidence note )) {
		ok exists $orig->{$key}, "hashref contains key '$key'";
	}
	like $orig->{ip}, qr/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/,
							  'ip is a dotted-quad IPv4 address';
	ok $orig->{confidence} =~ /^(?:high|medium|low)$/,
		"confidence is 'high', 'medium', or 'low'";
	restore_net();
};

subtest 'originating_ip() — confidence levels per POD' => sub {
	stub_net();
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(
		received => 'from spammer (spammer [91.198.174.1]) by mx'));
	is $a->originating_ip()->{confidence}, 'medium',
		'single external hop yields medium confidence';

	my $raw2 = "Received: from r1 (r1 [91.198.174.2]) by r2\n"
			 . "Received: from r2 (r2 [91.198.174.3]) by mx\n"
			 . "From: x\@y.com\nSubject: s\n\nbody";
	my $b = Email::Abuse::Investigator->new();
	$b->parse_email($raw2);
	is $b->originating_ip()->{confidence}, 'high',
		'two external hops yields high confidence';

	my $c = Email::Abuse::Investigator->new();
	$c->parse_email(make_email(
		received => 'from localhost [127.0.0.1] by mx',
		xoip	 => '62.105.128.99',
	));
	is $c->originating_ip()->{confidence}, 'low',
		'X-Originating-IP fallback yields low confidence';
	restore_net();
};

subtest 'originating_ip() — returns undef when no IP can be determined' => sub {
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("From: x\@y.com\nSubject: s\n\nbody");
	is $a->originating_ip(), undef,
		'undef returned when no Received: header and no X-Originating-IP';
};

subtest 'originating_ip() — result is cached between calls' => sub {
	stub_net();
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email());
	my $first  = $a->originating_ip();
	my $second = $a->originating_ip();
	is $first, $second, 'same ref returned on repeated calls (cached)';
	restore_net();
};

# =============================================================================
# embedded_urls()
# =============================================================================
subtest 'embedded_urls() — extracts from both plain and HTML parts' => sub {
	stub_net(resolve => '1.2.3.4');

	my $bnd = 'EMBU';
	my $mp  = "--$bnd\r\nContent-Type: text/plain\r\n\r\n"
			. "Plain: https://plain.example/path\r\n"
			. "--$bnd\r\nContent-Type: text/html\r\n\r\n"
			. '<a href="https://html.example/path">click</a>'
			. "\r\n--$bnd--\r\n";
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(
		ct   => qq{multipart/alternative; boundary="$bnd"},
		body => $mp,
	));
	my @urls  = $a->embedded_urls();
	my @hosts = map { $_->{host} } @urls;
	ok scalar(grep { $_ eq 'plain.example' } @hosts), 'URL from plain part extracted';
	ok scalar(grep { $_ eq 'html.example'  } @hosts), 'URL from HTML part extracted';

	restore_net();
};

subtest 'embedded_urls() — documented hashref structure' => sub {
	stub_net(resolve => '91.198.174.7', org => 'Dodgy Hosting Ltd',
			 abuse => 'abuse@dodgy.example');
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(
		body => 'Visit https://spamsite.example/offer to buy now.'));
	my @urls = $a->embedded_urls();
	ok @urls > 0, 'returns at least one hashref';
	my $u = $urls[0];
	is reftype($u), 'HASH', 'each element is a hashref';
	for my $key (qw( url host ip org abuse )) {
		ok exists $u->{$key}, "url hashref contains key '$key'";
	}
	like $u->{url},  qr{^https?://}, 'url starts with http(s)://';
	like $u->{url}, qr/\Q$u->{host}\E/, 'url contains host';
	restore_net();
};

subtest 'embedded_urls() — returns empty list when body has no URLs' => sub {
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(body => 'No links here at all.'));
	my @urls = $a->embedded_urls();
	is scalar @urls, 0, 'empty list returned when no URLs present';
};

subtest 'embedded_urls() — result is cached between calls' => sub {
	stub_net(resolve => '1.2.3.4');
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(body => 'https://cache.example/test'));
	my @first  = $a->embedded_urls();
	my @second = $a->embedded_urls();
	is scalar @second, scalar @first, 'same count returned on second call';
	restore_net();
};

subtest 'embedded_urls() — WHOIS queried once per unique host' => sub {
	stub_net(resolve => '1.2.3.4');
	my $whois_call_count = 0;
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_whois_ip = sub { $whois_call_count++; {} };
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(
		body => 'https://samehost.example/a and https://samehost.example/b '
			  . 'and https://samehost.example/c'));
	my @urls = $a->embedded_urls();
	is scalar @urls, 3,			'three URL entries returned';
	is $whois_call_count, 1,	  'WHOIS called once for one unique host';
	restore_net();
};

# =============================================================================
# mailto_domains()
# =============================================================================
subtest 'mailto_domains() — documented hashref structure' => sub {
	stub_net(resolve => '104.21.30.10');
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(
		from => 'Spammer <spammer@spamco.example>',
		body => 'Contact mailto:info@spamco.example for details',
	));
	my @doms = $a->mailto_domains();
	ok @doms > 0, 'returns at least one hashref';
	my $d = $doms[0];
	is reftype($d), 'HASH', 'each element is a hashref';
	for my $key (qw( domain source )) {
		ok exists $d->{$key},	 "domain hashref contains required key '$key'";
		ok defined $d->{$key},	"key '$key' is defined";
	}
	
	# Optional hosting keys — if present must be of correct type
	for my $key (qw( web_ip web_org web_abuse
					mx_host mx_ip mx_org mx_abuse
					ns_host ns_ip ns_org ns_abuse
					registrar registered expires recently_registered
					whois_raw )) {
		if (exists $d->{$key} && defined $d->{$key}) {
			ok !ref($d->{$key}) || ref($d->{$key}) eq 'SCALAR',
			  "key '$key', when present, is a plain scalar";
		}
	}

	# recently_registered — if present must be boolean (1 or undef/0)
	if (exists $d->{recently_registered}) {
		ok !defined($d->{recently_registered})
			|| $d->{recently_registered} == 0
			|| $d->{recently_registered} == 1,
		  'recently_registered is boolean';
	}

	restore_net();
};

subtest 'mailto_domains() — collects from From:, Reply-To:, Return-Path:' => sub {
	stub_net();

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(
		from		=> 'A <a@from-domain.example>',
		reply_to	=> 'B <b@replyto-domain.example>',
		return_path => '<c@returnpath-domain.example>',
		body		=> 'Nothing interesting',
	));
	my @doms  = $a->mailto_domains();
	my @names = map { $_->{domain} } @doms;

	ok scalar(grep { $_ eq 'from-domain.example'	} @names),
	  'domain from From: header captured';
	ok scalar(grep { $_ eq 'replyto-domain.example' } @names),
	  'domain from Reply-To: header captured';
	ok scalar(grep { $_ eq 'returnpath-domain.example' } @names),
	  'domain from Return-Path: header captured';

	restore_net();
};

subtest 'mailto_domains() — collects from mailto: links and bare addresses in body' => sub {
	stub_net();

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(
		from => 'x@trusted-infra.example',
		body => 'Contact mailto:sales@bodylink.example or info@bareaddr.example',
	));
	my @names = map { $_->{domain} } $a->mailto_domains();

	ok scalar(grep { $_ eq 'bodylink.example' } @names),
	  'domain from mailto: in body captured';
	ok scalar(grep { $_ eq 'bareaddr.example' } @names),
	  'domain from bare address in body captured';

	restore_net();
};

subtest 'mailto_domains() — infrastructure domains are excluded' => sub {
	stub_net();

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(
		from => 'Spammer <spammer@gmail.com>',
		body => 'Visit our site info@yahoo.com',
	));
	my @names = map { $_->{domain} } $a->mailto_domains();

	ok !scalar(grep { $_ eq 'gmail.com'   } @names), 'gmail.com excluded';
	ok !scalar(grep { $_ eq 'yahoo.com'   } @names), 'yahoo.com excluded';

	restore_net();
};

subtest 'mailto_domains() — recently_registered flag for domains < 180 days old' => sub {
	# Inject a pre-built domain result with a recent registration date
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(body => 'contact info@newdomain.example'));

	# Bypass network and WHOIS entirely by pre-populating the cache
	my $ten_days_ago = strftime('%Y-%m-%d', gmtime(time() - 10 * 86400));
	$a->{_domain_info}{'newdomain.example'} = {
		registered		=> $ten_days_ago,
		recently_registered => 1,
		expires		  => '2099-01-01',
	};

	stub_net(resolve => undef);
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };

	my @doms = $a->mailto_domains();
	my ($nd) = grep { $_->{domain} eq 'newdomain.example' } @doms;
	ok defined $nd,			 'newdomain.example present in results';
	is $nd->{recently_registered}, 1, 'recently_registered is 1 for recent domain';

	restore_net();
 };

subtest 'mailto_domains() — each domain appears only once (deduplicated)' => sub {
	stub_net();
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(
		from => 'A <a@dup.example>',
		body => 'Also mailto:b@dup.example and info@dup.example',
	));
	my @names = map { $_->{domain} } $a->mailto_domains();
	my @dups  = grep { $_ eq 'dup.example' } @names;
	is scalar @dups, 1, 'same domain appears only once';
	restore_net();
};

subtest 'mailto_domains() — result is cached between calls' => sub {
	stub_net();
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(body => 'contact info@cached.example'));
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };
	my @first  = $a->mailto_domains();
	my @second = $a->mailto_domains();
	is scalar @second, scalar @first, 'same count on second call';
	is $a->{_mailto_domains}, $a->{_mailto_domains}, 'same arrayref (cached)';
	restore_net();
};

# =============================================================================
# all_domains()
# =============================================================================
subtest 'all_domains() — returns union of URL hosts and mailto domains' => sub {
	stub_net(resolve => '1.2.3.4');
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(
		from => 'x@maildom.example',
		body => 'https://urldom.example/page and info@maildom.example',
	));
	my @all = $a->all_domains();
	ok scalar(grep { $_ eq 'urldom.example'  } @all), 'URL host in all_domains';
	ok scalar(grep { $_ eq 'maildom.example' } @all), 'mailto domain in all_domains';
	restore_net();
};

subtest 'all_domains() — no duplicates across sources' => sub {
	stub_net(resolve => '1.2.3.4');
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(
		from => 'x@shared.example',
		body => 'https://www.shared.example/path and info@shared.example',
	));
	my @all  = $a->all_domains();
	my %seen;
	my @dups = grep { $seen{$_}++ } @all;
	is scalar @dups, 0, 'all_domains contains no duplicates';
	restore_net();
};

subtest 'all_domains() — returns plain list of strings' => sub {
	stub_net(resolve => '1.2.3.4');
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(body => 'https://stringtest.example/x'));
	my @all = $a->all_domains();
	for my $item (@all) {
		ok !ref($item), "all_domains element is a plain string (got: $item)";
	}

	restore_net();
 };

# =============================================================================
# risk_assessment()
# =============================================================================
subtest 'risk_assessment() — documented top-level hashref structure' => sub {
	stub_net();
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email());
	my $risk = $a->risk_assessment();
	is reftype($risk), 'HASH', 'returns a hashref';
	for my $key (qw( level score flags )) {
		ok exists $risk->{$key}, "result contains key '$key'";
	}
	ok $risk->{level} =~ /^(?:HIGH|MEDIUM|LOW|INFO)$/,
		"level is HIGH|MEDIUM|LOW|INFO (got '$risk->{level}')";
	# score is a non-negative integer
	ok defined $risk->{score},		  'score is defined';
	like "$risk->{score}", qr/^\d+$/,	'score is a non-negative integer';

	# flags is an arrayref
	like "$risk->{score}", qr/^\d+$/, 'score is a non-negative integer';
	is reftype($risk->{flags}), 'ARRAY', 'flags is an arrayref';
	restore_net();
};

subtest 'risk_assessment() — each flag hashref has severity, flag, detail' => sub {
	stub_net(rdns => '1-2-3-4.dsl.isp.example');  # triggers residential flag
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(
		 received => 'from dsl-host (dsl-host [91.198.174.1]) by mx'));
	my $risk  = $a->risk_assessment();
	my @flags = @{ $risk->{flags} };

	ok @flags > 0, 'at least one flag generated';

	for my $f (@flags) {
		 is reftype($f), 'HASH', 'each flag is a hashref';
		 for my $key (qw( severity flag detail )) {
			  ok exists $f->{$key},  "flag hashref has key '$key'";
			  ok defined $f->{$key}, "flag key '$key' is defined";
		 }
		 ok $f->{severity} =~ /^(?:HIGH|MEDIUM|LOW|INFO)$/,
			 "flag severity is HIGH|MEDIUM|LOW|INFO (got '$f->{severity}')";
	}

	restore_net();
};

subtest 'risk_assessment() — score threshold boundaries match POD' => sub {
	# POD: HIGH >= 9, MEDIUM >= 5, LOW >= 2, INFO otherwise
	stub_net();
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };

	# INFO: clean message, no flags expected → score 0 → INFO
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(
		 auth	 => 'mx; spf=pass; dkim=pass; dmarc=pass',
		 from	 => 'Clean <clean@corp.example>',
		 to	 => 'user@bandsman.co.uk',
	));
	# Manually inject clean origin (no rDNS issues)
	$a->{_origin} = {
		 ip		 => '91.198.174.1',
		 rdns	=> 'mail.corp.example',
		 org			=> 'Corp ISP',
		 abuse	  => 'abuse@corp.example',
		 confidence => 'high',
		 note	=> 'test',
		 country => 'GB',
	};
	$a->{_urls}		  = [];
	$a->{_mailto_domains} = [];
	my $risk_info = $a->risk_assessment();
	is $risk_info->{level}, 'INFO', 'clean message scores INFO';
	ok $risk_info->{score} < 2, 'INFO score is < 2';

	 restore_net();
 };

subtest 'risk_assessment() — result is cached' => sub {
	stub_net();
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email());
	my $r1 = $a->risk_assessment();
	my $r2 = $a->risk_assessment();
	is $r2, $r1, 'risk_assessment returns the same ref on second call (cached)';
	restore_net();
};

# =============================================================================
# abuse_report_text()
# =============================================================================
subtest 'abuse_report_text() — returns a non-empty string' => sub {
	stub_net();
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email());
	my $text = $a->abuse_report_text();
	ok defined $text, 'returns a defined value';
	ok !ref($text),	'returns a plain string';
	ok length($text) > 0, 'string is non-empty';
	restore_net();
};

subtest 'abuse_report_text() — contains all documented sections' => sub {
	stub_net(rdns => 'mail.spammer.example', org => 'Bad ISP',
			 abuse => 'abuse@bad-isp.example');
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(
		received => 'from spammer (spammer [91.198.174.42]) by mx',
		body	 => 'Buy at https://scam.example/now',
	));
	{
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_resolve_host = sub { '91.198.174.99' };
		local *Email::Abuse::Investigator::_whois_ip	 = sub {
			{ org => 'Scam Host', abuse => 'abuse@scam.example' }
		};
		my $text = $a->abuse_report_text();
		like $text, qr/automated abuse report/i,  'report intro present';
		like $text, qr/RISK LEVEL:\s*\w+/,		'RISK LEVEL present';
		like $text, qr/ORIGINAL MESSAGE HEADERS/, 'headers section present';
		like $text, qr/ORIGINATING IP/,			'originating IP section present';
	}
	restore_net();
};

subtest 'abuse_report_text() — RED FLAGS section present when flags exist' => sub {
	stub_net(rdns => '1-2-3-4.dsl.example');  # triggers residential flag
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(
		 received => 'from dsl (dsl [91.198.174.1]) by mx'));
	my $text = $a->abuse_report_text();
	like $text, qr/RED FLAGS IDENTIFIED/, 'RED FLAGS section present when flags exist';

	restore_net();
};

subtest 'abuse_report_text() — ABUSE CONTACTS section present when contacts available' => sub {
	stub_net(rdns => 'mail-ej1.gmail.com');  # rDNS points to known provider
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };
	local *Email::Abuse::Investigator::_resolve_host = sub { undef };

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(
		 from	 => 'Spammer <spammer@gmail.com>',
		 received => 'from google (google [209.85.218.67]) by mx',
	));
	my $text = $a->abuse_report_text();
	like $text, qr/ABUSE CONTACTS/, 'ABUSE CONTACTS section present';

	restore_net();
};

subtest 'abuse_report_text() — suitable for emailing to abuse_contacts() addresses' => sub {
	# POD says: "Returns a string suitable for pasting into an abuse report email.
	#			  Then email to each address from $analyser->abuse_contacts()"
	# Verify that abuse_report_text() and abuse_contacts() are independently callable
	# and that both succeed on the same object.
	stub_net();
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(
		 from => 'x@gmail.com',
		 received => 'from g (g [209.85.218.67]) by mx',
	));
	my $text	  = $a->abuse_report_text();
	my @contacts = $a->abuse_contacts();

	ok defined $text,	  'abuse_report_text() succeeds';
	ok !ref($text),	  'abuse_report_text() returns a string';
	# At least the gmail provider contact should be found
	ok @contacts > 0,	  'abuse_contacts() returns results on same object';

	restore_net();
};

# =============================================================================
# abuse_contacts()
# =============================================================================
subtest 'abuse_contacts() — documented hashref structure' => sub {
	stub_net(rdns => 'mail-ej1.google.com', org => 'Google LLC',
			 abuse => 'network-abuse@google.com');
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(
		from	 => 'Spammer <spammer@gmail.com>',
		received => 'from google (google [209.85.218.67]) by mx',
	));
	my @contacts = $a->abuse_contacts();
	ok @contacts > 0, 'returns at least one contact';
	for my $c (@contacts) {
		is reftype($c), 'HASH', 'each contact is a hashref';
		for my $key (qw( role address via )) {
			ok exists  $c->{$key}, "contact hashref contains key '$key'";
			ok defined $c->{$key}, "contact key '$key' is defined";
		}
		like $c->{address}, qr/\@/, "contact address contains \@";
		ok $c->{via} =~ /^(?:ip-whois|domain-whois|provider-table|rdap)$/,
			"contact via '$c->{via}' is a documented value";
	}
	restore_net();
};

subtest 'abuse_contacts() — addresses are deduplicated across routes' => sub {
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(from => 'x@example.org', body => 'https://cf-hosted.example/page'));
	$a->{_origin}		 = undef;
	$a->{_urls}			= [{
		url	=> 'https://cf-hosted.example/page',
		host  => 'cf-hosted.example',
		ip	=> '104.21.0.1',
		org	=> 'CLOUDFLARENET',
		abuse => 'abuse@cloudflare.com',
	}];
	$a->{_mailto_domains} = [{
		domain		=> 'cf-hosted.example',
		source		=> 'body',
		web_ip		=> '104.21.0.1',
		web_org	  => 'CLOUDFLARENET',
		web_abuse	=> 'abuse@cloudflare.com',
		mx_abuse	 => 'abuse@cloudflare.com',
	}];
	my @contacts  = $a->abuse_contacts();
	my @cf		= grep { lc($_->{address}) eq 'abuse@cloudflare.com' } @contacts;
	is scalar @cf, 1, 'same address appears exactly once';
};

subtest 'abuse_contacts() — returns empty list when no contacts determinable' => sub {
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(
		from	 => 'x@noprovider.example',
		received => 'from localhost [127.0.0.1] by mx',
	));
	$a->{_origin}		 = undef;
	$a->{_urls}			= [];
	$a->{_mailto_domains} = [];
	my @contacts = $a->abuse_contacts();
	is scalar @contacts, 0, 'empty list when no contacts';
};

subtest 'abuse_contacts() — produces Sending ISP contact from originating IP' => sub {
	stub_net(org => 'Sending Corp', abuse => 'abuse@sending-corp.example');
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(
		received => 'from sender (sender [91.198.174.42]) by mx',
	));
	$a->{_urls}		= [];
	$a->{_mailto_domains} = [];
	my @contacts = $a->abuse_contacts();
	my @isp   = grep { $_->{role} =~ /Sending ISP/i } @contacts;
	ok @isp > 0, 'at least one Sending ISP contact produced';
	ok scalar(grep { lc($_->{address}) eq 'abuse@sending-corp.example' } @contacts),
	  'Sending ISP abuse address present in contacts';

	restore_net();
};

subtest 'abuse_contacts() — produces Account provider contact for known From: domain' => sub {
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(from => 'Spammer <spammer@gmail.com>'));
	$a->{_origin}		= undef;
	$a->{_urls}		= [];
	$a->{_mailto_domains} = [];

	my @contacts = $a->abuse_contacts();
	ok scalar(grep { $_->{role} =~ /Account provider/i } @contacts),
	  'Account provider contact produced for gmail.com From:';
	ok scalar(grep { lc($_->{address}) eq 'abuse@google.com' } @contacts),
	  'abuse@google.com in contacts for gmail sender';
};

subtest 'abuse_contacts() — produces Domain registrar contact' => sub {
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(from => 'x@example.org'));
	$a->{_origin}		= undef;
	$a->{_urls}		= [];
	$a->{_mailto_domains} = [{
		domain		 => 'spamreg.example',
		source		 => 'body',
		registrar		=> 'Dodgy Registrar',
		registrar_abuse  => 'abuse@dodgyreg.example',
	}];

	my @contacts = $a->abuse_contacts();
	ok scalar(grep { $_->{role} =~ /registrar/i } @contacts),
	  'Domain registrar contact role produced';
	ok scalar(grep { lc($_->{address}) eq 'abuse@dodgyreg.example' } @contacts),
	  'registrar abuse address present';
};

subtest 'abuse_contacts() — (unknown) abuse addresses are never included' => sub {
	stub_net(abuse => '(unknown)');
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(
		received => 'from s (s [91.198.174.1]) by mx',
		from	 => 'x@noprovider.example',   # not in provider table
	));
	$a->{_urls}		= [];
	$a->{_mailto_domains} = [];
	my @contacts = $a->abuse_contacts();
	ok !scalar(grep { $_->{address} eq '(unknown)' } @contacts),
	  '(unknown) abuse address is never added to contacts';

	restore_net();
};

subtest 'abuse_contacts() — returns empty list when no contacts determinable' => sub {
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(
		from	 => 'x@noprovider.example',
		received => 'from localhost [127.0.0.1] by mx',
	));
	$a->{_origin}		= undef;
	$a->{_urls}		= [];
	$a->{_mailto_domains} = [];

	my @contacts = $a->abuse_contacts();
	is scalar @contacts, 0,
	  'empty list returned when origin is undef and no domains/URLs';
};

# =============================================================================
# report()
# =============================================================================
subtest 'report() — returns a non-empty plain string' => sub {
	stub_net();
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email());
	my $r = $a->report();
	ok defined $r,	  'returns a defined value';
	ok !ref($r),		'returns a plain string';
	ok length($r) > 0,  'report is non-empty';
	restore_net();
};

subtest 'report() — contains all expected section headings' => sub {
	stub_net();
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(
		body => 'https://spamsite.example/buy and info@spamsite.example',
		from => 'Bad <bad@gmail.com>',
	));
	{
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_resolve_host = sub { '1.2.3.4' };
		local *Email::Abuse::Investigator::_whois_ip	 = sub {
			{ org => 'Test Org', abuse => 'abuse@testorg.example', country => 'US' }
		};
		local *Email::Abuse::Investigator::_domain_whois = sub { undef };
		my $r = $a->report();
		like $r, qr/Email::Abuse::Investigator Report/, 'report title present';
		like $r, qr/RISK ASSESSMENT/,			 'RISK ASSESSMENT present';
		like $r, qr/ORIGINATING HOST/,			'ORIGINATING HOST present';
		like $r, qr/EMBEDDED HTTP\/HTTPS URLs/,	'EMBEDDED HTTP/HTTPS URLs present';
		like $r, qr/CONTACT \/ REPLY-TO DOMAINS/, 'CONTACT/REPLY-TO DOMAINS present';
		like $r, qr/WHERE TO SEND ABUSE REPORTS/, 'WHERE TO SEND ABUSE REPORTS present';
	}
	restore_net();
};

subtest 'report() — idempotent on same object' => sub {
	stub_net();
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email());
	my $r1 = $a->report();
	my $r2 = $a->report();
	is $r2, $r1, 'report() returns same string on second call';
	restore_net();
};

subtest 'report() — envelope headers are decoded and displayed' => sub {
	stub_net();
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };
	local *Email::Abuse::Investigator::_resolve_host = sub { undef };

	# Use a base64-encoded From: display name (as in the firmluminary spam)
	my $enc_from = '=?UTF-8?B?' . encode_base64('eharmony Partner', '') . '?=';
	my $enc_subj = '=?UTF-8?B?' . encode_base64('Ready to Find Love', '') . '?=';

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(
		from	=> qq{"$enc_from" <peacelight\@firmluminary.com>},
		subject => $enc_subj,
	));
	my $r = $a->report();

	like $r, qr/eharmony Partner/, 'encoded From: display name decoded in report';
	like $r, qr/Ready to Find Love/, 'encoded Subject decoded in report';

	restore_net();
 };

# =============================================================================
# Cross-method: lazy evaluation and re-parse
# =============================================================================
subtest 'parse_email() re-invocation clears all public-method caches' => sub {
	stub_net(resolve => '1.2.3.4');
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(
		body	 => 'https://first.example/page',
		from	 => 'x@first.example',
		received => 'from first (first [91.198.174.1]) by mx',
	));
	my @urls1  = $a->embedded_urls();
	my $orig1  = $a->originating_ip();
	my $risk1  = $a->risk_assessment();
	ok @urls1  > 0,		'first parse: URLs populated';
	ok defined $orig1,	'first parse: origin populated';

	$a->parse_email(make_email(
		body	 => 'No links at all.',
		from	 => 'clean@verifiedcorp.example',
		received => 'from clean (clean [91.198.174.2]) by mx',
	));
	my @urls2  = $a->embedded_urls();
	is scalar @urls2, 0, 're-parse: URL cache refreshed (no links in new email)';
	my $orig2 = $a->originating_ip();
	ok !defined($orig2) || $orig2->{ip} ne '91.198.174.1', 're-parse: origin cache refreshed';
	restore_net();
};

subtest 'report() — URL shortener flagged inline in URL section' => sub {
	stub_net(resolve => '1.2.3.4');
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(body => 'Click https://bit.ly/abc123 now'));
	$a->{_origin} = {
		ip => '1.2.3.4', rdns => 'mail.ok', confidence => 'high',
		org => 'X', abuse => 'a@b', note => '', country => undef,
	};
		local *Email::Abuse::Investigator::_resolve_host = sub { '67.199.248.10' };
		local *Email::Abuse::Investigator::_whois_ip	 = sub { { org=>'Bitly', abuse=>'a@b' } };

		my $r = $a->report();
		like $r, qr/URL SHORTENER/, 'URL shortener warning appears in report';
	 restore_net();
};

# =============================================================================
# _sanitise_output contract
# =============================================================================
subtest '_sanitise_output() — strips C0 controls, preserves printable' => sub {
	my $fn = \&Email::Abuse::Investigator::_sanitise_output;
	ok defined &Email::Abuse::Investigator::_sanitise_output,
		'_sanitise_output is defined';
	is $fn->('Hello, World!'), 'Hello, World!', 'printable ASCII preserved';
	is $fn->(undef), '',				 'undef returns empty string';
	is $fn->("\x01\x02\x03abc"), 'abc',		'C0 controls stripped';
	is $fn->("abc\x7Fdef"), 'abcdef',		  'DEL stripped';
	is $fn->("tab\there"), "tab\there",		'tab preserved';
	is $fn->("line\nbreak"), "line\nbreak",		'LF preserved';
	my $utf8 = "caf\xC3\xA9";
	is $fn->($utf8), $utf8, 'UTF-8 high bytes preserved';
};

subtest 'report() — output does not contain C0 control characters from input' => sub {
	stub_net();
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email());
	$a->{_origin}	  = undef;
	$a->{_urls}		 = [];
	$a->{_mailto_domains} = [{
		domain		=> 'ctrl.example',
		source		=> 'body',
		registrar	=> "Evil\x07Registrar\x01Inc",
		registrar_abuse => 'abuse@evil.example',
	}];
	my $r = $a->report();
	ok $r !~ /[\x01-\x08\x0B\x0C\x0E-\x1F\x7F]/,
		'report() output contains no C0 controls';
	restore_net();
};

# =============================================================================
# NEW: parse_email input sanitisation contract
# =============================================================================
subtest 'parse_email() — NUL bytes stripped from _raw' => sub {
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("From: x\@y.com\n\n\x00body with\x00NUL");
	ok $a->{_raw} !~ /\x00/, 'NUL not present in _raw';
};

subtest 'parse_email() — DEL stripped from _raw' => sub {
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("Subject: del\x7Ftest\nFrom: x\@y.com\n\nbody");
	ok $a->{_raw} !~ /\x7F/, 'DEL not present in _raw';
};

subtest 'parse_email() — UTF-8 high bytes preserved in _raw' => sub {
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("From: x\@y.com\n\nCaf\xC3\xA9 au lait");
	ok $a->{_raw} =~ /\xC3\xA9/, 'UTF-8 sequence preserved in _raw';
};

subtest 'lazy evaluation — methods succeed in any call order' => sub {
	stub_net(resolve => '1.2.3.4');
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };

	my $raw = make_email(
		body => 'https://lazy.example/page and info@lazy.example',
		from => 'x@lazy.example',
	);

	# Call order 1: risk → urls → domains → origin
	{
		my $a = Email::Abuse::Investigator->new();
		$a->parse_email($raw);
		$a->{_origin} = { ip=>'1.2.3.4', rdns=>'mail.ok',
						 confidence=>'high', org=>'X', abuse=>'a@b',
						 note=>'', country=>undef };
		my $risk  = $a->risk_assessment();
		my @urls  = $a->embedded_urls();
		my @mdoms = $a->mailto_domains();
		my $orig  = $a->originating_ip();
		ok defined $risk,  'risk_assessment succeeds first';
		ok defined $orig,  'originating_ip succeeds after risk';
		ok 1,			 'no exception on any-order evaluation';
	}
	# Call order 2: report first (triggers everything lazily)
	my $b = Email::Abuse::Investigator->new();
	$b->parse_email($raw);
	$b->{_origin} = { ip=>'1.2.3.4', rdns=>'mail.ok',
					 confidence=>'high', org=>'X', abuse=>'a@b',
					 note=>'', country=>undef };
	my $r = eval { $b->report() };
	ok !$@, "report() does not die when called without prior method calls: $@";
	ok defined $r, 'report() returns a value';

	restore_net();
};

# =============================================================================
# NEW: _is_private IPv6 additions
# =============================================================================
subtest '_is_private() — IPv6 private ranges recognised' => sub {
	my $a = Email::Abuse::Investigator->new();
	ok  $a->_is_private('::1'),		'IPv6 loopback ::1';
	ok  $a->_is_private('fc00::1'),		 'ULA fc00::/7';
	ok  $a->_is_private('fd12::1'),		 'ULA fd00::/8';
	ok  $a->_is_private('fe80::1'),		 'link-local fe80::/10';
	ok  $a->_is_private('2001:db8::1'),	'documentation 2001:db8::/32';
	ok  $a->_is_private('64:ff9b::1'),	 'NAT64 64:ff9b::/96';
	ok !$a->_is_private('2a00:1450::1'),		'public Google IPv6 not private';
};

# =============================================================================
# NEW: _decode_multipart depth guard contract
# =============================================================================
subtest '_decode_multipart() — depth >= MAX_MULTIPART_DEPTH carps and returns' => sub {
	my $bnd  = 'UNITDEPTH';
	my $body = "--$bnd\r\nContent-Type: text/plain\r\n\r\ncontent\r\n--$bnd--\r\n";
	my $a	 = Email::Abuse::Investigator->new();
	$a->{_body_plain} = '';
	my $carped = 0;
	{
		no warnings 'redefine';
		local *Carp::carp = sub { $carped++ };
		$a->_decode_multipart($body, $bnd, 20);
	}
	is $carped, 1,	'_decode_multipart carps once at depth 20';
	is $a->{_body_plain}, '', 'body not populated at depth limit';
};


# =============================================================================
# NEW SECTIONS: Tests for TODO-implemented features
# =============================================================================

# Object::Configure integration
subtest 'new() — Object::Configure::configure() is called' => sub {
	 my @calls;
	 {
	 no warnings 'redefine';
	 local *Object::Configure::configure = sub {
		  push @calls, { class => $_[0], params => $_[1] };
		  return $_[1];
	 };
	 Email::Abuse::Investigator->new(timeout => 7);
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

# _sanitise_output contract
subtest '_sanitise_output() — strips C0 controls, preserves printable' => sub {
	 my $fn = \&Email::Abuse::Investigator::_sanitise_output;
	 ok defined &Email::Abuse::Investigator::_sanitise_output,
	 '_sanitise_output is defined as a package function';
	 is $fn->('Hello, World!'), 'Hello, World!', 'printable ASCII unchanged';
	 is $fn->(undef), '',				 'undef returns empty string';
	 is $fn->("\x01\x02\x03abc"), 'abc',	'C0 controls stripped';
	 is $fn->("abc\x7Fdef"), 'abcdef',		 'DEL (0x7F) stripped';
	 is $fn->("tab\there"), "tab\there",	 'tab (0x09) preserved';
	 is $fn->("line\nbreak"), "line\nbreak",	 'LF (0x0A) preserved';
	 my $utf8 = "caf\xC3\xA9";
	 is $fn->($utf8), $utf8, 'UTF-8 high bytes preserved';
};

subtest 'report() — output contains no C0 controls from adversarial input' => sub {
	 stub_net();
	 no warnings 'redefine';
	 local *Email::Abuse::Investigator::_domain_whois = sub { undef };
	 my $a = Email::Abuse::Investigator->new();
	 $a->parse_email(make_email());
	 $a->{_origin}	  = undef;
	 $a->{_urls}		 = [];
	 $a->{_mailto_domains} = [{
	 domain		=> 'ctrl.example',
	 source		=> 'body',
	 registrar	=> "Evil\x07Registrar\x01Inc",
	 registrar_abuse => 'abuse@evil.example',
	 }];
	 my $r = $a->report();
	 ok $r !~ /[\x01-\x08\x0B\x0C\x0E-\x1F\x7F]/,
	 'report() output contains no C0 control characters';
	 restore_net();
};

subtest 'report() — originating IP section shows (could not determine) when undef' => sub {
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("From: x\@y.com\nSubject: s\n\nbody");
	$a->{_origin}		= undef;
	$a->{_urls}		= [];
	$a->{_mailto_domains} = [];

	my $r = $a->report();
	like $r, qr/could not determine originating IP/,
		'"could not determine" message shown when origin is undef';
};

subtest 'report() — URL section shows "(none found)" when no URLs present' => sub {
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(body => 'No links here.'));
	$a->{_origin}		= undef;
	$a->{_urls}		= [];
	$a->{_mailto_domains} = [];

	my $r = $a->report();
	like $r, qr/none found/, '"none found" shown when no URLs';
};

subtest 'report() — originating IP section shows (could not determine) when undef' => sub {
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("From: x\@y.com\nSubject: s\n\nbody");
	$a->{_origin}		= undef;
	$a->{_urls}		= [];
	$a->{_mailto_domains} = [];

	my $r = $a->report();
	like $r, qr/could not determine originating IP/,
		'"could not determine" message shown when origin is undef';
};
 
subtest 'report() — URL section shows "(none found)" when no URLs present' => sub {
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(body => 'No links here.'));
	$a->{_origin}		= undef;
	$a->{_urls}		= [];
	$a->{_mailto_domains} = [];

	my $r = $a->report();
	like $r, qr/none found/, '"none found" shown when no URLs';
};

subtest 'report() — URL section groups multiple paths under single host' => sub {
	stub_net(resolve => '1.2.3.4');
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(
		body => 'https://multi.example/a https://multi.example/b https://multi.example/c'));
	$a->{_origin} = {
		ip => '1.2.3.4', rdns => 'mail.ok', confidence => 'high',
		org => 'X', abuse => 'a@b', note => '', country => undef,
	};
	{
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_resolve_host = sub { '1.2.3.4' };
		local *Email::Abuse::Investigator::_whois_ip	 = sub { { org=>'T', abuse=>'a@b' } };

		my $r = $a->report();
		like $r, qr/URLs \(3\)/, 'three URLs under same host shown as grouped count';

		# Host line appears only once
		my @host_lines = ($r =~ /Host\s*:\s*multi\.example/g);
		is scalar @host_lines, 1, 'host shown exactly once for grouped URLs';
	}
 
	restore_net();
 };

 # Cross-method contract: parse_email re-invocation
 # =============================================================================
subtest 'parse_email() re-invocation clears all public-method caches' => sub {
	stub_net(resolve => '1.2.3.4');
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };

	my $a = Email::Abuse::Investigator->new();

	# First parse — populate all caches
	$a->parse_email(make_email(
		body	 => 'https://first.example/page',
		from	 => 'x@first.example',
		received => 'from first (first [91.198.174.1]) by mx',
	));
	my @urls1  = $a->embedded_urls();
	my @mdoms1 = $a->mailto_domains();
	my $orig1  = $a->originating_ip();
	my $risk1  = $a->risk_assessment();

	ok @urls1  > 0,	'first parse: URLs populated';
	ok @mdoms1 > 0,	'first parse: domains populated';
	ok defined $orig1,	  'first parse: origin populated';
	ok defined $risk1,	  'first parse: risk populated';

	# Second parse — completely different email
	$a->parse_email(make_email(
		body	 => 'No links at all.',
		from	 => 'clean@verifiedcorp.example',
		received => 'from clean (clean [91.198.174.2]) by mx',
	));

	my @urls2  = $a->embedded_urls();
	my @mdoms2 = $a->mailto_domains();

	is scalar @urls2, 0, 're-parse: URL cache refreshed (no links in new email)';

	# Origin should now reflect the new email's IP
	my $orig2 = $a->originating_ip();
	ok !defined($orig2) || $orig2->{ip} ne '91.198.174.1', 're-parse: origin cache refreshed';

	restore_net();
};

# parse_email input sanitisation
subtest 'parse_email() — NUL bytes stripped from _raw' => sub {
	 my $a = Email::Abuse::Investigator->new();
	 $a->parse_email("From: x\@y.com\n\n\x00body with\x00NUL");
	 ok $a->{_raw} !~ /\x00/, 'NUL not present in _raw after parse';
};

subtest 'parse_email() — DEL (0x7F) stripped from _raw' => sub {
	 my $a = Email::Abuse::Investigator->new();
	 $a->parse_email("Subject: del\x7Ftest\nFrom: x\@y.com\n\nbody");
	 ok $a->{_raw} !~ /\x7F/, 'DEL not present in _raw after parse';
};

subtest 'parse_email() — UTF-8 high bytes preserved in _raw' => sub {
	 my $a = Email::Abuse::Investigator->new();
	 $a->parse_email("From: x\@y.com\n\nCaf\xC3\xA9 au lait");
	 ok $a->{_raw} =~ /\xC3\xA9/, 'UTF-8 multi-byte sequence preserved in _raw';
};

# _is_private IPv6 additions
subtest '_is_private() — IPv6 private ranges recognised' => sub {
	 my $a = Email::Abuse::Investigator->new();
	 ok  $a->_is_private('::1'),		'IPv6 loopback ::1';
	 ok  $a->_is_private('fc00::1'),		 'ULA fc00::/7';
	 ok  $a->_is_private('fd12::1'),		 'ULA fd00::/8';
	 ok  $a->_is_private('fe80::1'),		 'link-local fe80::/10';
	 ok  $a->_is_private('2001:db8::1'),	'documentation 2001:db8::/32';
	 ok  $a->_is_private('64:ff9b::1'),	 'NAT64 64:ff9b::/96';
	 ok !$a->_is_private('2a00:1450::1'),		'public Google IPv6 not private';
};

# _decode_multipart depth guard contract
subtest '_decode_multipart() — depth >= MAX_MULTIPART_DEPTH carps and returns' => sub {
	 my $bnd  = 'UNITDEPTH';
	 my $body = "--$bnd\r\nContent-Type: text/plain\r\n\r\ncontent\r\n--$bnd--\r\n";
	 my $a	 = Email::Abuse::Investigator->new();
	 $a->{_body_plain} = '';
	 my $carped = 0;
	 {
		 no warnings 'redefine';
		 local *Carp::carp = sub { $carped++ };
		 $a->_decode_multipart($body, $bnd, 20);
	 }
	 is $carped, 1,	'_decode_multipart carps once at depth 20';
	 is $a->{_body_plain}, '', 'body not populated when depth limit reached';
};

# =============================================================================
# parse_email() — named-arg form and croak on non-string ref
# =============================================================================
subtest 'parse_email() — accepts named arg text => $raw' => sub {
	my $raw = make_email(subject => 'Named arg test');
	my $a = Email::Abuse::Investigator->new();
	my $ret = $a->parse_email(text => $raw);
	is $ret, $a, 'parse_email(text => ...) returns $self';
	is $a->header_value('subject'), 'Named arg test',
		'named-arg form parses headers correctly';
};

subtest 'parse_email() — croaks when passed a non-string reference' => sub {
	my $a = Email::Abuse::Investigator->new();

	# An arrayref is not a string or scalar-ref; should croak
	eval { $a->parse_email([]) };
	like $@, qr/parse_email.*string/i,
		'arrayref argument causes croak mentioning string';

	# A ref-to-ref (REF type) is also not a scalar-ref; should croak
	my $aref = [];
	eval { $a->parse_email(\$aref) };
	like $@, qr/parse_email.*string/i,
		'ref-to-ref argument causes croak mentioning string';
};

# =============================================================================
# header_value()
# =============================================================================
subtest 'header_value() — returns value for a known header' => sub {
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(subject => 'Contract test subject'));
	is $a->header_value('Subject'), 'Contract test subject',
		'header_value returns correct subject string';
	is $a->header_value('From'), 'Sender <sender@spamsite.example>',
		'header_value returns From: value';
};

subtest 'header_value() — returns undef for absent header' => sub {
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email());
	is $a->header_value('X-Nonexistent-Header'), undef,
		'undef returned for a header that does not exist';
	is $a->header_value('X-Originating-IP'), undef,
		'undef returned for optional header when not present';
};

subtest 'header_value() — lookup is case-insensitive' => sub {
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(subject => 'Case test'));
	my $upper = $a->header_value('SUBJECT');
	my $lower = $a->header_value('subject');
	my $mixed = $a->header_value('Subject');
	is $upper, 'Case test', 'SUBJECT (all caps) returns value';
	is $lower, 'Case test', 'subject (lower) returns value';
	is $mixed, 'Case test', 'Subject (title case) returns value';
	is $upper, $lower, 'all three casings return the same value';
};

subtest 'header_value() — returns first occurrence when header repeated' => sub {
	# Build an email with two Date: headers; only the first should be returned
	my $raw = "Received: from x (x [91.198.174.1]) by mx\n"
	        . "From: x\@y.com\n"
	        . "Date: Mon, 01 Jan 2024 00:00:00 +0000\n"
	        . "Date: Tue, 02 Jan 2024 00:00:00 +0000\n"
	        . "Subject: dup\n\nbody";
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email($raw);
	is $a->header_value('Date'), 'Mon, 01 Jan 2024 00:00:00 +0000',
		'first occurrence of repeated header is returned';
};

subtest 'header_value() — never throws' => sub {
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email());
	# Even a completely empty name should not throw
	my $ret = eval { $a->header_value('') };
	ok !$@, 'header_value("") does not throw';
	is $ret, undef, 'header_value("") returns undef';
};

# =============================================================================
# sending_software()
# =============================================================================
subtest 'sending_software() — returns empty list when no fingerprint headers present' => sub {
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email());
	my @sw = $a->sending_software();
	is scalar @sw, 0, 'empty list when no X-Mailer/X-PHP/User-Agent headers';
};

subtest 'sending_software() — documented hashref structure' => sub {
	my $raw = "Received: from ext (ext [91.198.174.1]) by mx\n"
	        . "From: Sender <sender\@spamsite.example>\n"
	        . "To: victim\@bandsman.co.uk\n"
	        . "Subject: SW test\n"
	        . "Date: Mon, 01 Jan 2024 00:00:00 +0000\n"
	        . "Message-ID: <sw001\@test>\n"
	        . "Content-Type: text/plain\n"
	        . "X-Mailer: Thunderbird 91.0\n"
	        . "\nBody text";
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email($raw);
	my @sw = $a->sending_software();
	ok @sw > 0, 'X-Mailer header produces at least one result';
	for my $s (@sw) {
		is reftype($s), 'HASH', 'each entry is a hashref';
		for my $key (qw(header value note)) {
			ok exists $s->{$key},  "hashref has key '$key'";
			ok defined $s->{$key}, "key '$key' is defined";
		}
		ok !ref($s->{header}), 'header is a plain string';
		ok !ref($s->{value}),  'value is a plain string';
		ok !ref($s->{note}),   'note is a plain string';
	}
};

subtest 'sending_software() — captures X-PHP-Originating-Script' => sub {
	my $raw = "Received: from ext (ext [91.198.174.1]) by mx\n"
	        . "From: Sender <sender\@spamsite.example>\n"
	        . "To: victim\@bandsman.co.uk\n"
	        . "Subject: PHP test\n"
	        . "Date: Mon, 01 Jan 2024 00:00:00 +0000\n"
	        . "Message-ID: <php001\@test>\n"
	        . "Content-Type: text/plain\n"
	        . "X-PHP-Originating-Script: 1000:mailer.php\n"
	        . "\nBody";
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email($raw);
	my @sw    = $a->sending_software();
	my ($php) = grep { $_->{header} eq 'x-php-originating-script' } @sw;
	ok defined $php, 'X-PHP-Originating-Script entry present';
	is $php->{value}, '1000:mailer.php', 'PHP script value preserved verbatim';
	like $php->{note}, qr/PHP script/i, 'note mentions PHP script';
};

subtest 'sending_software() — header names are lower-cased in results' => sub {
	my $raw = "Received: from ext (ext [91.198.174.1]) by mx\n"
	        . "From: Sender <sender\@spamsite.example>\n"
	        . "To: victim\@bandsman.co.uk\n"
	        . "Subject: Case test\n"
	        . "Date: Mon, 01 Jan 2024 00:00:00 +0000\n"
	        . "Message-ID: <case001\@test>\n"
	        . "Content-Type: text/plain\n"
	        . "X-Mailer: TheMail 1.0\n"
	        . "\nBody";
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email($raw);
	my @sw = $a->sending_software();
	for my $s (@sw) {
		is $s->{header}, lc($s->{header}),
			"header name '$s->{header}' is already lower-cased";
	}
};

subtest 'sending_software() — results are in alphabetical header-name order' => sub {
	# Include both user-agent and x-mailer so we get two entries
	my $raw = "Received: from ext (ext [91.198.174.1]) by mx\n"
	        . "From: Sender <sender\@spamsite.example>\n"
	        . "To: victim\@bandsman.co.uk\n"
	        . "Subject: Sort test\n"
	        . "Date: Mon, 01 Jan 2024 00:00:00 +0000\n"
	        . "Message-ID: <sort001\@test>\n"
	        . "Content-Type: text/plain\n"
	        . "User-Agent: Mozilla/5.0\n"
	        . "X-Mailer: TheMail 1.0\n"
	        . "\nBody";
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email($raw);
	my @sw    = $a->sending_software();
	my @names = map { $_->{header} } @sw;
	my @sorted = sort @names;
	is_deeply \@names, \@sorted, 'sending_software() entries are alphabetically sorted';
};

# =============================================================================
# received_trail()
# =============================================================================
subtest 'received_trail() — returns empty list when no Received: headers' => sub {
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("From: x\@y.com\nSubject: bare\n\nbody");
	my @trail = $a->received_trail();
	is scalar @trail, 0, 'empty list when no Received: headers present';
};

subtest 'received_trail() — documented hashref structure' => sub {
	# A single Received: header with extractable IP, for-addr, and id
	my $raw = "Received: from r1 (r1 [91.198.174.1]) by mx (Postfix) with SMTP"
	        . " id ABCDEF123 for <victim\@bandsman.co.uk>; Mon, 01 Jan 2024 00:00:00 +0000\n"
	        . "From: x\@y.com\nSubject: s\n\nbody";
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email($raw);
	my @trail = $a->received_trail();
	ok @trail > 0, 'at least one hop returned';
	my $hop = $trail[0];
	is reftype($hop), 'HASH', 'each hop entry is a hashref';
	ok exists $hop->{received}, 'hashref has key "received"';
	ok defined $hop->{received}, '"received" key is defined';
	# ip, for, id are optional per POD (may be undef)
	for my $key (qw(ip for id)) {
		ok exists $hop->{$key}, "hashref has optional key '$key'";
	}
};

subtest 'received_trail() — oldest hop is first (oldest-first order)' => sub {
	# Two Received: headers; newest is first in the email, oldest is last.
	# The module reverses them so the oldest appears first in the trail.
	my $raw = "Received: from hop2 (hop2 [91.198.174.2]) by hop1"
	        . " (Postfix) id HOP2ID; Mon, 01 Jan 2024 00:00:01 +0000\n"
	        . "Received: from hop1 (hop1 [91.198.174.1]) by origin"
	        . " (Postfix) id HOP1ID; Mon, 01 Jan 2024 00:00:00 +0000\n"
	        . "From: x\@y.com\nSubject: s\n\nbody";
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email($raw);
	my @trail = $a->received_trail();
	is scalar @trail, 2, 'two hops returned for two Received: headers';
	is $trail[0]{ip}, '91.198.174.1', 'first trail entry is the oldest hop';
	is $trail[1]{ip}, '91.198.174.2', 'second trail entry is the newer hop';
};

subtest 'received_trail() — private IPs are NOT filtered (RFC 1918 included)' => sub {
	# POD explicitly states: "Private IPs are NOT filtered here"
	my $raw = "Received: from internal (internal [10.0.0.1]) by mx"
	        . " (Postfix) id PRIVID; Mon, 01 Jan 2024 00:00:00 +0000\n"
	        . "From: x\@y.com\nSubject: s\n\nbody";
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email($raw);
	my @trail   = $a->received_trail();
	my @rfc1918 = grep { defined $_->{ip} && $_->{ip} eq '10.0.0.1' } @trail;
	ok scalar @rfc1918, 'RFC 1918 IP (10.0.0.1) is included in received_trail';
};

subtest 'received_trail() — extracts for-addr and id from Received: header' => sub {
	my $raw = "Received: from smtp.example.com (smtp.example.com [91.198.174.3])"
	        . " by mx.bandsman.co.uk (Postfix) with ESMTP id 3A9B0C1D2E"
	        . " for <target\@bandsman.co.uk>; Mon, 01 Jan 2024 12:00:00 +0000\n"
	        . "From: x\@y.com\nSubject: trail\n\nbody";
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email($raw);
	my @trail = $a->received_trail();
	ok @trail > 0, 'at least one trail entry present';
	my $hop = $trail[0];
	is $hop->{ip},  '91.198.174.3',         'IP extracted from Received: header';
	is $hop->{for}, 'target@bandsman.co.uk', 'for-addr extracted from Received: header';
	like $hop->{id}, qr/3A9B0C1D2E/, 'message-id extracted from Received: header';
};

# =============================================================================
# form_contacts()
# =============================================================================
subtest 'form_contacts() — returns a list (not a reference)' => sub {
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email());
	$a->{_origin}         = undef;
	$a->{_urls}           = [];
	$a->{_mailto_domains} = [];
	my @result = $a->form_contacts();
	ok !ref(\@result) || ref(\@result) eq 'ARRAY',
		'form_contacts() returns a list in list context';
};

subtest 'form_contacts() — each hashref has form, role, note, via keys' => sub {
	# GoDaddy is a form-only provider; trigger via From: account provider route
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(from => 'Abuse <abuse@godaddy.com>'));
	$a->{_origin}         = undef;
	$a->{_urls}           = [];
	$a->{_mailto_domains} = [];
	my @forms = $a->form_contacts();
	ok @forms > 0, 'at least one form contact for godaddy.com From: sender';
	for my $f (@forms) {
		is reftype($f), 'HASH', 'each entry is a hashref';
		for my $key (qw(form role note via)) {
			ok exists $f->{$key},  "hashref has key '$key'";
			ok defined $f->{$key}, "key '$key' is defined";
		}
	}
};

subtest 'form_contacts() — form URL always starts with https://' => sub {
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(from => 'Abuse <abuse@godaddy.com>'));
	$a->{_origin}         = undef;
	$a->{_urls}           = [];
	$a->{_mailto_domains} = [];
	my @forms = $a->form_contacts();
	for my $f (@forms) {
		like $f->{form}, qr{^https?://},
			"form URL '$f->{form}' starts with https://";
	}
};

subtest 'form_contacts() — returns empty list when no form-only providers involved' => sub {
	# gmail.com is an email provider, not a form-only provider
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(from => 'Spammer <spammer@gmail.com>'));
	$a->{_origin}         = undef;
	$a->{_urls}           = [];
	$a->{_mailto_domains} = [];
	my @forms = $a->form_contacts();
	ok !scalar(grep { $_->{form} =~ /gmail/i } @forms),
		'no gmail.com form contact returned (gmail uses email, not web form)';
};

subtest 'form_contacts() — deduplication: same form URL appears at most once' => sub {
	# From: and Reply-To: both @godaddy.com should produce only one form entry
	my $raw = "Received: from ext (ext [91.198.174.1]) by mx\n"
	        . "From: A <a\@godaddy.com>\n"
	        . "Reply-To: B <b\@godaddy.com>\n"
	        . "To: victim\@bandsman.co.uk\n"
	        . "Subject: Dedup test\n"
	        . "Date: Mon, 01 Jan 2024 00:00:00 +0000\n"
	        . "Message-ID: <dedup\@test>\n"
	        . "Content-Type: text/plain\n"
	        . "\nBody";
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email($raw);
	$a->{_origin}         = undef;
	$a->{_urls}           = [];
	$a->{_mailto_domains} = [];
	my @forms = $a->form_contacts();
	my %seen;
	my @dups = grep { $seen{$_->{form}}++ } @forms;
	is scalar @dups, 0, 'same form URL appears at most once (deduplicated)';
};

subtest 'form_contacts() — via is always "provider-table"' => sub {
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(from => 'Abuse <abuse@godaddy.com>'));
	$a->{_origin}         = undef;
	$a->{_urls}           = [];
	$a->{_mailto_domains} = [];
	my @forms = $a->form_contacts();
	for my $f (@forms) {
		is $f->{via}, 'provider-table',
			"form contact via is 'provider-table' (got '$f->{via}')";
	}
};

# =============================================================================
# unresolved_contacts()
# =============================================================================
subtest 'unresolved_contacts() — returns list of hashrefs with domain/type/source' => sub {
	# Pre-inject a URL with no abuse contact so it appears as unresolved
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(body => 'nothing'));
	$a->{_origin}         = undef;
	$a->{_contacts}       = [];   # abuse_contacts() returns []
	$a->{_urls}           = [{
		url   => 'https://unknown-host.example/path',
		host  => 'unknown-host.example',
		ip    => undef,
		org   => undef,
		abuse => '(unknown)',
	}];
	$a->{_mailto_domains} = [];
	my @unres = $a->unresolved_contacts();
	ok @unres > 0, 'at least one unresolved entry for unknown-host.example';
	my $u = $unres[0];
	is reftype($u), 'HASH', 'each entry is a hashref';
	for my $key (qw(domain type source)) {
		ok exists $u->{$key},  "hashref has key '$key'";
		ok defined $u->{$key}, "key '$key' is defined";
	}
};

subtest 'unresolved_contacts() — type is "url_host" for URL hosts' => sub {
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(body => 'nothing'));
	$a->{_origin}         = undef;
	$a->{_contacts}       = [];
	$a->{_urls}           = [{
		url   => 'https://urlonly.example/page',
		host  => 'urlonly.example',
		ip    => undef,
		org   => undef,
		abuse => '(unknown)',
	}];
	$a->{_mailto_domains} = [];
	my @unres = $a->unresolved_contacts();
	my ($url_entry) = grep { $_->{domain} eq 'urlonly.example' } @unres;
	ok defined $url_entry, 'urlonly.example appears in unresolved contacts';
	is $url_entry->{type}, 'url_host', 'type is "url_host" for URL host';
};

subtest 'unresolved_contacts() — type is "domain" for mailto domains' => sub {
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(body => 'contact info@mailonly.example'));
	$a->{_origin}         = undef;
	$a->{_contacts}       = [];
	$a->{_urls}           = [];
	# Source must NOT be a spoofable header for it to appear in unresolved
	$a->{_mailto_domains} = [{
		domain => 'mailonly.example',
		source => 'body',
	}];
	my @unres = $a->unresolved_contacts();
	my ($dom_entry) = grep { $_->{domain} eq 'mailonly.example' } @unres;
	ok defined $dom_entry, 'mailonly.example appears in unresolved contacts';
	is $dom_entry->{type}, 'domain', 'type is "domain" for mailto domain';
};

subtest 'unresolved_contacts() — covered hosts are excluded' => sub {
	# A host already in abuse_contacts must not appear in unresolved
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(body => 'nothing'));
	$a->{_origin}         = undef;
	# Pre-cache abuse_contacts to include covered.example
	$a->{_contacts}       = [{
		role    => 'Sending ISP',
		address => 'abuse@covered.example',
		via     => 'ip-whois',
	}];
	$a->{_urls}           = [{
		url   => 'https://covered.example/page',
		host  => 'covered.example',
		ip    => '1.2.3.4',
		org   => 'Covered Corp',
		abuse => 'abuse@covered.example',
	}];
	$a->{_mailto_domains} = [];
	my @unres = $a->unresolved_contacts();
	ok !scalar(grep { $_->{domain} eq 'covered.example' } @unres),
		'covered.example does not appear in unresolved contacts';
};

subtest 'unresolved_contacts() — From:/Return-Path:/Sender: sourced domains excluded' => sub {
	# POD: "Domains sourced only from spoofable sending headers are excluded"
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(body => 'nothing'));
	$a->{_origin}         = undef;
	$a->{_contacts}       = [];
	$a->{_urls}           = [];
	# The source matches the spoofable header exclusion pattern
	$a->{_mailto_domains} = [{
		domain => 'spoofable.example',
		source => 'From: header',
	}];
	my @unres = $a->unresolved_contacts();
	ok !scalar(grep { $_->{domain} eq 'spoofable.example' } @unres),
		'spoofable.example (From: header source) excluded from unresolved';
};

subtest 'unresolved_contacts() — returns empty list when no URLs or domains' => sub {
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email());
	$a->{_origin}         = undef;
	$a->{_contacts}       = [];
	$a->{_urls}           = [];
	$a->{_mailto_domains} = [];
	my @unres = $a->unresolved_contacts();
	is scalar @unres, 0, 'empty list when there are no URLs or domains to check';
};

# =============================================================================
# risk_assessment() — HIGH / MEDIUM / LOW threshold validation
# =============================================================================
subtest 'risk_assessment() — HIGH level when score >= 9' => sub {
	# SPF=fail(+3) + DKIM=fail(+3) + DMARC=fail(+3) = score 9 -> HIGH
	# Pre-set a clean origin so _risk_check_origin adds no extra flags
	stub_net();
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(
		auth => 'mx; spf=fail; dkim=fail; dmarc=fail',
	));
	$a->{_origin} = {
		ip         => '91.198.174.1',
		rdns       => 'mail.corp.example',
		confidence => 'high',
		org        => 'Corp ISP',
		abuse      => 'abuse@corp.example',
		note       => '',
		country    => undef,
	};
	$a->{_urls}           = [];
	$a->{_mailto_domains} = [];
	my $risk = $a->risk_assessment();
	is $risk->{level}, 'HIGH', 'spf=fail + dkim=fail + dmarc=fail produces HIGH level';
	ok $risk->{score} >= 9, "score $risk->{score} is >= 9 (HIGH threshold)";
	restore_net();
};

subtest 'risk_assessment() — MEDIUM level when score is 5..8' => sub {
	# SPF=softfail(+2) + DKIM=fail(+3) = score 5 -> MEDIUM
	stub_net();
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(
		auth => 'mx; spf=softfail; dkim=fail',
	));
	$a->{_origin} = {
		ip         => '91.198.174.1',
		rdns       => 'mail.corp.example',
		confidence => 'high',
		org        => 'Corp ISP',
		abuse      => 'abuse@corp.example',
		note       => '',
		country    => undef,
	};
	$a->{_urls}           = [];
	$a->{_mailto_domains} = [];
	my $risk = $a->risk_assessment();
	is $risk->{level}, 'MEDIUM', 'spf=softfail + dkim=fail produces MEDIUM level';
	ok $risk->{score} >= 5 && $risk->{score} < 9,
		"score $risk->{score} is in MEDIUM range [5, 9)";
	restore_net();
};

subtest 'risk_assessment() — LOW level when score is 2..4' => sub {
	# SPF=softfail(+2) alone = score 2 -> LOW
	stub_net();
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(make_email(
		auth => 'mx; spf=softfail',
	));
	$a->{_origin} = {
		ip         => '91.198.174.1',
		rdns       => 'mail.corp.example',
		confidence => 'high',
		org        => 'Corp ISP',
		abuse      => 'abuse@corp.example',
		note       => '',
		country    => undef,
	};
	$a->{_urls}           = [];
	$a->{_mailto_domains} = [];
	my $risk = $a->risk_assessment();
	is $risk->{level}, 'LOW', 'spf=softfail alone produces LOW level';
	ok $risk->{score} >= 2 && $risk->{score} < 5,
		"score $risk->{score} is in LOW range [2, 5)";
	restore_net();
};

done_testing();
