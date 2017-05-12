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

plan tests => 5;

require "t/Event_RPC_Test_Server.pm";
my $PORT = Event_RPC_Test_Server->port;

# load client class
use_ok('Event::RPC::Client');

# start server in background, without logging
Event_RPC_Test_Server->start_server (
  p => $PORT,
  S => 1,
  L => $ENV{EVENT_RPC_LOOP},
);

# create client instance
my $client = Event::RPC::Client->new (
  host   => "localhost",
  port   => $PORT,
);

# connect to server
$client->connect;
ok(1, "connected");

# create instance of test class over RPC
my $object = Event_RPC_Test->new (
	data => "Some test data. " x 6
);
ok ((ref $object)=~/Event_RPC_Test/, "object created via RPC");

# disconnect client (this will also stop the server,
# because we started it with the -S option)
ok ($client->disconnect, "client disconnected");

# wait on server to quit
wait;
ok (1, "stop server");
