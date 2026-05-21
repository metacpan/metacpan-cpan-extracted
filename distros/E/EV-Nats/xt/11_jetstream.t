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
my $stream = "EV_NATS_TEST_JS_$$";

js_or_skip($nats, sub {
    my ($done) = @_;
    $js->stream_create({ name => $stream, subjects => ["evnats.test.$$.>"] },
                       sub { $done->($_[1]) });
});

plan tests => 5;
pass 'stream_create';

# Publish three messages with ack
my @ack_seqs;
my $publish_one;
$publish_one = sub {
    my $i = shift;
    $js->js_publish("evnats.test.$$.msg", "payload-$i", sub {
        my ($ack, $err) = @_;
        diag "publish err: $err" if $err;
        push @ack_seqs, $ack->{seq} if $ack;
        if ($i < 3) { $publish_one->($i + 1) }
        else        { EV::break }
    });
};
$publish_one->(1);
EV::timer(5, 0, sub { EV::break });
EV::run;
is scalar @ack_seqs, 3, 'js_publish acked 3 messages';

# Pull-fetch via durable consumer
$js->consumer_create($stream, {
    durable_name => 'puller',
    ack_policy   => 'explicit',
}, sub {
    my (undef, $err) = @_;
    diag "consumer_create err: $err" if $err;
    EV::break;
});
EV::timer(3, 0, sub { EV::break });
EV::run;

my $fetched;
$js->fetch($stream, 'puller', { batch => 3, expires => 1_000_000_000 }, sub {
    my ($msgs, $err) = @_;
    $fetched = $err ? "ERR $err" : $msgs;
    EV::break;
});
EV::timer(5, 0, sub { EV::break });
EV::run;
ok ref($fetched) eq 'ARRAY', 'fetch returned an array';
is scalar @$fetched, 3, 'fetch got 3 messages' if ref $fetched eq 'ARRAY';

# stream_info round-trip
$js->stream_info($stream, sub {
    my ($info, $err) = @_;
    ok !$err && $info->{config}{name} eq $stream, 'stream_info round-trip'
        or diag "err: $err";
    EV::break;
});
EV::timer(3, 0, sub { EV::break });
EV::run;

# Cleanup
$js->stream_delete($stream, sub { EV::break });
EV::timer(3, 0, sub { EV::break });
EV::run;
$nats->disconnect;
