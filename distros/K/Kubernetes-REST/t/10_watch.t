#!/usr/bin/env perl
# Tests for the Kubernetes Watch API using mock data.
#
# Run:
#   prove -l t/10_watch.t

use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock qw(mock_api);
use Kubernetes::REST;
use Kubernetes::REST::Server;
use Kubernetes::REST::AuthToken;
use Kubernetes::REST::WatchEvent;
use IO::K8s;

my $container = { name => 'nginx', image => 'nginx:1.27' };

# Build a mock API with watch-capable IO
my $mock_io = Test::Kubernetes::Mock::IO->new;

my $api = Kubernetes::REST->new(
    server      => Kubernetes::REST::Server->new(endpoint => 'http://mock.local'),
    credentials => Kubernetes::REST::AuthToken->new(token => 'MockToken'),
    resource_map_from_cluster => 0,
    io          => $mock_io,
);

# === Test 1: Watch with ADDED/MODIFIED/DELETED events ===
subtest 'watch pod events' => sub {
    $mock_io->add_watch_events('/api/v1/namespaces/default/pods', [
        {
            type   => 'ADDED',
            object => {
                apiVersion => 'v1',
                kind       => 'Pod',
                metadata   => {
                    name            => 'nginx-abc',
                    namespace       => 'default',
                    resourceVersion => '100',
                    uid             => 'uid-1',
                },
                spec   => { containers => [$container], nodeName => 'node-1' },
                status => { phase => 'Running' },
            },
        },
        {
            type   => 'MODIFIED',
            object => {
                apiVersion => 'v1',
                kind       => 'Pod',
                metadata   => {
                    name            => 'nginx-abc',
                    namespace       => 'default',
                    resourceVersion => '101',
                    uid             => 'uid-1',
                },
                spec   => { containers => [$container], nodeName => 'node-1' },
                status => { phase => 'Succeeded' },
            },
        },
        {
            type   => 'DELETED',
            object => {
                apiVersion => 'v1',
                kind       => 'Pod',
                metadata   => {
                    name            => 'nginx-abc',
                    namespace       => 'default',
                    resourceVersion => '102',
                    uid             => 'uid-1',
                },
                spec   => { containers => [$container], nodeName => 'node-1' },
                status => { phase => 'Succeeded' },
            },
        },
    ]);

    my @events;
    my $last_rv = $api->watch('Pod',
        namespace => 'default',
        on_event  => sub { push @events, $_[0] },
    );

    is(scalar @events, 3, 'received 3 events');

    # Check event types
    is($events[0]->type, 'ADDED', 'first event is ADDED');
    is($events[1]->type, 'MODIFIED', 'second event is MODIFIED');
    is($events[2]->type, 'DELETED', 'third event is DELETED');

    # Check inflated objects
    isa_ok($events[0]->object, 'IO::K8s::Api::Core::V1::Pod', 'ADDED object is inflated Pod');
    is($events[0]->object->metadata->name, 'nginx-abc', 'ADDED pod name');
    is($events[0]->object->status->phase, 'Running', 'ADDED pod phase');

    is($events[1]->object->status->phase, 'Succeeded', 'MODIFIED pod phase');
    is($events[2]->object->metadata->name, 'nginx-abc', 'DELETED pod name');

    # Check raw data preserved
    is($events[0]->raw->{metadata}{resourceVersion}, '100', 'raw resourceVersion');
};

# === Test 2: Verify last resourceVersion return ===
subtest 'last resourceVersion returned' => sub {
    $mock_io->add_watch_events('/api/v1/namespaces/kube-system/pods', [
        {
            type   => 'ADDED',
            object => {
                apiVersion => 'v1',
                kind       => 'Pod',
                metadata   => {
                    name            => 'coredns-xyz',
                    namespace       => 'kube-system',
                    resourceVersion => '500',
                },
                spec   => { containers => [$container] },
                status => { phase => 'Running' },
            },
        },
        {
            type   => 'MODIFIED',
            object => {
                apiVersion => 'v1',
                kind       => 'Pod',
                metadata   => {
                    name            => 'coredns-xyz',
                    namespace       => 'kube-system',
                    resourceVersion => '505',
                },
                spec   => { containers => [$container] },
                status => { phase => 'Running' },
            },
        },
    ]);

    my $last_rv = $api->watch('Pod',
        namespace       => 'kube-system',
        resourceVersion => '400',
        on_event        => sub {},
    );

    is($last_rv, '505', 'returns last resourceVersion');
};

# === Test 3: Watch without on_event dies ===
subtest 'watch without on_event dies' => sub {
    throws_ok {
        $api->watch('Pod', namespace => 'default');
    } qr/on_event/, 'dies without on_event callback';
};

