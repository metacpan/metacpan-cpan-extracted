use strict;
use warnings;
use blib;
use Carp qw(cluck);

use Test::More tests => 5;

use_ok('Mail::Karmasphere::Client');
use_ok('Mail::Karmasphere::Query');
use_ok('Mail::Karmasphere::Response');

local $SIG{__WARN__} = sub { cluck @_; };

my $DEBUG = 1 if $ENV{MKS_DEBUG_TESTS};

my $client = new Mail::Karmasphere::Client(
				PeerHost	=> $ENV{KARMA_SERVER},
				Debug		=> $DEBUG,
					);
# Send two small UDP queries
for (0..2) {
	$client->send(new Mail::Karmasphere::Query());
}

# Send one large TCP query
my $query = new Mail::Karmasphere::Query();
for (0..100) {
	$query->feed("test.nonexistent$_");
}
my $response = $client->ask($query);
ok(defined $response, "Got a response to the TCP query");

# Receive a UDP query
$response = $client->recv();
ok(defined $response, "Got a response to an old UDP query");
