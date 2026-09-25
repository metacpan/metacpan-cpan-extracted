use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Time::HiRes ();
use Plack::Test;
use HTTP::Request::Common qw(GET POST);
use Plack::Builder;
use ForgeOps::Tracker;
use ForgeOps::Tracker::Configuration;
use ForgeOps::Tracker::EventBuilder;
use ForgeOps::Tracker::Reporter;
use ForgeOps::Tracker::TraceParent;
use ForgeOps::Tracker::Integrations::PSGI;
use ForgeOps::Tracker::Integrations::PSGIPerformance;

my $TRACE_ID  = '4bf92f3577b34da6a3ce929d0e0e4736';
my $PARENT_ID = '00f067aa0ba902b7';
my $HEADER    = "00-$TRACE_ID-$PARENT_ID-01";

# Stands in for both DeliveryQueues: collects what would have gone over the wire.
package Fake::Queue {
    sub new { bless { pushed => [] }, shift }
    sub push { my ($self, $item) = @_; push @{ $self->{pushed} }, $item; return 1 }
}

my ($events, $traces);

# Initializes an enabled client whose real Reporter/EventBuilder and span queue deliver into
# Fake::Queue instances, so each test asserts on the actual payloads.
sub init_tracker {
    my (%overrides) = @_;
    ForgeOps::Tracker::_reset_for_testing();
    my $config = ForgeOps::Tracker::init(
        dsn                  => 'https://key@tracker.example.com/api/v1/events',
        environment          => 'production',
        enabled_environments => { production => 1 },
        %overrides,
    );
    $events = Fake::Queue->new;
    $traces = Fake::Queue->new;
    my $reporter = ForgeOps::Tracker::Reporter->new($config, ForgeOps::Tracker::EventBuilder->new($config), $events);
    no warnings 'redefine';
    *ForgeOps::Tracker::_reporter = sub { $reporter };
    *ForgeOps::Tracker::_span_queue = sub { $traces };
    return $config;
}

sub reported { $events->{pushed} }
sub sent_traces { $traces->{pushed} }

subtest 'parses a valid traceparent, trimming whitespace' => sub {
    is_deeply(ForgeOps::Tracker::TraceParent::parse($HEADER), { trace_id => $TRACE_ID, parent_span_id => $PARENT_ID });
    is(ForgeOps::Tracker::TraceParent::parse(" $HEADER\n")->{trace_id}, $TRACE_ID);
};

subtest 'accepts a future version with extra fields' => sub {
    is(ForgeOps::Tracker::TraceParent::parse("01-$TRACE_ID-$PARENT_ID-01-extra")->{trace_id}, $TRACE_ID);
};

subtest 'rejects invalid traceparents' => sub {
    my %invalid = (
        'undef'                     => undef,
        'a reference'               => [],
        'blank'                     => '',
        'garbage'                   => 'not-a-traceparent',
        'uppercase hex'             => '00-' . uc($TRACE_ID) . "-$PARENT_ID-01",
        'version ff'                => "ff-$TRACE_ID-$PARENT_ID-01",
        'all-zero trace id'         => '00-' . ('0' x 32) . "-$PARENT_ID-01",
        'all-zero parent id'        => "00-$TRACE_ID-" . ('0' x 16) . '-01',
        'short trace id'            => '00-' . substr($TRACE_ID, 1) . "-$PARENT_ID-01",
        'extra field on version 00' => "$HEADER-extra",
        'missing flags'             => "00-$TRACE_ID-$PARENT_ID",
    );
    for my $name (sort keys %invalid) {
        is(ForgeOps::Tracker::TraceParent::parse($invalid{$name}), undef, $name);
    }
};

subtest 'builds and generates W3C ids' => sub {
    is(ForgeOps::Tracker::TraceParent::build($TRACE_ID, $PARENT_ID), $HEADER);
    like(ForgeOps::Tracker::TraceParent::generate_trace_id(), qr/\A[0-9a-f]{32}\z/);
    like(ForgeOps::Tracker::TraceParent::generate_span_id(), qr/\A[0-9a-f]{16}\z/);
};

subtest 'propagates to every host by default' => sub {
    my $config = ForgeOps::Tracker::Configuration->new;
    is($config->{propagate_traces}, 1);
    is($config->{trace_propagation_targets}, undef);
    ok($config->should_propagate_trace('anything.example'));
    $config->{propagate_traces} = 0;
    ok(!$config->should_propagate_trace('anything.example'), 'propagate_traces off never propagates');
};

