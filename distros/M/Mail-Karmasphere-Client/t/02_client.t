use strict;
use warnings;
use blib;
use Carp qw(cluck);

use Test::More tests => 7;

use_ok('Mail::Karmasphere::Client');
use_ok('Mail::Karmasphere::Query');
use_ok('Mail::Karmasphere::Response');

local $SIG{__WARN__} = sub { cluck @_; };

my $DEBUG = 1 if $ENV{MKS_DEBUG_TESTS};

my $client = new Mail::Karmasphere::Client(
				PeerHost	=> $ENV{KARMA_SERVER},
				Debug		=> $DEBUG,
					);
for (0..5) {	# Send more than we receive, for robustness
	my $query = new Mail::Karmasphere::Query();
	$client->send($query);
}
for (0..3) {
	my $response = $client->recv();
	ok(defined $response, "Got a response without giving an id");
}