# === Test 4: Watch CRD class ===
subtest 'watch CRD class' => sub {
    require My::StaticWebSite;

    # Build API with CRD registered
    my $crd_io = Test::Kubernetes::Mock::IO->new;
    my $default_map = IO::K8s->default_resource_map;
    my $crd_api = Kubernetes::REST->new(
        server      => Kubernetes::REST::Server->new(endpoint => 'http://mock.local'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'MockToken'),
        resource_map_from_cluster => 0,
        resource_map => {
            %$default_map,
            StaticWebSite => '+My::StaticWebSite',
        },
        io => $crd_io,
    );

    $crd_io->add_watch_events('/apis/homelab.example.com/v1/namespaces/default/staticwebsites', [
        {
            type   => 'ADDED',
            object => {
                apiVersion => 'homelab.example.com/v1',
                kind       => 'StaticWebSite',
                metadata   => {
                    name            => 'my-blog',
                    namespace       => 'default',
                    resourceVersion => '200',
                },
                spec => {
                    domain   => 'blog.example.com',
                    image    => 'nginx:1.27',
                    replicas => 2,
                },
            },
        },
    ]);

    my @events;
    $crd_api->watch('StaticWebSite',
        namespace => 'default',
        on_event  => sub { push @events, $_[0] },
    );

    is(scalar @events, 1, 'received CRD event');
    is($events[0]->type, 'ADDED', 'CRD event type');
    is($events[0]->object->metadata->name, 'my-blog', 'CRD object name');
    is($events[0]->object->spec->{domain}, 'blog.example.com', 'CRD spec preserved');
};

# === Test 5: ERROR event handling ===
subtest 'ERROR event handling' => sub {
    $mock_io->add_watch_events('/api/v1/namespaces/test/pods', [
        {
            type   => 'ADDED',
            object => {
                apiVersion => 'v1',
                kind       => 'Pod',
                metadata   => {
                    name            => 'test-pod',
                    namespace       => 'test',
                    resourceVersion => '300',
                },
                spec   => { containers => [$container] },
                status => { phase => 'Running' },
            },
        },
        {
            type   => 'ERROR',
            object => {
                kind    => 'Status',
                status  => 'Failure',
                message => 'too old resource version: 100 (300)',
                reason  => 'Gone',
                code    => 410,
            },
        },
    ]);

    my @events;
    throws_ok {
        $api->watch('Pod',
            namespace => 'test',
            on_event  => sub { push @events, $_[0] },
        );
    } qr/410 Gone/, 'dies on 410 Gone';

    is(scalar @events, 2, 'received events before death');
    is($events[0]->type, 'ADDED', 'first event was ADDED');
    is($events[1]->type, 'ERROR', 'second event was ERROR');
    is(ref($events[1]->object), 'HASH', 'ERROR object is a hashref');
    is($events[1]->object->{code}, 410, 'ERROR code is 410');
};

# === Test 6: WatchEvent class ===
subtest 'WatchEvent class' => sub {
    my $event = Kubernetes::REST::WatchEvent->new(
        type   => 'ADDED',
        object => { metadata => { name => 'test' } },
        raw    => { metadata => { name => 'test' } },
    );
    ok($event, 'WatchEvent created');
    is($event->type, 'ADDED', 'type accessor');
    is($event->raw->{metadata}{name}, 'test', 'raw accessor');
};

# === Test 7: Watch with selectors ===
subtest 'watch with selectors' => sub {
    $mock_io->add_watch_events('/api/v1/namespaces/default/pods', [
        {
            type   => 'ADDED',
            object => {
                apiVersion => 'v1',
                kind       => 'Pod',
                metadata   => {
                    name            => 'web-1',
                    namespace       => 'default',
                    resourceVersion => '400',
                    labels          => { app => 'web' },
                },
                spec   => { containers => [$container] },
                status => { phase => 'Running' },
            },
        },
    ]);

    my @events;
    my $last_rv = $api->watch('Pod',
        namespace       => 'default',
        on_event        => sub { push @events, $_[0] },
        labelSelector   => 'app=web',
        fieldSelector   => 'status.phase=Running',
        resourceVersion => '399',
    );

    is(scalar @events, 1, 'received event with selectors');
    is($last_rv, '400', 'resourceVersion correct with selectors');
};

# === An exception in on_event reaches the caller of watch() (k71) ===
subtest 'exception in on_event propagates out of watch' => sub {
    $mock_io->add_watch_events('/api/v1/namespaces/default/pods', [
        {
            type   => 'ADDED',
            object => {
                apiVersion => 'v1', kind => 'Pod',
                metadata   => { name => 'p1', namespace => 'default', resourceVersion => '7' },
                spec       => { containers => [$container] },
            },
        },
    ]);

    my $seen = 0;
    my $rv = eval {
        $api->watch('Pod',
            namespace => 'default',
            on_event  => sub { $seen++; die "handler bug\n" },
        );
    };
    is $@, "handler bug\n", 'string exception reaches the caller';
    is $seen, 1, 'handler ran once';
    ok !defined $rv, 'no resourceVersion returned';

    my $obj = bless { why => 'leave watch' }, 'Test::LeaveWatch';
    eval { $api->watch('Pod', namespace => 'default', on_event => sub { die $obj }) };
    is ref $@, 'Test::LeaveWatch', 'object exception survives watch';
    is $@->{why}, 'leave watch', 'payload intact';
};

done_testing;