subtest 'matches targets as hosts on a dot boundary, or as regular expressions' => sub {
    my $config = ForgeOps::Tracker::Configuration->new;
    $config->{trace_propagation_targets} = ['.Example.com', qr/\A10\.0\./];

    ok($config->should_propagate_trace('example.com'));
    ok($config->should_propagate_trace('API.example.com'));
    ok(!$config->should_propagate_trace('badexample.com'));
    ok(!$config->should_propagate_trace('example.com.evil.test'));
    ok($config->should_propagate_trace('10.0.3.4'));
    ok(!$config->should_propagate_trace('110.0.3.4'));
    ok(!$config->should_propagate_trace(undef));

    $config->{trace_propagation_targets} = [];
    ok(!$config->should_propagate_trace('example.com'), 'an empty list propagates nowhere');
};

subtest 'errors reported during a request carry its trace id, name and endpoint, unscrubbed' => sub {
    init_tracker();
    ForgeOps::Tracker::start_trace($HEADER);
    # An email-shaped route segment would be scrubbed anywhere else in the payload.
    ForgeOps::Tracker::set_request_route('GET /users/:a@b.co', 'GET /users/:a@b.co');
    ForgeOps::Tracker::report("boom\n");
    ForgeOps::Tracker::finish_trace('GET /users/:a@b.co', Time::HiRes::time, 5);

    is(reported()->[0]{trace_id}, $TRACE_ID);
    is(reported()->[0]{transaction_name}, 'GET /users/:a@b.co');
    is(reported()->[0]{endpoint}, 'GET /users/:a@b.co');
};

subtest 'errors outside a request are unchanged' => sub {
    init_tracker();
    ForgeOps::Tracker::report("before\n");
    ForgeOps::Tracker::start_trace();
    ForgeOps::Tracker::finish_trace('GET /x', Time::HiRes::time, 5);
    ForgeOps::Tracker::report("after\n");

    for my $event (@{ reported() }) {
        ok(!exists $event->{$_}, "no $_") for qw(trace_id transaction_name endpoint);
    }
    is(ForgeOps::Tracker::current_trace_id(), undef);
};

subtest 'a trace id exists even with tracing off, and no trace is sent' => sub {
    init_tracker(track_tracing => 0);
    ForgeOps::Tracker::start_trace($HEADER);
    is(ForgeOps::Tracker::current_trace_id(), $TRACE_ID);
    ForgeOps::Tracker::report("boom\n");
    ForgeOps::Tracker::finish_trace('GET /x', Time::HiRes::time, 5000);

    is(reported()->[0]{trace_id}, $TRACE_ID);
    ok(!exists reported()->[0]{endpoint}, 'an endpoint nobody set is left out');
    is_deeply(sent_traces(), []);
};

subtest 'nothing starts when the client is not enabled' => sub {
    init_tracker(environment => 'development');
    ForgeOps::Tracker::start_trace($HEADER);
    is(ForgeOps::Tracker::current_trace_id(), undef);
};

subtest "a continued trace's root span points at the caller's span; a fresh one has no parent" => sub {
    init_tracker(trace_capture_threshold => 0.001);
    ForgeOps::Tracker::start_trace($HEADER);
    ForgeOps::Tracker::finish_trace('GET /x', Time::HiRes::time, 50);
    ForgeOps::Tracker::start_trace('00-ffffffffffffffffffffffffffffffff-zzzzzzzzzzzzzzzz-01');
    ForgeOps::Tracker::finish_trace('GET /y', Time::HiRes::time, 50);

    is(sent_traces()->[0]{trace_id}, $TRACE_ID);
    is(sent_traces()->[0]{spans}[0]{parent_span_id}, $PARENT_ID);
    like(sent_traces()->[1]{trace_id}, qr/\A[0-9a-f]{32}\z/);
    is(sent_traces()->[1]{spans}[0]{parent_span_id}, undef);
};

subtest 'a fast request that errored still sends its trace' => sub {
    init_tracker();
    ForgeOps::Tracker::start_trace();
    ForgeOps::Tracker::report("handled\n");
    ForgeOps::Tracker::finish_trace('GET /fast', Time::HiRes::time, 1);
    ForgeOps::Tracker::start_trace();
    ForgeOps::Tracker::finish_trace('GET /fast-and-fine', Time::HiRes::time, 1);

    is(scalar(@{ sent_traces() }), 1);
    is(sent_traces()->[0]{spans}[0]{name}, 'GET /fast');
    is(sent_traces()->[0]{trace_id}, reported()->[0]{trace_id});
};

