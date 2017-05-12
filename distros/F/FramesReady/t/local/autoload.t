#
# See if autoloading of protocol schemes work
#

use Test::More tests => 2;
use diagnostics;

BEGIN {
    require_ok('LWP::UserAgent::FramesReady');
}

# note no LWP::Protocol::file;

$url = "file:.";

require URI;
print "Trying to fetch '" . URI->new($url)->file . "'\n";

my $ua = new LWP::UserAgent::FramesReady;    # create a useragent to test
$ua->timeout(30);               # timeout in seconds
$ua->callbk(undef);		# No callback routine for this simple

my $request = HTTP::Request->new(GET => $url);

my $response = $ua->request($request);
is($response->is_success, 1, "Check for valid response");

# Verbose reporting
if ($response->is_success) {
    print $response->as_string;
} else {
    print $response->error_as_HTML;
}
