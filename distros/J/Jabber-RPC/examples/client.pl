#!/usr/bin/perl -w

use strict;
use Jabber::RPC::Client;

my $client = new Jabber::RPC::Client(
  server    => 'localhost',
  identauth => 'dj:password',
  resource  => 'the-client',
# endpoint  => 'a@localhost/the-server',
  endpoint  => 'jrpc.localhost/the-server',
);

my $result;

$result = $client->call('examples.getStateName', 5);
print "getStateName: ", $result || $client->lastfault, "\n";

$result = $client->call('examples.getStateList', [12, 28, 33, 39, 46]);
print "getStateList: ", $result || $client->lastfault, "\n";

$result = $client->call('examples.getStateStruct', 
                            {  state1 => 18, state2 => 27, state3 => 48 } );
print "getStateStruct: ", $result || $client->lastfault, "\n";


