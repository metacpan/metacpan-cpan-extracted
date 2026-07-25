use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use EVKafkaTest;
use EV;
use EV::Kafka;

# Regression tests for C5/C6/C7 (idempotent producer init + fencing):
#   I1  P5: a produce landing between metadata and InitProducerId is
#       QUEUED, never sent non-idempotent. Zero Produce frames before
#       InitProducerId completes; the frames after carry producer_id >= 0.
#   I2  InitProducerId failure is sticky: connect cb and produce cbs get
#       errors, on_error fires once, nothing is ever produced.
#   I3  C6: DUPLICATE_SEQUENCE (46) is an ack — cb success, no re-send,
#       no re-init (frame counts, not just cb args).
#   I4  C6: two partitions fenced with INVALID_PRODUCER_EPOCH (47)
#       simultaneously share ONE re-init (single-flight), then recover.
#   I5  C7: a late OUT_OF_ORDER_SEQUENCE (45) for an aborted
#       transaction's batch is delivered but never requeued/re-sent.
#
# Uses the shared in-process mock broker (t/lib/EVKafkaTest.pm).

plan tests => 25;

sub produce_frames { grep { $_->{api} == 0 } @{$_[0]{requests}} }
sub init_frames    { grep { $_->{api} == 22 } @{$_[0]{requests}} }

