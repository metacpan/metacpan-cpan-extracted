#!/usr/bin/env perl
# karr k24 increment C / design D12, D13, D17.
#
# The discovery-built cluster map used to invent an IO::K8s::Api::<Group>
# class name for EVERY group it saw, including foreign CRD groups
# (cilium.io -> Api::Cilium::V2::..., which is not a class this distribution
# ships). That short-circuited the real resolution order and mapped a Kind to
# a package that does not exist. This test pins the post-fix behaviour:
#
#   (a) a foreign Kind with no provider and no loaded spec is NOT mapped to an
#       invented Api::<Group> name -- it fails closed instead;
#   (b) the same Kind, with the matching provider merged via `with`, resolves
#       to the provider class;
#   (c) D17: a bare Kind resolves to the cluster's PREFERRED version, even when
#       that is a beta version and a stable one is also served;
#   (d) core Kinds still resolve exactly as before.
#
# The provider classes (IO::K8s::Cilium) and the versioned networking classes
# live in the neighbour io-k8s-p5 lib; the provider subtest skips cleanly when
# that lib is not on PERL5LIB, and the D17 subtest skips if the beta class it
# needs is not shipped by the installed IO::K8s.
use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";

use Test::Kubernetes::Mock ();
use Kubernetes::REST;
use Kubernetes::REST::Server;
use Kubernetes::REST::AuthToken;

# Mock IO that records every request it serves (same technique as t/41/t/42).
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

# --- discovery body builders ----------------------------------------------
sub disco_resource {
    my ($plural, $group, $version, $kind, $scope) = @_;
    return {
        resource     => $plural,
        responseKind => { group => $group, version => $version, kind => $kind },
        scope        => $scope // 'Namespaced',
    };
}

# GET /api : the core group.
my %CORE_DISCOVERY = (
    kind  => 'APIGroupDiscoveryList',
    items => [
        {
            metadata => { name => '' },
            versions => [
                {
                    version   => 'v1',
                    resources => [
                        disco_resource('pods',       '', 'v1', 'Pod',       'Namespaced'),
                        disco_resource('namespaces', '', 'v1', 'Namespace', 'Cluster'),
                    ],
                },
            ],
        },
    ],
);

