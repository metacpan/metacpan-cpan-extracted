#!/usr/bin/env perl
# karr k54: schema_for finds a definition by its group/version/Kind when the
# class name does not map onto the definition name.
#
# schema_for turned the class name into a definition name - IO::K8s::Api::
# Core::V1::Pod -> io.k8s.api.core.v1.Pod - and that only holds for the
# IO::K8s::Api:: classes. Upstream names apiextensions and apiregistration
# after their staging repositories (io.k8s.apiextensions-apiserver...,
# io.k8s.kube-aggregator...), a CRD's definition after its group
# (io.k8s.networking.gateway.v1..., com.example.v1...), and
# IO::K8s::Unstructured or a '+My::Class' map onto nothing at all: schema_for
# answered undef for all of them. Every Kind's definition carries
# x-kubernetes-group-version-kind, so the class's group/version/Kind finds it;
# without a match it stays undef, without a warning (k47).
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock ();
use Kubernetes::REST;
use IO::K8s;

BEGIN {
    package My::K54::V1::Gizmo;
    use IO::K8s::APIObject
        api_version     => 'example.com/v1',
        resource_plural => 'gizmos';
    k8s size => Int;
    $INC{'My/K54/V1/Gizmo.pm'} = 1;

    package My::K54::V1::Orphan;
    use IO::K8s::APIObject api_version => 'example.com/v1';
    $INC{'My/K54/V1/Orphan.pm'} = 1;
}

my $HAS_GATEWAY_API = eval { require IO::K8s::GatewayAPI; 1 };

sub gvk {
    my ($group, $version, $kind, $description) = @_;
    return {
        description => $description,
        'x-kubernetes-group-version-kind' =>
            [ { group => $group, version => $version, kind => $kind } ],
    };
}

# Decoys sort before the right definition and differ only in group or version.
my %SPEC = (definitions => {
    'io.k8s.api.core.v1.Pod' => gvk('', 'v1', 'Pod', 'a Pod'),
    'io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceDefinition'
        => gvk('apiextensions.k8s.io', 'v1', 'CustomResourceDefinition', 'a CRD'),
    'io.k8s.kube-aggregator.pkg.apis.apiregistration.v1.APIService'
        => gvk('apiregistration.k8s.io', 'v1', 'APIService', 'an APIService'),
    'io.istio.networking.v1.Gateway'
        => gvk('networking.istio.io', 'v1', 'Gateway', 'an Istio Gateway'),
    'io.k8s.networking.gateway.v1.Gateway'
        => gvk('gateway.networking.k8s.io', 'v1', 'Gateway', 'a Gateway API Gateway'),
    'com.example.alpha.Gizmo' => gvk('example.com', 'v1alpha1', 'Gizmo', 'an old Gizmo'),
    'com.example.v1.Gizmo'    => gvk('example.com', 'v1', 'Gizmo', 'a Gizmo'),
    'com.example.v1.Widget'   => gvk('example.com', 'v1', 'Widget', 'a Widget'),
    # A definition without the extension, as nested types have.
    'io.k8s.api.core.v1.PodSpec' => { description => 'a PodSpec' },
});

sub api {
    my (%args) = @_;
    my $io = Test::Kubernetes::Mock::IO->new;
    $io->add_response('GET', '/openapi/v2', \%SPEC);
    return Kubernetes::REST->new(
        server      => { endpoint => 'http://mock.local' },
        credentials => { token => 'MockToken' },
        io          => $io,
        %args,
    );
}

sub description_of {
    my ($api, $name) = @_;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    my $schema = $api->schema_for($name);
    is_deeply(\@warnings, [], "$name: without a warning") or diag explain \@warnings;
    return $schema ? $schema->{description} : undef;
}

subtest 'by class name, as before' => sub {
    my $api = api(resource_map_from_cluster => 0);
    is(description_of($api, 'Pod'), 'a Pod', 'Pod');
    is(description_of($api, 'io.k8s.api.core.v1.PodSpec'), 'a PodSpec',
        'a definition name');
};

subtest 'by group/version/Kind where the name does not map' => sub {
    my $api = api(
        resource_map => { %{ IO::K8s->default_resource_map },
            Gizmo  => '+My::K54::V1::Gizmo',
            Orphan => '+My::K54::V1::Orphan' },
        with => [ $HAS_GATEWAY_API ? 'IO::K8s::GatewayAPI' : () ],
        resource_map_from_cluster => 0,
    );
    is(description_of($api, 'CustomResourceDefinition'), 'a CRD',
        'apiextensions: CustomResourceDefinition');
    is(description_of($api, 'APIService'), 'an APIService', 'apiregistration: APIService');
    is(description_of($api, 'Gizmo'), 'a Gizmo',
        'a +class: its own group and version, not another version\'s');
    is(description_of($api, '+My::K54::V1::Gizmo'), 'a Gizmo', 'the +class by name');
    SKIP: {
        skip 'IO::K8s::GatewayAPI not installed', 2 unless $HAS_GATEWAY_API;
        is(description_of($api, 'Gateway'), 'a Gateway API Gateway',
            'a provider class: its own group, not another group\'s Gateway');
    }
    ok(!defined description_of($api, 'Orphan'), 'a GVK no definition carries: undef');
};

subtest 'IO::K8s::Unstructured: the group/version discovery confirmed' => sub {
    my $api = api();
    my $aggregated = sub {
        my ($group, $kind) = @_;
        return { kind => 'APIGroupDiscoveryList', items => [ {
            metadata => { name => $group },
            versions => [ { version => 'v1', resources => [ {
                resource     => lc($kind) . 's',
                responseKind => { group => $group, version => 'v1', kind => $kind },
                scope        => 'Namespaced',
            } ] } ],
        } ] };
    };
    $api->io->add_response('GET', '/api',  $aggregated->('', 'Pod'));
    $api->io->add_response('GET', '/apis', $aggregated->('example.com', 'Widget'));

    is($api->expand_class('Widget'), 'IO::K8s::Unstructured', 'Widget resolves to Unstructured');
    is(description_of($api, 'Widget'), 'a Widget', 'the bare Kind');
    is(description_of($api, 'example.com/v1/Widget'), 'a Widget', 'the qualified name');
};

subtest 'nothing resolves: undef, as before' => sub {
    my $api = api(resource_map_from_cluster => 0);
    ok(!defined description_of($api, 'other.org/v1/Widget'), 'a qualified name');
    ok(!defined description_of($api, 'Ghost'), 'a bare Kind');
};

done_testing;