# --- I1: the P5 race -------------------------------------------------------
{
    # InitProducerId answered 100ms late
    my ($port, $broker) = mock_broker(
        topics  => { t1 => 1 },
        respond => { 22 => sub {
            my ($req, $send, $conn, $ctx) = @_;
            push @{$ctx->{timers}}, EV::timer(0.1, 0, sub {
                $send->($req->{corr}, i32(0) . i16(0) . i64(1000) . i16(0));
            });
            return undef;
        } },
    );
    my @pcb;
    my $k = EV::Kafka->new(
        brokers    => "127.0.0.1:$port",
        idempotent => 1,
        on_error   => sub { },
    );
    $k->connect(sub { });
    # produce at 30ms: metadata is done, InitProducerId still in flight
    my $pt = EV::timer 0.03, 0, sub {
        $k->produce('t1', 'k', 'v', sub { push @pcb, [@_] });
    };
    my $early = EV::timer 0.06, 0, sub { EV::break };
    my $t = timeout_w();
    EV::run;
    is scalar(produce_frames($broker)), 0,
        'I1: zero Produce frames before InitProducerId completes';

    my $late = EV::timer 0.25, 0, sub { EV::break };
    EV::run;
    my @pf = produce_frames($broker);
    cmp_ok scalar(@pf), '>=', 1, 'I1: Produce flowed after init';
    ok(!grep({ ($_->{producer_id} // -1) < 0 } @pf),
        'I1: every Produce frame carries producer_id >= 0');
    is scalar(@pcb), 1, 'I1: produce callback fired';
}

# --- I2: sticky InitProducerId failure -------------------------------------
{
    my ($port, $broker) = mock_broker(topics => { t1 => 1 });
    $broker->{init_producer_error} = 42;
    my (@errs, @ccb, @pcb);
    my $k = EV::Kafka->new(
        brokers    => "127.0.0.1:$port",
        idempotent => 1,
        on_error   => sub { push @errs, $_[0] },
    );
    $k->produce('t1', 'k', 'v', sub { push @pcb, [@_] });
    $k->connect(sub { push @ccb, [@_]; EV::break });
    my $t = timeout_w(8);
    EV::run;

    is scalar(@ccb), 1, 'I2: connect callback fired';
    like $ccb[0][1] // '', qr/InitProducerId/,
        'I2: connect callback got the init error';
    is scalar(@pcb), 1, 'I2: queued produce callback failed';
    like $pcb[0][1] // '', qr/idempotent producer unavailable/,
        'I2: produce callback got the sticky error';
    is scalar(grep { /InitProducerId/ } @errs), 1,
        'I2: on_error fired exactly once for the init failure';
    is scalar(produce_frames($broker)), 0, 'I2: nothing was ever produced';

    # produce after the failure: immediate error, still no frames
    my @late;
    $k->produce('t1', 'k', 'v2', sub { push @late, [@_] });
    is scalar(@late), 1, 'I2: post-failure produce fails immediately';
    like $late[0][1] // '', qr/idempotent producer unavailable/,
        'I2: post-failure produce gets the sticky error';
}

# --- I3: 46 is an ack --------------------------------------------------------
{
    my ($port, $broker) = mock_broker(topics => { t1 => 1 });
    my $fired = 0;
    $broker->{produce_error} = sub { $fired++ ? 0 : 46 };
    my @pcb;
    my $k = EV::Kafka->new(
        brokers    => "127.0.0.1:$port",
        idempotent => 1,
        on_error   => sub { },
    );
    $k->connect(sub {
        $k->produce('t1', 'k', 'v', sub { push @pcb, [@_]; EV::break });
    });
    my $t = timeout_w();
    EV::run;

    is scalar(@pcb), 1, 'I3: produce callback fired';
    ok !$pcb[0][1] && $pcb[0][0]
        && ($pcb[0][0]{topics}[0]{partitions}[0]{error_code} // -1) == 0,
        'I3: 46 delivered as a clean ack';
    is scalar(produce_frames($broker)), 1,
        'I3: batch NOT re-sent (one Produce frame)';
    is scalar(init_frames($broker)), 1,
        'I3: no re-init (one InitProducerId)';
}

# --- I4: two partitions fenced with 47 -> ONE re-init -----------------------
{
    my ($port, $broker) = mock_broker(topics => { t2 => 2 });
    my %seen;
    $broker->{produce_error} = sub {
        my ($topic, $pid) = @_;
        return $seen{"$topic:$pid"}++ ? 0 : 47;
    };
    my (@p0, @p1);
    my $k = EV::Kafka->new(
        brokers    => "127.0.0.1:$port",
        idempotent => 1,
        on_error   => sub { },
    );
    my $done = 0;
    $k->connect(sub {
        $k->produce('t2', 'k', 'v0', { partition => 0 }, sub { push @p0, [@_] });
        $k->produce('t2', 'k', 'v1', { partition => 1 },
            sub { push @p1, [@_]; EV::break if @p0 });
    });
    # also break when p1 is second
    my $w = EV::timer 0, 0.02, sub { EV::break if @p0 && @p1 };
    my $t = timeout_w();
    EV::run;

    ok !$p0[0][1] && $p0[0][0]
        && ($p0[0][0]{topics}[0]{partitions}[0]{error_code} // -1) == 0,
        'I4: partition 0 recovered with a clean ack';
    ok !$p1[0][1] && $p1[0][0]
        && ($p1[0][0]{topics}[0]{partitions}[0]{error_code} // -1) == 0,
        'I4: partition 1 recovered with a clean ack';
    is scalar(produce_frames($broker)), 4,
        'I4: 2 fenced + 2 retried Produce frames';
    is scalar(init_frames($broker)), 2,
        'I4: initial init + exactly ONE shared re-init';
}

# --- I5: late 45 for an aborted batch is never resurrected ------------------
{
    my @held;
    my ($port, $broker) = mock_broker(
        topics  => { t1 => 1 },
        respond => { 0 => sub {
            my ($req, $send) = @_;
            push @held, [$req, $send];
            return undef;   # hold the Produce response
        } },
    );
    my (@pcb, @acb);
    my $k = EV::Kafka->new(
        brokers          => "127.0.0.1:$port",
        transactional_id => 'tx-i5',
        on_error         => sub { },
    );
    $k->connect(sub { EV::break });
    my $t = timeout_w();
    EV::run;

    $k->begin_transaction;
    $k->produce('t1', 'k', 'v', sub { push @pcb, [@_] });
    # wait for the Produce frame to be in flight (held by the mock)
    my $w; $w = EV::timer 0, 0.005, sub {
        return unless produce_frames($broker);
        undef $w; EV::break;
    };
    EV::run;

    $k->abort_transaction(sub { push @acb, [@_]; EV::break });
    EV::run;

    # NOW the broker answers the held Produce with OUT_OF_ORDER_SEQUENCE
    my ($req, $send) = @{$held[0]};
    $send->($req->{corr},
        i32(1) . kstr('t1') . i32(1)
        . i32(0) . i16(45) . i64(0) . i64(-1) . i64(0)
        . i32(0));
    my $settle = EV::timer 0.3, 0, sub { EV::break };
    EV::run;

    is scalar(produce_frames($broker)), 1,
        'I5: aborted batch never re-sent';
    is scalar(init_frames($broker)), 1,
        'I5: no re-init from the late 45';
    is scalar(@pcb), 1, 'I5: late response still delivered to the produce cb';

    # client is still functional afterwards
    delete $broker->{respond}{0};    # restore built-in produce handler
    $k->begin_transaction;
    my (@ok, @txn);
    $k->produce('t1', 'k', 'v2', sub { push @ok, [@_] });
    $k->commit_transaction(sub { push @txn, [@_]; EV::break });
    EV::run;
    is scalar(produce_frames($broker)), 2,
        'I5: client produces normally in a new transaction';
    ok !($txn[0][1] // '') && @txn, 'I5: commit_transaction succeeded';
}
