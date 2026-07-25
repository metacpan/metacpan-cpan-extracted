use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use EVKafkaTest;
use EV;
use EV::Kafka;

# Mock-based coverage for the assertions in the skip_all integration
# files t/01-t/05 and t/12-t/14 that had NO existing mock equivalent.
# See the coverage audit (batch 5): conn-level api_versions/produce/
# fetch/list_offsets/init_producer_id, and client-level commit/
# unsubscribe/send_offsets_to_transaction/commit_transaction.
#
# A: api_versions() XSUB against a real handshake        (t/01)
# B: conn->produce acks=1 result shape                   (t/02)
# C: conn->list_offsets + conn->fetch with records       (t/03)
# D: conn->init_producer_id with a transactional_id      (t/13)
# E: client commit() + unsubscribe() success paths       (t/05)
# F: full EOS flow: begin/produce/send_offsets/commit    (t/14)

plan tests => 34;

sub frames { grep { $_->{api} == $_[1] } @{ $_[0]{requests} } }

# --- A: api_versions() -----------------------------------------------------
{
    my ($conn, $broker) = ready_conn();
    my $v = $conn->api_versions;
    ok ref $v eq 'HASH', 'A: api_versions returns a hashref';
    is $v->{0}, 7, 'A: Produce API advertised at v7';
    is $v->{18}, 0, 'A: ApiVersions API itself advertised';
    eval { $conn->disconnect; };
}

# --- B: conn->produce with acks=1 -------------------------------------------
{
    my ($conn, $broker) = ready_conn();
    my (@p1, @p2);
    $conn->produce('t1', 0, 'k1', 'v1', sub { @p1 = @_; EV::break });
    my $t = timeout_w();
    EV::run;
    undef $t;
    ok !$p1[1], 'B: produce: no error';
    ok ref $p1[0] eq 'HASH', 'B: produce: got result hash';
    is $p1[0]{topics}[0]{partitions}[0]{error_code}, 0,
        'B: partition error_code=0';
    is $p1[0]{topics}[0]{partitions}[0]{base_offset}, 0,
        'B: first produce lands at base_offset 0';
    $conn->produce('t1', 0, 'k2', 'v2', sub { @p2 = @_; EV::break });
    $t = timeout_w();
    EV::run;
    is $p2[0]{topics}[0]{partitions}[0]{base_offset}, 1,
        'B: second produce advances to base_offset 1';
    eval { $conn->disconnect; };
}

# --- C: conn->list_offsets + conn->fetch ------------------------------------
{
    my ($conn, $broker) = ready_conn();
    $broker->{fetch_records}{'t1:0'} = [{ key => 'fk', value => 'fv' }];
    my (@lo, @fe, @lo2);
    $conn->list_offsets('t1', 0, -2, sub { @lo = @_; EV::break });
    my $t = timeout_w();
    EV::run;
    undef $t;
    ok !$lo[1], 'C: list_offsets: no error';
    is $lo[0]{topics}[0]{partitions}[0]{offset}, 0,
        'C: earliest offset is 0';
    $conn->fetch('t1', 0, 0, sub { @fe = @_; EV::break });
    $t = timeout_w();
    EV::run;
    undef $t;
    ok !$fe[1], 'C: fetch: no error';
    my $recs = $fe[0]{topics}[0]{partitions}[0]{records};
    is scalar @$recs, 1, 'C: one record fetched';
    is_deeply [map { @$_{qw(key value)} } @$recs], ['fk', 'fv'],
        'C: fetched record matches produced key/value';
    $conn->list_offsets('t1', 0, -1, sub { @lo2 = @_; EV::break });
    $t = timeout_w();
    EV::run;
    is $lo2[0]{topics}[0]{partitions}[0]{offset}, 1,
        'C: latest offset is 1 after the produce-side counter advanced';
    eval { $conn->disconnect; };
}

# --- D: conn->init_producer_id with a transactional_id ----------------------
{
    my ($conn, $broker) = ready_conn();
    my @r;
    $conn->init_producer_id('txn-test', 30000, sub { @r = @_; EV::break });
    my $t = timeout_w();
    EV::run;
    ok !$r[1], 'D: init_producer_id: no error';
    is $r[0]{error_code}, 0, 'D: error_code 0';
    is $r[0]{producer_id}, 1000, 'D: producer_id assigned by broker';
    my ($req) = frames($broker, 22);
    is $req->{body}, kstr('txn-test') . i32(30000),
        'D: transactional_id and timeout on the wire';
    eval { $conn->disconnect; };
}

