use strict;
use warnings;
use Test::More tests => 4;

use_ok 'EV::Kafka';

my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
isa_ok $conn, 'EV::Kafka::Conn';
ok !$conn->connected, 'not connected initially';

my $kafka = EV::Kafka::_new('EV::Kafka', undef);
isa_ok $kafka, 'EV::Kafka';
