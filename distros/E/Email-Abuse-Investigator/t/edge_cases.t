#!/usr/bin/env perl
# =============================================================================
# t/edge-cases.t  -- Destructive, pathological and boundary-condition tests
#					for Email::Abuse::Investigator
# =============================================================================

use strict;
use warnings;

use Test::Most;
use MIME::Base64	  qw( encode_base64 );
use MIME::QuotedPrint qw( encode_qp );
use POSIX			 qw( strftime );
use Scalar::Util	  qw( blessed );

use FindBin qw( $Bin );
use lib "$Bin/../lib", "$Bin/..";
BEGIN {
	use_ok('Email::Abuse::Investigator');
}

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
	*Email::Abuse::Investigator::_parallel_resolve_hosts = sub {};
}
sub restore_net {
	no warnings 'redefine';
	for my $fn (keys %_ORIG) {
		no strict 'refs';
		*{ "Email::Abuse::Investigator::$fn" } = $_ORIG{$fn};
	}
}

sub bare_email {
	my ($hdrs, $body) = @_;
	$body //= 'body';
	return "$hdrs\n$body";
}

# =============================================================================
# 1. CONSTRUCTOR EDGE CASES
# =============================================================================

subtest 'new() -- timeout=>0 stored correctly (// not ||)' => sub {
	restore_net();
	my $a = new_ok('Email::Abuse::Investigator', [timeout => 0]);
	is $a->{timeout}, 0, 'timeout=>0 stored correctly via // operator';
};

subtest 'new() -- unknown options silently ignored' => sub {
	restore_net();
	dies_ok { my $a = Email::Abuse::Investigator->new(no_such_option => 42) } 'unknown constructor option dies';
};

subtest 'new() -- verbose flag only enables debug, does not alter analysis' => sub {
	null_net();
	my $silent  = new_ok('Email::Abuse::Investigator', [verbose => 0]);
	my $noisy   = new_ok('Email::Abuse::Investigator', [verbose => 1]);
	undef $noisy->{logger};
	my $raw = "Received: from h [91.198.174.1] by mx\nFrom: x\@y.com\n\nbody";
	$silent->parse_email($raw);
	open my $save, '>&', \*STDERR or die $!;
	close STDERR; open STDERR, '>>', \my $captured or die $!;
	$noisy->parse_email($raw);
	$noisy->originating_ip();
	close STDERR; open STDERR, '>&', $save or die $!;
	like $captured, qr/Email::Abuse::Investigator/, 'verbose=1 writes to STDERR';
	is $silent->originating_ip()->{ip}, $noisy->originating_ip()->{ip},
		'verbose flag does not alter analysis results';
	restore_net();
};

# =============================================================================
# 2. parse_email -- DESTRUCTIVE INPUTS
# =============================================================================

subtest 'parse_email -- empty string' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	lives_ok { $a->parse_email('') } 'empty string does not die';
	is   $a->originating_ip(),  undef, 'empty email: no origin';
	is scalar($a->embedded_urls()), 0, 'empty email: no URLs';
	restore_net();
};

subtest 'parse_email -- only whitespace' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	lives_ok { $a->parse_email("   \n\t\n   ") } 'whitespace-only does not die';
	restore_net();
};

subtest 'parse_email -- no blank line between headers and body' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	lives_ok { $a->parse_email("From: x\@y.com\nSubject: s\nBody text here") }
		'missing header/body separator does not die';
	restore_net();
};

subtest 'parse_email -- body only, no headers' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	lives_ok { $a->parse_email("\nJust body text") } 'body-only email does not die';
	is $a->originating_ip(), undef, 'no origin when no headers';
	restore_net();
};

subtest 'parse_email -- 64 KB single header value' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	my $long = 'x' x 65536;
	lives_ok { $a->parse_email("Subject: $long\nFrom: x\@y.com\n\nbody") }
		'64 KB header value does not die';
	restore_net();
};

subtest 'parse_email -- 1000 Received: headers (chain bomb)' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	my $hdrs = join '', map {
		"Received: from h$_ (h$_ [10.0.0.${\($_%256)}]) by next\n"
	} 1..1000;
	$hdrs .= "From: x\@y.com\n";
	lives_ok { $a->parse_email(bare_email($hdrs)) }
		'1000 Received: headers does not die';
	is $a->originating_ip(), undef, 'all-private 1000-hop chain: undef origin';
	restore_net();
};

subtest 'parse_email -- NUL bytes in body' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	my $body = "Normal\x00NUL\x00more";
	lives_ok { $a->parse_email(bare_email("From: x\@y.com\n", $body)) }
		'NUL bytes in body do not die';
	restore_net();
};

subtest 'parse_email -- CRLF line endings throughout' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	my $raw = "Received: from ext (ext [91.198.174.1]) by mx\r\n"
			. "From: x\@y.com\r\nSubject: s\r\n\r\nBody\r\n";
	lives_ok { $a->parse_email($raw) } 'CRLF line endings do not die';
	is $a->originating_ip()->{ip}, '91.198.174.1',
		'IP extracted from CRLF email';
	restore_net();
};

subtest 'parse_email -- mixed CRLF and LF' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	my $raw = "Received: from ext (ext [91.198.174.2]) by mx\r\n"
			. "From: x\@y.com\n\r\n"
			. "body\r\n";
	lives_ok { $a->parse_email($raw) } 'mixed line endings do not die';
	restore_net();
};

subtest 'parse_email -- binary high-byte body' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	my $body = join '', map { chr $_ } 0x80..0xFF;
	lives_ok { $a->parse_email(bare_email("From: x\@y.com\n", $body)) }
		'high-byte binary body does not die';
	restore_net();
};

subtest 'parse_email -- header with no value after colon' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	my $raw = "From:\nSubject:\nReceived: from ext [91.198.174.3] by mx\n\nbody";
	lives_ok { $a->parse_email($raw) } 'empty header values do not die';
	is $a->originating_ip()->{ip}, '91.198.174.3',
		'normal headers still parsed after empty ones';
	restore_net();
};

subtest 'parse_email -- duplicate From: headers: first returned' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email("From: first\@a.com\nFrom: second\@b.com\n\nbody");
	is $a->_header_value('from'), 'first@a.com',
		'_header_value returns first of duplicate headers';
	restore_net();
};

subtest 'parse_email -- folded header continuation' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	my $raw = "Subject: first part\n\tcontinued part\nFrom: x\@y.com\n\nbody";
	$a->parse_email($raw);
	like $a->_header_value('subject'), qr/first part.*continued part/s,
		'folded header continuation correctly unfolded';
	restore_net();
};

# =============================================================================
# 3. RECEIVED HEADER -- ADVERSARIAL IPS
# =============================================================================

subtest 'Received: -- 0.0.0.0 excluded as this-network address' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(bare_email("Received: from h [0.0.0.0] by mx\nFrom: x\@y.com\n"));
	is $a->originating_ip(), undef,
		'0.0.0.0 excluded via 0.x PRIVATE_RANGES entry (RFC 1122 this-network)';
	restore_net();
};

subtest 'Received: -- 255.255.255.255 excluded as broadcast' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(bare_email(
		"Received: from bc [255.255.255.255] by mx\nFrom: x\@y.com\n"));
	is $a->originating_ip(), undef,
		'255.255.255.255 excluded by qr/^255./ PRIVATE_RANGES entry';
	restore_net();
};

subtest 'Received: -- all RFC-1918 range boundaries private' => sub {
	null_net();
	for my $ip (qw(10.0.0.0 10.255.255.255 172.16.0.0 172.31.255.255
				   192.168.0.0 192.168.255.255 169.254.0.0 169.254.255.255)) {
		my $a = new_ok('Email::Abuse::Investigator');
		$a->parse_email(bare_email(
			"Received: from h [$ip] by mx\nFrom: x\@y.com\n"));
		is $a->originating_ip(), undef, "$ip excluded as private";
	}
	restore_net();
};

subtest 'Received: -- 172.15.x and 172.32.x are NOT private' => sub {
	null_net();
	for my $ip (qw(172.15.255.255 172.32.0.0)) {
		my $a = new_ok('Email::Abuse::Investigator');
		$a->parse_email(bare_email(
			"Received: from h [$ip] by mx\nFrom: x\@y.com\n"));
		ok defined $a->originating_ip(),
			"$ip is outside RFC-1918 172.16-31 range -- not private";
	}
	restore_net();
};

subtest 'Received: -- octet > 255 rejected' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(bare_email("Received: from h [256.1.2.3] by mx\nFrom: x\@y.com\n"));
	is $a->originating_ip(), undef, 'octet > 255 rejected';
	restore_net();
};

subtest 'Received: -- IPv6-only header does not die' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	lives_ok {
		$a->parse_email(bare_email(
			"Received: from host (host [2001:db8::1]) by mx\nFrom: x\@y.com\n"))
	} 'IPv6-only Received: does not die';
	restore_net();
};

subtest 'Received: -- /32 trusted relay: adjacent IP is origin' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator',
				   [trusted_relays => ['91.198.174.5/32']]);
	$a->parse_email(bare_email(
		"Received: from t [91.198.174.5] by mx\n"
	  . "Received: from a [91.198.174.6] by t\n"
	  . "From: x\@y.com\n"));
	is $a->originating_ip()->{ip}, '91.198.174.6',
		'.5 trusted, .6 is origin';
	restore_net();
};

subtest 'Received: -- /0 trusted relay: all IPs trusted, origin undef' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator',
				   [trusted_relays => ['0.0.0.0/0']]);
	$a->parse_email(bare_email(
		"Received: from any [91.198.174.1] by mx\nFrom: x\@y.com\n"));
	is $a->originating_ip(), undef, '/0 trusted -- all IPs excluded, no origin';
	restore_net();
};

