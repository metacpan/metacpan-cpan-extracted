use strict;
use warnings;
use Test::More tests => 7;

use_ok 'EV::Nats';
use_ok 'EV::Nats::JetStream';
use_ok 'EV::Nats::KV';
use_ok 'EV::Nats::ObjectStore';

is $EV::Nats::JetStream::VERSION, $EV::Nats::VERSION, 'JetStream VERSION in sync';
is $EV::Nats::KV::VERSION,         $EV::Nats::VERSION, 'KV VERSION in sync';
is $EV::Nats::ObjectStore::VERSION, $EV::Nats::VERSION, 'ObjectStore VERSION in sync';
