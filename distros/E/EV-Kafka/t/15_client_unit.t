use strict;
use warnings;
use Test::More;
use EV;
use EV::Kafka;

plan tests => 22;

# SASL plaintext warning
{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    my $k = EV::Kafka->new(
        brokers => '127.0.0.1:9092',
        sasl    => { mechanism => 'PLAIN', username => 'u', password => 'p' },
    );
    ok scalar(grep { /SASL PLAIN configured without TLS/ } @warnings),
        'SASL PLAIN without TLS warns';
    @warnings = ();
    my $k2 = EV::Kafka->new(
        brokers => '127.0.0.1:9092',
        tls     => 1,
        sasl    => { mechanism => 'PLAIN', username => 'u', password => 'p' },
    );
    ok !scalar(grep { /without TLS/ } @warnings),
        'SASL PLAIN with TLS does not warn';
}

# _refresh_metadata_for_topic retry cap: the error goes to the operation
# callback if one was given, else to on_error — never both (C11 rule; the
# default on_error dies, so double-reporting would be fatal).
{
    my $k = EV::Kafka->new(brokers => '127.0.0.1:9092');
    my $cfg = $k->{cfg};
    my @errs;
    $cfg->{on_error} = sub { push @errs, $_[0] };
    # Simulate exhaustion: bump tries past the cap.
    $cfg->{_topic_meta_tries}{'doomed'} = 11;
    my $cb_called = 0;
    push @{$cfg->{pending_ops}}, {
        topic => 'doomed',
        cb    => sub { $cb_called++ },
        run   => sub { },
    };
    $k->_refresh_metadata_for_topic('doomed');
    is $cb_called, 1, 'pending op for doomed topic was drained with error';
    ok !@errs, 'on_error NOT fired when the op carried a callback';
    ok !exists $cfg->{_topic_meta_tries}{'doomed'},
        'tries counter reset after cap';

    # Same failure with no op callback: on_error is the only channel.
    $cfg->{_topic_meta_tries}{'doomed2'} = 11;
    push @{$cfg->{pending_ops}}, { topic => 'doomed2', run => sub { } };
    $k->_refresh_metadata_for_topic('doomed2');
    is scalar(@errs), 1, 'on_error fired when no op carried a callback';
    like $errs[0], qr/unavailable after/, 'on_error got the cap message';
}

# _drain_pending_for runs a copied list: ops pushed by a running op are
# appended to the fresh queue, not silently dropped (C11).
{
    my $k = EV::Kafka->new(brokers => '127.0.0.1:9092');
    my $cfg = $k->{cfg};
    my @ran;
    push @{$cfg->{pending_ops}},
        { node_id => 1, run => sub {
            push @ran, 'op1';
            push @{$cfg->{pending_ops}},
                { node_id => 2, run => sub { push @ran, 'op3' } };
        } },
        { node_id => 1, run => sub { push @ran, 'op2' } };
    $k->_drain_pending_for(1);
    is_deeply \@ran, ['op1', 'op2'], 'drain ran the copied ops in order';
    is scalar @{$cfg->{pending_ops}}, 1, 'op pushed mid-drain survived';
    is $cfg->{pending_ops}[0]{node_id}, 2, 'surviving op is the reentrant one';
}

# _merge_metadata evicts stale per-topic leaders on re-merge (C11).
{
    my $k = EV::Kafka->new(brokers => '127.0.0.1:9092');
    my $cfg = $k->{cfg};
    $cfg->{leaders}{'tx:0'} = 9;   # prefix-trap guard: must survive
    EV::Kafka::Client::_merge_metadata($cfg, {
        topics => [{ name => 't', error_code => 0, partitions => [
            { partition => 0, leader => 1 }, { partition => 1, leader => 2 },
        ] }],
    });
    EV::Kafka::Client::_merge_metadata($cfg, {
        topics => [{ name => 't', error_code => 0, partitions => [
            { partition => 0, leader => 5 },
        ] }],
    });
    is_deeply $cfg->{leaders}, { 't:0' => 5, 'tx:0' => 9 },
        'shrunk topic: stale partition leader evicted, prefix-safe';
    is $cfg->{leaders}{'t:0'}, 5, 'current leader re-added from the merge';
}

