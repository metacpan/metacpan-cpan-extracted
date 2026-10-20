#!perl -w

# t/bin.t — the programs the website is built from.
#
# bin/testcgibin drives cgi-bin/page.fcgi the way a browser would and prints the
# answer; bin/address_lookup prints its best answer for an address.  Both find
# their answers in an OpenAddresses database, and a real one is most of a
# gigabyte of downloads and hours of preparation, so these tests make their own:
# a small database holding exactly the addresses the scripts ask about, plus the
# small configuration the CGI page insists on.
#
# OPENADDR_HOME, CONFIG_DIR and LOGDIR are pointed at them, so every run — CI
# included — exercises the scripts end to end — CGI page, geocoder, database,
# output — with no downloaded data and no dependence on what happens to be
# installed on the machine.
#
# How much of the answer can be read off the page depends on the page.  The query
# page's template is not part of this distribution (query.txt ships empty; the
# live site supplies the real one), so the answer checked for that page is the
# coordinates the run prints.  The index and meta_data pages render templates
# that are shipped here, so what those two pages print is asserted: the heading,
# the form that starts a search, the title and description the configuration
# gives them, and the visitor types the status page counts.  The query page is
# then asked twice from the client the site trusts - once with a user agent
# Geo::Coder::Free::Allow blacklists, once with a browser's - and what comes back
# is asserted each way: the first is refused with a 403 and the block page, and
# the second is served the position, so the site's answer to a client it will not
# serve, and its answer to one it will, are both checked rather than assumed.
# The refusal is checked in full, because the page's own comment says the block
# page is written rather than rendered so a blocked attacker learns nothing about
# the site: its body is asserted to be the denial line and nothing else.  The
# same refusal asked with HEAD is checked against RFC 7231 §4.3.2, which the
# page cites: the headers a GET would get, and no body at all.  Two more of the
# page's refusals are then asked for, each made to be only one layer's: an
# address CGI::ACL cannot place in a country, and a country the site blocks,
# which is refused although it comes from an address the site trusts.  The
# query page's two remaining refusals follow: an address the page itself has
# blacklisted, and a form submission whose CSRF token the site did not sign -
# and, because a refusal is only half a rule, a submission carrying a token the
# site did sign, which must still be answered.

use strict;

use Test::Needs {
	'Test::Script' => 1.12, 'CGI::Carp' => 0, 'FCGI' => 0, 'FCGI::Buffer' => 0, 'Log::WarnDie' => 0,
	'CGI::ACL' => 0, 'DBI' => 0, 'DBD::SQLite' => 0, 'Geo::Hash' => 0
};
use Test::Most;

# Diagnostics go to STDERR by default, and Log::WarnDie - which page.fcgi sends
# its warnings to, and which this file needs installed - takes STDERR over when
# it is loaded: everything written to it becomes a log message, and a log message
# with no dispatcher behind it goes nowhere.  So a failing assertion below would
# be reported as a test name and nothing else, which is no use at all for a
# failure on a machine the author cannot run.  Point the diagnostics at STDOUT,
# which is where the TAP they belong with is already going.
Test::More->builder->failure_output(\*STDOUT);

use Cwd qw(abs_path);
use DBI;
use Digest::SHA qw(sha256_hex);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Geo::Hash;
use Geo::Coder::Free::OpenAddresses;

my $stub = tempdir(CLEANUP => 1);
my $data_dir = File::Spec->catdir($stub, 'openaddresses');
my $conf_dir = File::Spec->catdir($stub, 'conf');
mkdir $data_dir or BAIL_OUT("Cannot create $data_dir: $!");
mkdir $conf_dir or BAIL_OUT("Cannot create $conf_dir: $!");

# ---------------------------------------------------------------------------
# The stub database
#
# One row per address the scripts look up.  The coordinates are the real
# positions of those places, so the assertions below are the values the live
# service produces, and a stub that answered with the wrong position would be
# caught rather than blessed.
# ---------------------------------------------------------------------------

