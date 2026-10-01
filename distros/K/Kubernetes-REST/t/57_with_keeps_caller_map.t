#!/usr/bin/env perl
# karr k57: with => [...] merges its providers into the client's own copy of
# the resource map, never into a hash the client does not own.
#
# The inner IO::K8s is handed the client's resource_map and merges every
# `with` provider into it in place (IO::K8s::add). When the caller passed
# resource_map, that was the caller's own hash: it grew by the provider Kinds
# (Net::Async::Kubernetes k62 counted 204 -> 228 keys). When the cluster map
# could not be fetched, the fallback was IO::K8s's process-wide built-in map
# itself, and the provider Kinds leaked into IO::K8s->default_resource_map.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock ();
use Kubernetes::REST;
use IO::K8s;

BEGIN {
    package My::K57::V1::Gizmo;
    use IO::K8s::APIObject
        api_version     => 'example.com/v1',
        resource_plural => 'gizmos';
    with 'IO::K8s::Role::Namespaced';
    k8s size => Int;
    $INC{'My/K57/V1/Gizmo.pm'} = 1;
}

my $HAS_GATEWAY_API = eval { require IO::K8s::GatewayAPI; 1 };

sub api {
    my (%args) = @_;
    return Kubernetes::REST->new(
        server      => { endpoint => 'http://mock.local' },
        credentials => { token => 'MockToken' },
        io          => Test::Kubernetes::Mock::IO->new,
        %args,
    );
}

my %PROVIDER = (Gizmo => '+My::K57::V1::Gizmo');

subtest 'with plus a passed resource_map: the caller\'s hash keeps its keys' => sub {
    my $map = { %{ IO::K8s->default_resource_map }, Special => '+My::Special' };
    my @before = sort keys %$map;

    my $api = api(
        resource_map => $map,
        with         => [ \%PROVIDER, ($HAS_GATEWAY_API ? 'IO::K8s::GatewayAPI' : ()) ],
        resource_map_from_cluster => 0,
    );

    is($api->expand_class('Gizmo'), 'My::K57::V1::Gizmo', 'the provider Kind resolves');
    is($api->build_path($api->expand_class('Gizmo'), namespace => 'ns'),
        '/apis/example.com/v1/namespaces/ns/gizmos', 'and addresses its endpoint');
    SKIP: {
        skip 'IO::K8s::GatewayAPI not installed', 1 unless $HAS_GATEWAY_API;
        is($api->expand_class('Gateway'), 'IO::K8s::GatewayAPI::V1::Gateway',
            'a provider class\'s Kind resolves');
    }
    is($api->expand_class('Special'), 'My::Special', 'the caller\'s own entry resolves');
    is($api->new_object(Gizmo => { metadata => { name => 'g' } })->metadata->name, 'g',
        'new_object builds the provider class');

    is_deeply([ sort keys %$map ], \@before, 'the passed hash has the same keys as before');
    is($api->resource_map->{Gizmo}, '+My::K57::V1::Gizmo',
        'the client\'s own map carries the provider Kind');

    $api->invalidate_discovery;
    is($api->expand_class('Gizmo'), 'My::K57::V1::Gizmo',
        'after invalidate_discovery the provider Kind still resolves');
    is_deeply([ sort keys %$map ], \@before, 'and the passed hash is still untouched');
};

subtest 'a failed cluster fetch leaves IO::K8s\'s built-in map alone' => sub {
    my @builtin = sort keys %{ IO::K8s->default_resource_map };
    my $api = api(with => [ \%PROVIDER ]);   # discovery answers 404 from the mock

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    is($api->expand_class('Gizmo'), 'My::K57::V1::Gizmo', 'the provider Kind resolves');
    like(join('', @warnings), qr/Falling back to the built-in resource map/,
        'on the built-in map, after the carp');

    ok(!exists IO::K8s->default_resource_map->{Gizmo},
        'IO::K8s->default_resource_map did not get the provider Kind');
    is_deeply([ sort keys %{ IO::K8s->default_resource_map } ], \@builtin,
        'nor any other key');
};

done_testing;
