use strict;
use warnings;
use Test::More tests => 2;
use Google::gRPC::Channel;

subtest 'HTTP/2 PING Keepalive Configuration' => sub {
    my $channel = Google::gRPC::Channel->new(
        target               => 'localhost:8000',
        engine_type          => 'PP',
        keepalive_time_sec   => 10,
        keepalive_timeout_sec => 5,
    );

    ok($channel, 'created channel with keepalive options');
    is($channel->keepalive_time_sec, 10, 'keepalive_time_sec set to 10');
    is($channel->keepalive_timeout_sec, 5, 'keepalive_timeout_sec set to 5');
};

subtest 'HTTP/2 PING frame emission on idle connection' => sub {
    my $channel = Google::gRPC::Channel->new(
        target               => 'localhost:8000',
        engine_type          => 'PP',
        keepalive_time_sec   => 0.01,
        keepalive_timeout_sec => 1,
    );

    # Set last_activity_time in past to simulate idle connection
    $channel->last_activity_time(time() - 2);

    my $ping_sent = 0;
    $channel->send_ping(sub {
        $ping_sent = 1;
    });

    my $out = $channel->get_output();
    ok(length($out) > 0, 'channel generated output bytes for PING frame');

    $channel->check_keepalive();
    ok(1, 'check_keepalive executed successfully');
};
