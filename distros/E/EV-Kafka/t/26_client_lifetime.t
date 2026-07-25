use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use EVKafkaTest;
use Scalar::Util 'weaken';
use EV;
use EV::Kafka;

# Regression tests for the client-lifetime contract (CLIENT LIFETIME in
# the EV::Kafka POD):
#   L1  connect -> produce -> flush works against the mock broker
#   L2  a connected client is collectible when dropped (no cycles)
#   L3  pre-metadata produce no longer pins the client (pending_ops
#       cycle); dropping fails the queued callback with an error
#   L4  dropping mid-connect fails the connect AND queued produce
#       callbacks with an error
#   L5  bootstrap failover to the next broker still leaves a collectible
#       client, and fires the connect callback exactly once
#   L6  an armed periodic metadata timer does not pin the client
#   L7  poll with an empty assignment invokes its callback (C3)
#   L8  poll queued pre-metadata drains after connect and fires (C3)
#   L9  poll with only unknown-leader assignments fires its callback (C3)
#
# Uses the shared in-process mock broker (t/lib/EVKafkaTest.pm).

plan tests => 23;

# --- L1/L2: full lifecycle, then collect --------------------------------
{
    my ($port, $broker) = mock_broker(topics => { t1 => 1 });
    my (@errs, @ccb, @pcb);
    my $flushed = 0;
    my $k = EV::Kafka->new(
        brokers  => "127.0.0.1:$port",
        on_error => sub { push @errs, $_[0] },
    );
    weaken(my $weak = $k);
    $k->connect(sub {
        my ($meta, $err) = @_;
        push @ccb, [$meta, $err];
        $k->produce('t1', 'k', 'v', sub { push @pcb, [@_] });
        $k->flush(sub { $flushed = 1; EV::break });
    });
    my $t = timeout_w();
    EV::run;

    ok $ccb[0] && $ccb[0][0]{brokers} && !$ccb[0][1],
        'L1: connect callback fired with metadata';
    is scalar(@ccb), 1, 'L1: connect callback fired exactly once';
    ok $pcb[0] && defined $pcb[0][0] && !$pcb[0][1],
        'L1: produce callback fired with a result';
    ok $flushed, 'L1: flush completed';
    is scalar(@errs), 0, 'L1: no errors';

    undef $k;
    ok !defined($weak), 'L2: dropped client is collected (no cycles)';
}

# --- L3: pending_ops cycle, no broker at all ----------------------------
{
    my @pcb;
    my $k = EV::Kafka->new(
        brokers  => '127.0.0.1:1',   # nothing listening; never connect
        on_error => sub { },
    );
    weaken(my $weak = $k);
    $k->produce('t1', 'k', 'v', sub { push @pcb, [@_] });
    undef $k;
    ok !defined($weak), 'L3: pre-metadata produce does not pin the client';
    is scalar(@pcb), 1, 'L3: queued produce callback fired at teardown';
    like $pcb[0][1] // '', qr/client closed/,
        'L3: queued produce callback got the teardown error';
}

# --- L4: dropped mid-connect ---------------------------------------------
{
    my ($port, $broker) = mock_broker(
        topics  => { t1 => 1 },
        respond => { 3 => sub {
            my ($req, $send, $conn, $ctx) = @_;
            push @{$ctx->{timers}}, EV::timer(0.3, 0, sub {
                $send->($req->{corr}, metadata_v1(
                    port => $ctx->{port}, topics => $ctx->{topics}));
            });
            return undef;
        } },
    );
    my (@ccb, @pcb, @warns);
    local $SIG{__WARN__} = sub { push @warns, $_[0] };
    my $k = EV::Kafka->new(
        brokers  => "127.0.0.1:$port",
        on_error => sub { },
    );
    weaken(my $weak = $k);
    $k->connect(sub { push @ccb, [@_] });
    $k->produce('t1', 'k', 'v', sub { push @pcb, [@_] });

    # run until the metadata request is in flight, then drop the client
    my $wait; $wait = EV::timer 0, 0.005, sub {
        return unless grep { $_->{api} == 3 } @{$broker->{requests}};
        undef $wait;
        EV::break;
    };
    my $t = timeout_w();
    EV::run;
    undef $k;
    ok !defined($weak), 'L4: client dropped mid-connect is collected';
    is scalar(@ccb), 1, 'L4: connect callback fired at teardown';
    like $ccb[0][1] // '', qr/client closed/,
        'L4: connect callback got the teardown error';
    is scalar(@pcb), 1, 'L4: queued produce callback fired at teardown';

    # let the mock's delayed metadata response hit the dead conn
    my $done = EV::timer 0.6, 0, sub { EV::break };
    EV::run;
    is scalar(grep { /EV::Kafka/ } @warns), 0,
        'L4: no warnings from late broker traffic after teardown';
}