# =============================================================================
# 4. _extract_ip_from_received -- BOUNDARY CONDITIONS
# =============================================================================

subtest '_extract_ip_from_received -- bracketed IP takes priority over bare' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	my $ip = $a->_extract_ip_from_received(
		'from host [91.198.174.10] by mx also 62.105.128.1');
	is $ip, '91.198.174.10', 'bracketed IP wins over bare fallback';
};

subtest '_extract_ip_from_received -- whitespace inside brackets' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	is $a->_extract_ip_from_received('from h [ 91.198.174.1 ] by mx'),
	   '91.198.174.1', 'whitespace inside brackets stripped';
};

subtest '_extract_ip_from_received -- empty string and no-IP string' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	is $a->_extract_ip_from_received(''),
	   undef, 'empty string: undef';
	is $a->_extract_ip_from_received('from localhost by mx with LMTP id 1'),
	   undef, 'no IP in header: undef';
};

# =============================================================================
# 5. _ip_in_cidr -- BOUNDARY CONDITIONS
# =============================================================================

subtest '_ip_in_cidr -- /0 matches all addresses' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	ok  $a->_ip_in_cidr('1.2.3.4',	   '0.0.0.0/0'), '/0 matches public';
	ok  $a->_ip_in_cidr('192.168.1.1',   '0.0.0.0/0'), '/0 matches private';
	ok  $a->_ip_in_cidr('255.255.255.255','0.0.0.0/0'), '/0 matches broadcast';
};

subtest '_ip_in_cidr -- /32 matches exactly one host' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	ok  $a->_ip_in_cidr('91.198.174.42', '91.198.174.42/32'), '/32 exact match';
	ok !$a->_ip_in_cidr('91.198.174.43', '91.198.174.42/32'), '/32 off-by-one miss';
	ok !$a->_ip_in_cidr('91.198.174.41', '91.198.174.42/32'), '/32 off-by-one below';
};

subtest '_ip_in_cidr -- network and broadcast addresses included in /24' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	ok  $a->_ip_in_cidr('62.105.128.0',   '62.105.128.0/24'), 'network address in /24';
	ok  $a->_ip_in_cidr('62.105.128.255', '62.105.128.0/24'), 'broadcast in /24';
	ok !$a->_ip_in_cidr('62.105.129.0',   '62.105.128.0/24'), 'next block out of /24';
};

subtest '_ip_in_cidr -- /16 straddles correctly' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	ok  $a->_ip_in_cidr('172.16.0.1',	'172.16.0.0/16'), '/16 low';
	ok  $a->_ip_in_cidr('172.16.255.254','172.16.0.0/16'), '/16 high';
	ok !$a->_ip_in_cidr('172.17.0.0',	'172.16.0.0/16'), '/16 next block';
};

# =============================================================================
# 6. _parse_date_to_epoch -- BOUNDARY DATES
# =============================================================================

subtest '_parse_date_to_epoch -- Unix epoch origin 1970-01-01' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	my $e = $a->_parse_date_to_epoch('1970-01-01');
	ok defined $e && $e >= 0, '1970-01-01 parses to >= 0';
};

subtest '_parse_date_to_epoch -- far future 2099-12-31' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	my $e = $a->_parse_date_to_epoch('2099-12-31');
	ok defined $e && $e > time(), 'far future date > now';
};

subtest '_parse_date_to_epoch -- leap year Feb 29 valid' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	my $e = $a->_parse_date_to_epoch('2024-02-29');
	ok defined $e, '2024-02-29 (valid leap day) parses';
};

subtest '_parse_date_to_epoch -- invalid Feb 29 in non-leap year does not die' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	my $e;
	lives_ok { $e = $a->_parse_date_to_epoch('2023-02-29') }
		'2023-02-29 (invalid leap day) does not die';
};

subtest '_parse_date_to_epoch -- year-end boundary Dec 31 vs Jan 1' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	my $e_dec = $a->_parse_date_to_epoch('2024-12-31');
	my $e_jan = $a->_parse_date_to_epoch('2025-01-01');
	ok defined $e_dec && defined $e_jan, 'both year-boundary dates parse';
	ok $e_jan > $e_dec, 'Jan 1 epoch > Dec 31 epoch';
};

subtest '_parse_date_to_epoch -- exactly 180 days ago is within window' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	my $boundary = strftime('%Y-%m-%d', gmtime(time() - 180 * 86400));
	my $e = $a->_parse_date_to_epoch($boundary);
	ok defined $e, '180-day boundary date parses';
	ok (time() - $e) <= 180 * 86400 + 86400,
		'180-day boundary within window (+1 day clock-skew tolerance)';
};

subtest '_parse_date_to_epoch -- 181 days ago is outside window' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	my $old = strftime('%Y-%m-%d', gmtime(time() - 181 * 86400));
	my $e   = $a->_parse_date_to_epoch($old);
	ok defined $e && (time() - $e) > 180 * 86400,
		'181-day-old date beyond 180-day window';
};

subtest '_parse_date_to_epoch -- unknown DD-Mon-YYYY month returns undef' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	is $a->_parse_date_to_epoch('15-Xyz-2024'), undef,
		'unknown month abbreviation returns undef';
};

# =============================================================================
# 7. MIME DECODING -- PATHOLOGICAL ENCODED-WORDS
# =============================================================================

subtest '_decode_mime_words -- empty base64 payload' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	my $r;
	lives_ok { $r = $a->_decode_mime_words('=?UTF-8?B??=') }
		'empty base64 payload does not die';
	is $r, '', 'empty payload decodes to empty string';
};

subtest '_decode_mime_words -- invalid base64 characters do not die' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	my $r;
	lives_ok { $r = $a->_decode_mime_words('=?UTF-8?B?not!!valid@@b64?=') }
		'invalid base64 does not die';
	ok defined $r, 'invalid base64 returns defined value';
};

subtest '_decode_mime_words -- 4 KB base64 payload' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	my $payload = encode_base64('A' x 4096, '');
	my $r;
	lives_ok { $r = $a->_decode_mime_words("=?UTF-8?B?${payload}?=") }
		'4 KB encoded-word does not die';
	ok length($r) > 0, '4 KB payload decodes to non-empty string';
};

subtest '_decode_mime_words -- QP with truncated trailing =' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	my $r;
	lives_ok { $r = $a->_decode_mime_words('=?UTF-8?Q?Hello=?=') }
		'truncated QP does not die';
	ok defined $r, 'truncated QP returns defined value';
};

subtest '_decode_mime_words -- unknown charset does not die' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	my $r;
	lives_ok {
		$r = $a->_decode_mime_words(
			'=?X-NONEXISTENT-12345?B?' . encode_base64('test','') . '?=')
	} 'unknown charset does not die';
	ok defined $r, 'unknown charset returns defined value';
};

subtest '_decode_mime_words -- multiple encoded-words in one string' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	my $s = '=?UTF-8?B?' . encode_base64('Hello', '') . '?= '
		  . '=?UTF-8?B?' . encode_base64('World', '') . '?=';
	is $a->_decode_mime_words($s), 'Hello World', 'multiple words decoded';
};

# =============================================================================
# 8. MULTIPART -- DEGENERATE STRUCTURES
# =============================================================================

subtest 'multipart -- boundary in Content-Type but absent from body' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	lives_ok {
		$a->parse_email(
			"Content-Type: multipart/alternative; boundary=\"MISSING\"\n\n"
			. "This body has no boundary markers at all.")
	} 'missing multipart boundary in body does not die';
	restore_net();
};

subtest 'multipart -- parts with no Content-Type header' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	lives_ok {
		$a->parse_email(
			"Content-Type: multipart/alternative; boundary=\"B\"\n\n"
			. "--B\r\nX-Custom: foo\r\n\r\npart one\r\n"
			. "--B\r\nX-Custom: bar\r\n\r\npart two\r\n"
			. "--B--\r\n")
	} 'multipart parts with no Content-Type do not die';
	restore_net();
};

subtest 'multipart -- boundary containing regex metacharacters' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	my $bnd = 'b+o.u*n[d]a(r)y^$';
	lives_ok {
		$a->parse_email(
			"Content-Type: multipart/alternative; boundary=\"$bnd\"\n\n"
			. "--$bnd\r\nContent-Type: text/plain\r\n\r\ntext\r\n"
			. "--$bnd--\r\n")
	} 'boundary with regex metacharacters does not die';
	restore_net();
};

subtest 'multipart -- empty sub-part body' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	lives_ok {
		$a->parse_email(
			"Content-Type: multipart/alternative; boundary=\"B\"\n\n"
			. "--B\r\nContent-Type: text/plain\r\n\r\n"
			. "--B\r\nContent-Type: text/html\r\n\r\n<p>html</p>\r\n"
			. "--B--\r\n")
	} 'empty multipart sub-part body does not die';
	restore_net();
};

# =============================================================================
# 9. URL EXTRACTION -- PATHOLOGICAL INPUTS
# =============================================================================

subtest 'embedded_urls -- bare-host URL (no path)' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email("From: x\@y.com\n\nhttps://example.com");
	my @u = $a->embedded_urls();
	ok @u > 0,						 'bare-host URL extracted';
	is $u[0]{host}, 'example.com',	 'bare-host URL host correct';
	restore_net();
};

subtest 'embedded_urls -- URL with port number: port stripped from host' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email("From: x\@y.com\n\nhttps://evil.example:8443/path");
	my @u = $a->embedded_urls();
	ok @u > 0,						 'URL with port extracted';
	is $u[0]{host}, 'evil.example',	'port stripped from host';
	restore_net();
};

