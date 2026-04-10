use strict;
use warnings;
use Test::More;
use EV;
use EV::Kafka;

plan tests => 6;

# test that on_error fires on connection refused
{
    my $error;
    my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    $conn->on_error(sub { $error = $_[0]; EV::break });
    $conn->connect('127.0.0.1', 19999, 2.0); # nothing listening
    my $t = EV::timer 3, 0, sub { EV::break };
    EV::run;
    ok defined $error, 'on_error fired on connection refused';
    like $error, qr/connect|refused|timeout/i, 'error message is meaningful';
}

# test that produce before connect croaks
{
    my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    eval { $conn->produce('t', 0, 'k', 'v', sub {}) };
    like $@, qr/not connected/, 'produce before connect croaks';
}

# test that fetch before connect croaks
{
    my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    eval { $conn->fetch('t', 0, 0, sub {}) };
    like $@, qr/not connected/, 'fetch before connect croaks';
}

# test that metadata before connect croaks
{
    my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    eval { $conn->metadata(undef, sub {}) };
    like $@, qr/not connected/, 'metadata before connect croaks';
}

# test cluster produce before connect queues (doesn't crash)
{
    my $kafka = EV::Kafka->new(
        brokers  => '127.0.0.1:19999',
        on_error => sub {},
    );
    # produce before connect - should queue, not crash
    eval { $kafka->produce('test', 'k', 'v') };
    ok !$@, 'produce before connect does not crash';
}
