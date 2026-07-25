use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use EVKafkaTest;
use EV;
use EV::Kafka;

# Regression tests for C4 (cluster-client reconnection + flush timeout):
#   R1  a broker bounce no longer strands queued produces: the conn
#       auto-reconnects and the queued op drains and completes
#   R2  a broker that stays down produces exactly ONE user-visible
#       report (the on_disconnect notice), not one per reconnect retry
#   R3  the user's connect callback (and on_connect handler) cannot
#       fire twice when auto_reconnect refires conn on_connect
#   R4  flush() honors flush_timeout with an error to its callback
#
# Uses the shared in-process mock broker (t/lib/EVKafkaTest.pm).

plan tests => 13;

# --- R1: bounce -> queued produce completes ------------------------------
{
    my ($port, $broker) = mock_broker(topics => { t1 => 1 });
    my (@errs, @pcb);
    my $k = EV::Kafka->new(
        brokers  => "127.0.0.1:$port",
        on_error => sub { push @errs, $_[0] },
    );
    $k->connect(sub { EV::break });
    my $t = timeout_w();
    EV::run;

    # baseline produce works
    $k->produce('t1', 'k', 'v1', sub { push @pcb, [@_]; EV::break });
    EV::run;
    is scalar(@pcb), 1, 'R1: baseline produce completed';

    # bounce the broker: conns drop, listener stays up
    my $accepts0 = $broker->{accepts};
    $broker->{close_all}();

    # queued while the conn is down; must complete after reconnect
    $k->produce('t1', 'k', 'v2', sub { push @pcb, [@_]; EV::break });
    my $t2 = timeout_w(8);
    EV::run;

    is scalar(@pcb), 2, 'R1: queued produce completed after bounce';
    ok !$pcb[1][1] && defined $pcb[1][0],
        'R1: queued produce succeeded (no error)';
    cmp_ok $broker->{accepts}, '>', $accepts0,
        'R1: client reconnected (new accept)';
    is scalar(grep { $_->{api} == 0 } @{$broker->{requests}}), 2,
        'R1: both records reached the broker (no duplicate send)';
    is scalar(@errs), 1, 'R1: exactly one loss report';
    like $errs[0] // '', qr/lost|disconnect/i,
        'R1: the one report is the disconnect notice';
}

# --- R2: broker stays down -> one report across retries -------------------
{
    my ($port, $broker) = mock_broker(topics => { t1 => 1 });
    my @errs;
    my $k = EV::Kafka->new(
        brokers  => "127.0.0.1:$port",
        on_error => sub { push @errs, $_[0] },
    );
    $k->connect(sub { EV::break });
    my $t = timeout_w();
    EV::run;

    $broker->{shutdown}();   # conns dropped AND listener closed (refused)

    # several reconnect attempts (1s delay each) against a dead broker
    my $done = EV::timer 2.6, 0, sub { EV::break };
    EV::run;

    is scalar(@errs), 1, 'R2: exactly one report across several retries';
    like $errs[0] // '', qr/lost|disconnect/i,
        'R2: the one report is the disconnect notice';
}

# --- R3: connect callback cannot refire after reconnect -------------------
{
    my ($port, $broker) = mock_broker(topics => { t1 => 1 });
    my (@ccb, @onc);
    my $k = EV::Kafka->new(
        brokers   => "127.0.0.1:$port",
        on_error  => sub { },
        on_connect => sub { push @onc, 1 },
    );
    $k->connect(sub { push @ccb, 1; EV::break });
    my $t = timeout_w();
    EV::run;

    $broker->{close_all}();
    my $accepts0 = $broker->{accepts};
    # wait for the reconnect, then some settle time
    my $wait; $wait = EV::timer 0, 0.05, sub {
        return unless $broker->{accepts} > $accepts0;
        undef $wait; EV::break;
    };
    my $t2 = timeout_w(8);
    EV::run;
    my $done = EV::timer 0.3, 0, sub { EV::break };
    EV::run;

    is scalar(@ccb), 1, 'R3: connect callback fired exactly once';
    is scalar(@onc), 1, 'R3: on_connect handler fired exactly once';
}

# --- R4: flush timeout -----------------------------------------------------
{
    my ($port, $broker) = mock_broker(
        topics  => { t1 => 1 },
        respond => { 0 => sub { undef } },   # swallow Produce
    );
    my @fcb;
    my $k = EV::Kafka->new(
        brokers       => "127.0.0.1:$port",
        flush_timeout => 0.3,
        on_error      => sub { },
    );
    $k->connect(sub { EV::break });
    my $t = timeout_w();
    EV::run;

    $k->produce('t1', 'k', 'v');
    $k->flush(sub { push @fcb, [@_]; EV::break });
    my $t2 = timeout_w(8);
    EV::run;
    is scalar(@fcb), 1, 'R4: flush callback fired';
    like $fcb[0][0] // '', qr/timed out/, 'R4: flush callback got the timeout error';
}