subtest 'embedded_urls -- 500 identical URLs deduplicated to one' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email("From: x\@y.com\n\n" . ('https://spamhost.example/offer ' x 500));
	my @u = $a->embedded_urls();
	is scalar @u, 1, '500 identical URLs deduplicated to one';
	restore_net();
};

subtest 'embedded_urls -- 500 different paths on same host: WHOIS called once' => sub {
	my $wc = 0;
	{ no warnings 'redefine';
	  *Email::Abuse::Investigator::_reverse_dns  = sub { undef };
	  *Email::Abuse::Investigator::_resolve_host = sub { '1.2.3.4' };
	  *Email::Abuse::Investigator::_whois_ip	 = sub { $wc++; {} };
	  *Email::Abuse::Investigator::_domain_whois = sub { undef };
	  *Email::Abuse::Investigator::_raw_whois	= sub { undef };
	  *Email::Abuse::Investigator::_rdap_lookup  = sub { {} };
	}
	my $a = new_ok('Email::Abuse::Investigator');
	my $body = join ' ', map { "https://onehost.example/p$_" } 1..500;
	$a->parse_email("From: x\@y.com\n\n$body");
	my @u = $a->embedded_urls();
	is scalar @u,  500, '500 distinct paths all returned';
	is $wc,		  1, 'WHOIS called exactly once for 500 same-host URLs';
	restore_net();
};

subtest 'embedded_urls -- 8 KB URL path does not die' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	my $path = 'a' x 8192;
	lives_ok { $a->parse_email("From: x\@y.com\n\nhttps://spam.example/$path") }
		'8 KB URL path does not die';
	restore_net();
};

subtest 'embedded_urls -- each trailing punctuation char stripped' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	for my $punct ('.', ',', ';', ':', '!', '?', ')', '>', ']') {
		$a->parse_email("From: x\@y.com\n\nhttps://spam.example/path$punct");
		my @u = $a->embedded_urls();
		if (@u) {
			my $url = $u[0]{url};
			ok $url !~ /\Q$punct\E$/,
				"trailing '$punct' stripped from URL (got: $url)";
		} else {
			pass "URL with trailing '$punct': handled without dying";
		}
	}
	restore_net();
};

subtest 'embedded_urls -- uppercase scheme HTTP:// recognised' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email("From: x\@y.com\n\nHTTPS://SPAM.EXAMPLE/path");
	my @u = $a->embedded_urls();
	ok @u >= 1, 'uppercase HTTPS:// scheme URL extracted';
	restore_net();
};

# =============================================================================
# 10. DOMAIN EXTRACTION -- PATHOLOGICAL INPUTS
# =============================================================================

subtest 'mailto_domains -- single-label domain does not die' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email("From: user\@com\n\nbody");
	lives_ok { $a->mailto_domains() } 'single-label domain in From: does not die';
	restore_net();
};

subtest 'mailto_domains -- 200 distinct domains all extracted' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	my $body = join ' ', map { "info\@domain$_.example" } 1..200;
	$a->parse_email("From: x\@domain1.example\nReturn-Path: <x\@domain1.example>\n\n$body");
	my @d;
	lives_ok { @d = $a->mailto_domains() }
		'200 distinct body domains do not die';
	is scalar @d, 200, 'all 200 domains extracted';
	restore_net();
};

subtest 'mailto_domains -- all TRUSTED_DOMAINS variants excluded' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(
		"From: x\@gmail.com\n"
	  . "Return-Path: <y\@googlemail.com>\n\n"
	  . "contact info\@yahoo.com and mail\@outlook.com");
	my @names = map { $_->{domain} } $a->mailto_domains();
	ok !scalar(grep {
		/^(?:gmail|googlemail|yahoo|outlook|hotmail|google|microsoft|apple|amazon)\.com$/
	} @names), 'all TRUSTED_DOMAINS excluded';
	restore_net();
};

subtest 'mailto_domains -- domain object not mutated by abuse_contacts()' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email("From: x\@y.com\n\nbody");
	$a->{_origin}		 = undef;
	$a->{_urls}		   = [];
	$a->{_mailto_domains} = [{
		domain	=> 'test.example',
		source	=> 'body',
		mx_abuse  => 'abuse@mx.example',
		mx_host   => undef,
		mx_ip	 => undef,
		mx_org	=> undef,
	}];
	my @before = map { +{ %$_ } } @{ $a->{_mailto_domains} };
	$a->abuse_contacts();
	my @after = @{ $a->{_mailto_domains} };
	is $after[0]{mx_host}, $before[0]{mx_host},
		'abuse_contacts() does not mutate mx_host in domain hashref';
	is $after[0]{mx_ip},   $before[0]{mx_ip},
		'abuse_contacts() does not mutate mx_ip in domain hashref';
	restore_net();
};

# =============================================================================
# 11. _registrable -- BOUNDARY CASES
# =============================================================================

subtest '_registrable -- single label returns undef' => sub {
	is Email::Abuse::Investigator::_registrable('localhost'), undef, 'no dot: undef';
	is Email::Abuse::Investigator::_registrable('com'),	   undef, 'tld-only: undef';
};

subtest '_registrable -- two labels returned unchanged' => sub {
	is Email::Abuse::Investigator::_registrable('example.com'), 'example.com',
		'two labels unchanged';
};

subtest '_registrable -- ccTLD second-level variants' => sub {
	is Email::Abuse::Investigator::_registrable('sub.example.co.uk'),
	   'example.co.uk',  'co.uk ccTLD';
	is Email::Abuse::Investigator::_registrable('sub.example.com.au'),
	   'example.com.au', 'com.au ccTLD';
	is Email::Abuse::Investigator::_registrable('sub.example.org.ph'),
	   'example.org.ph', 'org.ph ccTLD';
	is Email::Abuse::Investigator::_registrable('sub.example.ac.uk'),
	   'example.ac.uk',  'ac.uk ccTLD';
};

subtest '_registrable -- non-ccTLD-pair two-char TLD' => sub {
	is Email::Abuse::Investigator::_registrable('sub.example.io'),
	   'example.io', '.io without co/com prefix treated as simple TLD';
};

# =============================================================================
# 12. risk_assessment -- SCORE THRESHOLD BOUNDARIES
# =============================================================================

subtest 'risk_assessment -- score >= 9 is HIGH' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(
		"Received: from h [91.198.174.1] by mx\n"
	  . "Authentication-Results: mx; spf=fail; dkim=fail; dmarc=fail\n"
	  . "From: x\@y.com\nTo: v\@t.com\n\nbody");
	$a->{_urls}		   = [];
	$a->{_mailto_domains} = [];
	my $risk = $a->risk_assessment();
	ok $risk->{score} >= 9, "score >= 9 (got $risk->{score})";
	is $risk->{level}, 'HIGH', 'score >= 9 gives HIGH';
	restore_net();
};

subtest 'risk_assessment -- score 5..8 is MEDIUM' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(
		"Received: from h (h [91.198.174.1]) by mx\n"
	  . "From: x\@gmail.com\n"
	  . "Reply-To: y\@other.com\n"
	  . "To: undisclosed-recipients:;\n\nbody");
	$a->{_origin} = {
		ip=>'91.198.174.1', rdns=>'mail.isp.example', confidence=>'medium',
		org=>'ISP', abuse=>'abuse@isp.example', note=>'', country=>undef,
	};
	$a->{_urls}		   = [];
	$a->{_mailto_domains} = [];
	my $risk = $a->risk_assessment();
	ok $risk->{score} >= 5 && $risk->{score} < 9,
		"score 5..8 (got $risk->{score})";
	is $risk->{level}, 'MEDIUM', 'score 5..8 gives MEDIUM';
	restore_net();
};

subtest 'risk_assessment -- score 2..4 is LOW' => sub {
	null_net();
	my $enc = '=?UTF-8?B?' . encode_base64('Buy now', '') . '?=';
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(
		"Received: from h (h [91.198.174.1]) by mx\n"
	  . "From: x\@verifiedcorp.example\n"
	  . "Return-Path: <x\@verifiedcorp.example>\n"
	  . "To: user\@test.example\n"
	  . "Subject: $enc\n\nbody");
	$a->{_origin} = {
		ip=>'91.198.174.1', rdns=>'mail.verifiedcorp.example',
		confidence=>'medium', org=>'Corp', abuse=>'abuse@corp.example',
		note=>'', country=>undef,
	};
	$a->{_urls} = [{
		url=>'http://plain.example/page', host=>'plain.example',
		ip=>'1.2.3.4', org=>'T', abuse=>'a@b',
	}];
	$a->{_mailto_domains} = [];
	my $risk = $a->risk_assessment();
	ok $risk->{score} >= 2 && $risk->{score} < 5,
		"score 2..4 (got $risk->{score})";
	is $risk->{level}, 'LOW', 'score 2..4 gives LOW';
	restore_net();
};

subtest 'risk_assessment -- score 0..1 is INFO' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	my $today = strftime('%a, %d %b %Y %H:%M:%S +0000', gmtime);
	$a->parse_email(
		"Received: from h (h [91.198.174.1]) by mx\n"
	  . "Authentication-Results: mx; spf=pass; dkim=pass; dmarc=pass\n"
	  . "From: x\@verifiedcorp.example\n"
	  . "Return-Path: <x\@verifiedcorp.example>\n"
	  . "To: user\@test.example\n"
	  . "Date: $today\n"
	  . "Subject: Plain subject\n\nbody");
	$a->{_origin} = {
		ip=>'91.198.174.1', rdns=>'mail.verifiedcorp.example',
		confidence=>'medium', org=>'Corp', abuse=>'abuse@corp.example',
		note=>'', country=>'GB',
	};
	$a->{_urls}		   = [];
	$a->{_mailto_domains} = [];
	my $risk = $a->risk_assessment();
	ok $risk->{score} < 2, "score < 2 (got $risk->{score})";
	is $risk->{level}, 'INFO', 'score < 2 gives INFO';
	restore_net();
};

