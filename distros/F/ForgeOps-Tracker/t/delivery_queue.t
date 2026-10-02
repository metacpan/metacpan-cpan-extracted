use strict;
use warnings;
use threads;
use threads::shared;
use Test::More;
use FindBin qw($Bin);
use File::Temp qw(tempfile);
use Time::HiRes ();
use lib "$Bin/../lib";
use lib "$Bin/..";
use t::lib::EchoServer;
use ForgeOps::Tracker;
use ForgeOps::Tracker::Configuration;
use ForgeOps::Tracker::DeliveryQueue;

sub new_configuration {
    my ($queue_size) = @_;
    my $config = ForgeOps::Tracker::Configuration->new;
    $config->{queue_size} = $queue_size // 10;
    return $config;
}

sub wait_until {
    my ($predicate, $timeout) = @_;
    $timeout //= 2;
    my $deadline = time + $timeout;
    while (time < $deadline) {
        return 1 if $predicate->();
        select(undef, undef, undef, 0.02);
    }
    return 0;
}

package Fake::Client {
    sub new {
        my ($class, %args) = @_;
        return bless { %args }, $class;
    }
    sub deliver {
        my ($self, $payload) = @_;
        if ($self->{die_on_first} && !$self->{called}++) {
            die "boom\n";
        }
        {
            lock(@{ $self->{delivered} });
            push @{ $self->{delivered} }, $payload->{n};
        }
        return 1;
    }
}

subtest 'delivers a pushed payload via the client on its background thread' => sub {
    my @delivered :shared;
    my $client = Fake::Client->new(delivered => \@delivered);
    my $queue = ForgeOps::Tracker::DeliveryQueue->new(new_configuration(10), $client);

    $queue->push({ n => 1 });

    ok(wait_until(sub { scalar(@delivered) == 1 }), 'delivered within timeout');
    is($delivered[0], 1);
};

subtest 'drops a payload without blocking when the queue is already full' => sub {
    # A client that never actually completes delivery (sleeps far longer than this test runs), so
    # nothing drains the queue and capacity stays exactly at queue_size (1) for a deterministic
    # full-queue test.
    package Fake::NeverDelivers {
        sub new { return bless {}, shift }
        sub deliver { sleep 5; return 1; }
    }
    my $client = Fake::NeverDelivers->new;
    my $queue = ForgeOps::Tracker::DeliveryQueue->new(new_configuration(1), $client);

    is($queue->push({ n => 1 }), 1);

    # The first push may already have been dequeued by the worker thread (draining the queue
    # before it observes "full"), so retry briefly rather than asserting on a single racy attempt.
    my $deadline = time + 2;
    my $second_push_result = 1;
    while (time < $deadline) {
        $second_push_result = $queue->push({ n => 2 });
        last unless $second_push_result;
    }

    is($second_push_result, 0);
};

subtest 'recovers from the client dying instead of returning' => sub {
    my @delivered :shared;
    my $client = Fake::Client->new(delivered => \@delivered, die_on_first => 1);
    my $queue = ForgeOps::Tracker::DeliveryQueue->new(new_configuration(10), $client);

    $queue->push({ n => 1 }); # dies inside the worker thread; must not kill it
    $queue->push({ n => 2 });

    ok(wait_until(sub { scalar(@delivered) == 1 }), 'delivered within timeout');
    is($delivered[0], 2);
};

# A client that sleeps before recording, to stand in for a slow network call.
package Fake::SlowClient {
    sub new {
        my ($class, %args) = @_;
        return bless { %args }, $class;
    }
    sub deliver {
        my ($self, $payload) = @_;
        Time::HiRes::sleep($self->{delay});
        lock(@{ $self->{delivered} });
        push @{ $self->{delivered} }, $payload->{n};
        return 1;
    }
}

subtest 'drain delivers what is still queued on the calling thread' => sub {
    my @delivered :shared;
    my $queue = ForgeOps::Tracker::DeliveryQueue->new(new_configuration(10), Fake::Client->new(delivered => \@delivered));
    # Hold the worker back, the way a program exiting right after reporting outruns it.
    no warnings 'redefine';
    local *ForgeOps::Tracker::DeliveryQueue::_ensure_worker = sub { };
    $queue->push({ n => 1 });
    $queue->push({ n => 2 });

    is($queue->drain(2), 1, 'reports everything went out');
    is_deeply([ @delivered ], [ 1, 2 ]);
};