my @lookups = (
	# bin/testcgibin 1, 3 and 4
	{ query => [ location => 'NASA TIROS RD GREENBELT MD US' ], lat => 38.9917, long => -76.8488 },
	# bin/testcgibin 2 (scantext)
	{ query => [ scantext => 'Washington DC USA' ], lat => 38.8951, long => -77.0100 },
	# bin/address_lookup
	{ query => [ location => 'Fairfield Road, Broadstairs, Kent, UK' ], lat => 51.3607, long => 1.4275 },
);

my $db_file = File::Spec->catfile($data_dir, 'openaddresses.sql');
my $dbh = DBI->connect("dbi:SQLite:dbname=$db_file", '', '', { RaiseError => 1, PrintError => 0 })
	or BAIL_OUT("Cannot create the stub OpenAddresses database $db_file: $DBI::errstr");
$dbh->do('CREATE TABLE openaddresses (md5 TEXT PRIMARY KEY, geohash TEXT)');

# Which keys the stub has to hold is the geocoder's business, not this file's:
# it rewrites a query into several look-up keys (with and without the country,
# upper and mixed case, and so on).  So ask it — point it at the still-empty
# database with a recorder standing in for the column look-up, and keep every
# key it asks for.
{
	my $recorder;
	no warnings 'once', 'redefine';
	*Geo::Coder::Free::DB::openaddresses::geohash = sub {
		my ($self, %param) = @_;
		push @{$recorder}, $param{'md5'};
		return;
	};

	my $geohash = Geo::Hash->new();
	my $insert = $dbh->prepare('INSERT INTO openaddresses (md5, geohash) VALUES (?, ?)');
	for my $lookup (@lookups) {
		my @keys;
		$recorder = \@keys;
		Geo::Coder::Free::OpenAddresses->new(openaddr => $data_dir)->geocode(@{$lookup->{'query'}});
		my %seen;
		$insert->execute($_, $geohash->encode($lookup->{'lat'}, $lookup->{'long'}))
			for grep { !$seen{$_}++ } @keys;
	}
	$insert->finish();
}

my $rows = $dbh->selectrow_array('SELECT COUNT(*) FROM openaddresses');
ok($rows > 0, "the stub database holds $rows keys for the addresses the scripts look up");

# ---------------------------------------------------------------------------
# The stub configuration
#
# page.fcgi treats every warning as fatal, and the page warns when
# security.csrf.secret is missing, so the page this test drives is given a
# configuration that has one.  The cache settings matter for the same reason:
# without them the page probes cache drivers that are not installed and warns
# about each one.  The secret is a fixture value, not a deployment credential,
# and nothing here leaves the temporary directory.
#
# The index page renders its title and description from the configuration, so
# the stub is given ones of this test's choosing and the assertions read them
# back off the rendered page: a page that stopped using what it was configured
# with would fail here rather than quietly render the shipped defaults.
# ---------------------------------------------------------------------------

my $site_title = 'Free Geocoder (test)';
my $index_title = 'Stub Index Title';
my $index_description = 'A stub page description';

my $cache_dir = File::Spec->catdir($stub, 'cache');
mkdir $cache_dir or BAIL_OUT("Cannot create $cache_dir: $!");

my $conf_file = File::Spec->catfile($conf_dir, 'default');
open(my $conf_fh, '>', $conf_file) or BAIL_OUT("Cannot write $conf_file: $!");
print $conf_fh "OPENADDR_HOME: $data_dir\n",
	"memory_cache: driver=Memory, global=1\n",
	"disc_cache: driver=File, root_dir=$cache_dir\n",
	"security:\n",
	"  csrf:\n",
	"    secret: ", ('a1' x 32), "\n",
	"SiteTitle: $site_title\n",
	"title: $index_title\n",
	"description: $index_description\n";
close $conf_fh;

# ---------------------------------------------------------------------------
# The stub VWF log
#
# The meta_data page counts the log the server keeps, one figure per visitor
# type.  CGI::Info::logdir() honours LOGDIR, so the page can be pointed at a log
# of this test's own making and the figures it renders are then the rows written
# below rather than whatever the machine's log happens to hold.  The rows carry
# the domain the page will be asked about (SERVER_NAME below), since the page
# counts only its own domain's entries, and follow the column order the server
# writes.  The file is written by write_log(), at the moment the assertions need
# it: a page records the visit it served, so the log the status page is asked to
# count is written after the landing page has been served, and its rows are
# exactly the ones the assertions name.
# ---------------------------------------------------------------------------