subtest 'risk_assessment -- domain expiry exactly now: at most one expiry flag' => sub {
	null_net();
	my $today = strftime('%Y-%m-%d', gmtime(time()));
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email("From: x\@y.com\n\nbody");
	$a->{_origin}		 = undef;
	$a->{_urls}		   = [];
	$a->{_mailto_domains} = [{
		domain=>'borderline.example', source=>'body',
		recently_registered=>0, expires=>$today,
	}];
	my $risk;
	lives_ok { $risk = $a->risk_assessment() }
		'domain expiring today does not die';
	my @expiry = grep { $_->{flag} =~ /^domain_expir/ } @{ $risk->{flags} };
	ok scalar @expiry <= 1,
		'expires_soon and expired are mutually exclusive (at most one flag)';
	restore_net();
};

subtest 'risk_assessment -- 31 days to expiry: domain_expires_soon NOT raised' => sub {
	null_net();
	my $future = strftime('%Y-%m-%d', gmtime(time() + 31 * 86400));
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email("From: x\@y.com\n\nbody");
	$a->{_origin}		 = undef;
	$a->{_urls}		   = [];
	$a->{_mailto_domains} = [{
		domain=>'future.example', source=>'body',
		expires=>$future, recently_registered=>0,
	}];
	my $risk = $a->risk_assessment();
	ok !scalar(grep { $_->{flag} eq 'domain_expires_soon' } @{ $risk->{flags} }),
		'31 days to expiry does not trigger domain_expires_soon';
	restore_net();
};

subtest 'risk_assessment -- cached result returned on second call' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email("From: x\@y.com\n\nbody");
	$a->{_urls} = []; $a->{_mailto_domains} = [];
	my $r1 = $a->risk_assessment();
	my $r2 = $a->risk_assessment();
	is $r2, $r1, 'second call returns same hashref (cached)';
	restore_net();
};

# =============================================================================
# 13. risk_assessment -- LOOKALIKE DOMAIN BOUNDARIES
# =============================================================================

subtest 'risk_assessment -- canonical brand domains not flagged as lookalikes' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email("From: x\@y.com\n\nbody");
	$a->{_origin} = undef; $a->{_urls} = [];
	for my $real (qw(paypal.com paypal.co.uk apple.com google.com
					 amazon.com microsoft.com netflix.com ebay.com)) {
		$a->{_mailto_domains} = [{
			domain=>$real, source=>'body', recently_registered=>0
		}];
		$a->{_risk} = undef;
		my $risk = $a->risk_assessment();
		ok !scalar(grep { $_->{flag} eq 'lookalike_domain' } @{ $risk->{flags} }),
			"$real not flagged as lookalike";
	}
	restore_net();
};

subtest 'risk_assessment -- prefix and suffix lookalikes flagged' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email("From: x\@y.com\n\nbody");
	$a->{_origin} = undef; $a->{_urls} = [];
	for my $fake (qw(paypal-secure.example getpaypal.example
					 applesupport.example apple-id.example
					 google-login.example secure-amazon.example)) {
		$a->{_mailto_domains} = [{
			domain=>$fake, source=>'body', recently_registered=>0
		}];
		$a->{_risk} = undef;
		my $risk = $a->risk_assessment();
		ok scalar(grep { $_->{flag} eq 'lookalike_domain' } @{ $risk->{flags} }),
			"$fake flagged as lookalike";
	}
	restore_net();
};

# =============================================================================
# 14. abuse_contacts -- EDGE CASES
# =============================================================================

subtest 'abuse_contacts -- address without @ never added' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email("From: x\@y.com\n\nbody");
	$a->{_origin}		 = undef;
	$a->{_urls}		   = [];
	$a->{_mailto_domains} = [{
		domain		  => 'bad.example', source => 'body',
		web_abuse	   => 'not-an-email',
		registrar_abuse => 'also-no-at',
	}];
	my @contacts = $a->abuse_contacts();
	ok !scalar(grep { $_->{address} !~ /\@/ } @contacts),
		'addresses without @ never added';
};

subtest 'abuse_contacts -- 40 routes to same address: appears exactly once' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email("From: x\@y.com\n\nbody");
	$a->{_origin} = {
		ip=>'1.2.3.4', rdns=>'mail.x', confidence=>'medium',
		org=>'X', abuse=>'abuse@shared.example', note=>'', country=>undef,
	};
	$a->{_urls} = [];
	$a->{_mailto_domains} = [map { {
		domain		  => "dom$_.example",
		source		  => 'body',
		web_abuse	   => 'abuse@shared.example',
		registrar_abuse => 'abuse@shared.example',
		mx_abuse		=> 'abuse@shared.example',
		ns_abuse		=> 'abuse@shared.example',
	} } 1..10];
	my @contacts = $a->abuse_contacts();
	my @shared   = grep { lc($_->{address}) eq 'abuse@shared.example' } @contacts;
	is scalar @shared, 1, 'address from 41 routes appears exactly once';
};

subtest 'abuse_contacts -- gmail From/Reply-To/Return-Path: one google contact' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(
		"From: a\@gmail.com\n"
	  . "Reply-To: b\@gmail.com\n"
	  . "Return-Path: <c\@gmail.com>\n\nbody");
	$a->{_origin}		 = undef;
	$a->{_urls}		   = [];
	$a->{_mailto_domains} = [];
	my @contacts = $a->abuse_contacts();
	my @google   = grep { lc($_->{address}) eq 'abuse@google.com' } @contacts;
	is scalar @google, 1,
		'google abuse address appears once despite 3 gmail headers';
};

# =============================================================================
# 15. _parse_whois_text -- ADVERSARIAL WHOIS
# =============================================================================

subtest '_parse_whois_text -- all-comment WHOIS returns empty hash' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	my $r = $a->_parse_whois_text("% comment\n% another\n");
	is_deeply $r, {}, 'all-comment WHOIS text returns {}';
};

subtest '_parse_whois_text -- first OrgName wins over second' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	my $r = $a->_parse_whois_text("OrgName: First\nOrgName: Second\n");
	is $r->{org}, 'First', 'first OrgName takes priority';
};

subtest '_parse_whois_text -- trailing whitespace stripped from abuse email' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	my $r = $a->_parse_whois_text("OrgAbuseEmail: abuse\@corp.example   \n");
	is $r->{abuse}, 'abuse@corp.example', 'trailing whitespace stripped';
};

subtest '_parse_whois_text -- country code normalised to uppercase' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	is $a->_parse_whois_text("country: au\n")->{country}, 'AU',
		'lowercase country code matched and normalised to uppercase';
	is $a->_parse_whois_text("country: AU\n")->{country}, 'AU',
		'uppercase country code matched and stored as-is';
	is $a->_parse_whois_text("country: Gb\n")->{country}, 'GB',
		'mixed-case country code normalised to uppercase';
};

subtest '_parse_whois_text -- 2 KB padded WHOIS blob: fields found correctly' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	my $pad  = ("% " . "x" x 70 . "\n") x 25;
	my $text = $pad . "OrgName: Correct Org\n" . $pad
			 . "OrgAbuseEmail: correct\@org.example\n" . $pad;
	my $r = $a->_parse_whois_text($text);
	is $r->{org},   'Correct Org',		 'org found in padded WHOIS';
	is $r->{abuse}, 'correct@org.example', 'abuse found in padded WHOIS';
};

# =============================================================================
# 16. report() / abuse_report_text() -- DEFENSIVE OUTPUT
# =============================================================================

subtest 'report() -- does not die on completely empty email' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email('');
	$a->{_urls} = []; $a->{_mailto_domains} = [];
	my $r;
	lives_ok { $r = $a->report() } 'report() on empty email does not die';
	ok length($r) > 0, 'report() returns non-empty string for empty email';
	restore_net();
};

subtest 'report() -- does not die when all network returns undef' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(
		"Received: from h [91.198.174.1] by mx\n"
	  . "From: x\@spam.example\n\n"
	  . "Visit https://spam.example/buy");
	my $r;
	lives_ok { $r = $a->report() } 'all-undef network still produces report';
	ok length($r) > 0, 'report non-empty even with all-undef network';
	restore_net();
};

subtest 'report() -- special chars in registrar name do not corrupt output' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email("From: x\@y.com\n\nbody");
	$a->{_origin}		 = undef;
	$a->{_urls}		   = [];
	$a->{_mailto_domains} = [{
		domain		  => 'test.example',
		source		  => 'body',
		registrar	   => 'Registrar (Pty) Ltd. [SA] & Co.',
		registrar_abuse => 'abuse@registrar.example',
	}];
	my $r;
	lives_ok { $r = $a->report() }
		'registrar name with special chars does not die';
	like $r, qr/Registrar \(Pty\) Ltd/, 'special chars preserved in output';
	restore_net();
};

subtest 'abuse_report_text() -- does not die on empty email' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email('');
	$a->{_urls} = []; $a->{_mailto_domains} = [];
	my $r;
	lives_ok { $r = $a->abuse_report_text() }
		'abuse_report_text() on empty email does not die';
	ok length($r) > 0, 'abuse_report_text() non-empty for empty email';
	restore_net();
};

# =============================================================================
# 17. STATE ISOLATION BETWEEN OBJECTS
# =============================================================================

