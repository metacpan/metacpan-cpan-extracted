use strict;
use warnings;
use Test::More;
use lib 'xt/lib';
use EVNatsHelpers qw(nats_or_skip js_or_skip);
use EV;
use EV::Nats;
use EV::Nats::JetStream;

my ($host, $port) = nats_or_skip();
my $nats   = EV::Nats->new(host => $host, port => $port);
my $js     = EV::Nats::JetStream->new(nats => $nats, timeout => 2000);
my $stream = "EV_NATS_TEST_ACK_$$";

js_or_skip($nats, sub {
    my ($d) = @_;
    $js->stream_create({ name => $stream, subjects => ["ack.test.$$.>"] },
                       sub { $d->($_[1]) });
});

plan tests => 5;
pass 'stream_create';

# Publish two messages.
my $published = 0;
my $publish_one;
$publish_one = sub {
    my $i = shift;
    $js->js_publish("ack.test.$$.msg", "payload-$i", sub {
        $published++;
        if ($i < 2) { $publish_one->($i + 1) }
        else        { EV::break }
    });
};
$publish_one->(1);
EV::timer(5, 0, sub { EV::break });
EV::run;
is $published, 2, 'published 2 messages';

# Durable pull consumer with explicit ack.
$js->consumer_create($stream, {
    durable_name => 'acker',
    ack_policy   => 'explicit',
    ack_wait     => 1_000_000_000,  # 1s — short enough to test NAK redelivery
}, sub { EV::break });
EV::timer(3, 0, sub { EV::break });
EV::run;

# Fetch 2: ACK first, NAK second.
my $first_fetch;
$js->fetch($stream, 'acker', { batch => 2, expires => 1_000_000_000 }, sub {
    $first_fetch = $_[0];
    EV::break;
});
EV::timer(5, 0, sub { EV::break });
EV::run;
is scalar(@$first_fetch), 2, 'first fetch got 2 messages'
    or diag explain $first_fetch;

if (@$first_fetch == 2) {
    $nats->publish($first_fetch->[0]{reply}, '+ACK');
    $nats->publish($first_fetch->[1]{reply}, '-NAK');
}

# Refetch: NAK'd message should be redelivered.
my $second_fetch;
$js->fetch($stream, 'acker', { batch => 1, expires => 2_000_000_000 }, sub {
    $second_fetch = $_[0];
    EV::break;
});
EV::timer(5, 0, sub { EV::break });
EV::run;

is scalar(@$second_fetch), 1, 'second fetch redelivered NAK\'d message'
    or diag explain $second_fetch;

# ACK the redelivered message and confirm there are no more.
if (@$second_fetch == 1) {
    $nats->publish($second_fetch->[0]{reply}, '+ACK');
}

my $third_fetch;
$js->fetch($stream, 'acker', { batch => 1, expires => 500_000_000, no_wait => 1 }, sub {
    $third_fetch = $_[0];
    EV::break;
});
EV::timer(5, 0, sub { EV::break });
EV::run;

is scalar(@$third_fetch), 0, 'third fetch returns no messages';

$js->stream_delete($stream, sub { EV::break });
EV::timer(3, 0, sub { EV::break });
EV::run;
$nats->disconnect;