# GET /apis : apps + the exception-table groups + a foreign CRD group
# (cilium.io) + networking serving ServiceCIDR in two versions with the BETA
# one marked preferred (listed first).
my %GROUPED_DISCOVERY = (
    kind  => 'APIGroupDiscoveryList',
    items => [
        {
            metadata => { name => 'apps' },
            versions => [
                { version => 'v1', resources => [
                    disco_resource('deployments', 'apps', 'v1', 'Deployment') ] },
            ],
        },
        {
            metadata => { name => 'apiextensions.k8s.io' },
            versions => [
                { version => 'v1', resources => [
                    disco_resource('customresourcedefinitions', 'apiextensions.k8s.io',
                        'v1', 'CustomResourceDefinition', 'Cluster') ] },
            ],
        },
        {
            metadata => { name => 'apiregistration.k8s.io' },
            versions => [
                { version => 'v1', resources => [
                    disco_resource('apiservices', 'apiregistration.k8s.io',
                        'v1', 'APIService', 'Cluster') ] },
            ],
        },
        {
            metadata => { name => 'cilium.io' },
            versions => [
                { version => 'v2', resources => [
                    disco_resource('ciliumnetworkpolicies', 'cilium.io', 'v2',
                        'CiliumNetworkPolicy') ] },
            ],
        },
        {
            # v1beta1 is served first -> the cluster's preferred version; v1 is
            # the stable one. D17: the map must pick the PREFERRED (beta) one.
            metadata => { name => 'networking.k8s.io' },
            versions => [
                { version => 'v1beta1', resources => [
                    disco_resource('servicecidrs', 'networking.k8s.io', 'v1beta1',
                        'ServiceCIDR', 'Cluster') ] },
                { version => 'v1', resources => [
                    disco_resource('servicecidrs', 'networking.k8s.io', 'v1',
                        'ServiceCIDR', 'Cluster') ] },
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

# --------------------------------------------------------------------------
# (a) stop inventing: a foreign Kind with no provider fails closed.
# --------------------------------------------------------------------------
subtest 'D12/D13: a foreign Kind is not mapped to an invented Api::<Group> name'
=> sub {
    my ($api, $io) = discovery_api();

    my $map = $api->fetch_resource_map;

    # Pre-fix, this key held 'Api::Cilium::V2::CiliumNetworkPolicy' -- a class
    # this distribution does not ship. Now it is absent.
    ok !exists $map->{CiliumNetworkPolicy},
        'no map entry for a group with no shipped IO::K8s class';

    # And nothing invents the name on the resolution path either.
    my $resolved = $api->expand_class('CiliumNetworkPolicy');
    unlike $resolved, qr/Api::Cilium/,
        'expand_class does not resolve to an invented Api::Cilium name';

    # Fail closed at use: constructing the Kind dies (no bundled class, no
    # provider, no spec) rather than silently building the wrong object.
    throws_ok { $api->new_object('CiliumNetworkPolicy', { metadata => { name => 'x' } }) }
        qr/CiliumNetworkPolicy/,
        'using the unresolved foreign Kind fails closed, naming the Kind';
};

# --------------------------------------------------------------------------
# (b) the same Kind resolves to the provider class when `with` supplies it.
# --------------------------------------------------------------------------
subtest 'D13 rung 2: a provider from `with` resolves the foreign Kind' => sub {
    plan skip_all => 'IO::K8s::Cilium not available '
        . '(prepend io-k8s-p5/lib to PERL5LIB to run this subtest)'
        unless eval { require IO::K8s::Cilium; 1 };

    my ($api, $io) = discovery_api(with => ['IO::K8s::Cilium']);

    is $api->expand_class('CiliumNetworkPolicy'),
        'IO::K8s::Cilium::V2::CiliumNetworkPolicy',
        'the provider Kind resolves to the provider class';

    my $obj = $api->new_object('CiliumNetworkPolicy',
        { metadata => { name => 'policy' } });
    isa_ok $obj, 'IO::K8s::Cilium::V2::CiliumNetworkPolicy',
        'new_object builds the provider class';
};

# --------------------------------------------------------------------------
# (c) D17: the bare short name resolves to the cluster's PREFERRED version.
# --------------------------------------------------------------------------
subtest 'D17: a bare Kind resolves to the cluster preferred version' => sub {
    plan skip_all =>
        'IO::K8s::Api::Networking::V1beta1::ServiceCIDR not shipped by this IO::K8s'
        unless eval { require IO::K8s::Api::Networking::V1beta1::ServiceCIDR; 1 };

    my ($api, $io) = discovery_api();
    my $map = $api->fetch_resource_map;

    # Both versions ship a class; the cluster prefers v1beta1, so the short
    # name must point at the beta class -- not the stable one the old
    # "stable beats beta" heuristic would have chosen.
    is $map->{ServiceCIDR}, 'Api::Networking::V1beta1::ServiceCIDR',
        'short name maps to the cluster preferred (beta) version';

    # The catalog still records the preference and every served version.
    my $cat = $api->_discovery;
    is $cat->{groups}{'networking.k8s.io'}{preferred}, 'v1beta1',
        'preferred version recorded in the catalog';
};

# --------------------------------------------------------------------------
# (d) core Kinds and the two exception-table groups are unchanged.
# --------------------------------------------------------------------------
subtest 'D12: core Kinds and exception groups resolve unchanged' => sub {
    my ($api, $io) = discovery_api();
    my $map = $api->fetch_resource_map;

    is $map->{Pod},        'Api::Core::V1::Pod',        'core Pod unchanged';
    is $map->{Namespace},  'Api::Core::V1::Namespace',  'core Namespace unchanged';
    is $map->{Deployment}, 'Api::Apps::V1::Deployment', 'apps Deployment unchanged';
    is $map->{CustomResourceDefinition},
        'ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinition',
        'apiextensions exception table preserved';
    is $map->{APIService},
        'KubeAggregator::Pkg::Apis::Apiregistration::V1::APIService',
        'apiregistration exception table preserved';
};

done_testing;
