use strict;
use warnings;
use Test::More tests => 4;
use Google::gRPC::ChannelPool;
use Google::gRPC::Client;
use Google::gRPC::Framing;

subtest 'DNS Resolution and Subchannel Pool Instantiation' => sub {
    my $pool = Google::gRPC::ChannelPool->new(
        target     => 'spanner.googleapis.com:443',
        auth_token => 'mock_token_testtoken',
    );

    ok($pool, 'instantiated ChannelPool');
    is($pool->target, 'spanner.googleapis.com:443', 'pool target matches');
    my $subs = $pool->subchannels;
    ok(scalar(@$subs) > 0, 'resolved target to subchannel endpoints');

    my $metrics = $pool->get_metrics();
    ok($metrics, 'retrieved metrics hash');
    my @ips = keys %$metrics;
    ok(scalar(@ips) > 0, 'metrics contain entries for resolved IPs');
};

subtest 'Round-Robin Subchannel Selection Algorithm' => sub {
    my $pool = Google::gRPC::ChannelPool->new(
        target       => 'spanner.googleapis.com:443',
        resolved_ips => ['10.0.0.1', '10.0.0.2', '10.0.0.3'],
        engine_type  => 'PP',
    );

    is(scalar(@{$pool->subchannels}), 3, 'pool contains 3 resolved subchannels');

    my @targets;
    for (1 .. 6) {
        my $ch = $pool->get_channel();
        push @targets, $ch->target;
    }

    is_deeply(\@targets, [
        '10.0.0.1:443',
        '10.0.0.2:443',
        '10.0.0.3:443',
        '10.0.0.1:443',
        '10.0.0.2:443',
        '10.0.0.3:443',
    ], 'round-robin algorithm distributes sequentially across subchannels');
};

subtest 'Per-IP Request Counts and Byte Metrics Tracking' => sub {
    my $pool = Google::gRPC::ChannelPool->new(
        target       => 'spanner.googleapis.com:443',
        resolved_ips => ['192.168.1.1', '192.168.1.2'],
        engine_type  => 'PP',
    );

    my @streams;
    for my $i (1 .. 4) {
        my $s = $pool->create_stream(
            service => 'google.spanner.v1.Spanner',
            method  => 'ExecuteSql',
            request => 'SELECT * FROM test_table WHERE id = ' . $i,
            type    => 'unary',
        );
        push @streams, $s;

        my $response_payload = 'mock_response_data_' . $i;
        my $framed = Google::gRPC::Framing::pack_frame($response_payload);
        $s->push_incoming_data($framed);
    }

    my $m1 = $pool->get_metrics('192.168.1.1');
    my $m2 = $pool->get_metrics('192.168.1.2');

    is($m1->{requests}, 2, 'ip 192.168.1.1 received 2 requests');
    is($m2->{requests}, 2, 'ip 192.168.1.2 received 2 requests');

    ok($m1->{bytes_sent} > 0, 'ip 192.168.1.1 tracked sent request bytes');
    ok($m1->{bytes_received} > 0, 'ip 192.168.1.1 tracked received response bytes');
    is($m1->{total_bytes}, $m1->{bytes_sent} + $m1->{bytes_received}, 'ip 192.168.1.1 total_bytes sum is correct');

    ok($m2->{bytes_sent} > 0, 'ip 192.168.1.2 tracked sent request bytes');
    ok($m2->{bytes_received} > 0, 'ip 192.168.1.2 tracked received response bytes');
    is($m2->{total_bytes}, $m2->{bytes_sent} + $m2->{bytes_received}, 'ip 192.168.1.2 total_bytes sum is correct');
};

subtest 'Client Integration with ChannelPool' => sub {
    my $pool = Google::gRPC::ChannelPool->new(
        target       => 'spanner.googleapis.com:443',
        resolved_ips => ['10.1.1.1', '10.1.1.2'],
        engine_type  => 'PP',
    );

    my $client = Google::gRPC::Client->new(
        channel_pool => $pool,
    );

    ok($client, 'created client with channel_pool');
    is($client->target, 'spanner.googleapis.com:443', 'client target derived from channel pool');
    is($client->channel, $pool, 'client channel returns channel pool');

    my $s1 = $client->stream(
        service => 'google.spanner.v1.Spanner',
        method  => 'BatchCreateSessions',
        request => 'session_request_1',
    );
    is($s1->channel->target, '10.1.1.1:443', 'first client stream dispatched to subchannel 10.1.1.1');

    my $s2 = $client->stream(
        service => 'google.spanner.v1.Spanner',
        method  => 'BatchCreateSessions',
        request => 'session_request_2',
    );
    is($s2->channel->target, '10.1.1.2:443', 'second client stream dispatched to subchannel 10.1.1.2');
};
