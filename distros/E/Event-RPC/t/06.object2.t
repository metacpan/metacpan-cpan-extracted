#!/usr/bin/perl

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

plan tests => 10;

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
  host     => "localhost",
  port     => $PORT,
);

# connect to server
$client->connect;
ok(1, "connected");

# create instance of test class over RPC
my $data = "Some test data. " x 6;
my $object = Event_RPC_Test->new (
    data => $data
);

# check object
ok($object->isa("Event_RPC_Test"), "object is Event_RPC_Test");

# get another object from this object
my $object2 = $object->get_object2;
ok($object2->isa("Event_RPC_Test2"), "object is Event_RPC_Test2");

# check data of object2
ok($object2->get_data eq 'foo', "object data is 'foo'");

# create another object from this object
$object2 = $object->new_object2($$);
ok($object2->isa("Event_RPC_Test2"), "object is Event_RPC_Test2");

# check data of object2
ok($object2->get_data == $$, "object data is $$");

# check if copying the complete object hash works
my $ref = $object2->get_object_copy;
ok($ref->{data} == $$, "object copy data is $$");

# disconnect client
ok ($client->disconnect, "client disconnected");

# wait on server to quit
wait;
ok (1, "server stopped");
