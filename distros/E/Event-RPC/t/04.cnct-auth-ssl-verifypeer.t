use strict;
use utf8;

use Test::More;

my $depend_modules = 0;
eval { require EV };
eval { require AnyEvent } && ++$depend_modules;
eval { require Event    } && ++$depend_modules;
eval { require Glib     } && ++$depend_modules;

if ( not $depend_modules ) {
    plan skip_all => "Neither AnyEvent, Event nor Glib installed";
}

eval { require IO::Socket::SSL };
if ( $@ ) {
	plan skip_all => "IO::Socket::SSL required";
}

plan tests => 6;

require "t/Event_RPC_Test_Server.pm";
my $PORT = Event_RPC_Test_Server->port;

my $AUTH_USER = "foo";
my $AUTH_PASS = "bar";

# load client class
use_ok('Event::RPC::Client');

# start server in background, without logging
Event_RPC_Test_Server->start_server (
  p => $PORT,
  a => "$AUTH_USER:$AUTH_PASS",
  s => 1,
  S => 1,
  L => $ENV{EVENT_RPC_LOOP},
);

# create client instance
my $client = Event::RPC::Client->new (
  host        => "localhost",
  port        => $PORT,
  auth_user   => $AUTH_USER,
  auth_pass   => "wrong pass",
  ssl         => 1,
  ssl_ca_file => "t/ssl/ca.crt",
);

# try to connect with wrong password
eval { $client->connect };
ok($@ ne '', "connection failed with wrong pw");

# now set correct password
$client->set_auth_pass(Event::RPC->crypt($AUTH_USER,$AUTH_PASS));

# connect to server with correct password
$client->connect;
ok(1, "connected");

# create instance of test class over RPC
my $object = Event_RPC_Test->new (
	data => "Some test data. " x 6
);
ok ((ref $object)=~/Event_RPC_Test/, "object created via RPC");

# disconnect client
ok ($client->disconnect, "client disconnected");

# wait on server to quit
wait;
ok (1, "server stopped");
