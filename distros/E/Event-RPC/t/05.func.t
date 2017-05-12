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

plan tests => 18;

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

# count created objects
my $object_cnt = 0;

# connect to server
$client->connect;
ok(1, "connected");

# create instance of test class over RPC
my $data = "Some test data. " x 6;
my $object = Event_RPC_Test->new (
	data => $data
);
++$object_cnt;
ok ((ref $object)=~/Event_RPC_Test/, "object created via RPC");

# test data
ok ($object->get_data eq $data, "data member ok");

# set data, some utf8
ok ($object->set_data("你好世界") eq "你好世界", "set data utf8");

# check set data, some utf8
ok ($object->get_data eq "你好世界", "get data utf8");

# set data
ok ($object->set_data("foo") eq "foo", "set data");

# check set data
ok ($object->get_data eq "foo", "get data");

# object transfer
my $clone;
++$object_cnt;
ok ( $clone = $object->clone, "object transfer");

# check clone
$clone->set_data("bar");
ok ( $clone->get_data eq 'bar' &&
     $object->get_data eq 'foo', "clone");


# transfer a list of objects
my ($lref, $href) = $object->multi(10);
$object_cnt += 10;
ok ( @$lref       == 10 && $lref->[5]->get_data == 5, "multi object list");
ok ( keys(%$href) == 10 && $href->{4}->get_data == 4, "multi object hash");

# complex parameter transfer
my @params = (
  "scalar", { 1 => "hash" }, [ "a", "list" ],
);

my @result = $object->echo(@params);

ok ( @result == 3                &&
     $result[0]      eq 'scalar' &&
     ref $result[1]  eq 'HASH'   &&
     $result[1]->{1} eq 'hash'   &&
     ref $result[2]  eq 'ARRAY'  &&
     $result[2]->[1] eq 'list'
     ,
     "complex parameter transfer"
);

# get connection cid
ok ($object->get_cid == 1, "access connection object");

# get client object cnt via connection
ok ($object->get_object_cnt == $object_cnt, "client object cnt via connection");

# check undef object returner
ok (!defined $object->get_undef_object, "get undef from an object returner");

# disconnect client
ok ($client->disconnect, "client disconnected");

# wait on server to quit
wait;
ok (1, "server stopped");