subtest 'two objects have independent state' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	my $b = new_ok('Email::Abuse::Investigator');
	$a->parse_email(
		"Received: from h [91.198.174.1] by mx\nFrom: x\@a.example\n\nbody");
	$b->parse_email(
		"Received: from h [91.198.174.2] by mx\nFrom: x\@b.example\n\nbody");

	isnt $a->originating_ip()->{ip}, $b->originating_ip()->{ip},
		'two objects have independent originating IPs';

	$a->{_risk} = { level => 'MUTATED', score => 999, flags => [] };
	my $risk_b = $b->risk_assessment();
	isnt $risk_b->{level}, 'MUTATED',
		'mutating object A cache does not affect object B';
	restore_net();
};

subtest 're-parse on same object produces independent results' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(
		"Received: from h [91.198.174.1] by mx\nFrom: x\@first.example\n\nbody");
	my $orig1 = $a->originating_ip();

	$a->parse_email(
		"Received: from h [91.198.174.2] by mx\nFrom: x\@second.example\n\nbody");
	my $orig2 = $a->originating_ip();

	is $orig2->{ip}, '91.198.174.2', 'second parse: new IP';
	isnt $orig1->{ip}, $orig2->{ip}, 'first parse IP not reused';
	restore_net();
};

# =============================================================================
# 18. _provider_abuse_for_host -- SUBDOMAIN STRIPPING
# =============================================================================

subtest '_provider_abuse_for_host -- 10-level deep subdomain reaches provider' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	my $deep = 'a.b.c.d.e.f.g.h.i.gmail.com';
	my $r = $a->_provider_abuse_for_host($deep);
	is $r->{email}, 'abuse@google.com',
		'10-level subdomain of gmail reaches provider table';
};

subtest '_provider_abuse_for_host -- case-insensitive lookup' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	is $a->_provider_abuse_for_host('GMAIL.COM')->{email},
	   'abuse@google.com', 'GMAIL.COM matched case-insensitively';
	is $a->_provider_abuse_for_host('Mail.GMAIL.Com')->{email},
	   'abuse@google.com', 'mixed-case subdomain matched';
};

subtest '_provider_abuse_for_host -- completely unknown host returns undef' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	is $a->_provider_abuse_for_host('completely.unknown.example'),
	   undef, 'unknown host returns undef';
};


# NEW SECTIONS: Tests for TODO-implemented features
# =============================================================================

# 19. CHI cross-message cache: graceful degradation when cache unavailable
subtest 'CHI absent -- all methods work when class-level cache is undef' => sub {
	no warnings qw(redefine once);
	local *Email::Abuse::Investigator::_reverse_dns  = sub { 'mail.test.example' };
	local *Email::Abuse::Investigator::_resolve_host = sub { '1.2.3.4' };
	local *Email::Abuse::Investigator::_whois_ip	 = sub { { org => 'Test', abuse => 'a@b' } };
	local *Email::Abuse::Investigator::_domain_whois = sub { undef };

	# Temporarily remove the class-level cache
	my $saved = $Email::Abuse::Investigator::_cache;
	$Email::Abuse::Investigator::_cache = undef;

	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("Received: from h [91.198.174.1] by mx\nFrom: x\@y.com\n\nbody");
	lives_ok { $a->originating_ip() } 'originating_ip lives without CHI cache';
	lives_ok { $a->embedded_urls()   } 'embedded_urls lives without CHI cache';
	lives_ok { $a->risk_assessment() } 'risk_assessment lives without CHI cache';
	lives_ok { $a->report()		  } 'report lives without CHI cache';

	$Email::Abuse::Investigator::_cache = $saved;
	restore_net();
};

# 20. IPv6 private range coverage
subtest '_is_private -- full IPv6 private range coverage' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	ok  $a->_is_private('2001:db8::1'),		  '2001:db8::1 documentation range (private)';
	ok  $a->_is_private('2001:db8:ffff::1'),	  '2001:db8:ffff:: documentation range (private)';
	ok  $a->_is_private('fe80::1'),			   'fe80::1 link-local (private)';
	ok  $a->_is_private('fe80:0:0:0:1:2:3:4'),	'fe80:: full form (private)';
	ok  $a->_is_private('64:ff9b::1'),			'64:ff9b:: NAT64 prefix (private)';
	ok !$a->_is_private('2a00:1450:4001::1'),	 '2a00: Google IPv6 not private';
	ok !$a->_is_private('2001:500:4::1'),		  '2001:500: IANA IPv6 not private';
};

subtest 'IPv6 Received: header -- originating_ip does not die' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	lives_ok {
		$a->parse_email(
			"Received: from mail.example.com (mail.example.com [2001:db8::1]) by mx\n"
		  . "From: x\@y.com\n\nbody")
	} 'parse_email with IPv6 Received: does not die';
	my $orig;
	lives_ok { $orig = $a->originating_ip() }
		'originating_ip does not die on IPv6-only Received:';
	restore_net();
};

# 21. parse_email input sanitisation
subtest 'parse_email -- NUL and C0 controls stripped from _raw' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email("From: x\@y.com\n\n\x00NUL\x01SOH\x07BEL bytes");
	ok $a->{_raw} !~ /\x00/, 'NUL (0x00) stripped';
	ok $a->{_raw} !~ /\x01/, 'SOH (0x01) stripped';
	ok $a->{_raw} !~ /\x07/, 'BEL (0x07) stripped';
};

subtest 'parse_email -- valid UTF-8 high bytes preserved in _raw' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email("From: x\@y.com\n\nCaf\xC3\xA9");
	ok $a->{_raw} =~ /\xC3\xA9/, 'UTF-8 high bytes preserved';
};

subtest 'parse_email -- DEL (0x7F) stripped from _raw' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email("From: x\@y.com\n\ndel\x7Fchar");
	ok $a->{_raw} !~ /\x7F/, 'DEL (0x7F) stripped';
};

# 22. _sanitise_output: full C0 control character coverage
subtest '_sanitise_output -- all C0 controls stripped except tab/LF/CR' => sub {
	my $fn = \&Email::Abuse::Investigator::_sanitise_output;
	for my $byte (0x01..0x08, 0x0B, 0x0C, 0x0E..0x1F) {
		my $result = $fn->("pre" . chr($byte) . "post");
		is $result, 'prepost', sprintf('0x%02X stripped', $byte);
	}
};

subtest '_sanitise_output -- tab LF CR preserved' => sub {
	my $fn = \&Email::Abuse::Investigator::_sanitise_output;
	is $fn->("col1\tcol2"),   "col1\tcol2",   'tab (0x09) preserved';
	is $fn->("line1\nline2"), "line1\nline2", 'LF (0x0A) preserved';
	is $fn->("cr\rhere"),	 "cr\rhere",	 'CR (0x0D) preserved';
};

subtest '_sanitise_output -- DEL (0x7F) stripped' => sub {
	my $fn = \&Email::Abuse::Investigator::_sanitise_output;
	is $fn->("del\x7Fchar"), 'delchar', 'DEL (0x7F) stripped';
};

subtest '_sanitise_output -- high bytes 0x80-0xFF preserved' => sub {
	my $fn = \&Email::Abuse::Investigator::_sanitise_output;
	my $high = join '', map { chr $_ } 0x80..0xFF;
	is $fn->($high), $high, 'high bytes 0x80-0xFF preserved unchanged';
};

subtest '_sanitise_output -- undef returns empty string without dying' => sub {
	my $fn = \&Email::Abuse::Investigator::_sanitise_output;
	my $r;
	lives_ok { $r = $fn->(undef) } 'undef does not die';
	is $r, '', 'undef returns empty string';
};

# 23. _decode_multipart depth boundary (recursion guard)
subtest '_decode_multipart -- depth threshold is exactly 20' => sub {
	my $bnd  = 'DTEST';
	my $body = "--$bnd\r\nContent-Type: text/plain\r\n\r\ntext\r\n--$bnd--\r\n";

	# depth 19 (below limit): content processed, no carp
	{
		my $a = Email::Abuse::Investigator->new();
		$a->{_body_plain} = ''; $a->{_body_html} = '';
		my $carped = 0;
		{ no warnings 'redefine'; local *Carp::carp = sub { $carped++ };
		  $a->_decode_multipart($body, $bnd, 19); }
		is $carped, 0,	'depth 19: no carp (below limit)';
		like $a->{_body_plain}, qr/text/, 'depth 19: content processed';
	}

	# depth 20 (at limit): carp once, content NOT processed
	{
		my $a = Email::Abuse::Investigator->new();
		$a->{_body_plain} = ''; $a->{_body_html} = '';
		my $carped = 0;
		{ no warnings 'redefine'; local *Carp::carp = sub { $carped++ };
		  $a->_decode_multipart($body, $bnd, 20); }
		is $carped, 1,	'depth 20: carp called exactly once (at limit)';
		is $a->{_body_plain}, '', 'depth 20: content NOT processed';
	}

	# depth 25 (beyond limit): still one carp (immediate return)
	{
		my $a = Email::Abuse::Investigator->new();
		$a->{_body_plain} = ''; $a->{_body_html} = '';
		my $carped = 0;
		{ no warnings 'redefine'; local *Carp::carp = sub { $carped++ };
		  $a->_decode_multipart($body, $bnd, 25); }
		is $carped, 1, 'depth 25: carp called once (beyond limit, immediate return)';
	}
};

# 24. AnyEvent::DNS parallel resolver graceful degradation
subtest '_parallel_resolve_hosts -- empty hashref does not die' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	lives_ok { $a->_parallel_resolve_hosts({}, {}) }
		'_parallel_resolve_hosts({},{}) does not die';
};

