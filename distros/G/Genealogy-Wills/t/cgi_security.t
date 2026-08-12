#!perl

# Penetration test suite for Genealogy::Wills used as a CGI back-end.
#
# Simulates an attacker controlling HTTP inputs (QUERY_STRING, POST body,
# HTTP headers) that are parsed by a CGI wrapper and forwarded to this
# module's API. Each section names the exploit mechanism, the defence, and
# what failure looks like.
#
# Run:  prove -l t/cgi_security.t
#
# NOTE: this file uses a mock Genealogy::Wills::wills class defined in
# BEGIN so that no real SQLite database is required.

use strict;
use warnings;

use File::Temp qw(tempdir);
use Genealogy::Wills;
use Readonly;
use Scalar::Util qw(blessed);
use Time::HiRes qw(time);
use Test::Most;

# ---------------------------------------------------------------------------
# Weaponised payloads (named constants; no magic strings in test assertions)
# ---------------------------------------------------------------------------

Readonly my $SQL_INJECT_CLASSIC  => q{' OR '1'='1};
Readonly my $SQL_INJECT_DROP     => q{'; DROP TABLE wills; --};
Readonly my $SQL_INJECT_UNION    => q{' UNION SELECT 1,2,3,4,5,6 --};
Readonly my $SQL_INJECT_COMMENT  => q{Smith'--};
Readonly my $SQL_INJECT_TAUTOLOGY => q{1=1--};

Readonly my $SHELL_PIPE          => q{Smith|cat /etc/passwd};
Readonly my $SHELL_SEMI          => q{Smith;id};
Readonly my $SHELL_BACKTICK      => q{Smith`id`};
Readonly my $SHELL_DOLLAR        => q{Smith$(id)};

Readonly my $XSS_SCRIPT          => q{<script>alert(1)</script>};
Readonly my $XSS_IMG             => q{<img src=x onerror=alert(1)>};
Readonly my $XSS_JS_PROTO        => q{javascript:alert(1)};
Readonly my $XSS_ATTR_BREAK      => q{"><script>alert(1)</script>};

Readonly my $CRLF_COOKIE         => "Smith\r\nSet-Cookie: evil=1";
Readonly my $CRLF_REDIRECT       => "Smith\r\nLocation: http://evil.com/";

Readonly my $NULL_BYTE           => "Smith\x00/etc/passwd";
Readonly my $NULL_BYTE_ENCODED   => "Smith%00/etc/passwd";

Readonly my $PATH_TRAVERSAL      => '../../../etc/passwd';
Readonly my $PATH_TRAVERSAL_ABS  => '/etc/passwd';
Readonly my $PATH_TRAVERSAL_SYMLINK => '/proc/self/environ';

# Boundary values for length checks (last: min=1, max=100)
Readonly my $AT_MIN              => 'A';           # 1 char -- valid
Readonly my $AT_MAX              => 'A' x 100;     # 100 chars -- valid
Readonly my $ABOVE_MAX           => 'A' x 101;     # 101 chars -- invalid
Readonly my $MEGA_INPUT          => 'A' x 100_000; # 100k chars -- invalid (DoS probe)

# ReDoS candidate: valid chars up to position 50, then an invalid char.
# qr/^[\w\-]+$/ is O(n) with no catastrophic backtrack; this confirms it.
Readonly my $REDOS_CANDIDATE     => ('a' x 50) . '!';

# Unicode lookalike: Cyrillic small 'a' (U+0430).
# Without /a, Perl's \w matches Unicode \w, so this passes PVS -- a finding.
Readonly my $UNICODE_CYRILLIC_A  => "\x{0430}";

# ---------------------------------------------------------------------------
# Mock database layer
# Intercepts Genealogy::Wills::wills->new() so no real SQLite file is needed.
# The `selectall_hashref` and `fetchrow_hashref` stubs can be overridden
# locally in individual subtests to capture the exact params the module
# passes to the DB layer.
# ---------------------------------------------------------------------------

BEGIN {
	package Genealogy::Wills::wills;
	use strict;
	use warnings;
	sub new             { bless {}, shift }
	sub selectall_hashref { [] }
	sub fetchrow_hashref  { undef }
}

my $temp_dir = tempdir(CLEANUP => 1);
my $obj      = Genealogy::Wills->new(directory => $temp_dir);
ok(blessed($obj), 'sanity: test object created with temp directory');

# ---------------------------------------------------------------------------
# CGI helper: decode an application/x-www-form-urlencoded QUERY_STRING.
# Mirrors what a real CGI wrapper does before forwarding params to the module.
# ---------------------------------------------------------------------------

sub decode_qs {
	my $qs = shift // '';
	my %p;
	for my $pair (split /&/, $qs) {
		my ($k, $v) = split /=/, $pair, 2;
		$v //= '';
		$v =~ s/%([0-9A-Fa-f]{2})/chr hex $1/ge;
		$v =~ s/\+/ /g;
		$p{$k} = $v;
	}
	return %p;
}

# ===========================================================================
# SECTION 1 -- SQL injection via 'last'
#
# Exploit: attacker supplies ?last='; DROP TABLE wills; -- hoping the value
# is interpolated into a raw SQL string.
# Defence: PVS enforces matches => qr/^[\w\-]+$/ before any DB call;
# apostrophes, spaces, and semicolons are all outside that character class.
# ===========================================================================

subtest 'SQL injection via last (PVS matches must reject)' => sub {
	for my $payload (
		$SQL_INJECT_CLASSIC,
		$SQL_INJECT_DROP,
		$SQL_INJECT_UNION,
		$SQL_INJECT_COMMENT,
		$SQL_INJECT_TAUTOLOGY,
	) {
		dies_ok(
			sub { $obj->search(last => $payload) },
			"PVS blocks SQL injection in last: [" . substr($payload, 0, 40) . ']'
		);
	}
};

# ===========================================================================
# SECTION 2 -- Cross-site scripting via 'last'
#
# Exploit: attacker supplies ?last=<script>alert(1)</script> hoping the raw
# value is reflected in an HTML response generated by the CGI wrapper.
# Defence: PVS matches => qr/^[\w\-]+$/ rejects < > " ' and all other
# HTML metacharacters before the value reaches the DB or any output path.
# ===========================================================================

subtest 'XSS via last (PVS matches must reject)' => sub {
	for my $payload ($XSS_SCRIPT, $XSS_IMG, $XSS_JS_PROTO, $XSS_ATTR_BREAK) {
		dies_ok(
			sub { $obj->search(last => $payload) },
			"PVS blocks XSS in last: [" . substr($payload, 0, 40) . ']'
		);
	}
};

# ===========================================================================
# SECTION 3 -- Shell command injection via 'last'
#
# Exploit: attacker passes ?last=Smith|cat+/etc/passwd hoping the value
# eventually reaches system(), exec(), backticks, or open(FH, "$val |").
# Defence: | ; ` $() are all outside qr/^[\w\-]+$/ so PVS rejects them.
# Even if they reached the DB layer, the module performs no shell operations.
# ===========================================================================

subtest 'shell metacharacters in last (PVS matches must reject)' => sub {
	for my $payload ($SHELL_PIPE, $SHELL_SEMI, $SHELL_BACKTICK, $SHELL_DOLLAR) {
		dies_ok(
			sub { $obj->search(last => $payload) },
			"PVS blocks shell metachar in last: [" . substr($payload, 0, 40) . ']'
		);
	}
};

# ===========================================================================
# SECTION 4 -- CRLF header injection via 'last'
#
# Exploit: inject \r\n into a value that a CGI script writes into an HTTP
# header (e.g. a Set-Cookie or Location header built from search results).
# Defence: \r and \n are outside qr/^[\w\-]+$/ so PVS blocks them first.
# ===========================================================================

subtest 'CRLF injection via last (PVS must reject)' => sub {
	dies_ok(
		sub { $obj->search(last => $CRLF_COOKIE) },
		'CRLF Set-Cookie injection in last is rejected'
	);
	dies_ok(
		sub { $obj->search(last => $CRLF_REDIRECT) },
		'CRLF Location injection in last is rejected'
	);
};

# ===========================================================================
# SECTION 5 -- Null byte injection via 'last'
#
# Exploit: null bytes (\x00) can terminate C-level strings, causing a path
# like "Smith\x00/etc/passwd" to be seen as "Smith" by Perl but truncated
# to "/etc/passwd" by a C library function.
# Defence: \x00 is outside qr/^[\w\-]+$/ so PVS blocks it.
# ===========================================================================

subtest 'null byte injection via last (PVS must reject)' => sub {
	dies_ok(
		sub { $obj->search(last => $NULL_BYTE) },
		'null byte in last is rejected by PVS'
	);
	# URL-encoded form: the CGI layer decodes %00 to \x00 before PVS sees it
	local %ENV = (%ENV,
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => 'last=Smith%00%2Fetc%2Fpasswd',
	);
	my %cgi = decode_qs($ENV{QUERY_STRING});
	dies_ok(
		sub { $obj->search(%cgi) },
		'URL-decoded null byte from QUERY_STRING is rejected by PVS'
	);
};

# ===========================================================================
# SECTION 6 -- Input length boundary tests on 'last'
#
# Exploit: oversized input to exhaust memory, crash the process, or slow a
# regex to O(2^n) (ReDoS). PVS max => 100 must truncate the attack surface.
# ===========================================================================

subtest 'last name length boundaries (PVS min/max)' => sub {
	# min boundary: 1 char -- must be accepted
	lives_ok(
		sub { my @r = $obj->search(last => $AT_MIN) },
		'last="A" (1 char, min boundary) accepted'
	);
	# max boundary: 100 chars -- must be accepted
	lives_ok(
		sub { my @r = $obj->search(last => $AT_MAX) },
		'last=100-char string (max boundary) accepted'
	);
	# above max: 101 chars -- PVS must reject
	dies_ok(
		sub { $obj->search(last => $ABOVE_MAX) },
		'last=101-char string (above max) rejected by PVS'
	);
	# DoS probe: 100k-char payload -- PVS must reject early (not iterate)
	dies_ok(
		sub { $obj->search(last => $MEGA_INPUT) },
		'last=100k-char DoS payload rejected by PVS'
	);
};

# ===========================================================================
# SECTION 7 -- Type confusion via 'last'
#
# Exploit: pass a reference (arrayref, hashref, coderef) instead of a string,
# hoping to trigger a prototype confusion or data-structure leak.
# Defence: PVS type => 'string' must reject any non-scalar.
# ===========================================================================

subtest 'type confusion in last (PVS type => string must reject refs)' => sub {
	dies_ok(sub { $obj->search(last => []) },   'arrayref for last is rejected');
	dies_ok(sub { $obj->search(last => {}) },   'hashref for last is rejected');
	dies_ok(sub { $obj->search(last => \1) },   'scalarref for last is rejected');
	dies_ok(sub { $obj->search(last => sub{}) },'coderef for last is rejected');
};

# ===========================================================================
# SECTION 8 -- CGI QUERY_STRING simulation (URL-encoded payloads)
#
# Exploit: attacker sends a crafted HTTP GET request; the CGI wrapper
# URL-decodes QUERY_STRING and passes the results directly to search().
# The decoded values must still be blocked by PVS.
# ===========================================================================

subtest 'CGI QUERY_STRING injection (URL-encoded payloads)' => sub {
	# SQL injection: "' OR '1'='1" URL-encoded
	{
		local %ENV = (%ENV,
			REQUEST_METHOD => 'GET',
			QUERY_STRING   => q{last=%27+OR+%271%27%3D%271},
		);
		my %p = decode_qs($ENV{QUERY_STRING});
		dies_ok(
			sub { $obj->search(%p) },
			'URL-decoded SQL injection from QUERY_STRING rejected by PVS'
		);
	}

	# XSS: "<script>alert(1)</script>" URL-encoded
	{
		local %ENV = (%ENV,
			REQUEST_METHOD => 'GET',
			QUERY_STRING   => q{last=%3Cscript%3Ealert%281%29%3C%2Fscript%3E},
		);
		my %p = decode_qs($ENV{QUERY_STRING});
		dies_ok(
			sub { $obj->search(%p) },
			'URL-decoded XSS from QUERY_STRING rejected by PVS'
		);
	}

	# Shell: "Smith|id" URL-encoded
	{
		local %ENV = (%ENV,
			REQUEST_METHOD => 'GET',
			QUERY_STRING   => q{last=Smith%7Cid},
		);
		my %p = decode_qs($ENV{QUERY_STRING});
		dies_ok(
			sub { $obj->search(%p) },
			'URL-decoded shell pipe from QUERY_STRING rejected by PVS'
		);
	}
};

# ===========================================================================
# SECTION 9 -- POST body simulation (hostile application/x-www-form-urlencoded)
#
# Exploit: attacker sends weaponised POST body; CGI wrapper reads STDIN,
# URL-decodes, and passes to search(). The module never reads STDIN itself --
# this tests the CGI-layer decode -> module-call path end-to-end.
# ===========================================================================

subtest 'POST body simulation (in-memory STDIN)' => sub {
	my $body = q{last=%27%3B+DROP+TABLE+wills%3B+--&year=1750};
	open(my $fake_stdin, '<', \$body) or die "in-memory open failed: $!";

	local %ENV = (%ENV,
		REQUEST_METHOD => 'POST',
		CONTENT_TYPE   => 'application/x-www-form-urlencoded',
		CONTENT_LENGTH => length($body),
	);

	read($fake_stdin, my $raw, $ENV{CONTENT_LENGTH});
	close($fake_stdin);

	my %post = decode_qs($raw);
	# After decode: last => "'; DROP TABLE wills; --"
	dies_ok(
		sub { $obj->search(%post) },
		'URL-decoded POST body SQL injection rejected by PVS'
	);
};

# ===========================================================================
# SECTION 10 -- SQL injection via optional fields (first, middle, town)
#
# FINDING 1 APPLIED: matches constraints added to first, middle, town:
#   first/middle: qr/^[\w '.-]+\z/   (word, space, apostrophe, period, hyphen)
#   town:         qr/^[\w ',.-]+\z/  (same + comma for "Town, County, Country")
#
# SQL metacharacters outside those classes (=, ;, <, >, |, \r, \n, \0)
# are now rejected by PVS before any data reaches the database layer.
#
# Primary SQL injection defence remains parameterised queries
# (Database::Abstraction). The matches constraint is defence-in-depth.
#
# Residual surface: Smith'-- contains only apostrophe + hyphens (valid in
# names) and passes the constraint, but is neutralised by parameterised
# queries -- the value is bound as a literal, never interpolated into SQL.
# ===========================================================================

subtest 'SQL injection via optional fields (matches constraint now rejects)' => sub {
	# 'first': = sign is outside qr/^[\w '.-]+\z/
	dies_ok(
		sub { $obj->search(last => 'Smith', first => $SQL_INJECT_CLASSIC) },
		"SQL injection (= in first) rejected by PVS matches constraint"
	);

	# 'town': ; is outside qr/^[\w ',.-]+\z/
	dies_ok(
		sub { $obj->search(last => 'Smith', town => $SQL_INJECT_DROP) },
		"SQL injection (; in town) rejected by PVS matches constraint"
	);

	# 'middle': , is outside qr/^[\w '.-]+\z/ (comma not allowed in name fields)
	dies_ok(
		sub { $obj->search(last => 'Smith', middle => $SQL_INJECT_UNION) },
		"SQL injection (, in middle) rejected by PVS matches constraint"
	);

	# Positive: legitimate name values that contain apostrophes/commas/periods
	# must still be accepted -- the constraint must not over-reject valid data.
	{
		no warnings 'redefine';
		local *Genealogy::Wills::wills::selectall_hashref = sub { [] };

		lives_ok(
			sub { my @r = $obj->search(last => 'Smith', first  => "O'Brien") },
			"first with apostrophe (O'Brien) accepted by matches"
		);
		lives_ok(
			sub { my @r = $obj->search(last => 'Jones', town   => 'Canterbury, Kent, England') },
			"town with comma and space accepted by matches"
		);
		lives_ok(
			sub { my @r = $obj->search(last => 'Smith', middle => 'St. John') },
			"middle with period and space accepted by matches"
		);
	}

	note(
		"FINDING 1 APPLIED: first/middle/town now reject SQL metacharacters via PVS.\n" .
		"Residual: Smith'-- passes (apostrophe + hyphens are valid name chars) " .
		"but is neutralised by parameterised queries."
	);
};

# ===========================================================================
# SECTION 11 -- Oversized first, middle, town (PVS max => 100)
#
# Exploit: DoS via very long optional field values.
# Defence: PVS max => 100 on all string fields must reject 101+ chars.
# ===========================================================================

subtest 'oversized optional fields (PVS max => 100 must reject)' => sub {
	dies_ok(
		sub { $obj->search(last => 'Smith', first  => $ABOVE_MAX) },
		'101-char first rejected by PVS'
	);
	dies_ok(
		sub { $obj->search(last => 'Smith', middle => $ABOVE_MAX) },
		'101-char middle rejected by PVS'
	);
	dies_ok(
		sub { $obj->search(last => 'Smith', town   => $ABOVE_MAX) },
		'101-char town rejected by PVS'
	);
};

# ===========================================================================
# SECTION 12 -- Year field injection
#
# PVS enforces type => 'integer', min => 1, max => MAX_WILL_YEAR.
# Any non-integer or out-of-range value must be rejected before DB access.
# ===========================================================================

subtest 'year field injection (PVS integer + range)' => sub {
	my $max_year = (localtime)[5] + 1900;

	# SQL injection string -- fails PVS integer type check
	dies_ok(
		sub { $obj->search(last => 'Smith', year => "1750; DROP TABLE wills; --") },
		'SQL injection in year rejected (not an integer)'
	);
	# XSS -- fails PVS integer type
	dies_ok(
		sub { $obj->search(last => 'Smith', year => $XSS_SCRIPT) },
		'XSS in year rejected (not an integer)'
	);
	# Negative -- fails PVS min => 1
	dies_ok(
		sub { $obj->search(last => 'Smith', year => -1) },
		'negative year rejected by PVS min'
	);
	# Zero -- fails PVS min => 1
	dies_ok(
		sub { $obj->search(last => 'Smith', year => 0) },
		'year=0 rejected by PVS min => 1'
	);
	# Float -- fails PVS integer type
	dies_ok(
		sub { $obj->search(last => 'Smith', year => 1750.9) },
		'float year rejected by PVS integer type'
	);
	# Above max -- fails PVS max => MAX_WILL_YEAR
	dies_ok(
		sub { $obj->search(last => 'Smith', year => $max_year + 1) },
		'year above MAX_WILL_YEAR rejected by PVS'
	);
	# Min and max boundaries -- both must be accepted
	lives_ok(
		sub { my @r = $obj->search(last => 'Smith', year => 1) },
		'year=1 (min boundary) accepted'
	);
	lives_ok(
		sub { my @r = $obj->search(last => 'Smith', year => $max_year) },
		'year=MAX_WILL_YEAR (max boundary) accepted'
	);
};

# ===========================================================================
# SECTION 13 -- Path traversal via 'directory' in new()
#
# Exploit: attacker supplies a crafted directory path to read outside the
# data directory -- e.g. "../../etc" or pointing at a file, not a directory.
# Defence: new() checks -d $path && -r _ (cached stat). A file path fails
# -d; a traversal path that doesn't exist also fails -d. Both produce carp
# + undef return, never a croak (constructor does not die on this path).
# ===========================================================================

subtest 'path traversal via directory in new()' => sub {
	# /etc/passwd is a file, not a directory -- -d returns false
	{
		my $r;
		warning_like {
			$r = Genealogy::Wills->new(directory => $PATH_TRAVERSAL_ABS);
		} qr/is not a directory/, '/etc/passwd rejected as directory (file, not dir)';
		ok(!defined($r), 'new() returns undef for file path');
	}

	# Relative traversal string: ../../../etc/passwd -- path does not exist as a dir
	{
		my $r;
		warning_like {
			$r = Genealogy::Wills->new(directory => $PATH_TRAVERSAL);
		} qr/is not a directory/, 'relative traversal path rejected';
		ok(!defined($r), 'new() returns undef for traversal path');
	}

	# Null byte in directory -- Perl emits "Invalid \0 in pathname" AND our carp.
	# Two warnings fire; capture them all and verify the object is not returned.
	{
		my @warns;
		local $SIG{__WARN__} = sub { push @warns, @_ };
		my $r = Genealogy::Wills->new(directory => "/tmp/wills\x00evil");
		ok(!defined($r), 'null byte in directory does not produce a usable object');
		ok((grep { /is not a directory/i } @warns),
			'directory carp warning was issued for null-byte path');
	}

	# /proc/self/environ -- a file on Linux, not a directory
	if(-e $PATH_TRAVERSAL_SYMLINK && !-d $PATH_TRAVERSAL_SYMLINK) {
		my $r;
		warning_like {
			$r = Genealogy::Wills->new(directory => $PATH_TRAVERSAL_SYMLINK);
		} qr/is not a directory/, '/proc/self/environ rejected as directory';
		ok(!defined($r), 'new() returns undef for /proc/self/environ path');
	}
};

# ===========================================================================
# SECTION 14 -- Malicious config_file (SSRF / file disclosure via YAML parser)
#
# Exploit: attacker passes config_file => '/etc/passwd' hoping Object::Configure
# parses it as YAML and leaks its contents, or that a YAML bomb causes DoS.
# Defence layer 1: new() checks -r $path and croaks if it does not exist.
# Defence layer 2: /etc/passwd is readable but contains no Genealogy__Wills
# YAML key, so Object::Configure returns an empty config (safe).
# An attacker-controlled YAML bomb (e.g. deeply nested aliases) is the
# primary remaining risk; that is an Object::Configure concern, not ours.
# ===========================================================================

subtest 'malicious config_file in new()' => sub {
	# Non-existent file -- must croak immediately (never reaches YAML parser)
	throws_ok(
		sub { Genealogy::Wills->new(config_file => '/does/not/exist/attacker.yml') },
		qr/Can't load configuration from/,
		'non-existent config_file causes immediate croak (safe-fail)'
	);

	# /dev/null -- readable, no valid YAML, must not crash
	{
		my $r;
		lives_ok(
			sub { $r = Genealogy::Wills->new(config_file => '/dev/null') },
			'/dev/null as config_file does not crash'
		);
		ok(!defined($r) || blessed($r),
			'/dev/null config_file yields undef or a blessed object, never a half-constructed one');
	}
};

# ===========================================================================
# SECTION 15 -- Hostile logger object injection via new()
#
# Exploit: attacker passes a blessed object whose methods execute arbitrary
# code, or a plain string like 'system("id")', as the logger argument.
#
# DEFENCE (APPLIED FIX): The logger validation check runs BEFORE
# Object::Configure::configure() -- so a bad logger causes an immediate croak
# rather than being silently replaced.  This blocks injection of
# objects that lack info()/error() (including unblessed values) and surfaces
# a clear error to callers who supply an invalid logger.
#
# A trojan logger that DOES implement info()/error() passes the validation
# gate but is subsequently replaced by Object::Configure's own Log::Abstraction
# logger -- so exec_shell-style extra methods are never called via the module.
#
# Security outcome:
#   - Missing-interface loggers  → croak (caught early, no silent bypass)
#   - Valid-interface trojans    → accepted by validation, replaced by configure()
# ===========================================================================

subtest 'hostile logger injection via new()' => sub {
	# Bad logger (no info/error methods): croak fires BEFORE configure() can
	# replace it.  This is the corrected behaviour after the bug-fix that moved
	# the validation check before Object::Configure::configure().
	{
		my $bad = bless {}, 'MockBadLogger';
		throws_ok(
			sub { Genealogy::Wills->new(directory => $temp_dir, logger => $bad) },
			qr/Logger must be an object with info\(\) and error\(\)/,
			'bad logger (missing interface) causes an immediate croak'
		);
	}

	# Non-object scalar (e.g. 'system("id")') is not blessed -- croak fires.
	{
		throws_ok(
			sub { Genealogy::Wills->new(directory => $temp_dir, logger => 'system("id")') },
			qr/Logger must be an object with info\(\) and error\(\)/,
			'scalar string logger causes croak (not blessed)'
		);
	}

	# Trojan logger with a correct interface but a malicious extra method.
	# The validation gate passes (info + error present), but Object::Configure
	# then replaces the logger with its own -- so exec_shell is never called.
	# State is stored in the object (not a lexical-in-package) to avoid
	# the "variable not available" warning from nested package declarations.
	{
		my $trojan = bless { breach => 0, calls => 0 }, 'MockTrojanLogger';
		# no warnings 'once': each glob is assigned once intentionally
		no warnings 'once';
		*MockTrojanLogger::info       = sub { $_[0]->{calls}++ };
		*MockTrojanLogger::error      = sub { $_[0]->{calls}++ };
		*MockTrojanLogger::exec_shell = sub { $_[0]->{breach} = 1; die 'BREACH' };

		my $obj4;
		lives_ok(
			sub { $obj4 = Genealogy::Wills->new(directory => $temp_dir, logger => $trojan) },
			'trojan logger (valid interface) passes validation -- Object::Configure then replaces it'
		);
		is($trojan->{breach}, 0, 'exec_shell was NEVER invoked during new()');
		is($trojan->{calls},  0, 'info/error were NOT called during new()');
		ok(blessed($obj4->{logger}) && ref($obj4->{logger}) ne 'MockTrojanLogger',
			'stored logger is the Object::Configure replacement, NOT the trojan');
	}

	note(
		'SECURITY FINDING (updated): Bad-interface loggers now croak early (before configure). ' .
		'Valid-interface trojans pass validation but are replaced by Object::Configure. ' .
		'net result: exec_shell-style injection via logger is blocked on both paths.'
	);
};

# ===========================================================================
# SECTION 16 -- search() called as class method (blessed() guard)
#
# Exploit: attacker triggers Genealogy::Wills->search(last => 'Smith')
# hoping to bypass object-level encapsulation or cause a panic.
# Defence: first line of search() croaks unless blessed($self).
# ===========================================================================

subtest 'search() as class method is rejected' => sub {
	throws_ok(
		sub { Genealogy::Wills->search(last => 'Smith') },
		qr/search\(\) must be called on an object/,
		'class-method call to search() is immediately rejected'
	);
};

# ===========================================================================
# SECTION 17 -- search() with empty argument list
#
# Exploit: CGI script fails to validate QUERY_STRING and calls search()
# with no parameters, hoping to retrieve the full database contents.
# Defence: search() detects empty @_ and croaks with a Usage message.
# ===========================================================================

subtest 'search() with no arguments croaks with Usage message' => sub {
	throws_ok(
		sub { $obj->search() },
		qr/^Usage: search/,
		'empty argument list to search() is rejected before any DB access'
	);
};

# ===========================================================================
# SECTION 18 -- HTTP header injection (module is not the target; CGI layer is)
#
# Exploit: attacker crafts hostile HTTP headers (User-Agent, Cookie, Referer)
# hoping they are reflected in the CGI response or used in a search query.
# Scope: Genealogy::Wills never reads %ENV headers directly. This test
# confirms the module is unaffected by poisoned headers in the environment,
# and documents that sanitisation responsibility lies in the CGI wrapper.
# ===========================================================================

subtest 'hostile HTTP headers in %ENV do not affect the module' => sub {
	local %ENV = (%ENV,
		HTTP_USER_AGENT => $XSS_SCRIPT,
		HTTP_REFERER    => $CRLF_COOKIE,
		HTTP_COOKIE     => $SQL_INJECT_DROP,
		HTTP_X_CUSTOM   => $SHELL_PIPE,
	);

	# A clean search() call must still work normally
	lives_ok(
		sub { my @r = $obj->search(last => 'Smith') },
		'poisoned HTTP headers in %ENV do not affect search() result'
	);
	pass('HTTP header sanitisation is the CGI wrapper\'s responsibility, not this module\'s');
};

# ===========================================================================
# SECTION 19 -- Unicode lookalike characters in 'last'
#
# Exploit: attacker uses Cyrillic or other Unicode characters that visually
# resemble ASCII letters (homograph attack), hoping to bypass filters while
# querying for ASCII-only data in the database.
# Finding: qr/^[\w\-]+$/ without /a matches Unicode \w, so Cyrillic 'a'
# (U+0430) passes PVS validation. To restrict to ASCII only, add the /a flag.
# This test documents the current behaviour rather than asserting pass/fail.
# ===========================================================================

subtest 'Unicode lookalike in last (homograph attack -- documents behaviour)' => sub {
	my $cyrillic_smith = $UNICODE_CYRILLIC_A . 'mith';
	my $rejected = 0;
	eval { $obj->search(last => $cyrillic_smith) };
	if($@) {
		$rejected = 1;
		pass('Unicode lookalike in last is rejected by PVS on this build');
	} else {
		pass('Unicode lookalike in last passes PVS (\\w is Unicode-aware without /a)');
		note(
			'SECURITY FINDING: qr/^[\\w\\-]+$/ without /a accepts Unicode \\w chars. ' .
			'If strict ASCII names are required, change the matches regex to ' .
			'qr/^[\\w\\-]+$/a to restrict \\w to [0-9A-Za-z_].'
		);
	}
	ok(1, 'homograph attack behaviour documented; see note above');
};

# ===========================================================================
# SECTION 20 -- ReDoS (Regular Expression Denial of Service)
#
# Exploit: crafted string triggers O(2^n) backtracking in the PVS regex,
# blocking the event loop for seconds or minutes.
# Defence: qr/^[\w\-]+$/ contains no alternation or overlapping quantifiers.
# Its complexity is O(n) -- linear in input length. This test confirms that
# a 50-char adversarial string (valid chars followed by one invalid char)
# completes in well under 1 second.
# ===========================================================================

subtest 'ReDoS probe on PVS matches regex' => sub {
	# $REDOS_CANDIDATE = 'a' x 50 . '!' -- fails PVS because '!' is not [\w-]
	my $t0 = time();
	eval { $obj->search(last => $REDOS_CANDIDATE) };
	my $elapsed = time() - $t0;

	ok($@,
		'adversarial ReDoS string (50 valid + 1 invalid char) is rejected by PVS');
	cmp_ok($elapsed, '<', 1.0,
		sprintf('PVS regex evaluation completes in <1s (%.4fs) -- not vulnerable to ReDoS', $elapsed));
};

done_testing();
