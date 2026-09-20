use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib", "$Bin/..";
use JSON::PP;
use Time::HiRes ();
use Plack::Test;
use HTTP::Request::Common qw(GET);
use Plack::Builder;
use ForgeOps::Tracker;
use ForgeOps::Tracker::Configuration;
use ForgeOps::Tracker::SpanBuffer;
use ForgeOps::Tracker::Integrations::PSGIPerformance;
use t::lib::EchoServer;

sub new_configuration {
    my $config = ForgeOps::Tracker::Configuration->new;
    $config->{dsn} = 'https://key@tracker.example.com/api/v1/events';
    $config->{enabled_environments} = { production => 1 };
    $config->{environment} = 'production';
    $config->{release} = 'abc123';
    $config->{trace_capture_threshold} = 0.01;
    return $config;
}

# Stands in for the DeliveryQueue: records every trace pushed instead of delivering it.
package Fake::Queue {
    sub new { bless { pushed => [] }, shift }
    sub push { my ($self, $trace) = @_; push @{ $self->{pushed} }, $trace; return 1 }
}

sub init_tracker {
    my (%overrides) = @_;
    ForgeOps::Tracker::_reset_for_testing();
    ForgeOps::Tracker::init(
        dsn                     => 'https://key@tracker.example.com/api/v1/events',
        environment             => 'production',
        release                 => 'abc123',
        enabled_environments    => { production => 1 },
        trace_capture_threshold => 0.01,
        %overrides,
    );
}

subtest 'spans_uri swaps the trailing /events segment' => sub {
    is(new_configuration()->spans_uri, 'https://tracker.example.com/api/v1/spans');
};

subtest 'nests spans under the open one and the root, with the wire shape' => sub {
    my $buffer = ForgeOps::Tracker::SpanBuffer->new(new_configuration());
    my $outer = $buffer->open_span;
    $buffer->record_leaf('SELECT users', 'database', Time::HiRes::time, 3, {});
    $buffer->finish($outer, 'charge', 'service', Time::HiRes::time, 20, { k => 'v' });
    $buffer->record_leaf('sibling', 'database', Time::HiRes::time, 1, {});

    my $payload = $buffer->finish_trace('GET /x', Time::HiRes::time, 1500);
    my %by_name = map { $_->{name} => $_ } @{ $payload->{spans} };

    like($payload->{trace_id}, qr/\A[0-9a-f]{32}\z/);
    is($by_name{'GET /x'}{parent_span_id}, undef);
    is($by_name{'GET /x'}{kind}, 'controller');
    is($by_name{'SELECT users'}{parent_span_id}, $by_name{charge}{span_id});
    is($by_name{charge}{parent_span_id}, $by_name{'GET /x'}{span_id});
    is($by_name{sibling}{parent_span_id}, $by_name{'GET /x'}{span_id});
    like($by_name{charge}{span_id}, qr/\A[0-9a-f]{16}\z/);
    is($by_name{charge}{environment}, 'production');
    is($by_name{charge}{release}, 'abc123');
    like($by_name{charge}{started_at}, qr/\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d{3}Z\z/);
    like(JSON::PP->new->canonical->encode($by_name{'GET /x'}), qr/"parent_span_id":null/);
    like(JSON::PP->new->encode($by_name{'GET /x'}), qr/"data":\{\}/);
};

subtest 'an unknown kind is sent as other, since the server would reject the whole trace' => sub {
    my $buffer = ForgeOps::Tracker::SpanBuffer->new(new_configuration());
    $buffer->record_leaf('q', 'db', Time::HiRes::time, 1, {});
    $buffer->record_leaf('r', 'database', Time::HiRes::time, 1, {});
    my $spans = $buffer->finish_trace('root', Time::HiRes::time, 2000)->{spans};
    is($spans->[1]{kind}, 'other');
    is($spans->[2]{kind}, 'database');
};

subtest 'drops the trace when the root is under the threshold' => sub {
    my $config = new_configuration();
    $config->{trace_capture_threshold} = 1;
    my $buffer = ForgeOps::Tracker::SpanBuffer->new($config);
    is($buffer->finish_trace('GET /fast', Time::HiRes::time, 999), undef);
};

subtest 'caps a trace at 500 spans including the root' => sub {
    my $buffer = ForgeOps::Tracker::SpanBuffer->new(new_configuration());
    $buffer->record_leaf('q', 'database', Time::HiRes::time, 1, {}) for 1 .. 700;
    is(scalar(@{ $buffer->finish_trace('GET /x', Time::HiRes::time, 2000)->{spans} }), 500);
};

