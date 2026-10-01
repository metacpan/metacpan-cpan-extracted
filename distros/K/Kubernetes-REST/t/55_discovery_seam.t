#!/usr/bin/env perl
# karr k51: a public seam for discovery, for async clients.
#
# With resource_map_from_cluster the client reads discovery (GET /api and
# GET /apis) through its own synchronous io the first time it resolves a Kind
# - which blocks the event loop of an async client (Net::Async::Kubernetes
# k59). prepare_discovery_requests builds those two requests without sending
# them; absorb_discovery takes the responses back. When both are aggregated
# discovery, the catalog is cached and resolution needs no io of its own;
# legacy discovery (clusters before 1.27) answers false and caches nothing,
# and the caller falls back to the synchronous path.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use JSON::MaybeXS ();
use Test::Kubernetes::Mock ();
use Kubernetes::REST;
use Kubernetes::REST::HTTPResponse;

my $ACCEPT = 'application/json;g=apidiscovery.k8s.io;v=v2;as=APIGroupDiscoveryList';

# Records every request (METHOD /path?query) with its headers.
{
    package Test::DiscoverySeam::IO;
    use Moo;
    extends 'Test::Kubernetes::Mock::IO';

    has calls   => (is => 'ro', default => sub { [] });
    has headers => (is => 'ro', default => sub { [] });

    around call => sub {
        my ($orig, $self, $req) = @_;
        (my $path = $req->url) =~ s{\Ahttps?://[^/]+}{};
        push @{ $self->calls }, $req->method . ' ' . $path;
        push @{ $self->headers }, { %{ $req->headers } };
        return $self->$orig($req);
    };
}

sub api {
    my (%args) = @_;
    return Kubernetes::REST->new(
        server      => { endpoint => 'http://mock.local' },
        credentials => { token => 'MockToken' },
        io          => Test::DiscoverySeam::IO->new,
        %args,
    );
}

my $wire_json = JSON::MaybeXS->new(utf8 => 1, canonical => 1);

sub response {
    my ($status, $body) = @_;
    return Kubernetes::REST::HTTPResponse->new(
        status  => $status,
        content => ref $body ? $wire_json->encode($body) : $body,
    );
}

sub resource {
    my ($group, $plural, $kind) = @_;
    return {
        resource     => $plural,
        responseKind => { group => $group, version => 'v1', kind => $kind },
        scope        => 'Namespaced',
    };
}

sub aggregated {
    my ($group, @resources) = @_;
    return {
        kind       => 'APIGroupDiscoveryList',
        apiVersion => 'apidiscovery.k8s.io/v2',
        items      => [ {
            metadata => { name => $group },
            versions => [ { version => 'v1', resources => \@resources } ],
        } ],
    };
}

# Cluster A serves Pod and example.com/v1 Widget; cluster B, the same one
# later, ConfigMap and Gadget as well.
my $CORE_A    = aggregated('', resource('', 'pods', 'Pod'));
my $GROUPED_A = aggregated('example.com', resource('example.com', 'widgets', 'Widget'));
my $CORE_B    = aggregated('', resource('', 'pods', 'Pod'),
                               resource('', 'configmaps', 'ConfigMap'));
my $GROUPED_B = aggregated('example.com', resource('example.com', 'widgets', 'Widget'),
                                          resource('example.com', 'gadgets', 'Gadget'));

my $LEGACY_CORE = { kind => 'APIVersions', versions => ['v1'] };

subtest 'prepare_discovery_requests: the two requests, nothing sent' => sub {
    my $api = api();
    my @pairs = $api->prepare_discovery_requests;
    is_deeply([ @pairs[0, 2] ], [ '/api', '/apis' ], '/api, then /apis');
    my %req = @pairs;
    for my $root ('/api', '/apis') {
        my $req = $req{$root};
        isa_ok($req, 'Kubernetes::REST::HTTPRequest', $root);
        is($req->method, 'GET', "$root: GET");
        is($req->url, "http://mock.local$root", "$root: url");
        is($req->headers->{Accept}, $ACCEPT, "$root: aggregated discovery Accept header");
        is($req->headers->{Authorization}, 'Bearer MockToken', "$root: authorized");
    }
    is_deeply($api->io->calls, [], 'nothing was sent');

    # The synchronous path sends the same requests.
    $api->io->add_response('GET', '/api',  $CORE_A);
    $api->io->add_response('GET', '/apis', $GROUPED_A);
    $api->fetch_resource_map;
    is_deeply($api->io->calls, [ 'GET /api', 'GET /apis' ], 'the synchronous fetch');
    is_deeply($api->io->headers, [ map { $req{$_}->headers } '/api', '/apis' ],
        'sends exactly the prepared headers');
};

subtest 'absorb_discovery: resolution needs no io afterwards' => sub {
    my $api = api();
    ok($api->absorb_discovery(
        '/api'  => response(200, $CORE_A),
        '/apis' => response(200, $GROUPED_A),
    ), 'both aggregated: true');

    is($api->expand_class('Widget'), 'IO::K8s::Unstructured',
        'expand_class: a Kind only discovery serves');
    is($api->expand_class('example.com/v1/Widget'), 'IO::K8s::Unstructured',
        'expand_class: the qualified name');
    is($api->expand_class('Pod'), 'IO::K8s::Api::Core::V1::Pod', 'expand_class: Pod');
    is($api->fetch_resource_map->{Pod}, 'Api::Core::V1::Pod', 'fetch_resource_map');
    is($api->resource_map->{Pod}, 'Api::Core::V1::Pod', 'the lazy resource_map');
    is($api->build_path('IO::K8s::Unstructured',
            kind => 'Widget', name => 'w1', namespace => 'ns'),
        '/apis/example.com/v1/namespaces/ns/widgets/w1',
        'build_path: plural and scope from the absorbed catalog');
    is_deeply($api->io->calls, [], 'not one request went to the io');
};

subtest 'absorb_discovery replaces what an earlier catalog built' => sub {
    my $api = api();
    $api->io->add_response('GET', '/api',  $CORE_A);
    $api->io->add_response('GET', '/apis', $GROUPED_A);
    is($api->expand_class('Widget'), 'IO::K8s::Unstructured', 'cluster A, fetched');
    ok(!exists $api->resource_map->{ConfigMap}, 'cluster A has no ConfigMap');
    my $mark = @{ $api->io->calls };

    ok($api->absorb_discovery(
        '/api'  => response(200, $CORE_B),
        '/apis' => response(200, $GROUPED_B),
    ), 'cluster B absorbed');
    is($api->expand_class('Gadget'), 'IO::K8s::Unstructured', 'a Kind only B serves resolves');
    is($api->resource_map->{ConfigMap}, 'Api::Core::V1::ConfigMap',
        'the resource map was rebuilt from B');
    is_deeply([ @{ $api->io->calls }[ $mark .. $#{ $api->io->calls } ] ], [],
        'without a request');
};

subtest 'a resource_map passed to the constructor stays' => sub {
    my $map = { %{ IO::K8s->default_resource_map }, Special => 'Api::Core::V1::ConfigMap' };
    my $api = api(resource_map => $map);
    # The client's own copy of it (karr k57), held since construction.
    my $held = $api->resource_map;
    ok($api->absorb_discovery(
        '/api'  => response(200, $CORE_A),
        '/apis' => response(200, $GROUPED_A),
    ), 'absorbed');
    is($api->resource_map, $held, 'the map held since construction, not rebuilt');
    is($api->resource_map->{Special}, 'Api::Core::V1::ConfigMap', 'with the caller\'s entry');
    is($api->expand_class('Widget'), 'IO::K8s::Unstructured',
        'and the absorbed catalog still confirms Widget');
    is_deeply($api->io->calls, [], 'without a request');
};

subtest 'legacy discovery: false, nothing cached' => sub {
    my $api = api();
    ok(!$api->absorb_discovery(
        '/api'  => response(200, $LEGACY_CORE),
        '/apis' => response(200, $GROUPED_A),
    ), 'a legacy /api: false');
    ok(!$api->_has_discovery, 'no catalog cached');

    # An absorbed catalog is not touched by a later legacy answer.
    ok($api->absorb_discovery(
        '/api'  => response(200, $CORE_A),
        '/apis' => response(200, $GROUPED_A),
    ), 'aggregated absorbed');
    ok(!$api->absorb_discovery(
        '/api'  => response(200, $CORE_B),
        '/apis' => response(200, { kind => 'APIGroupList', groups => [] }),
    ), 'a legacy /apis: false');
    ok(!eval { $api->build_path('IO::K8s::Unstructured', kind => 'Gadget', name => 'g1'); 1 },
        'the catalog is still cluster A: no Gadget');
    is_deeply($api->io->calls, [], 'no request');
};

subtest 'an HTTP error dies with an APIError, as discovery does' => sub {
    my $api = api();
    eval {
        $api->absorb_discovery(
            '/api'  => response(200, $CORE_A),
            '/apis' => response(503, 'unavailable'),
        );
    };
    isa_ok($@, 'Kubernetes::REST::APIError', 'the error');
    like($@, qr{\AKubernetes API error \(discovery GET /apis\): 503 unavailable at },
        'names the root, the status and the body');
    ok(!$api->_has_discovery, 'no catalog cached');
};

subtest 'both responses are required, nothing else is taken' => sub {
    my $api = api();
    eval { $api->absorb_discovery('/api' => response(200, $CORE_A)) };
    like($@, qr{absorb_discovery requires the response for /apis}, 'a missing /apis');
    eval {
        $api->absorb_discovery(
            '/api'  => response(200, $CORE_A),
            '/apis' => response(200, $GROUPED_A),
            '/apis/example.com/v1' => response(200, {}),
        );
    };
    like($@, qr{\AUnknown argument '/apis/example\.com/v1' to absorb_discovery\(\)},
        'an unknown root');
    ok(!$api->_has_discovery, 'no catalog cached');
};

done_testing;
