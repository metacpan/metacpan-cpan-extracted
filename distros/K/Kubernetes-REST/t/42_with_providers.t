#!/usr/bin/env perl
# Design D12 (karr k24), increment B: Kubernetes::REST->new(with => [...])
# mirrors IO::K8s->new(with => [...]), and the lazily fetched /openapi/v2 spec
# is handed to the inner IO::K8s as openapi_spec -- WITHOUT the pass-through
# forcing that download at construction time. What is observable now is the
# plumbing: the inner instance has the providers merged (CRD Kinds resolve to
# real classes) and, once the spec has actually been fetched, carries it as
# openapi_spec. The AutoGen resolution that consumes it is increment C.
#
# IO::K8s::GatewayAPI and its GatewayAPI::V1::* classes live in the neighbour
# io-k8s-p5 lib, so this test must run with that lib prepended to PERL5LIB.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";

use Test::Kubernetes::Mock ();
use Kubernetes::REST;
use Kubernetes::REST::Server;
use Kubernetes::REST::AuthToken;

# The provider classes only exist in the neighbour lib; skip cleanly rather
# than fail if this test is run without that lib on the path.
BEGIN {
    unless (eval { require IO::K8s::GatewayAPI; 1 }) {
        plan skip_all =>
            'IO::K8s::GatewayAPI not available '
          . '(prepend io-k8s-p5/lib to PERL5LIB to run this test)';
    }
}

# Mock IO that records every request it serves (same technique as t/36/t/38).
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

my %OPENAPI_SPEC = (
    definitions => {
        'io.k8s.api.core.v1.Pod' => {
            description => 'Pod is a collection of containers',
            properties  => { metadata => {}, spec => {} },
        },
    },
);

sub provider_api {
    my (%extra) = @_;
    my $io = Counting::Mock::IO->new;
    $io->add_response('GET', '/openapi/v2', \%OPENAPI_SPEC);
    my $api = Kubernetes::REST->new(
        server      => Kubernetes::REST::Server->new(endpoint => 'http://mock.local'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'MockToken'),
        io          => $io,
        # keep the suite cluster-free: the provider merge and the spec passthrough
        # are what is under test, not discovery.
        resource_map_from_cluster => 0,
        %extra,
    );
    return ($api, $io);
}

subtest 'with => [...] is mirrored onto the inner IO::K8s' => sub {
    my ($api, $io) = provider_api(with => ['IO::K8s::GatewayAPI']);

    is_deeply $api->with, ['IO::K8s::GatewayAPI'],
        'the with attribute holds the provider list';

    my $inner = $api->k8s;
    is $inner->resource_map->{Gateway}, 'GatewayAPI::V1::Gateway',
        'the provider resource_map was merged into the inner IO::K8s';
    is $inner->expand_class('Gateway'), 'IO::K8s::GatewayAPI::V1::Gateway',
        'a provider Kind resolves through the inner IO::K8s';

    # End-to-end through the delegated new_object seam: the provider Kind
    # inflates to the provider class.
    my $gw = $api->new_object(Gateway => { metadata => { name => 'gw' } });
    isa_ok $gw, 'IO::K8s::GatewayAPI::V1::Gateway', 'new_object(Gateway)';

    is count_calls($io, 'GET /openapi/v2'), 0,
        'merging providers and using the inner instance fetched no /openapi/v2';
};

subtest 'a bare client has no providers and still no eager spec fetch' => sub {
    my ($api, $io) = provider_api();

    is_deeply $api->with, [], 'with defaults to []';
    ok !exists $api->k8s->resource_map->{Gateway},
        'no provider Kinds without with';
    ok !$api->k8s->has_openapi_spec,
        'the inner IO::K8s has no openapi_spec at construction';
    is count_calls($io, 'GET /openapi/v2'), 0,
        'and building/using the inner instance never fetched the spec';
};

subtest 'openapi_spec is passed through only after it is fetched' => sub {
    my ($api, $io) = provider_api(with => ['IO::K8s::GatewayAPI']);

    # Build and use the inner instance BEFORE the spec exists: it must carry
    # no spec and cause no download.
    ok $api->k8s->expand_class('Gateway'), 'inner instance built and usable';
    ok !$api->k8s->has_openapi_spec, 'no spec on the inner instance yet';
    is count_calls($io, 'GET /openapi/v2'), 0, 'nothing fetched /openapi/v2 yet';

    # Force the lazy spec through the public API.
    my $schema = $api->schema_for('io.k8s.api.core.v1.Pod');
    is $schema->{description}, 'Pod is a collection of containers',
        'schema_for fetched the spec';
    is count_calls($io, 'GET /openapi/v2'), 1, 'exactly one /openapi/v2 download';

    # The inner instance was rebuilt and now carries the spec (D12 passthrough).
    ok $api->k8s->has_openapi_spec,
        'the inner IO::K8s now has openapi_spec';
    is_deeply $api->k8s->openapi_spec, \%OPENAPI_SPEC,
        'and it is exactly the fetched spec';
    # The rebuild kept the providers.
    is $api->k8s->resource_map->{Gateway}, 'GatewayAPI::V1::Gateway',
        'the rebuilt inner instance still has the providers merged';

    is count_calls($io, 'GET /openapi/v2'), 1,
        'reading the spec back through the inner instance fetched nothing more';
};

done_testing;