subtest 'AnyEvent::DNS absent -- embedded_urls works via sequential fallback' => sub {
	# Stub _parallel_resolve_hosts to a no-op so the test exercises the
	# sequential fallback path unconditionally, regardless of whether
	# AnyEvent::DNS happens to be installed in the current environment.
	# Without this stub, the parallel path fires real DNS queries when the
	# module is installed, violating the no-network rule.
	null_net();
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_parallel_resolve_hosts = sub {};
	local *Email::Abuse::Investigator::_resolve_host = sub { '1.2.3.4' };
	local *Email::Abuse::Investigator::_whois_ip	 = sub { { org=>'T', abuse=>'a@b' } };

	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email("From: x\@y.com\n\n"
		. 'https://anyevent-test1.example/a https://anyevent-test2.example/b');
	my @urls;
	lives_ok { @urls = $a->embedded_urls() }
		'embedded_urls does not die without AnyEvent::DNS';
	is scalar @urls, 2, 'both URLs extracted via sequential fallback';
	restore_net();
};

# 25. IO::Socket::IP fallback
subtest '_raw_whois -- does not die regardless of IO::Socket::IP availability' => sub {
	# In a test environment _raw_whois will fail to connect (no live WHOIS server)
	# but must not die; it should return undef gracefully.
	my $a = new_ok('Email::Abuse::Investigator', [timeout => 1]);
	my $result;
	lives_ok { $result = $a->_raw_whois('test.example', 'whois.iana.org') }
		'_raw_whois does not die';
	ok !defined($result) || length($result) > 0,
		'_raw_whois returns undef or non-empty string (network-dependent)';
};


# =============================================================================
# 26. _parse_rfc2822_date -- RFC 2822 DATE FORMAT BOUNDARY CASES
# =============================================================================
# _parse_rfc2822_date is a plain package function (no $self), not a method.
# Tests verify the RFC 2822 date regex and Time::Local bridge.

subtest '_parse_rfc2822_date -- full RFC 2822 date string' => sub {
	my $fn = \&Email::Abuse::Investigator::_parse_rfc2822_date;
	my $e = $fn->('15 Jan 2024 12:00:00 +0000');
	ok defined($e) && $e > 0, 'full RFC 2822 date parses to positive epoch';
};

subtest '_parse_rfc2822_date -- optional day-of-week prefix' => sub {
	my $fn = \&Email::Abuse::Investigator::_parse_rfc2822_date;
	my $e1 = $fn->('Mon, 15 Jan 2024 12:00:00 +0000');
	my $e2 = $fn->('15 Jan 2024 12:00:00 +0000');
	ok defined($e1), 'day-of-week prefix: parses';
	ok defined($e2), 'no day-of-week prefix: parses';
	is $e1, $e2, 'same epoch regardless of day-of-week prefix';
};

subtest '_parse_rfc2822_date -- single-digit day' => sub {
	my $fn = \&Email::Abuse::Investigator::_parse_rfc2822_date;
	ok defined($fn->('1 Jan 2024 00:00:00 +0000')),
		'single-digit day ("1 Jan") parses';
	ok defined($fn->('01 Jan 2024 00:00:00 +0000')),
		'zero-padded day ("01 Jan") parses';
};

subtest '_parse_rfc2822_date -- case-insensitive month abbreviation' => sub {
	my $fn = \&Email::Abuse::Investigator::_parse_rfc2822_date;
	ok defined($fn->('1 JAN 2024 00:00:00 +0000')), 'uppercase JAN parses';
	ok defined($fn->('1 jan 2024 00:00:00 +0000')), 'lowercase jan parses';
	ok defined($fn->('1 Jan 2024 00:00:00 +0000')), 'mixed-case Jan parses';
};

subtest '_parse_rfc2822_date -- timezone offset ignored: same epoch' => sub {
	my $fn = \&Email::Abuse::Investigator::_parse_rfc2822_date;
	my $utc  = $fn->('15 Jan 2024 12:00:00 +0000');
	my $east = $fn->('15 Jan 2024 12:00:00 +0500');
	my $west = $fn->('15 Jan 2024 12:00:00 -0800');
	ok defined($utc),  '+0000 parses';
	ok defined($east), '+0500 parses';
	ok defined($west), '-0800 parses';
	# The parser ignores timezone, so all three resolve to the same epoch
	is $utc, $east, '+0500 and +0000 yield same epoch (TZ ignored)';
	is $utc, $west, '-0800 and +0000 yield same epoch (TZ ignored)';
};

subtest '_parse_rfc2822_date -- bogus string returns undef' => sub {
	my $fn = \&Email::Abuse::Investigator::_parse_rfc2822_date;
	is $fn->('not a date at all'),	undef, 'garbage string: undef';
	is $fn->('2024-01-15'),		   undef, 'ISO date without time: undef';
	is $fn->(''),				     undef, 'empty string: undef';
};

subtest '_parse_rfc2822_date -- all twelve months parse correctly' => sub {
	my $fn = \&Email::Abuse::Investigator::_parse_rfc2822_date;
	for my $mon (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)) {
		ok defined($fn->("15 $mon 2024 00:00:00 +0000")),
			"month $mon parses";
	}
};

# =============================================================================
# 27. _country_name -- FULL TABLE AND FALLBACK
# =============================================================================
# _country_name is a plain package function; returns human name or code as-is.

subtest '_country_name -- known spam-country codes return full names' => sub {
	my $fn = \&Email::Abuse::Investigator::_country_name;
	is $fn->('CN'), 'China',	  'CN -> China';
	is $fn->('RU'), 'Russia',	 'RU -> Russia';
	is $fn->('NG'), 'Nigeria',	'NG -> Nigeria';
	is $fn->('VN'), 'Vietnam',	'VN -> Vietnam';
	is $fn->('IN'), 'India',	  'IN -> India';
	is $fn->('PK'), 'Pakistan',   'PK -> Pakistan';
	is $fn->('BD'), 'Bangladesh', 'BD -> Bangladesh';
};

subtest '_country_name -- unknown code returned as-is' => sub {
	my $fn = \&Email::Abuse::Investigator::_country_name;
	is $fn->('ZZ'), 'ZZ', 'unknown ZZ returned as-is';
	is $fn->('GB'), 'GB', 'GB (not in table) returned as-is';
	is $fn->('US'), 'US', 'US (not in table) returned as-is';
};

# =============================================================================
# 28. parse_email -- HOSTILE REFERENCE TYPES CAUSE CROAK
# =============================================================================
# The module croaks on any reference type other than SCALAR (e.g., ARRAY, CODE,
# GLOB, REF).  Hashref is consumed as empty named-params (undef text -> ok).

subtest 'parse_email -- CODE ref causes croak' => sub {
	my $a = Email::Abuse::Investigator->new();
	eval { $a->parse_email(sub { 'evil' }) };
	like $@, qr/parse_email.*string/i, 'CODE ref causes croak';
};

subtest 'parse_email -- ARRAY ref causes croak' => sub {
	my $a = Email::Abuse::Investigator->new();
	eval { $a->parse_email(['item1', 'item2']) };
	like $@, qr/parse_email.*string/i, 'ARRAY ref causes croak';
};

subtest 'parse_email -- REF-to-hashref silently treated as empty named-params' => sub {
	# Params::Get unwraps REF -> HASH and treats it as named-params (no 'text'
	# key) -> text=undef -> silent empty parse, same as parse_email({}).
	# This is an inherited Params::Get behaviour, not a module bug.
	null_net();
	my $a = Email::Abuse::Investigator->new();
	my $inner = {};
	lives_ok { $a->parse_email(\$inner) }
		'REF-to-hashref silently consumed as empty named-params (no croak)';
	is $a->originating_ip(), undef, 'REF-to-hashref: no origin (empty parse)';
	restore_net();
};

subtest 'parse_email -- GLOB ref causes an error (any kind)' => sub {
	# Params::Get raises its own Usage error before the module croak check,
	# so the error text is Params::Get-originated, not parse_email-originated.
	my $a = Email::Abuse::Investigator->new();
	eval { $a->parse_email(\*STDIN) };
	ok $@, 'GLOB ref causes some error';
	like $@, qr/Usage:/i, 'GLOB ref causes Params::Get Usage error';
};

subtest 'parse_email -- undef does NOT croak (treated as empty email)' => sub {
	null_net();
	my $a = Email::Abuse::Investigator->new();
	lives_ok { $a->parse_email(undef) } 'undef does not croak';
	is $a->originating_ip(), undef, 'undef email: no origin';
	restore_net();
};

# =============================================================================
# 29. PUBLIC METHODS WITHOUT PRIOR parse_email
# =============================================================================
# A freshly constructed object has safe initial state; all public methods
# should return empty/undef results without dying.

subtest 'public methods before parse_email -- all return safely' => sub {
	null_net();
	my $a = Email::Abuse::Investigator->new();
	# No parse_email called
	lives_ok { $a->originating_ip()        } 'originating_ip without parse_email';
	lives_ok { [$a->embedded_urls()]       } 'embedded_urls without parse_email';
	lives_ok { [$a->mailto_domains()]      } 'mailto_domains without parse_email';
	lives_ok { [$a->all_domains()]         } 'all_domains without parse_email';
	lives_ok { [$a->abuse_contacts()]      } 'abuse_contacts without parse_email';
	lives_ok { [$a->form_contacts()]       } 'form_contacts without parse_email';
	lives_ok { [$a->sending_software()]    } 'sending_software without parse_email';
	lives_ok { [$a->received_trail()]      } 'received_trail without parse_email';
	lives_ok { $a->risk_assessment()       } 'risk_assessment without parse_email';
	lives_ok { $a->report()               } 'report() without parse_email';
	lives_ok { $a->abuse_report_text()    } 'abuse_report_text without parse_email';
	lives_ok { $a->header_value('from')   } 'header_value without parse_email';
	lives_ok { [$a->unresolved_contacts()] } 'unresolved_contacts without parse_email';

	is $a->originating_ip(),        undef, 'originating_ip returns undef';
	is scalar($a->embedded_urls()),  0,    'embedded_urls returns empty list';
	is scalar($a->mailto_domains()), 0,    'mailto_domains returns empty list';
	is scalar($a->all_domains()),    0,    'all_domains returns empty list';
	is $a->header_value('from'),    undef, 'header_value returns undef';
	restore_net();
};

