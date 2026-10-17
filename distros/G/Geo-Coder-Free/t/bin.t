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

use DBI;
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

Test::Script->import();

script_compiles('bin/testcgibin');
script_compiles('bin/address_lookup');

if($ENV{'AUTHOR_TESTING'}) {
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

	# Test 8 is the same client allowed through: the position it asked for, and no
	# block page.
	script_runs(['bin/testcgibin', 8]);
	script_stdout_like(qr/\-76\.84/, 'allowed: the client is served the answer');
	script_stdout_unlike(qr/^Access Denied$/m, 'allowed: no block page is sent');
	script_stdout_unlike(qr/^Status: 403/m, 'allowed: and no 403');
} else {
	diag('Author tests not required for installation');
}

done_testing();