my $log_dir = File::Spec->catdir($stub, 'log');
mkdir $log_dir or BAIL_OUT("Cannot create $log_dir: $!");

my $log_file = File::Spec->catfile($log_dir, 'vwf.log');

# The address the access-control tests ask from: the page's CGI::ACL trusts it and
# reads it as being in the US, and bin/testcgibin uses it for the same reasons.
my $us_ip = '108.44.193.70';

# The address the CGI::ACL test asks from: private, so no country can be looked
# up for it and the ACL refuses the client.  bin/testcgibin asks test 10 from it.
my $unplaceable_ip = '10.0.0.1';

# The country the blocked-country tests arrive from, passed the way a web server
# or CDN passes it to the page, and one of the countries the site blocks.
my $blocked_country = 'RU';

# The last log row matching a pattern, as the page wrote it, or undef when the
# page wrote none.  The reason a row carries is what tells which layer of the
# page's access control turned a client away; nothing written before these runs
# carries the one they look for, so the row is this request's.
sub _logged_row
{
	my ($pattern) = @_;

	open(my $log_fh, '<', $log_file) or return;

	my @rows = grep { /$pattern/ } <$log_fh>;
	close $log_fh;

	return $rows[-1];
}

# A root directory of its own for one refusal test.  The page roots the file
# caches it keeps - the country it remembers for a visitor, the answers it
# remembers for a page - at root_dir, and looks for its templates there as well,
# so a fresh root is given a link to the templates this distribution ships: a
# test that is refused never needs it, and the one that is served an answer
# cannot do without it.  Nothing written here outlives the run.
sub private_root
{
	my ($name) = @_;

	my $dir = File::Spec->catdir($stub, $name);
	make_path($dir);
	symlink(abs_path('templates'), File::Spec->catdir($dir, 'templates'))
		or BAIL_OUT("Cannot link the templates into $dir: $!");

	return $dir;
}

# The end of the log, for the diagnosis when a row that should be there is not.
sub _log_tail
{
	open(my $log_fh, '<', $log_file) or return "\n\t$log_file cannot be read: $!\n";

	my @rows = <$log_fh>;
	close $log_fh;

	my @tail = @rows > 5 ? @rows[-5 .. -1] : @rows;

	return "\n\tlast rows of $log_file:\n\t" . join("\t", @tail) . "\n";
}

# The domain the pages are asked about, and the one the stub log is written for:
# naming it keeps the test off the machine's hostname, which the pages fall back
# to when nothing else says which site they are answering for.
my $domain_name = 'example.com';

# A log of the test's own making: two web visits, one mobile, three search
# engines and no robots.  What the status page makes of them is asserted below.
my %log_entries = (web => 2, mobile => 1, search => 3, robot => 0);

sub write_log
{
	open(my $log_fh, '>', $log_file) or BAIL_OUT("Cannot write $log_file: $!");
	print $log_fh join(',', map { qq("$_") } qw(domain_name time IP country type language http_code template args messages error duration_ms)), "\n";
	foreach my $type(sort keys %log_entries) {
		for my $entry(1 .. $log_entries{$type}) {
			print $log_fh join(',', qq("$domain_name"), qq("2026-01-01 00:00:0$entry"), '"127.0.0.1"', '"gb"',
				qq("$type"), '"English"', 200, '""', '""', '""', '""', 25), "\n";
		}
	}
	close $log_fh;
}

# The answers checked below must come from the stub, so the tests do not use
# anyone else's data: the same assertions then hold on a machine with an
# OpenStreetMap or WhosOnFirst download and on one with neither.
delete @ENV{qw(OSM_HOME WHOSONFIRST_HOME DR5HN_HOME)};
local $ENV{'OPENADDR_HOME'} = $data_dir;
local $ENV{'CONFIG_DIR'} = $conf_dir;

