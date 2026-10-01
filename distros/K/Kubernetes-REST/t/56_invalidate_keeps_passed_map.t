#!/usr/bin/env perl
# karr k52: invalidate_discovery - and ensure_crd, which calls it - discards
# only a resource map the client built itself, never one passed to the
# constructor.
#
# invalidate_discovery cleared the resource_map attribute however it had come
# to be. A map passed to the constructor was then rebuilt by the default
# builder - from the cluster's discovery, or from IO::K8s's built-in map - and
# every entry the caller had put in it was gone: '+My::Class' for a CRD no
# longer resolved, not even the Kind ensure_crd had just installed.
# absorb_discovery already told the two apart (k51).
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock ();
use Kubernetes::REST;
use IO::K8s;

BEGIN {
    package My::K52::V1::StaticWebSite;
    use IO::K8s::APIObject
        api_version     => 'homelab.example.com/v1',
        resource_plural => 'staticwebsites';
    k8s hostname => Str;
    $INC{'My/K52/V1/StaticWebSite.pm'} = 1;
}

# Records every request as 'METHOD /path'.
{
    package Test::K52::IO;
    use Moo;
    extends 'Test::Kubernetes::Mock::IO';

    has calls => (is => 'ro', default => sub { [] });

    around call => sub {
        my ($orig, $self, $req) = @_;
        (my $path = $req->url) =~ s{\Ahttps?://[^/]+}{};
        push @{ $self->calls }, $req->method . ' ' . $path;
        return $self->$orig($req);
    };
}

sub api {
    my (%args) = @_;
    return Kubernetes::REST->new(
        server      => { endpoint => 'http://mock.local' },
        credentials => { token => 'MockToken' },
        io          => Test::K52::IO->new,
        %args,
    );
}

sub aggregated {
    my ($group, @kinds) = @_;
    return {
        kind       => 'APIGroupDiscoveryList',
        apiVersion => 'apidiscovery.k8s.io/v2',
        items      => [ {
            metadata => { name => $group },
            versions => [ { version => 'v1', resources => [ map { {
                resource     => lc($_) . 's',
                responseKind => { group => $group, version => 'v1', kind => $_ },
                scope        => 'Namespaced',
            } } @kinds ] } ],
        } ],
    };
}

sub serve_discovery {
    my ($api, $core, $grouped) = @_;
    $api->io->add_response('GET', '/api',  $core);
    $api->io->add_response('GET', '/apis', $grouped);
}

sub passed_map {
    return { %{ IO::K8s->default_resource_map }, Special => '+My::Special', @_ };
}

subtest 'without the cluster map: the passed map survives' => sub {
    my $api = api(resource_map => passed_map(), resource_map_from_cluster => 0);
    is($api->expand_class('Special'), 'My::Special', 'before: the caller\'s class');

    $api->invalidate_discovery;

    is($api->resource_map->{Special}, '+My::Special', 'the entry is still in the map');
    is($api->expand_class('Special'), 'My::Special', 'and still resolves');
};

subtest 'with the cluster map: the passed map survives, discovery is read again' => sub {
    my $api = api(resource_map => passed_map());
    serve_discovery($api, aggregated('', 'Pod'), aggregated('example.com', 'Widget'));
    is($api->expand_class('Widget'), 'IO::K8s::Unstructured', 'Widget, from discovery');
    is($api->expand_class('Special'), 'My::Special', 'Special, from the passed map');

    serve_discovery($api, aggregated('', 'Pod'), aggregated('example.com', 'Widget', 'Gadget'));
    $api->invalidate_discovery;

    is($api->resource_map->{Special}, '+My::Special', 'the entry is still in the map');
    is($api->expand_class('Special'), 'My::Special', 'and still resolves');
    is($api->expand_class('Gadget'), 'IO::K8s::Unstructured',
        'the discovery catalog was read again');
    is(scalar(grep { $_ eq 'GET /apis' } @{ $api->io->calls }), 2,
        'GET /apis once before, once after');
};

subtest 'ensure_crd keeps the passed map' => sub {
    my $api = api(
        resource_map => passed_map(StaticWebSite => '+My::K52::V1::StaticWebSite'),
        resource_map_from_cluster => 0,
    );
    my $name = 'staticwebsites.homelab.example.com';
    my $crd  = {
        apiVersion => 'apiextensions.k8s.io/v1',
        kind       => 'CustomResourceDefinition',
        metadata   => { name => $name, resourceVersion => '1' },
        spec       => {
            group    => 'homelab.example.com',
            scope    => 'Cluster',
            names    => { plural => 'staticwebsites', kind => 'StaticWebSite' },
            versions => [ { name => 'v1', served => \1, storage => \1 } ],
        },
        status => { conditions => [ { type => 'Established', status => 'True' } ] },
    };
    my $path = "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/$name";
    $api->io->add_response('GET', $path, $crd);
    $api->io->add_response('PUT', $path, $crd);

    my @established = $api->ensure_crd('My::K52::V1::StaticWebSite');
    is(scalar @established, 1, 'the CRD is established');

    is($api->expand_class('StaticWebSite'), 'My::K52::V1::StaticWebSite',
        'its Kind still resolves to the caller\'s class');
    is($api->build_path($api->expand_class('StaticWebSite')),
        '/apis/homelab.example.com/v1/staticwebsites',
        'and addresses the CRD\'s endpoint');
};

subtest 'a map the client built is still discarded and rebuilt' => sub {
    my $api = api();
    serve_discovery($api, aggregated('', 'Pod'), aggregated('example.com', 'Widget'));
    ok(!exists $api->resource_map->{ConfigMap}, 'the first catalog has no ConfigMap');

    serve_discovery($api, aggregated('', 'Pod', 'ConfigMap'), aggregated('example.com', 'Widget'));
    $api->invalidate_discovery;

    is($api->resource_map->{ConfigMap}, 'Api::Core::V1::ConfigMap',
        'rebuilt from the catalog read afterwards');
};

done_testing;