subtest 'an error snapshotted on its way out keeps its context when reported afterwards' => sub {
    init_tracker();
    my $object = bless { message => 'object error' }, 'My::Error';
    ForgeOps::Tracker::start_trace($HEADER);
    ForgeOps::Tracker::set_request_route('POST /checkout', 'POST /checkout');
    ForgeOps::Tracker::set_user(id => 7);
    ForgeOps::Tracker::add_breadcrumb('clicked pay');
    ForgeOps::Tracker::snapshot_onto("string error\n");
    ForgeOps::Tracker::snapshot_onto($object);
    ForgeOps::Tracker::finish_trace('POST /checkout', Time::HiRes::time, 1);
    ForgeOps::Tracker::set_user();
    ForgeOps::Tracker::clear_breadcrumbs();

    ForgeOps::Tracker::report("string error\n");
    ForgeOps::Tracker::report($object);
    ForgeOps::Tracker::report("unrelated\n");

    for my $event (@{ reported() }[0, 1]) {
        is($event->{trace_id}, $TRACE_ID);
        is($event->{endpoint}, 'POST /checkout');
        is_deeply($event->{user}, { id => 7 });
        is($event->{breadcrumbs}[0]{message}, 'clicked pay');
    }
    ok(!exists reported()->[2]{trace_id}, 'an unrelated error gets nothing');
    is(scalar(@{ sent_traces() }), 1, 'snapshotting marked the fast request errored');
};

subtest 'http_span hands over a traceparent naming its own recorded span' => sub {
    init_tracker();
    ForgeOps::Tracker::start_trace($HEADER);
    my $sent;
    my $result = ForgeOps::Tracker::http_span(post => 'https://Payments.Example.com:8443/charges/42?token=x', sub {
        ($sent) = @_;
        return 'response';
    }, data => { attempt => 1 });
    ForgeOps::Tracker::report("boom\n");
    ForgeOps::Tracker::finish_trace('POST /checkout', Time::HiRes::time, 1);

    is($result, 'response');
    my $parsed = ForgeOps::Tracker::TraceParent::parse($sent->{traceparent});
    is($parsed->{trace_id}, $TRACE_ID);
    my $http = sent_traces()->[0]{spans}[1];
    is($http->{name}, 'POST payments.example.com');
    is($http->{kind}, 'http');
    is($http->{span_id}, $parsed->{parent_span_id});
    is($http->{parent_span_id}, sent_traces()->[0]{spans}[0]{span_id});
    is_deeply($http->{data}, { attempt => 1 });
};

subtest 'http_span records and re-raises when the call dies' => sub {
    init_tracker(trace_capture_threshold => 0);
    ForgeOps::Tracker::start_trace();
    eval { ForgeOps::Tracker::http_span(GET => 'https://api.example.com/', sub { die "connection refused\n" }) };
    is($@, "connection refused\n");
    ForgeOps::Tracker::finish_trace('GET /x', Time::HiRes::time, 1);

    is(sent_traces()->[0]{spans}[1]{name}, 'GET api.example.com');
};

subtest 'http_span sends no header to a host outside the targets, or with propagation off' => sub {
    my $config = init_tracker(trace_propagation_targets => ['internal.example']);
    ForgeOps::Tracker::start_trace();
    my $outside = ForgeOps::Tracker::http_span(GET => 'https://api.thirdparty.test/x', sub { $_[0] });
    my $inside = ForgeOps::Tracker::http_span(GET => 'https://orders.internal.example/x', sub { $_[0] });
    $config->{propagate_traces} = 0;
    my $off = ForgeOps::Tracker::http_span(GET => 'https://orders.internal.example/x', sub { $_[0] });

    is_deeply($outside, {});
    ok(exists $inside->{traceparent});
    is_deeply($off, {});
};

subtest 'http_span still propagates with tracing off but records nothing' => sub {
    init_tracker(track_tracing => 0);
    ForgeOps::Tracker::start_trace($HEADER);
    my $headers = ForgeOps::Tracker::http_span(GET => 'https://api.example.com/', sub { $_[0] });
    ForgeOps::Tracker::finish_trace('GET /x', Time::HiRes::time, 5000);

    is(ForgeOps::Tracker::TraceParent::parse($headers->{traceparent})->{trace_id}, $TRACE_ID);
    is_deeply(sent_traces(), []);
};