subtest 'drain waits for a delivery the worker already has under way' => sub {
    my @delivered :shared;
    my $queue = ForgeOps::Tracker::DeliveryQueue->new(new_configuration(10), Fake::SlowClient->new(delivered => \@delivered, delay => 0.3));
    $queue->push({ n => 1 });
    # Let the worker pick it up, so it is in flight rather than queued.
    wait_until(sub { !$queue->{queue}->pending });

    is($queue->drain(2), 1);
    is_deeply([ @delivered ], [ 1 ], 'delivered once, by the worker');
};

subtest 'drain gives up at the timeout rather than holding the program open' => sub {
    my @delivered :shared;
    my $queue = ForgeOps::Tracker::DeliveryQueue->new(new_configuration(10), Fake::SlowClient->new(delivered => \@delivered, delay => 0.5));
    no warnings 'redefine';
    local *ForgeOps::Tracker::DeliveryQueue::_ensure_worker = sub { };
    $queue->push({ n => $_ }) for 1 .. 3;

    my $started = Time::HiRes::time();
    is($queue->drain(0.2), 0, 'reports that something was left');
    cmp_ok(Time::HiRes::time() - $started, '<', 1.0);
};

subtest 'drain waits for nothing when nothing was ever pushed' => sub {
    my $queue = ForgeOps::Tracker::DeliveryQueue->new(new_configuration(10), Fake::Client->new(delivered => []));
    my $started = Time::HiRes::time();
    is($queue->drain, 1);
    cmp_ok(Time::HiRes::time() - $started, '<', 0.1);
};

subtest 'a program that pushes and exits at once still delivers from the END block' => sub {
    my (undef, $out) = tempfile(UNLINK => 1);
    my $script = qq{
        use lib "$Bin/../lib";
        use ForgeOps::Tracker::Configuration;
        use ForgeOps::Tracker::DeliveryQueue;
        package FileClient { sub deliver { open my \$fh, '>>', '$out' or die; print \$fh \$_[1]{message}; close \$fh; 1 } }
        no warnings 'redefine';
        *ForgeOps::Tracker::DeliveryQueue::_ensure_worker = sub { }; # the worker never gets to it
        my \$queue = ForgeOps::Tracker::DeliveryQueue->new(ForgeOps::Tracker::Configuration->new, bless({}, 'FileClient'));
        \$queue->push({ message => 'reported just before exit' });
        exit 3;
    };
    system($^X, '-e', $script);

    is($? >> 8, 3, 'keeps the program exit status');
    open my $fh, '<', $out or die;
    is(do { local $/; <$fh> }, 'reported just before exit');
};

subtest 'a script that reports an error and ends delivers it' => sub {
    my $server = t::lib::EchoServer->start;
    my $script = qq{
        use lib "$Bin/../lib";
        use ForgeOps::Tracker;
        ForgeOps::Tracker::init(
            dsn => 'http://key\\\@127.0.0.1:$server->{port}/api/v1/events',
            environment => 'production',
            enabled_environments => { production => 1 },
        );
        ForgeOps::Tracker::report("cron job failed\\n");
    };
    system($^X, '-e', $script) == 0 or diag("child exit: $?");

    my ($request) = grep { $_->{path} eq '/api/v1/events' } @{ $server->requests };
    ok($request, 'the error arrived');
    like($request->{body}, qr/cron job failed/) if $request;
    $server->stop;
};

subtest 'ForgeOps::Tracker::flush sends queued errors right away' => sub {
    my $server = t::lib::EchoServer->start;
    ForgeOps::Tracker::_reset_for_testing();
    ForgeOps::Tracker::init(
        dsn                  => 'http://key@127.0.0.1:' . $server->{port} . '/api/v1/events',
        environment          => 'production',
        enabled_environments => { production => 1 },
    );
    ForgeOps::Tracker::report("flushed\n");

    is(ForgeOps::Tracker::flush(5), 1);
    ok((grep { $_->{path} eq '/api/v1/events' } @{ $server->requests }), 'arrived before flush returned');
    ForgeOps::Tracker::_reset_for_testing();
    $server->stop;
};

done_testing;