# =============================================================================
# 30. SECURITY -- NON-HTTP SCHEMES NOT EXTRACTED
# =============================================================================
# Only http:// and https:// URLs should be extracted.  Dangerous schemes like
# javascript:, data:, ftp:, and file: must not appear in embedded_urls().

subtest 'embedded_urls -- javascript: scheme not extracted' => sub {
	null_net();
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("From: x\@y.com\n\nClick javascript:alert(1) for more info");
	my @urls = $a->embedded_urls();
	ok !scalar(grep { $_->{url} =~ /^javascript:/i } @urls),
		'javascript: scheme not extracted';
	restore_net();
};

subtest 'embedded_urls -- data: scheme not extracted' => sub {
	null_net();
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("From: x\@y.com\n\ndata:text/html,<h1>XSS</h1> is nasty");
	my @urls = $a->embedded_urls();
	ok !scalar(grep { $_->{url} =~ /^data:/i } @urls),
		'data: scheme not extracted';
	restore_net();
};

subtest 'embedded_urls -- ftp: scheme not extracted' => sub {
	null_net();
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("From: x\@y.com\n\nftp://ftp.example.com/file.txt");
	my @urls = $a->embedded_urls();
	ok !scalar(grep { $_->{url} =~ /^ftp:/i } @urls),
		'ftp: scheme not extracted (only http/https)';
	restore_net();
};

subtest 'embedded_urls -- file: scheme not extracted' => sub {
	null_net();
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("From: x\@y.com\n\nfile:///etc/passwd is a common target");
	my @urls = $a->embedded_urls();
	ok !scalar(grep { $_->{url} =~ /^file:/i } @urls),
		'file: scheme not extracted';
	restore_net();
};

# =============================================================================
# 31. SECURITY -- CRLF INJECTION IN HEADER DATA FLOWING TO REPORT
# =============================================================================
# The From: and Subject: headers may contain attacker-controlled data.
# CR/LF sequences are sanitised by parse_email before storage, and
# _sanitise_output strips any C0 controls from report output.

subtest 'NUL in Subject: -- stripped from report output' => sub {
	null_net();
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("From: x\@y.com\nSubject: Normal\x00Subject\n\nbody");
	my $report = $a->report();
	ok $report !~ /\x00/, 'NUL bytes absent from report output';
	restore_net();
};

subtest 'ESC and C0 controls in From: -- stripped from report output' => sub {
	null_net();
	my $a = Email::Abuse::Investigator->new();
	# ESC sequences could confuse terminal emulators and ANSI parsers.
	$a->parse_email("From: evil\x1B[31mred\x1B[0m\@bad.example\n\nbody");
	my $report = $a->report();
	ok $report !~ /\x1B/, 'ESC sequences absent from report output';
	restore_net();
};

subtest 'SOH/BEL/BS in Subject: -- stripped from report output' => sub {
	null_net();
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("From: x\@y.com\nSubject: bad\x01\x07\x08chars\n\nbody");
	my $report = $a->report();
	ok $report !~ /[\x01\x07\x08]/, 'SOH/BEL/BS stripped from report';
	restore_net();
};

# =============================================================================
# 32. header_value() -- COMPREHENSIVE CASE INSENSITIVITY AND EDGE CASES
# =============================================================================

subtest 'header_value -- case-insensitive lookup' => sub {
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("From: user\@example.com\nSubject: Test subject\n\nbody");
	is $a->header_value('from'),    'user@example.com', 'lowercase name works';
	is $a->header_value('FROM'),    'user@example.com', 'uppercase name works';
	is $a->header_value('From'),    'user@example.com', 'mixed-case name works';
	is $a->header_value('subject'), 'Test subject',     'subject lowercase';
	is $a->header_value('SUBJECT'), 'Test subject',     'subject uppercase';
};

subtest 'header_value -- nonexistent header returns undef' => sub {
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("From: x\@y.com\n\nbody");
	is $a->header_value('x-nonexistent-header'), undef,
		'missing header returns undef';
};

subtest 'header_value -- standard headers accessible by name' => sub {
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(
		"From: sender\@a.example\n"
	  . "To: rcpt\@b.example\n"
	  . "Reply-To: reply\@c.example\n"
	  . "Message-ID: <abc123\@mail.example>\n"
	  . "Return-Path: <bounce\@a.example>\n"
	  . "\nbody");
	is $a->header_value('to'),          'rcpt@b.example',        'To: accessible';
	is $a->header_value('reply-to'),    'reply@c.example',       'Reply-To: accessible';
	is $a->header_value('message-id'),  '<abc123@mail.example>', 'Message-ID: accessible';
	is $a->header_value('return-path'), '<bounce@a.example>',    'Return-Path: accessible';
};

# =============================================================================
# 33. sending_software() -- HEADER FINGERPRINTS
# =============================================================================
# All six SW-fingerprint headers must be detected and returned.

subtest 'sending_software -- X-PHP-Originating-Script fingerprint' => sub {
	null_net();
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(
		"From: x\@y.com\n"
	  . "X-PHP-Originating-Script: 1000:mailer.php\n"
	  . "\nbody");
	my @sw = $a->sending_software();
	ok scalar @sw >= 1, 'at least one SW entry detected';
	ok scalar(grep { $_->{header} eq 'x-php-originating-script' } @sw),
		'X-PHP-Originating-Script header captured';
	restore_net();
};

subtest 'sending_software -- X-Mailer fingerprint' => sub {
	null_net();
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(
		"From: x\@y.com\n"
	  . "X-Mailer: BulkMailer Pro 2.1\n"
	  . "\nbody");
	my @sw = $a->sending_software();
	ok scalar(grep { $_->{header} eq 'x-mailer' } @sw),
		'X-Mailer header captured';
	is $sw[0]{value}, 'BulkMailer Pro 2.1', 'X-Mailer value preserved';
	restore_net();
};

subtest 'sending_software -- multiple SW headers all returned' => sub {
	null_net();
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(
		"From: x\@y.com\n"
	  . "X-Mailer: SpamSend 1.0\n"
	  . "X-PHP-Originating-Script: 999:spam.php\n"
	  . "X-Source: /var/www/script.php\n"
	  . "\nbody");
	my @sw = $a->sending_software();
	my %headers = map { $_->{header} => 1 } @sw;
	ok $headers{'x-mailer'},                   'X-Mailer in results';
	ok $headers{'x-php-originating-script'},   'X-PHP-Originating-Script in results';
	ok $headers{'x-source'},                   'X-Source in results';
	restore_net();
};

subtest 'sending_software -- absent SW headers: empty list' => sub {
	null_net();
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("From: x\@y.com\nSubject: plain\n\nbody");
	my @sw = $a->sending_software();
	is scalar @sw, 0, 'no SW headers: empty list returned';
	restore_net();
};

# =============================================================================
# 34. received_trail() -- RFC 1918 IPs INCLUDED AND OLDEST-FIRST ORDERING
# =============================================================================
# received_trail() is NOT filtered like originating_ip().  Private IPs appear
# in the trail.  Entries are in oldest-first order (reversed from message).

