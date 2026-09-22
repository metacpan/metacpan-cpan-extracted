#!/usr/bin/env perl
# karr k24 / design D11: the cluster resource map is built from aggregated
# discovery (GET /api + GET /apis with the apidiscovery.k8s.io v2 Accept
# header, per-group APIResourceList fallback for pre-1.27 clusters), not from
# GET /openapi/v2. The discovery catalog is cached per instance, carries
# plural/scope/preferred, and is invalidated by invalidate_discovery.
# /openapi/v2 stays lazy - fetched only when schema_for/compare_schema need it.
use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";

use Test::Kubernetes::Mock qw(mock_api);
use Kubernetes::REST;
use Kubernetes::REST::Server;
use Kubernetes::REST::AuthToken;

# Mock IO that records every request it serves (METHOD PATH), as in t/36/t/38.
{
    package Counting::Mock::IO;
    use Moo;
    extends 'Test::Kubernetes::Mock::IO';

    has calls => (is => 'ro', default => sub { [] });

    around call => sub {
        my ($orig, $self, $req) = @_;
        (my $path = $req->url // '') =~ s{^https?://[^/]+}{};
        push @{$self->calls}, ($req->method // 'GET') . ' ' . $path;
        return $self->$orig($req);
    };
}

sub count_calls {
    my ($io, $wanted) = @_;
    return scalar grep { $_ eq $wanted } @{$io->calls};
}

# ---------------------------------------------------------------------------
# Aggregated discovery v2 bodies (APIGroupDiscoveryList)
# ---------------------------------------------------------------------------

# GET /api -> the core group (metadata.name is the empty string)
my %CORE_DISCOVERY = (
    kind       => 'APIGroupDiscoveryList',
    apiVersion => 'apidiscovery.k8s.io/v2',
    items      => [
        {
            metadata => { name => '' },
            versions => [
                {
                    version   => 'v1',
                    resources => [
                        {
                            resource     => 'pods',
                            responseKind => { group => '', version => 'v1', kind => 'Pod' },
                            scope        => 'Namespaced',
                        },
                        {
                            resource     => 'namespaces',
                            responseKind => { group => '', version => 'v1', kind => 'Namespace' },
                            scope        => 'Cluster',
                        },
                    ],
                },
            ],
        },
    ],
);

# GET /apis -> the grouped APIs. 'stable.example' is a FOREIGN CRD group with
# no bundled IO::K8s class; it serves v2beta1 (listed first, hence preferred)
# and v1. It exercises two things: the catalog still records every version and
# the preferred one (below), while the built map omits the Kind entirely -- no
# invented Api::Stable::V1::Thing class (design D12/D13, "stop inventing").
my %GROUPED_DISCOVERY = (
    kind  => 'APIGroupDiscoveryList',
    items => [
        {
            metadata => { name => 'apps' },
            versions => [
                {
                    version   => 'v1',
                    resources => [
                        {
                            resource     => 'deployments',
                            responseKind => { group => 'apps', version => 'v1', kind => 'Deployment' },
                            scope        => 'Namespaced',
                        },
                    ],
                },
            ],
        },
        {
            metadata => { name => 'stable.example' },
            versions => [
                {
                    version   => 'v2beta1',
                    resources => [
                        {
                            resource     => 'things',
                            responseKind => { group => 'stable.example', version => 'v2beta1', kind => 'Thing' },
                            scope        => 'Namespaced',
                        },
                    ],
                },
                {
                    version   => 'v1',
                    resources => [
                        {
                            resource     => 'things',
                            responseKind => { group => 'stable.example', version => 'v1', kind => 'Thing' },
                            scope        => 'Namespaced',
                        },
                    ],
                },
            ],
        },
    ],
);

sub discovery_api {
    my (%extra) = @_;
    my $io = Counting::Mock::IO->new;
    $io->add_response('GET', '/api',  \%CORE_DISCOVERY);
    $io->add_response('GET', '/apis', \%GROUPED_DISCOVERY);
    my $api = Kubernetes::REST->new(
        server      => Kubernetes::REST::Server->new(endpoint => 'http://mock.local'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'MockToken'),
        io          => $io,
        %extra,
    );
    return ($api, $io);
}

subtest 'the map is built from discovery, not /openapi/v2' => sub {
    my ($api, $io) = discovery_api();

    my $map = $api->fetch_resource_map;

    is $map->{Pod},        'Api::Core::V1::Pod',        'core Pod';
    is $map->{Namespace},  'Api::Core::V1::Namespace',  'core Namespace';
    is $map->{Deployment}, 'Api::Apps::V1::Deployment', 'apps Deployment';
    ok !exists $map->{Thing},
        'a foreign-group Kind with no bundled class is omitted (no invented name)';

    is count_calls($io, 'GET /api'),  1, 'GET /api once';
    is count_calls($io, 'GET /apis'), 1, 'GET /apis once';
    is count_calls($io, 'GET /openapi/v2'), 0, 'the map build never touched /openapi/v2';
};

subtest 'the discovery catalog carries plural, scope and preferred version' => sub {
    my ($api, $io) = discovery_api();
    my $cat = $api->_discovery;

    is $cat->{groups}{''}{versions}{v1}{kinds}{Pod}{resource}, 'pods',
        'plural for a core kind';
    is $cat->{groups}{''}{versions}{v1}{kinds}{Pod}{scope}, 'Namespaced',
        'scope Namespaced';
    is $cat->{groups}{''}{versions}{v1}{kinds}{Namespace}{scope}, 'Cluster',
        'scope Cluster';

    is $cat->{groups}{'stable.example'}{versions}{v2beta1}{kinds}{Thing}{resource},
        'things', 'plural for a grouped kind';

    # preferred = the first version discovery lists for the group, regardless
    # of which version the (prefer-stable) map picks.
    is $cat->{groups}{'stable.example'}{preferred}, 'v2beta1',
        'preferred version is the first one served';
    is $cat->{groups}{apps}{preferred}, 'v1', 'apps preferred v1';
};

subtest 'discovery is fetched once, cached, and re-fetched after invalidation' => sub {
    my ($api, $io) = discovery_api();

    $api->fetch_resource_map;
    $api->fetch_resource_map;
    is count_calls($io, 'GET /api'),  1, 'a repeated fetch_resource_map reuses the cached catalog (/api)';
    is count_calls($io, 'GET /apis'), 1, 'a repeated fetch_resource_map reuses the cached catalog (/apis)';

    $api->invalidate_discovery;
    $api->fetch_resource_map;
    is count_calls($io, 'GET /api'),  2, 'invalidate_discovery forces a re-fetch (/api)';
    is count_calls($io, 'GET /apis'), 2, 'invalidate_discovery forces a re-fetch (/apis)';
};

subtest 'a name the built-in map cannot answer still fetches discovery' => sub {
    my ($api, $io) = discovery_api();

    # 'Thing' is not in the built-in map, so resolving it falls through and
    # forces the discovery-built cluster map. That map omits the foreign Kind
    # (D12), so resolution fails open to the bare IO::K8s::Thing fallback --
    # crucially NOT to an invented IO::K8s::Api::Stable::V1::Thing. The point of
    # this subtest is the fetch behaviour: discovery once, /openapi/v2 never.
    my $class = $api->expand_class('Thing');
    unlike $class, qr/Api::Stable/,
        'no invented Api::<Group> class for a foreign Kind';
    is count_calls($io, 'GET /api'),  1, 'built via discovery (/api)';
    is count_calls($io, 'GET /apis'), 1, 'built via discovery (/apis)';
    is count_calls($io, 'GET /openapi/v2'), 0, 'and not via /openapi/v2';
};

# ---------------------------------------------------------------------------
# /openapi/v2 stays lazy: schema_for still fetches it, exactly once, and the
# map build does not (replaces the premise of the old t/38).
# ---------------------------------------------------------------------------
subtest 'schema_for still fetches /openapi/v2 lazily and exactly once' => sub {
    my ($api, $io) = discovery_api();
    $io->add_response('GET', '/openapi/v2', {
        definitions => {
            'io.k8s.api.core.v1.Pod' => {
                description => 'Pod is a collection of containers',
            },
        },
    });

    $api->fetch_resource_map;
    is count_calls($io, 'GET /openapi/v2'), 0, 'map build did not fetch the spec';

    my $schema = $api->schema_for('io.k8s.api.core.v1.Pod');
    is $schema->{description}, 'Pod is a collection of containers', 'schema_for reads the spec';
    is count_calls($io, 'GET /openapi/v2'), 1, 'one /openapi/v2 download';

    $api->schema_for('io.k8s.api.core.v1.Pod');
    is count_calls($io, 'GET /openapi/v2'), 1, 'the spec is cached, not re-fetched';
};

# ---------------------------------------------------------------------------
# Pre-1.27 fallback: the server ignores the aggregated-discovery Accept header
# and answers the legacy documents; the catalog is filled from per-group
# APIResourceList responses instead.
# ---------------------------------------------------------------------------
subtest 'per-group APIResourceList fallback for old clusters' => sub {
    my $io = Counting::Mock::IO->new;

    # Legacy /api -> APIVersions, legacy /apis -> APIGroupList
    $io->add_response('GET', '/api', {
        kind     => 'APIVersions',
        versions => ['v1'],
    });
    $io->add_response('GET', '/apis', {
        kind   => 'APIGroupList',
        groups => [
            {
                name             => 'apps',
                versions         => [{ groupVersion => 'apps/v1', version => 'v1' }],
                preferredVersion => { groupVersion => 'apps/v1', version => 'v1' },
            },
        ],
    });
    # Per-version APIResourceLists
    $io->add_response('GET', '/api/v1', {
        kind         => 'APIResourceList',
        groupVersion => 'v1',
        resources    => [
            { name => 'pods',        namespaced => JSON::MaybeXS::true(),  kind => 'Pod' },
            { name => 'pods/status', namespaced => JSON::MaybeXS::true(),  kind => 'Pod' },
            { name => 'namespaces',  namespaced => JSON::MaybeXS::false(), kind => 'Namespace' },
        ],
    });
    $io->add_response('GET', '/apis/apps/v1', {
        kind         => 'APIResourceList',
        groupVersion => 'apps/v1',
        resources    => [
            { name => 'deployments', namespaced => JSON::MaybeXS::true(), kind => 'Deployment' },
        ],
    });

    my $api = Kubernetes::REST->new(
        server      => Kubernetes::REST::Server->new(endpoint => 'http://mock.local'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'MockToken'),
        io          => $io,
    );

    my $map = $api->fetch_resource_map;
    is $map->{Pod},        'Api::Core::V1::Pod',        'fallback: core Pod';
    is $map->{Namespace},  'Api::Core::V1::Namespace',  'fallback: core Namespace';
    is $map->{Deployment}, 'Api::Apps::V1::Deployment', 'fallback: apps Deployment';

    my $cat = $api->_discovery;
    is $cat->{groups}{''}{versions}{v1}{kinds}{Pod}{resource}, 'pods',
        'fallback: plural from APIResourceList';
    is $cat->{groups}{''}{versions}{v1}{kinds}{Pod}{scope}, 'Namespaced',
        'fallback: namespaced -> Namespaced';
    is $cat->{groups}{''}{versions}{v1}{kinds}{Namespace}{scope}, 'Cluster',
        'fallback: not namespaced -> Cluster';
    ok !exists $cat->{groups}{''}{versions}{v1}{kinds}{'Pod/status'},
        'fallback: subresource entries (name with /) are skipped';
    is $cat->{groups}{apps}{preferred}, 'v1', 'fallback: preferred from preferredVersion';
};

# ---------------------------------------------------------------------------
# The failure path keeps the documented wording of fetch_resource_map.
# ---------------------------------------------------------------------------
subtest 'discovery failure keeps fetch_resource_map wording' => sub {
    my $api = mock_api();  # no /api or /apis mocked -> 404
    throws_ok { $api->fetch_resource_map }
        qr/Could not load resource map from cluster:/,
        'fetch_resource_map croaks with its own message';
    like $@, qr/404/, 'and the underlying status rides along';
};

# ---------------------------------------------------------------------------
# _load_resource_map_from_cluster (the lazy fallback behind the resource_map
# attribute) used to wrap fetch_resource_map's own croak text inside a carp
# that repeated the same "Could not load resource map from cluster" phrase,
# so an unreachable cluster logged it twice: "Could not load resource map
# from cluster, using default: Could not load resource map from cluster:
# discovery GET /api failed: 404 ...". The outer wrapper now names its own
# failure mode instead of echoing the inner one (k29).
# ---------------------------------------------------------------------------
subtest 'the built-in-map fallback names the load failure once, not twice (k29)' => sub {
    # mock_api() hardcodes resource_map_from_cluster => 0, which never reaches
    # the lazy fallback at all -- built directly here, at the class default of
    # 1, with no /api or /apis fixture registered (same 404 as the subtest
    # above), so that reading resource_map exercises the real cluster-backed
    # path and its carp.
    my $api = Kubernetes::REST->new(
        server      => Kubernetes::REST::Server->new(endpoint => 'http://mock.local'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'MockToken'),
        io          => Test::Kubernetes::Mock::IO->new,
    );

    my @warnings;
    my $map = do {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        $api->resource_map;
    };

    is scalar @warnings, 1, 'exactly one warning for the whole fallback';
    like $warnings[0],
        qr/^Falling back to the built-in resource map: Could not load resource map from cluster: discovery GET \/api failed: 404/,
        'the outer wrapper names its own failure, with the inner one riding along once';
    my $repeats = () = $warnings[0] =~ /Could not load resource map from cluster/g;
    is $repeats, 1, 'and the phrase is not doubled';

    ok $map->{Pod}, 'the built-in default map still comes back';
};

done_testing;
