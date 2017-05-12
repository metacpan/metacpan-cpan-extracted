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

plan tests => 9;

require "t/Event_RPC_Test_Server.pm";
my $PORT = Event_RPC_Test_Server->port;

# load client class
use_ok('Event::RPC::Client');

# start server in background, without logging
Event_RPC_Test_Server->start_server (
  p => $PORT,
  S => 1,
  L => $ENV{EVENT_RPC_LOOP},
  M => 1024,
);

# create client instance
my $client = Event::RPC::Client->new (
  host     => "localhost",
  port     => $PORT,
);

# connect to server
$client->connect;
ok(1, "connected");

ok($client->set_max_packet_size(1024) == 1024, "Client->set_max_packet_size");
ok($client->get_max_packet_size       == 1024, "Client->get_max_packet_size");

my $data = "Some test data. " x 6;
my $object = Event_RPC_Test->new (
  data => $data
);
ok ((ref $object)=~/Event_RPC_Test/, "object created via RPC");

eval { $object->get_big_data_struct };
ok ($@ =~ /exceeds/, "packet too big: $@");
 
eval { $object->get_cid };
ok ($@ eq '', "packet small enough");
 
# disconnect client
ok ($client->disconnect, "client disconnected");

# wait on server to quit
wait;
ok (1, "server stopped");