# --- E: client commit() + unsubscribe() --------------------------------------
{
    my ($port, $broker) = mock_broker(topics => { t1 => 1 });
    $broker->{committed}{'t1:0'}     = 0;
    $broker->{fetch_records}{'t1:0'} = [{ key => 'gk', value => 'gv' }];
    $broker->{hold_fetch} = 1;      # deterministic single delivery
    my (@errs, @msgs, $assigned, $commit_err, $unsubbed);
    my $k = EV::Kafka->new(
        brokers    => "127.0.0.1:$port",
        on_error   => sub { push @errs, $_[0] },
        on_message => sub { push @msgs, [@_]; EV::break },
    );
    $k->connect(sub { EV::break });
    my $t = timeout_w();
    EV::run;
    undef $t;

    $k->subscribe('t1',
        group_id           => 'g1',
        heartbeat_interval => 60,
        on_assign          => sub { $assigned = $_[0] },
    );
    # Wait for the group fetch loop's first (held) fetch, then release it.
    my $w; $w = EV::timer 0, 0.02, sub {
        return unless @{ $broker->{held_fetch} // [] };
        undef $w;
        release_held_fetch($broker, 1);
    };
    $t = timeout_w();
    EV::run;    # breaks in on_message
    undef $t; undef $w;

    ok((ref $assigned eq 'ARRAY')
        && (grep { $_->{topic} eq 't1' && $_->{partition} == 0 } @$assigned),
        'E: on_assign fires with t1:0');
    is_deeply [@{ $msgs[0] }[0, 1, 3, 4]], ['t1', 0, 'gk', 'gv'],
        'E: message received via consumer group';

    $k->commit(sub { $commit_err = $_[0]; EV::break });
    $t = timeout_w();
    EV::run;
    undef $t;
    ok !defined($commit_err), 'E: commit completed without error';
    is $broker->{committed}{'t1:0'}, 1,
        'E: committed offset advanced past the consumed record';
    my ($oc) = frames($broker, 8);
    is $oc->{group_id}, 'g1', 'E: OffsetCommit went to the group coordinator';

    $k->unsubscribe(sub { $unsubbed = 1; EV::break });
    $t = timeout_w();
    EV::run;
    undef $t;
    ok $unsubbed, 'E: unsubscribe callback fired';
    ok scalar(frames($broker, 13)), 'E: LeaveGroup sent to the coordinator';
}

# --- F: full EOS flow ---------------------------------------------------------
{
    my ($port, $broker) = mock_broker(topics => { src => 1, out => 1 });
    my (@errs, @pcb, @ocb, @ccb);
    my $k = EV::Kafka->new(
        brokers          => "127.0.0.1:$port",
        acks             => -1,
        transactional_id => 'eos-mock',
        on_error         => sub { push @errs, $_[0] },
    );
    $k->connect(sub { EV::break });
    my $t = timeout_w();
    EV::run;
    undef $t;
    is $k->{cfg}{producer_id}, 1000,
        'F: producer_id initialized at connect';

    $k->begin_transaction;
    $k->produce('out', 'k', 'v', sub { @pcb = @_; EV::break });
    $t = timeout_w();
    EV::run;
    undef $t;
    ok !$pcb[1], 'F: transactional produce ok';
    my ($apt) = frames($broker, 24);
    ok(($apt && index($apt->{body}, "\x00\x03out") >= 0),
        'F: AddPartitionsToTxn covered the output topic');
    my ($pf) = frames($broker, 0);
    is $pf->{producer_id}, 1000,
        'F: produce frame carries the transactional producer_id';

    $k->assign([{ topic => 'src', partition => 0, offset => 1 }]);
    $k->send_offsets_to_transaction('g1', sub { @ocb = @_; EV::break });
    $t = timeout_w();
    EV::run;
    undef $t;
    ok !$ocb[1], 'F: send_offsets_to_transaction completed';
    my ($toc) = frames($broker, 28);
    ok(($toc && $toc->{transactional_id} eq 'eos-mock'
        && $toc->{group_id} eq 'g1'),
        'F: TxnOffsetCommit carries the txn id and group');
    is $broker->{txn_committed}{'src:0'}, 1,
        'F: consumer offset committed inside the transaction';

    $k->commit_transaction(sub { @ccb = @_; EV::break });
    $t = timeout_w();
    EV::run;
    undef $t;
    ok !$ccb[1], 'F: commit_transaction completed';
    is $broker->{end_txn_last_committed}, 1,
        'F: EndTxn reached the broker with committed=1';
}
