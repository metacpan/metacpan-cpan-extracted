use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;

use lib 't/lib';
use Test::IO::Async::Pg qw(skip_without_postgres test_dsn);

# Skip if no PostgreSQL available
my $dsn = skip_without_postgres();
skip_all("Set TEST_PG_DSN to run pubsub tests") unless $dsn;

use IO::Async::Loop;
use IO::Async::Pg;

my $loop = IO::Async::Loop->new;
my $pg;

sub setup {
    $pg = IO::Async::Pg->new(
        dsn             => test_dsn(),
        min_connections => 0,
        max_connections => 5,
    );
    $loop->add($pg);
}

sub cleanup {
    $loop->remove($pg);
}

setup();

subtest 'create pubsub instance' => sub {
    my $pubsub = $pg->pubsub;

    isa_ok $pubsub, 'IO::Async::Pg::PubSub';
    ok !$pubsub->is_connected, 'not connected before subscribe';
    is $pubsub->subscribed_channels, 0, 'no channels';

    $pubsub->disconnect->get;
};

subtest 'subscribe and connect' => sub {
    my $pubsub = $pg->pubsub;
    my @received;

    $pubsub->subscribe('test_channel', sub {
        my ($channel, $payload, $pid) = @_;
        push @received, { channel => $channel, payload => $payload };
    })->get;

    ok $pubsub->is_connected, 'connected after subscribe';
    is $pubsub->subscribed_channels, 1, 'one channel subscribed';

    $pubsub->disconnect->get;
};

subtest 'notify and receive' => sub {
    my $pubsub = $pg->pubsub;
    my @received;

    $pubsub->subscribe('notify_test', sub {
        my ($channel, $payload, $pid) = @_;
        push @received, { channel => $channel, payload => $payload };
    })->get;

    # Send notification from another connection
    my $conn = $pg->connection->get;
    $conn->query("NOTIFY notify_test, 'hello'")->get;
    $conn->release;

    # Wait a bit for notification to arrive
    $loop->delay_future(after => 0.1)->get;

    # Force check for notifications
    $pubsub->_process_notifications;

    is scalar(@received), 1, 'received one notification';
    is $received[0]{channel}, 'notify_test', 'correct channel';
    is $received[0]{payload}, 'hello', 'correct payload';

    $pubsub->disconnect->get;
};

subtest 'notify via pubsub instance' => sub {
    my $pubsub = $pg->pubsub;
    my @received;

    $pubsub->subscribe('pubsub_notify', sub {
        my ($channel, $payload, $pid) = @_;
        push @received, { channel => $channel, payload => $payload };
    })->get;

    # Notify using the pubsub instance
    $pubsub->notify('pubsub_notify', 'test message')->get;

    # Wait a bit and process
    $loop->delay_future(after => 0.1)->get;
    $pubsub->_process_notifications;

    is scalar(@received), 1, 'received notification';
    is $received[0]{payload}, 'test message', 'correct payload';

    $pubsub->disconnect->get;
};

subtest 'multiple subscribers' => sub {
    my $pubsub = $pg->pubsub;
    my @received1;
    my @received2;

    $pubsub->subscribe('multi_channel', sub {
        my ($channel, $payload) = @_;
        push @received1, $payload;
    })->get;

    $pubsub->subscribe('multi_channel', sub {
        my ($channel, $payload) = @_;
        push @received2, $payload;
    })->get;

    is $pubsub->subscribed_channels, 1, 'still one channel (multiple callbacks)';

    $pubsub->notify('multi_channel', 'broadcast')->get;

    $loop->delay_future(after => 0.1)->get;
    $pubsub->_process_notifications;

    is scalar(@received1), 1, 'first callback received';
    is scalar(@received2), 1, 'second callback received';
    is $received1[0], 'broadcast', 'first got payload';
    is $received2[0], 'broadcast', 'second got payload';

    $pubsub->disconnect->get;
};

subtest 'unsubscribe' => sub {
    my $pubsub = $pg->pubsub;
    my @received;

    my $callback = sub {
        my ($channel, $payload) = @_;
        push @received, $payload;
    };

    $pubsub->subscribe('unsub_test', $callback)->get;
    is $pubsub->subscribed_channels, 1, 'subscribed';

    $pubsub->unsubscribe('unsub_test', $callback)->get;
    is $pubsub->subscribed_channels, 0, 'unsubscribed';

    $pubsub->disconnect->get;
};

subtest 'unsubscribe all' => sub {
    my $pubsub = $pg->pubsub;

    $pubsub->subscribe('channel1', sub {})->get;
    $pubsub->subscribe('channel2', sub {})->get;
    $pubsub->subscribe('channel3', sub {})->get;

    is $pubsub->subscribed_channels, 3, 'three channels subscribed';

    $pubsub->unsubscribe_all->get;
    is $pubsub->subscribed_channels, 0, 'all unsubscribed';

    $pubsub->disconnect->get;
};

subtest 'invalid channel name' => sub {
    my $pubsub = $pg->pubsub;

    my $err;
    eval { $pubsub->subscribe('bad;channel', sub {})->get };
    $err = $@;

    like $err, qr/Invalid channel name/, 'error for bad channel name';

    $pubsub->disconnect->get;
};

cleanup();
done_testing;
