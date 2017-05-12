#!/usr/bin/perl -w

# jrpc-requester.pl
# Jabber-RPC requester

use strict;
use Jabber::RPC::Client;

my $client = new Jabber::RPC::Client(
  server    => 'localhost',
  identauth => 'client:pass',
  endpoint  => 'jrpc.localhost/the-server',
);

my $result;

# Call component-based Jabber-RPC responder
# (the responder is jrpc-responder-component.pl)
# ----------------------------------------------
$result = $client->call('examples.getStateName', 5);
print "getStateName: ", $result || $client->lastfault, "\n";


# Call client-based Jabber-RPC responder
# (the responder is jrpc-responder-client.pl)
# -------------------------------------------
$client->endpoint('jrpc@localhost/jrpc-server');
$result = $client->call('examples.getStateList', [12, 28, 33, 39, 46]);
print "getStateList: ", $result || $client->lastfault, "\n";


# Call HTTP-based responder (via HTTPgate)
# (the responder is states-daemon.pl)
# ----------------------------------------
$client->endpoint('jrpchttp.localhost/http://localhost:8000/RPC2');
$result = $client->call('examples.getStateStruct', 
                            {  state1 => 18, state2 => 27, state3 => 48 } );
print "getStateStruct: ", $result || $client->lastfault, "\n";


