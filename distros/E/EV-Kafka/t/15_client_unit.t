use strict;
use warnings;
use Test::More;
use EV;
use EV::Kafka;

plan tests => 9;

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

# _refresh_metadata_for_topic retry cap
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
    ok scalar(grep { /unavailable after/ } @errs),
        'topic-meta retry cap fires on_error';
    is $cb_called, 1, 'pending op for doomed topic was drained with error';
    ok !exists $cfg->{_topic_meta_tries}{'doomed'},
        'tries counter reset after cap';
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