# --- L5: bootstrap failover ----------------------------------------------
{
    my $dead = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 1,
        Proto => 'tcp', ReuseAddr => 1,
    ) or BAIL_OUT "cannot bind: $!";
    my $dead_port = $dead->sockport;
    close $dead;

    my ($port, $broker) = mock_broker(topics => { t1 => 1 });
    my @ccb;
    my $k = EV::Kafka->new(
        brokers  => "127.0.0.1:$dead_port,127.0.0.1:$port",
        on_error => sub { },
    );
    weaken(my $weak = $k);
    $k->connect(sub { push @ccb, [@_]; EV::break });
    my $t = timeout_w();
    EV::run;
    ok $ccb[0] && $ccb[0][0]{brokers}, 'L5: failover connect succeeded';
    is scalar(@ccb), 1, 'L5: connect callback fired exactly once';
    undef $k;
    ok !defined($weak), 'L5: client collectible after failover connect';
}

# --- L6: armed metadata timer does not pin the client --------------------
{
    my ($port, $broker) = mock_broker(topics => { t1 => 1 });
    my $k = EV::Kafka->new(
        brokers          => "127.0.0.1:$port",
        metadata_refresh => 0.1,
        on_error         => sub { },
    );
    weaken(my $weak = $k);
    $k->connect(sub { });
    my $ticks = 0;
    my $wait; $wait = EV::timer 0, 0.02, sub {
        my $n = grep { $_->{api} == 3 } @{$broker->{requests}};
        if ($n >= 2) { $ticks = $n; undef $wait; EV::break }
    };
    my $t = timeout_w();
    EV::run;
    cmp_ok $ticks, '>=', 2, 'L6: periodic metadata refresh ticked';
    undef $k;
    ok !defined($weak), 'L6: armed metadata timer does not pin the client';
}

# --- L7: poll with empty assignment fires its callback -------------------
{
    my $k = EV::Kafka->new(brokers => '127.0.0.1:1', on_error => sub { });
    my $fired = 0;
    $k->poll(sub { $fired++ });
    is $fired, 1, 'L7: empty-assignment poll fires callback synchronously';
}

# --- L8: queued poll drains after connect --------------------------------
{
    my ($port, $broker) = mock_broker(topics => { t1 => 1 });
    my $k = EV::Kafka->new(
        brokers  => "127.0.0.1:$port",
        on_error => sub { },
    );
    $k->assign([{ topic => 't1', partition => 0, offset => 0 }]);
    my $fired = 0;
    $k->poll(sub { $fired++; EV::break });
    $k->connect(sub { });
    my $t = timeout_w();
    EV::run;
    is $fired, 1, 'L8: pre-metadata poll fires after connect';
    ok scalar(grep { $_->{api} == 1 } @{$broker->{requests}}),
        'L8: a Fetch request reached the broker';
}

# --- L9: poll with unknown-leader assignment fires its callback ----------
{
    my ($port, $broker) = mock_broker(topics => { t1 => 1 });
    my $k = EV::Kafka->new(
        brokers  => "127.0.0.1:$port",
        on_error => sub { },
    );
    $k->connect(sub { EV::break });
    my $t = timeout_w();
    EV::run;
    $k->assign([{ topic => 'no-such-topic', partition => 0, offset => 0 }]);
    my $fired = 0;
    $k->poll(sub { $fired++ });
    is $fired, 1, 'L9: unknown-leader poll fires its callback';
}