# Every run logs the visit it served, and every log it writes is written here
# (CGI::Info::logdir() takes LOGDIR), so the pages that count the log and the
# tests that read it back are looking at the same file - and no run writes an
# access log outside the temporary directory.
local $ENV{'LOGDIR'} = $log_dir;

# The server's temporary directory, so that what the page keeps between requests
# - the throttle that counts them, and the file it sends its own errors to - is
# this run's rather than the machine's.  A throttle left in the system's
# temporary directory counts the requests of one run against the next, and these
# tests ask as the same client several times.
local $ENV{'TMPDIR'} = $stub;

# The page roots the file caches it keeps - the country it remembers for a
# visitor, the answers it remembers for a page - at $ENV{'root_dir'}, which
# bin/testcgibin sets to this distribution when nothing else has.  The tests
# below give it a directory of the run's own, so everything a run caches is
# inside the tree the run deletes: the checkout is not written to, and no country
# resolved in one run can answer for the next.  The refusal tests that need a
# cache of their own say so where they ask.

Test::Script->import();

script_compiles('bin/testcgibin');
script_compiles('bin/address_lookup');

if($ENV{'AUTHOR_TESTING'}) {
	# Every page asked below is rooted in this run's own directory rather than in
	# the checkout: what the page caches as it runs - the country it resolves for
	# a visitor, the answer it remembers for a page - then belongs to the run that
	# made it and is deleted with it, and a run leaves nothing behind for the
	# manifest to trip over.
	local $ENV{'root_dir'} = private_root('root');

	# Test 1 looks a US postal address up in the stub.
	script_runs(['bin/testcgibin', 1]);
	script_stdout_like(qr/\-76\.84/, 'test 1: the Greenbelt address prints the stub longitude');
	script_stderr_is('', 'test 1: no error output');

	# Test 2 scans free text for place names.
	script_runs(['bin/testcgibin', 2]);
	script_stdout_like(qr/\-77\.01/, 'test 2: the scanned text finds Washington DC in the stub');
	script_stderr_is('', 'test 2: no error output');

	# Tests 3 and 4 ask from a US address, so the page takes the country from
	# the client's IP address: 4 leaves the country out of the address itself.
	script_runs(['bin/testcgibin', 3]);
	script_stdout_like(qr/\-76\.84/, 'test 3: the address resolves when the country comes from the client');
	script_stderr_is('', 'test 3: no error output');

	script_runs(['bin/testcgibin', 4]);
	script_stdout_like(qr/\-76\.84/, 'test 4: the address resolves without a country of its own');
	script_stderr_is('', 'test 4: no error output');

	# A street address, found through the stub rather than an OSM download.
	script_runs(['bin/address_lookup', 'Fairfield Road,', 'Broadstairs,', ' Kent,', ' UK']);
	script_stdout_like(qr/51\.3/, 'address_lookup: the Broadstairs address prints the stub latitude');
	script_stderr_is('', 'address_lookup: no error output');

	# The two remaining pages are rendered from templates this distribution
	# ships, so their output is the page and can be asserted as such.  The domain
	# they answer for is named here, and the stub log written above is a log of
	# that domain's visitors.
	local $ENV{'SERVER_NAME'} = "www.$domain_name";

	# Test 5 is the landing page: the title and description it was configured
	# with, and the form that sends a visitor to the query page.
	script_runs(['bin/testcgibin', 5]);
	script_stdout_like(qr/<title>\s*\Q$index_title\E\s*<\/title>/,
		"index: the page renders the title the configuration gives it ($index_title)");
	script_stdout_like(qr/<meta name="description" content="\Q$index_description\E" \/>/,
		'index: and the description it was configured with');
	script_stdout_like(qr/<h1>Free Geo-Coding Website - alpha test<\/h1>/,
		'index: the landing page heading is rendered');
	script_stdout_like(qr/<form method="post" action="\/cgi-bin\/page\.fcgi\?page=query"/,
		'index: the search form posts to the query page');
	script_stdout_like(qr/<input name="q" type="search"/,
		'index: and carries the location field it searches for');
	script_stderr_is('', 'index: no error output');

	# The landing page has just been served, and serving it recorded a visit in
	# the log below.  Write the log now, whole, so that the status page counts
	# the rows named here and not that visit as well.
	write_log();

	# Test 6 is the server's status page: the site title it was configured with,
	# the domain it was asked about, and the visitor types it counted in the stub
	# log - two web, one mobile, three search engines and no robots.
	script_runs(['bin/testcgibin', 6]);
	script_stdout_like(qr/<title>\Q$site_title\E: Meta Data<\/title>/,
		"meta_data: the page renders the configured site title ($site_title)");
	script_stdout_like(qr/<h1>\Q$site_title\E: Meta Data<\/h1>/,
		'meta_data: and as its heading');
	script_stdout_like(qr/domain_name: \Q$domain_name\E<br>/,
		'meta_data: it reports the domain it was asked about');
	script_stdout_like(qr/<h2>Lingua<\/h2>/,
		'meta_data: the visitor\'s language is reported');
	script_stdout_like(qr/<script src="https:\/\/cdn\.canvasjs\.com\/canvasjs\.min\.js"><\/script>/,
		'meta_data: the chart of visitor types is rendered');
	script_stdout_like(
		qr/dataPoints: \[\s*\{y: 2, label: "web"\},\s*\{y: 1, label: "mobile"\},\s*\{y: 3, label: "search"\},\s*\{y: 0, label: "robot"\},/,
		'the chart holds the counts from the stub log: 2 web, 1 mobile, 3 search, 0 robots');
	script_stderr_is('', 'meta_data: no error output');

	# Tests 7 and 8 are the two answers the same client gets, and the only
	# difference between them is the user agent it sends: 7 sends one that
	# Geo::Coder::Free::Allow blacklists, 8 sends a browser's.  They come from the
	# address tests 3 and 4 are answered for, so the site is not refusing them for
	# their address, and neither asks anything the site would refuse to answer.
	#
	# Neither asserts on stderr: a client that sends a user agent has its stderr
	# redirected by the page itself, into a file of its own, so what the test
	# harness captures would be empty whether the run had been quiet or not.
	# A warning is fatal there (Log::WarnDie), so a noisy run fails the stdout
	# assertions below rather than passing them quietly.

	# Test 7 is the blacklisted client: a 403, the block page, and no answer.
	script_runs(['bin/testcgibin', 7]);
	script_stdout_like(qr/^Status: 403 Forbidden$/m, 'blocked: the page answers 403');
	# The block page spells its own header Content-type, where a rendered page
	# sends Content-Type: asserting the block page's spelling is what tells the
	# two answers apart rather than a typo in the pattern.
	script_stdout_like(qr/^Content-type: text\/plain$/m,
		'blocked: and sends the plain-text block page, not the rendered page');
	script_stdout_like(qr/^Access Denied$/m, 'blocked: which says the client is denied');
	script_stdout_unlike(qr/\-76\.84/, 'blocked: the answer is not given away');

	# The block page is written by the page itself, not rendered from a template,
	# and its comment says why: a blocked attacker must receive no information
	# about the site's structure.  The whole answer is therefore pinned here to
	# those three headers and the one denial line - nothing may be added to it -
	# and the answer is then held to naming no page, link, markup or site title.
	script_stdout_is("Status: 403 Forbidden\nContent-type: text/plain\nPragma: no-cache\n\nAccess Denied\n",
		'blocked: the answer is the denial line and no more');
	script_stdout_unlike(
		qr{/cgi-bin/|page=|<html|<title|href=|\Q$site_title\E|\b(?:index|query|meta_data)\b},
		'blocked: the block page names no page, link, markup or site title');

	# The refusal is recorded, so an operator can see who was turned away and
	# why.  The reason is one only this layer produces: a client refused by
	# CGI::ACL, or for its country, or by the SQL-injection check, is logged with
	# a different one, so the row below is the user-agent blacklist answering and
	# not something else in the stack.
	my $blocked = _logged_row(qr/ is blacklisted/);
	ok(defined($blocked), 'blocked: the denial is recorded in the log with its reason')
		or diag(_log_tail());
	like($blocked, qr/,403,/, 'blocked: the record carries the status the client was given')
		or diag("\n\t" . (defined($blocked) ? $blocked : 'no such row') . "\n");
	like($blocked, qr/"\Q$us_ip\E"/, 'blocked: and the address that was refused');

	# Test 9 is test 7's refusal asked with HEAD.  RFC 7231 §4.3.2, which the block
	# page's own comment cites, says the answer is what the headers would be and
	# no body: the status and content type must be sent, and nothing at all may
	# follow the blank line that ends the headers - not merely without the denial
	# line, but without a body of any kind.
	script_runs(['bin/testcgibin', 9]);
	script_stdout_is("Status: 403 Forbidden\nContent-type: text/plain\nPragma: no-cache\n\n",
		'blocked HEAD: the headers are sent and the response ends there');
	script_stdout_unlike(qr/Access Denied/,
		'blocked HEAD: the denial line a GET would carry is not sent as a body');

	# Test 8 is the same client allowed through: the position it asked for, and no
	# block page.
	script_runs(['bin/testcgibin', 8]);
	script_stdout_like(qr/\-76\.84/, 'allowed: the client is served the answer');
	script_stdout_unlike(qr/^Access Denied$/m, 'allowed: no block page is sent');
	script_stdout_unlike(qr/^Status: 403/m, 'allowed: and no 403');

	# Tests 10 and 11 are the page's other two refusals, and each is arranged to
	# be one layer's alone.  Neither asserts on stderr, for the reason given
	# above the blacklisted client: the page redirects the errors of any client
	# that sends a user agent into a file of its own.  Both are asked with a cache
	# of their own, so that what the page remembers for the client as it runs - the
	# country it resolves for a visitor, the answer it renders for a page - cannot
	# be what these tests then read: what is asserted below is the page's answer to
	# the request, not to a request like it.
	my $refusal_cache = File::Spec->catdir($stub, 'refusal-cache');
	make_path($refusal_cache);
	local $ENV{'root_dir'} = $refusal_cache;

	# Test 10 is CGI::ACL refusing an address: it cannot be placed in a country,
	# and the ACL denies what it cannot place.  Everything else about the request
	# is test 3's - an ordinary browser, asking the question the stub answers - so
	# the address is the only thing the client can be refused for.  The reason
	# the log records is the one only this layer writes, and the country column
	# beside it shows the address went unplaced, which is what it was refused for.
	script_runs(['bin/testcgibin', 10]);
	script_stdout_like(qr/^Status: 403 Forbidden$/m, 'ACL: the page refuses the client');
	script_stdout_like(qr/^Access Denied$/m, 'ACL: with the block page');
	script_stdout_unlike(qr/\-76\.84/, 'ACL: and the address is not answered');

	my $acl_refusal = _logged_row(qr/Denied by CGI::ACL/);
	ok(defined($acl_refusal), 'ACL: the refusal is recorded against the layer that made it')
		or diag(_log_tail());
	like($acl_refusal, qr/"\Q$unplaceable_ip\E"/, 'ACL: against the address it was made for');
	like($acl_refusal, qr/,"unknown",/, 'ACL: and the address is recorded as one no country was found for');
	like($acl_refusal, qr/,403,/, 'ACL: with the status the client was given');

	# Test 11 is a blocked country.  It comes from the address the site trusts,
	# so the ACL serves it and the refusal is the country list's - the reason
	# recorded names that refusal and the country it read the client as being in,
	# and is one no other layer writes.  The country arrives the way a web server
	# or CDN passes it, which is the way CGI::Lingua reads a client's country.
	script_runs(['bin/testcgibin', 11]);
	script_stdout_like(qr/^Status: 403 Forbidden$/m, 'blocked country: the page refuses the client');
	script_stdout_like(qr/^Access Denied$/m, 'blocked country: with the block page');
	script_stdout_unlike(qr/\-76\.84/, 'blocked country: and the address it trusts is not answered either');

	my $country_refusal = _logged_row(qr/blocked connexion from \Q$blocked_country\E/i);
	ok(defined($country_refusal), 'blocked country: the refusal is recorded with its reason')
		or diag(_log_tail());
	like($country_refusal, qr/"\Q$us_ip\E"/, 'blocked country: against the address it came from');
	like($country_refusal, qr/,"\L$blocked_country\E",/, 'blocked country: and the country the client was read as being in');
	like($country_refusal, qr/,403,/, 'blocked country: with the status the client was given');

	# Tests 12 to 14 are the query page's own two refusals, and the control for
	# the second.  None asserts on stderr, for the reason given above the
	# blacklisted client: the page redirects the errors of any client that sends
	# a user agent into a file of its own.  Each is asked with a root of its own,
	# so what is asserted is the page's answer to the request and not the
	# country an earlier test remembered for the client.

	# Test 12 is a client the page has blacklisted.  It asks test 3's question
	# - from test 3's address, with the user agent test 8 is served with - but
	# its wording reads like a SQL injection attempt, so the page adds the
	# address to the blacklist it keeps in the process and refuses it.  The
	# reason the log records is the one only that layer writes, and the 403 is
	# the block page the user-agent refusal is given.
	local $ENV{'root_dir'} = private_root('injection-cache');

	script_runs(['bin/testcgibin', 12]);
	script_stdout_like(qr/^Status: 403 Forbidden$/m, 'blacklisted IP: the page refuses the client');
	script_stdout_like(qr/^Access Denied$/m, 'blacklisted IP: with the block page');
	script_stdout_unlike(qr/\-76\.84/, 'blacklisted IP: and the address is not answered');

	my $injection_refusal = _logged_row(qr/Blacklisted for attempting to break in/);
	ok(defined($injection_refusal), 'blacklisted IP: the refusal is recorded against the layer that made it')
		or diag(_log_tail());
	like($injection_refusal, qr/"\Q$us_ip\E"/, 'blacklisted IP: against the address it was made for');
	like($injection_refusal, qr/,403,/, 'blacklisted IP: with the status the client was given');

	# The page reads the country it remembered for this address before it looks
	# at a token, so these two tests ask from a root no other test has written
	# to: what they are refused for is the token and not a country.
	local $ENV{'root_dir'} = private_root('csrf-cache');

	# Test 13 is a form submission whose CSRF token the site did not sign:
	# everything else is test 3's, so the token is what it can be refused for.
	# The token is long enough to be one and carries no signature the page could
	# have made, which is what a guess at the token's shape looks like.
	script_runs(['bin/testcgibin', 13]);
	script_stdout_like(qr/^Status: 403 Forbidden$/m, 'CSRF: the page refuses an unsigned token');
	script_stdout_like(qr/^Access Denied$/m, 'CSRF: with the block page');
	script_stdout_unlike(qr/\-76\.84/, 'CSRF: and the answer is not given away');

	my $csrf_refusal = _logged_row(qr/Rejected CSRF token/);
	ok(defined($csrf_refusal), 'CSRF: the refusal is recorded against the layer that made it')
		or diag(_log_tail());
	like($csrf_refusal, qr/"\Q$us_ip\E"/, 'CSRF: against the address it was made for');
	like($csrf_refusal, qr/,403,/, 'CSRF: with the status the client was given');

	# Test 14 is the control test 13 needs: the same submission, carrying a
	# token this site signed.  The token is built the way the page builds one -
	# "timestamp:random:signature" with the signature taken over the first two
	# fields and the secret the stub configuration gives the page - so a page
	# that refused every token would fail here, and one that accepted every
	# token would fail test 13.
	my $token_data = '0:' . ('ab' x 32);
	local $ENV{'CSRF_TOKEN'} = $token_data . ':' . sha256_hex("$token_data:" . ('a1' x 32));

	script_runs(['bin/testcgibin', 14]);
	script_stdout_like(qr/\-76\.84/, 'CSRF: a token the site signed is accepted');
	script_stdout_unlike(qr/^Status: 403/m, 'CSRF: and no 403 is sent');
} else {
	diag('Author tests not required for installation');
}

done_testing();