subtest 'queues a slow trace with nested spans, and re-raises unchanged when the code dies' => sub {
    init_tracker();
    my $queue = Fake::Queue->new;
    no warnings 'redefine';
    local *ForgeOps::Tracker::_span_queue = sub { $queue };

    ForgeOps::Tracker::start_trace();
    my $result = ForgeOps::Tracker::span('charge', sub {
        ForgeOps::Tracker::record_span('SELECT', 'database', Time::HiRes::time, 3);
        return 'ok';
    }, kind => 'service', data => { order => 1 });
    is($result, 'ok');
    my @list = ForgeOps::Tracker::span('list', sub { return (1, 2, 3) });
    is_deeply(\@list, [1, 2, 3]);

    eval { ForgeOps::Tracker::span('bad', sub { die "boom\n" }) };
    is($@, "boom\n");

    ForgeOps::Tracker::finish_trace('GET /checkout', Time::HiRes::time, 250);

    is(scalar(@{ $queue->{pushed} }), 1);
    my @names = map { $_->{name} } @{ $queue->{pushed}[0]{spans} };
    is_deeply([sort @names], [sort 'GET /checkout', 'charge', 'SELECT', 'list', 'bad']);
    is($ForgeOps::Tracker::current_trace, undef, 'finish_trace clears the trace');
};

subtest 'span just runs the code outside a trace' => sub {
    init_tracker();
    is(ForgeOps::Tracker::span('free', sub { 7 }), 7);
};

subtest 'sends nothing under the threshold, or with track_tracing off' => sub {
    init_tracker();
    my $queue = Fake::Queue->new;
    no warnings 'redefine';
    local *ForgeOps::Tracker::_span_queue = sub { $queue };

    ForgeOps::Tracker::start_trace();
    ForgeOps::Tracker::finish_trace('GET /fast', Time::HiRes::time, 1);
    is(scalar(@{ $queue->{pushed} }), 0);

    init_tracker(track_tracing => 0);
    ForgeOps::Tracker::start_trace();
    is($ForgeOps::Tracker::current_trace, undef);
    ForgeOps::Tracker::span('x', sub { 1 });
    ForgeOps::Tracker::finish_trace('GET /x', Time::HiRes::time, 500);
    is(scalar(@{ $queue->{pushed} }), 0);
};

subtest 'the PSGI performance middleware traces a slow request with the request as root span' => sub {
    init_tracker();
    my $queue = Fake::Queue->new;
    no warnings 'redefine';
    local *ForgeOps::Tracker::_span_queue = sub { $queue };
    local *ForgeOps::Tracker::record_performance = sub { };

    my $app = builder {
        enable '+ForgeOps::Tracker::Integrations::PSGIPerformance';
        sub {
            my $env = shift;
            ForgeOps::Tracker::span('inner work', sub { select(undef, undef, undef, 0.03) });
            return [200, ['Content-Type' => 'text/plain'], ['ok']];
        };
    };

    test_psgi $app, sub {
        my $cb = shift;
        is($cb->(GET '/slow')->code, 200);
    };

    is(scalar(@{ $queue->{pushed} }), 1);
    my @names = map { $_->{name} } @{ $queue->{pushed}[0]{spans} };
    is_deeply(\@names, ['GET /slow', 'inner work']);
};

subtest 'a finished trace really is delivered to /spans through the real background queue' => sub {
    my $server = t::lib::EchoServer->start;
    init_tracker(dsn => 'http://key@127.0.0.1:' . $server->{port} . '/api/v1/events');

    ForgeOps::Tracker::start_trace();
    ForgeOps::Tracker::span('inner', sub { 1 });
    ForgeOps::Tracker::finish_trace('GET /x', Time::HiRes::time, 250);

    my $deadline = time + 5;
    select(undef, undef, undef, 0.05) while time < $deadline && !@{ $server->requests };
    my $requests = $server->requests;
    is(scalar(@$requests), 1);
    is($requests->[0]{path}, '/api/v1/spans');
    my $body = JSON::PP::decode_json($requests->[0]{body});
    is($body->{spans}[0]{name}, 'GET /x');
    like($body->{trace_id}, qr/\A[0-9a-f]{32}\z/);
    $server->stop;
};

done_testing;