subtest 'received_trail -- RFC 1918 IPs included (not filtered)' => sub {
	null_net();
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(
		"Received: from mx (mx [10.0.0.1]) by final id ABC\n"
	  . "Received: from h (h [91.198.174.1]) by mx id DEF\n"
	  . "From: x\@y.com\n\nbody");
	my @trail = $a->received_trail();
	ok scalar @trail >= 2, 'both hops in trail';
	my @ips = map { $_->{ip} // '' } @trail;
	ok scalar(grep { $_ eq '10.0.0.1' } @ips),
		'RFC 1918 IP 10.0.0.1 included in trail';
	ok scalar(grep { $_ eq '91.198.174.1' } @ips),
		'public IP 91.198.174.1 included in trail';
	restore_net();
};

subtest 'received_trail -- oldest-first ordering' => sub {
	null_net();
	my $a = Email::Abuse::Investigator->new();
	# Received: headers in raw message are newest-first;
	# received_trail() reverses to oldest-first.
	$a->parse_email(
		"Received: from newest (newest [91.198.174.3]) by final id C\n"
	  . "Received: from middle (middle [91.198.174.2]) by relay id B\n"
	  . "Received: from oldest (oldest [91.198.174.1]) by origin id A\n"
	  . "From: x\@y.com\n\nbody");
	my @trail = $a->received_trail();
	is scalar @trail, 3, 'all three hops captured';
	is $trail[0]{ip}, '91.198.174.1', 'first entry is oldest hop';
	is $trail[2]{ip}, '91.198.174.3', 'last entry is newest hop';
	restore_net();
};

subtest 'received_trail -- for= and id= fields extracted' => sub {
	null_net();
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(
		"Received: from smtp (smtp [91.198.174.1]) by mx"
	  . " for <victim\@domain.example> id MSG-ABC\n"
	  . "From: x\@y.com\n\nbody");
	my @trail = $a->received_trail();
	ok scalar @trail >= 1, 'trail non-empty';
	is $trail[0]{for}, 'victim@domain.example', 'for= field extracted';
	is $trail[0]{id},  'MSG-ABC',               'id= field extracted';
	restore_net();
};

# =============================================================================
# 35. CONTEXT ABUSE -- SCALAR VS LIST CONTEXT
# =============================================================================
# Methods returning lists must behave predictably in scalar context.
# The module does not document scalar-context semantics, but must not die.

subtest 'list methods in scalar context -- all survive without dying' => sub {
	null_net();
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("From: x\@y.com\n\nhttps://spam.example/page");
	my $n_urls  = do { my @x = $a->embedded_urls();    scalar @x };
	my $n_mdom  = do { my @x = $a->mailto_domains();   scalar @x };
	my $n_adom  = do { my @x = $a->all_domains();      scalar @x };
	my $n_abuse = do { my @x = $a->abuse_contacts();   scalar @x };
	my $n_form  = do { my @x = $a->form_contacts();    scalar @x };
	my $n_sw    = do { my @x = $a->sending_software(); scalar @x };
	my $n_trail = do { my @x = $a->received_trail();   scalar @x };
	ok defined($n_urls),  'embedded_urls scalar context: defined';
	ok defined($n_mdom),  'mailto_domains scalar context: defined';
	ok defined($n_adom),  'all_domains scalar context: defined';
	ok defined($n_abuse), 'abuse_contacts scalar context: defined';
	ok defined($n_form),  'form_contacts scalar context: defined';
	ok defined($n_sw),    'sending_software scalar context: defined';
	ok defined($n_trail), 'received_trail scalar context: defined';
	restore_net();
};

# =============================================================================
# 36. _parse_whois_text -- INJECTION SAFETY
# =============================================================================
# WHOIS responses are external data.  Embedded CR/LF, shell metacharacters,
# and HTML special chars must survive safely without code execution or
# field injection into the parsed result.

subtest '_parse_whois_text -- shell metacharacters in org name passed through' => sub {
	my $a = Email::Abuse::Investigator->new();
	my $evil_org = 'Acme; rm -rf / | cat /etc/passwd `whoami`';
	my $r = $a->_parse_whois_text("OrgName: $evil_org\n");
	is $r->{org}, $evil_org,
		'shell metacharacters in org name passed through safely (no exec)';
};

subtest '_parse_whois_text -- HTML special chars in org name passed through' => sub {
	my $a = Email::Abuse::Investigator->new();
	my $html_org = 'Acme <script>alert(1)</script> & "Corp"';
	my $r = $a->_parse_whois_text("OrgName: $html_org\n");
	is $r->{org}, $html_org,
		'HTML special chars in org name unchanged (no HTML encoding at this level)';
};

subtest '_parse_whois_text -- 64 KB OrgName does not crash parser' => sub {
	my $a = Email::Abuse::Investigator->new();
	my $huge = 'X' x 65536;
	my $r;
	lives_ok { $r = $a->_parse_whois_text("OrgName: $huge\n") }
		'64 KB OrgName does not crash';
	ok defined $r, 'result defined after 64 KB OrgName';
};

subtest '_parse_whois_text -- CRLF embedded in block: second field still parsed' => sub {
	my $a = Email::Abuse::Investigator->new();
	# An attacker-controlled WHOIS server may embed CRLF to inject extra lines.
	# The second line should be parsed as a separate field, not smuggled into org.
	my $r = $a->_parse_whois_text(
		"OrgName: Evil Corp\r\nOrgAbuseEmail: abuse\@evil.example\r\n");
	like $r->{org}, qr/Evil Corp/, 'org name parsed despite CRLF line ending';
	ok defined($r->{abuse}), 'abuse email parsed from CRLF-terminated block';
};

# =============================================================================
# 37. all_domains() -- IDEMPOTENCY AND UNION PROPERTY
# =============================================================================

subtest 'all_domains -- same result on repeated calls (idempotent)' => sub {
	null_net();
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(
		"From: sender\@contact.example\n\n"
	  . "https://urlhost.example/page and email\@contact.example");
	my @d1 = $a->all_domains();
	my @d2 = $a->all_domains();
	is scalar @d1, scalar @d2, 'same count on repeated call';
	is_deeply [sort @d1], [sort @d2], 'same domains on repeated call';
	restore_net();
};

subtest 'all_domains -- every member comes from URL hosts or mailto domains' => sub {
	null_net();
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(
		"From: x\@mail-domain.example\n\n"
	  . "Visit https://url-host.example/path");
	my @all  = $a->all_domains();
	my @mdom = map { $_->{domain} } $a->mailto_domains();
	my @udom = map { $_->{host}   } $a->embedded_urls();
	my %union = map { $_ => 1 } @mdom, @udom;
	for my $d (@all) {
		ok exists($union{$d}),
			"all_domains member '$d' is from URL hosts or mailto domains";
	}
	restore_net();
};

subtest 'all_domains -- no duplicates when domain appears in both sources' => sub {
	null_net();
	my $a = Email::Abuse::Investigator->new();
	# Same domain in both From: (mailto) and body URL
	$a->parse_email(
		"From: x\@shared.example\n\n"
	  . "Visit https://shared.example/page");
	my @all = $a->all_domains();
	my %seen;
	my @dups = grep { $seen{$_}++ } @all;
	is scalar @dups, 0, 'no duplicate domains in all_domains()';
	restore_net();
};

# =============================================================================
# 38. parse_email CACHE INVALIDATION
# =============================================================================
# Calling parse_email() a second time must reset ALL per-message caches,
# including _contacts, _risk, _urls, _mailto_domains, and _auth_results.

subtest 'parse_email -- _contacts cache cleared on re-parse' => sub {
	null_net();
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("From: x\@y.com\n\nbody");
	$a->{_contacts} = ['STALE'];     # Manually poison the cache
	$a->parse_email("From: x\@y.com\n\nbody");  # Re-parse
	is $a->{_contacts}, undef, '_contacts invalidated by re-parse';
	restore_net();
};

subtest 'parse_email -- _risk cache cleared on re-parse' => sub {
	null_net();
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("From: x\@y.com\n\nbody");
	$a->{_risk} = { level => 'STALE', score => 999, flags => [] };
	$a->parse_email("From: x\@y.com\n\nbody");
	is $a->{_risk}, undef, '_risk invalidated by re-parse';
	restore_net();
};

subtest 'parse_email -- _auth_results cache cleared on re-parse' => sub {
	null_net();
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email(
		"Authentication-Results: mx; spf=fail\n"
	  . "From: x\@y.com\n\nbody");
	$a->parse_email("From: x\@y.com\n\nbody");  # Re-parse without auth header
	is $a->{_auth_results}, undef, '_auth_results invalidated by re-parse';
	restore_net();
};

# =============================================================================
# 39. risk_assessment -- SPARSE / EMPTY INTERNAL STATE HASHREFS
# =============================================================================
# If internal caches contain incomplete hashrefs (missing keys), risk_assessment
# must not die when attempting to access those keys.

subtest 'risk_assessment -- _origin={} (no ip/rdns) does not die' => sub {
	null_net();
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("From: x\@y.com\n\nbody");
	$a->{_origin}         = {};   # All keys absent
	$a->{_urls}           = [];
	$a->{_mailto_domains} = [];
	my $risk;
	lives_ok { $risk = $a->risk_assessment() }
		'risk_assessment with empty _origin hashref does not die';
	ok defined $risk, 'result defined with empty _origin';
	restore_net();
};

subtest 'risk_assessment -- _urls=[{}] (no host/ip) does not die' => sub {
	null_net();
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("From: x\@y.com\n\nbody");
	$a->{_origin}         = undef;
	$a->{_urls}           = [{}];  # URL entry with no keys
	$a->{_mailto_domains} = [];
	my $risk;
	lives_ok { $risk = $a->risk_assessment() }
		'risk_assessment with empty URL hashref does not die';
	restore_net();
};

subtest 'risk_assessment -- _mailto_domains=[{}] (no domain) does not die' => sub {
	null_net();
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("From: x\@y.com\n\nbody");
	$a->{_origin}         = undef;
	$a->{_urls}           = [];
	$a->{_mailto_domains} = [{}];  # Domain entry with no keys
	my $risk;
	lives_ok { $risk = $a->risk_assessment() }
		'risk_assessment with empty domain hashref does not die';
	restore_net();
};

# =============================================================================
# 40. unresolved_contacts() AND form_contacts() EDGE CASES
# =============================================================================

subtest 'unresolved_contacts -- empty object returns empty list' => sub {
	null_net();
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("From: x\@y.com\n\nbody");
	$a->{_origin}         = undef;
	$a->{_urls}           = [];
	$a->{_mailto_domains} = [];
	my @unres = $a->unresolved_contacts();
	is scalar @unres, 0, 'empty state: no unresolved contacts';
	restore_net();
};

subtest 'unresolved_contacts -- domain with no abuse contacts listed' => sub {
	null_net();
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("From: x\@y.com\n\nbody");
	$a->{_origin}         = undef;
	$a->{_urls}           = [];
	# Domain with no abuse-email fields at all
	$a->{_mailto_domains} = [{
		domain => 'nocontact.example',
		source => 'body',
	}];
	my @unres = $a->unresolved_contacts();
	ok scalar @unres >= 1, 'domain with no abuse email appears in unresolved list';
	ok scalar(grep { $_->{domain} eq 'nocontact.example' } @unres),
		'nocontact.example in unresolved list';
	restore_net();
};

subtest 'form_contacts -- empty object returns empty list' => sub {
	null_net();
	my $a = Email::Abuse::Investigator->new();
	$a->parse_email("From: x\@y.com\n\nbody");
	$a->{_origin}         = undef;
	$a->{_urls}           = [];
	$a->{_mailto_domains} = [];
	my @forms = $a->form_contacts();
	is scalar @forms, 0, 'empty state: no form contacts';
	restore_net();
};

done_testing();
