#!/usr/bin/env perl
# Since design D11 (karr k24) the cluster resource map is built from aggregated
# discovery (GET /api + GET /apis), NOT from GET /openapi/v2. This test used to
# assert that fetch_resource_map and schema_for shared a single /openapi/v2
# download (karr #17); that premise is gone - the map no longer touches the
# spec at all. The reformulated claim:
#   * building the map fetches discovery (/api + /apis), never /openapi/v2;
#   * schema_for still fetches /openapi/v2, lazily and exactly once, and the
#     map build does not fetch it for it.
# The old shared-single-download assertion is retired because it no longer
# describes the code; the /openapi/v2-stays-lazy half of the intent survives
# here and the discovery half is pinned in t/39_aggregated_discovery.t.
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

# Mock IO that records every request it serves.
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

my %CORE_DISCOVERY = (
    kind  => 'APIGroupDiscoveryList',
    items => [
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
                    ],
                },
            ],
        },
    ],
);

my %GROUPED_DISCOVERY = (
    kind  => 'APIGroupDiscoveryList',
    items => [],
);

my %OPENAPI_SPEC = (
    definitions => {
        'io.k8s.api.core.v1.Pod' => {
            description => 'Pod is a collection of containers',
            properties => { metadata => {}, spec => {} },
        },
    },
);

subtest 'the map builds from discovery, schema_for still uses /openapi/v2 once' => sub {
    my $io = Counting::Mock::IO->new;
    $io->add_response('GET', '/api',  \%CORE_DISCOVERY);
    $io->add_response('GET', '/apis', \%GROUPED_DISCOVERY);
    $io->add_response('GET', '/openapi/v2', \%OPENAPI_SPEC);
    my $api = Kubernetes::REST->new(
        server => Kubernetes::REST::Server->new(endpoint => 'http://mock.local'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'MockToken'),
        io => $io,
    );

    my $map = $api->fetch_resource_map;
    is $map->{Pod}, 'Api::Core::V1::Pod', 'fetch_resource_map builds the map from discovery';
    is count_calls($io, 'GET /api'),  1, 'GET /api for the map';
    is count_calls($io, 'GET /apis'), 1, 'GET /apis for the map';
    is count_calls($io, 'GET /openapi/v2'), 0,
        'the map build never downloaded /openapi/v2';

    my $schema = $api->schema_for('io.k8s.api.core.v1.Pod');
    is $schema->{description}, 'Pod is a collection of containers',
        'schema_for answers from the lazily-fetched spec';
    is count_calls($io, 'GET /openapi/v2'), 1, 'one /openapi/v2 download for schema_for';

    $api->schema_for('io.k8s.api.core.v1.Pod');
    is count_calls($io, 'GET /openapi/v2'), 1,
        'the spec is cached - schema_for does not download it again';

    $api->fetch_resource_map;
    is count_calls($io, 'GET /openapi/v2'), 1,
        'a repeated fetch_resource_map still does not touch /openapi/v2';
    is count_calls($io, 'GET /api'),  1,
        'a repeated fetch_resource_map rebuilds from the cached discovery catalog';
};

subtest 'the failure path keeps its documented wording' => sub {
    my $api = mock_api();
    # mock_api has no /api or /apis discovery response -> 404
    throws_ok { $api->fetch_resource_map }
        qr/Could not load resource map from cluster:/,
        'fetch_resource_map croaks with its own message';
    like $@, qr/404/, 'and the underlying status rides along';
};

done_testing;
