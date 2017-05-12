#!/usr/bin/perl -w

# adapted from states-client.pl:
#
# Copyright (C) 1999 Ken MacLeod
# See the file COPYING for distribution terms.
#

use Data::Dumper;

use Frontier::Client;

# XML-RPC call to HTTP responder
# ------------------------------
$server = Frontier::Client->new(
          url => 'http://localhost:8000/RPC2',
);
$result = $server->call('examples.getStateName', 21);
print "getStateName: $result\n";


# XML-RPC call to Jabber-RPC responder as component
# -------------------------------------------------
$server = Frontier::Client->new(
          url => 'http://localhost:5281/jrpc.localhost/jrpc-server',
);
$result = $server->call('examples.getStateList', [12, 28, 33, 39, 46]);
print "getStateList: $result\n";


# XML-RPC call to Jabber-RPC responder as client
# ----------------------------------------------
$server = Frontier::Client->new(
          url => 'http://localhost:5281/jrpc@localhost/jrpc-server',
);
$result = $server->call('examples.getStateStruct',
			{ state1 => 18, state2 => 27, state3 => 48 });
print "getStateStruct: $result\n";