# _flush_all_batches re-arms linger timer when batches can't be sent yet
# (no leader / no connected conn).
{
    my $k = EV::Kafka->new(brokers => '127.0.0.1:9092');
    my $cfg = $k->{cfg};
    $cfg->{batches}{'pending:0'} = [{ rec => { key => 'k', value => 'v' }, cb => undef }];
    # No metadata, no leader resolves -> _flush_batch is skipped, and the
    # outer loop should arm a fallback timer.
    $cfg->{_linger_active} = 0;
    $k->_flush_all_batches;
    ok $cfg->{_linger_active}, 'flush_all_batches arms linger when skipped';
    ok defined $cfg->{_linger_timer}, 'linger timer object stored';
}

# produce_many with acks=0 fires the completion callback synchronously
# after the loop, without waiting on any per-record callback (because
# fire-and-forget installs none).
{
    my $k = EV::Kafka->new(brokers => '127.0.0.1:9092', acks => 0);
    my $fired = 0;
    # Stub produce so the test doesn't actually require metadata/conn.
    no warnings 'redefine';
    local *EV::Kafka::Client::produce = sub { };
    $k->produce_many(
        [['t', 'k1', 'v1'], ['t', 'k2', 'v2']],
        sub { $fired++ },
    );
    is $fired, 1, 'produce_many acks=0 fires the cb exactly once';
}

# produce_many on an empty list still fires the cb immediately.
{
    my $k = EV::Kafka->new(brokers => '127.0.0.1:9092');
    my $fired = 0;
    $k->produce_many([], sub { $fired++ });
    is $fired, 1, 'produce_many([]) fires the cb without any wire work';
}

# C10/P13: option validation
{
    # new() croaks on unknown options (catches typos at construction)
    my $ok = eval { EV::Kafka->new(brokers => '127.0.0.1:9092', brkoers => 'x'); 1 };
    ok !$ok && $@ =~ /unknown option\(s\): brkoers/,
        'new() croaks on unknown options';

    # produce() croaks on unknown option keys (catches 'partiton')
    my $k = EV::Kafka->new(brokers => '127.0.0.1:9092', on_error => sub { });
    $ok = eval { $k->produce('t', 'k', 'v', { partiton => 1 }); 1 };
    ok !$ok && $@ =~ /produce: unknown option 'partiton'/,
        'produce() croaks on unknown option keys';

    # group_id => '0' is a valid group id (defined-ness, not truthiness)
    my $k2 = EV::Kafka->new(brokers => '127.0.0.1:9092', on_error => sub { });
    $ok = eval { $k2->subscribe('t1', group_id => '0'); 1 };
    ok $ok && $k2->{cfg}{group}{group_id} eq '0',
        "subscribe() accepts group_id => '0'";

    # a known option key without a value croaks instead of shifting undef
    my $k3 = EV::Kafka->new(brokers => '127.0.0.1:9092', on_error => sub { });
    $ok = eval { $k3->subscribe('t1', 'group_id'); 1 };
    ok !$ok && $@ =~ /option 'group_id' requires a value/,
        'subscribe() croaks on a valueless option';

    # topic names are validated against the Kafka charset
    my $k4 = EV::Kafka->new(brokers => '127.0.0.1:9092', on_error => sub { });
    $ok = eval { $k4->subscribe('bad topic!', group_id => 'g'); 1 };
    ok !$ok && $@ =~ /invalid topic name/,
        'subscribe() croaks on invalid topic names';
    $ok = eval { $k4->subscribe('ok.topic_name-1', group_id => 'g'); 1 };
    ok $ok, 'subscribe() accepts the full Kafka topic charset';
}
