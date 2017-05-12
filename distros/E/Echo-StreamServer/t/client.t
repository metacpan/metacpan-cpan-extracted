# Base Echo Client Tests

use strict;
use Test::More tests => 4;
BEGIN {
	use_ok('Echo::StreamServer::Client');
	use_ok('Echo::StreamServer::Account');
};

# Create a client using an account.
# ======================================================================
my $appkey = 'test.echoenabled.com';
my $secret = ''; # really, it is an empty string.
my $acct = new Echo::StreamServer::Account($appkey, $secret);
isa_ok($acct, 'Echo::StreamServer::Account');

my $client = new Echo::StreamServer::Client($acct);
isa_ok($client, 'Echo::StreamServer::Client');