subtest 'http_span outside a request just runs the call with no headers' => sub {
    init_tracker();
    is_deeply(ForgeOps::Tracker::http_span(GET => 'https://api.example.com/', sub { $_[0] }), {});
};

subtest 'PSGI: continues the incoming trace, and an escaped error keeps it when reported outside' => sub {
    init_tracker();
    my $app = builder {
        enable '+ForgeOps::Tracker::Integrations::PSGI';
        enable '+ForgeOps::Tracker::Integrations::PSGIPerformance';
        sub {
            my $env = shift;
            ForgeOps::Tracker::report("handled\n") if $env->{PATH_INFO} eq '/handled';
            die "route exploded\n" if $env->{PATH_INFO} eq '/boom';
            return [200, ['Content-Type' => 'text/plain'], ['ok']];
        };
    };

    test_psgi $app, sub {
        my $cb = shift;
        $cb->(GET '/handled', traceparent => $HEADER);
        $cb->(GET '/boom');
    };

    my ($handled, $escaped) = @{ reported() };
    is($handled->{trace_id}, $TRACE_ID);
    ok(!exists $handled->{endpoint}, 'plain PSGI has no route pattern');
    like($escaped->{trace_id}, qr/\A[0-9a-f]{32}\z/);
    isnt($escaped->{trace_id}, $TRACE_ID, 'a request without the header starts its own trace');
    is(scalar(@{ sent_traces() }), 2, 'both fast requests errored, so both traces were sent');
    is(sent_traces()->[0]{spans}[0]{parent_span_id}, $PARENT_ID);
    is(sent_traces()->[1]{trace_id}, $escaped->{trace_id});
    is(ForgeOps::Tracker::current_trace_id(), undef, 'nothing leaks past the request');
};

# Loaded in both orders: Dancer2 runs the two plugins' on_route_exception hooks in load order, and
# the report has to carry the request context either way.
package ErrorsFirstApp {
    use Dancer2;
    use ForgeOps::Tracker::Integrations::Dancer2;
    use ForgeOps::Tracker::Integrations::Dancer2Performance;

    set apphandler => 'PSGI';
    set startup_info => 0;
    set logger => 'Null';

    get '/orders/:id' => sub { ForgeOps::Tracker::report("handled\n"); return 'ok'; };
    post '/checkout/:cart' => sub { die "route exploded\n"; };
}

package PerformanceFirstApp {
    use Dancer2;
    use ForgeOps::Tracker::Integrations::Dancer2Performance;
    use ForgeOps::Tracker::Integrations::Dancer2;

    set apphandler => 'PSGI';
    set startup_info => 0;
    set logger => 'Null';

    post '/checkout/:cart' => sub { die "route exploded\n"; };
}

package main;

subtest 'Dancer2: an error reported inside a route carries the continued trace and the route pattern' => sub {
    init_tracker();
    test_psgi(ErrorsFirstApp->to_app, sub { $_[0]->(GET '/orders/42', traceparent => $HEADER) });

    is(reported()->[0]{trace_id}, $TRACE_ID);
    is(reported()->[0]{transaction_name}, 'GET /orders/:id');
    is(reported()->[0]{endpoint}, 'GET /orders/:id');
    is(sent_traces()->[0]{spans}[0]{parent_span_id}, $PARENT_ID, 'fast, but errored: sent');
};

for my $app_class (qw(ErrorsFirstApp PerformanceFirstApp)) {
    subtest "Dancer2 ($app_class): a route that dies is reported with its context and its trace is sent" => sub {
        init_tracker();
        my $res;
        test_psgi($app_class->to_app, sub { $res = $_[0]->(POST '/checkout/9', traceparent => $HEADER) });

        is($res->code, 500);
        is(scalar(@{ reported() }), 1);
        is(reported()->[0]{trace_id}, $TRACE_ID);
        is(reported()->[0]{endpoint}, 'POST /checkout/:cart');
        is(scalar(@{ sent_traces() }), 1);
        is(sent_traces()->[0]{spans}[0]{name}, 'POST /checkout/:cart');
        is(ForgeOps::Tracker::current_trace_id(), undef, 'nothing leaks past the request');
    };
}

done_testing;
