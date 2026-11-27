use strict;
use warnings;
use Test::More tests => 8;

use_ok $_ for qw(EV EV::Nats EV::Nats::JetStream EV::Nats::KV EV::Nats::ObjectStore);

is $EV::Nats::JetStream::VERSION,   $EV::Nats::VERSION, 'JetStream VERSION in sync';
is $EV::Nats::KV::VERSION,          $EV::Nats::VERSION, 'KV VERSION in sync';
is $EV::Nats::ObjectStore::VERSION, $EV::Nats::VERSION, 'ObjectStore VERSION in sync';

diag "EV::Nats $EV::Nats::VERSION, EV $EV::VERSION, Perl $]";
