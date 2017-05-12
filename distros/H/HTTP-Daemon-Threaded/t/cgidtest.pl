BEGIN {
	push @INC, './t';
}

use threads;
use threads::shared;
use HTTP::Daemon::Threaded;
use HTTP::Daemon::Threaded::Listener;
use HTTP::Daemon::Threaded::CGIHandler;
use HTTP::Daemon::Threaded::SessionCache;
use HTTP::Daemon::Threaded::Logger;
use HTTP::Daemon::Threaded::WebClient;
use MyWebLogger;
use TestHTML;
use TestCGI;

use strict;
use warnings;
#
#	main script to run for attachable browser based
#	debugger based on Devel::Psichedb
#
my $port = 9876;
my $maxclients = 10;
my $docroot = undef;
my $loglevel = 3;
my $quiet = undef;
my $useSess = undef;
my $weblog = undef;

while (@ARGV) {
	my $op = shift @ARGV;

	$port = shift @ARGV,
	next
		if ($op eq '-p');

	$maxclients = shift @ARGV,
	next
		if ($op eq '-c');

	$docroot = shift @ARGV,
	next
		if ($op eq '-d');

	$loglevel = shift @ARGV,
	next
		if ($op eq '-l');

	$quiet = 1, next
		if ($op eq '-q');

	$useSess = 1, next
		if ($op eq '-s');

	$weblog = 1, next
		if ($op eq '-w');
}

my $sessions = $useSess ? HTTP::Daemon::Threaded::SessionCache->new() : undef;
$weblog = Thread::Apartment->new(
	AptClass => 'MyWebLogger'
	)
	if $weblog;

my $httpd = HTTP::Daemon::Threaded->new(
	AptTimeout => 100,
	Port => $port,
	MaxClients => $maxclients,
	SessionCache => $sessions,
	LogLevel => $loglevel,
	DocRoot => $docroot,
	WebLogger => $weblog,
	#
	#	our media types; note the LWP::MediaTypes does not
	#	include defaults for some common types: javascript, CSS,
	#	XML, or DTD
	#
	MediaTypes => {
		'text/xml' => [ 'xml', 'dtd' ],
		'text/javascript' => 'js',
		'text/css' => 'css'
	},
	#
	#	our content handlers:
	#	each entry is a regex string, and a package name.
	#	A Devel::Psichedb::ContentParams container is created by
	#	each WebClient object, and passed to the package when invoked;
	#	Each package implements HTTP::Daemon::Threaded::Content.
	#	Order of the list is important, as URI's are evaluated against the
	#	regex's in order until a match is found.
	#	NOTE: we use true literal strings here, *not* qr//, since
	#	Thread::Apartment will marshal this arrayref using Storable,
	#	and it doesn't recover qr//'s properly
	#
	Handlers => [
		'^/\w+\.html$', 'TestHTML',
		'^/posted$', 'TestCGI',
		'^/postxml$', 'TestCGI',
		'^.*/scripty\.js$', '*',
	],
	#
	#	app specific params installed into the ContentParams container
	#

	);

die "Unable to create web server, exitting."
	unless $httpd;

print "HTTPD created\n";

sleep 5
	while ($httpd->status() ne 'stopped');

$httpd->stop();
$httpd->join();

if ($weblog) {
	$weblog->close();
	$weblog->stop();
	$weblog->join();
}
