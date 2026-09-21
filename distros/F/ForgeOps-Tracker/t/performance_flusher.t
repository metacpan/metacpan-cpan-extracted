use strict;
use warnings;
use threads;
use threads::shared;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use JSON::PP;
use ForgeOps::Tracker::Configuration;
use ForgeOps::Tracker::PerformanceFlusher;

sub new_configuration {
    my $config = ForgeOps::Tracker::Configuration->new;
    $config->{dsn} = 'https://key@tracker.example.com/api/v1/events';
    $config->{enabled_environments} = { production => 1 };
    $config->{environment} = 'production';
    $config->{release} = '1.2.3';
    # Long enough that no test relying on an explicit flush() call also races a real background
    # tick; the interval-driven test below overrides this down to something short instead.
    $config->{performance_flush_interval} = 600;
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
        return bless { calls => 0, %args }, $class;
    }
    sub deliver_performance_samples {
        my ($self, $samples) = @_;
        $self->{calls}++;
        return 0 if $self->{fail};
        # Lets a test land a record() in the window between the snapshot and delivery succeeding.
        if (my $on_deliver = delete $self->{on_deliver}) {
            $on_deliver->();
        }
        {
            # A shared array can only hold shared references (or plain scalars): JSON-encoding
            # each delivery into a plain string, the same way DeliveryQueue's own Fake::Client
            # test double sidesteps this by pushing a plain scalar rather than a hashref, is the
            # simplest way to hand a whole batch of samples across the thread boundary.
            lock(@{ $self->{delivered} });
            push @{ $self->{delivered} }, JSON::PP::encode_json($samples);
        }
        return 1;
    }
}

sub decode_delivered {
    my ($json) = @_;
    return JSON::PP::decode_json($json);
}

subtest 'buckets by transaction_name and delivers on flush' => sub {
    my @delivered :shared;
    my $client = Fake::Client->new(delivered => \@delivered);
    my $flusher = ForgeOps::Tracker::PerformanceFlusher->new(new_configuration(), $client);

    $flusher->record('GET /posts/:id', 100);
    $flusher->record('GET /posts/:id', 200);
    $flusher->record('GET /posts', 50);
    $flusher->flush;

    is(scalar(@delivered), 1);
    my $samples = decode_delivered($delivered[0]);
    is(scalar(@$samples), 2);

    my ($show) = grep { $_->{transaction_name} eq 'GET /posts/:id' } @$samples;
    my ($index) = grep { $_->{transaction_name} eq 'GET /posts' } @$samples;
    ok($show && $index, 'both transactions represented');
    is($show->{request_count}, 2);
    is($show->{duration_sum_ms}, 300);
    is($show->{max_duration_ms}, 200);
    is($index->{request_count}, 1);
    is($show->{release}, '1.2.3');
    is($show->{environment}, 'production');
};

subtest 'does nothing on a flush with nothing recorded' => sub {
    my $client = Fake::Client->new(delivered => []);
    my $flusher = ForgeOps::Tracker::PerformanceFlusher->new(new_configuration(), $client);

    $flusher->flush;

    is($client->{calls}, 0);
};

subtest 'keeps the bucket for the next flush when delivery fails' => sub {
    my @delivered :shared;
    my $client = Fake::Client->new(delivered => \@delivered, fail => 1);
    my $flusher = ForgeOps::Tracker::PerformanceFlusher->new(new_configuration(), $client);

    $flusher->record('GET /posts/:id', 100);
    $flusher->flush; # fails; the bucket must not be reset

    $client->{fail} = 0;
    $flusher->record('GET /posts/:id', 100);
    $flusher->flush;

    is(scalar(@delivered), 1);
    is(decode_delivered($delivered[0])->[0]{request_count}, 2);
};

subtest 'the background thread flushes on its own after the configured interval' => sub {
    my @delivered :shared;
    my $client = Fake::Client->new(delivered => \@delivered);
    my $config = new_configuration();
    $config->{performance_flush_interval} = 1;
    my $flusher = ForgeOps::Tracker::PerformanceFlusher->new($config, $client);

    $flusher->record('GET /posts/:id', 100);

    ok(wait_until(sub { scalar(@delivered) == 1 }, 3), 'delivered within timeout');
    is(decode_delivered($delivered[0])->[0]{request_count}, 1);
};

subtest 'does not record when track_performance is disabled' => sub {
    my $client = Fake::Client->new(delivered => []);
    my $config = new_configuration();
    $config->{track_performance} = 0;
    my $flusher = ForgeOps::Tracker::PerformanceFlusher->new($config, $client);

    $flusher->record('GET /posts/:id', 100);
    $flusher->flush;

    is($client->{calls}, 0);
};

subtest 'delivers a latency histogram per bucket alongside count, sum and max' => sub {
    my @delivered :shared;
    my $client = Fake::Client->new(delivered => \@delivered);
    my $flusher = ForgeOps::Tracker::PerformanceFlusher->new(new_configuration(), $client);

    $flusher->record('GET /posts', $_) for (10, 40, 120, 700, 12000);
    $flusher->flush;

    my $sample = decode_delivered($delivered[0])->[0];
    is_deeply($sample->{histogram}, { 50 => 2, 250 => 1, 1000 => 1, inf => 1 });
    my $total = 0;
    $total += $_ for values %{ $sample->{histogram} };
    is($total, $sample->{request_count}, 'histogram counts add up to request_count');
};

subtest 'keeps histogram counts for the next flush when delivery fails' => sub {
    my @delivered :shared;
    my $client = Fake::Client->new(delivered => \@delivered, fail => 1);
    my $flusher = ForgeOps::Tracker::PerformanceFlusher->new(new_configuration(), $client);

    $flusher->record('GET /posts', 10);
    $flusher->flush;

    $client->{fail} = 0;
    $flusher->record('GET /posts', 300);
    $flusher->flush;

    is_deeply(decode_delivered($delivered[0])->[0]{histogram}, { 50 => 1, 500 => 1 });
};

subtest 'a record that lands during delivery is never lost and is sent on the next flush' => sub {
    my @delivered :shared;
    my $client = Fake::Client->new(delivered => \@delivered);
    my $flusher = ForgeOps::Tracker::PerformanceFlusher->new(new_configuration(), $client);
    $client->{on_deliver} = sub {
        $flusher->record('GET /posts', 300);
        $flusher->record('GET /new', 5);
    };

    $flusher->record('GET /posts', 10);
    $flusher->flush;
    $flusher->flush;

    is(scalar(@delivered), 2);
    is_deeply(decode_delivered($delivered[0])->[0]{histogram}, { 50 => 1 });

    my %second = map { $_->{transaction_name} => $_ } @{ decode_delivered($delivered[1]) };
    is($second{'GET /posts'}{request_count}, 1);
    is_deeply($second{'GET /posts'}{histogram}, { 500 => 1 });
    is_deeply($second{'GET /new'}{histogram}, { 50 => 1 });
};

done_testing;
