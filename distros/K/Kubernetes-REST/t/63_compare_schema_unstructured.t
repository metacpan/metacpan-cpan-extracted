#!/usr/bin/env perl
# karr k60: compare_schema croaks for a name that resolves to
# IO::K8s::Unstructured, which has no local schema to compare.
#
# Since k54 schema_for finds the definition of a Kind resolved to
# IO::K8s::Unstructured by its group/version/Kind. compare_schema then held
# that definition against Unstructured's own fields - only apiVersion, kind
# and metadata, everything else rides untyped in its unknown-fields bag - and
# reported every other field (spec, status, ...) as missing locally: a skew
# report for a class that by design has no schema. It now croaks saying so,
# before /openapi/v2 is fetched. A typed class keeps comparing, also one
# that declares no fields of its own.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock ();
use Kubernetes::REST;
use IO::K8s;

BEGIN {
    # A CRD class with no fields beyond what every API object has.
    package My::K60::V1::Bare;
    use IO::K8s::APIObject api_version => 'example.com/v1';
    $INC{'My/K60/V1/Bare.pm'} = 1;
}

# Records every request as 'METHOD /path'.
{
    package Test::K60::IO;
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

my $WIDGET_DEFINITION = {
    description => 'a Widget',
    properties  => {
        apiVersion => { type => 'string' },
        kind       => { type => 'string' },
        metadata   => { '$ref' => '#/definitions/ObjectMeta' },
        spec       => { type => 'object' },
        status     => { type => 'object' },
    },
    'x-kubernetes-group-version-kind' =>
        [ { group => 'example.com', version => 'v1', kind => 'Widget' } ],
};

my %SPEC = (definitions => {
    'com.example.v1.Widget' => $WIDGET_DEFINITION,
    'com.example.v1.Bare'   => {
        properties => { metadata => { type => 'object' }, spec => { type => 'object' } },
        'x-kubernetes-group-version-kind' =>
            [ { group => 'example.com', version => 'v1', kind => 'Bare' } ],
    },
});

sub aggregated {
    my ($group, $kind) = @_;
    return { kind => 'APIGroupDiscoveryList', items => [ {
        metadata => { name => $group },
        versions => [ { version => 'v1', resources => [ {
            resource     => lc($kind) . 's',
            responseKind => { group => $group, version => 'v1', kind => $kind },
            scope        => 'Namespaced',
        } ] } ],
    } ] };
}

# The cluster serves example.com/v1 Widget, which no class resolves.
sub api {
    my (%args) = @_;
    my $io = Test::K60::IO->new;
    $io->add_response('GET', '/api',  aggregated('', 'Pod'));
    $io->add_response('GET', '/apis', aggregated('example.com', 'Widget'));
    $io->add_response('GET', '/openapi/v2', \%SPEC);
    return Kubernetes::REST->new(
        server      => { endpoint => 'http://mock.local' },
        credentials => { token => 'MockToken' },
        io          => $io,
        %args,
    );
}

subtest 'a name resolved to IO::K8s::Unstructured croaks, before the spec is fetched' => sub {
    for my $name ('Widget', 'example.com/v1/Widget', 'IO::K8s::Unstructured') {
        my $api = api();
        is($api->expand_class('Widget'), 'IO::K8s::Unstructured',
            "$name: Widget resolves to IO::K8s::Unstructured");

        my $line = __LINE__; my $ok = eval { $api->compare_schema($name); 1 };
        my $err = $@;
        ok(!$ok, "$name: compare_schema croaks");
        is($err, "compare_schema: '$name' resolves to IO::K8s::Unstructured, which has"
            . " no local schema to compare (add a typed class for it to resource_map or"
            . " with) at $0 line $line.\n",
            "$name: says why, at the caller's line");
        ok(!grep({ $_ eq 'GET /openapi/v2' } @{ $api->io->calls }),
            "$name: /openapi/v2 was not fetched");
    }
};

subtest 'schema_for still answers the definition' => sub {
    my $api = api();
    is($api->schema_for('Widget')->{description}, 'a Widget', 'the Widget definition');
};

subtest 'a typed class with no fields of its own still compares' => sub {
    my $api = api(
        resource_map => { %{ IO::K8s->default_resource_map }, Bare => '+My::K60::V1::Bare' },
        resource_map_from_cluster => 0,
    );
    my $result = $api->compare_schema('Bare');
    is_deeply($result->{missing_locally}, ['spec'],
        'reports what the class lacks against its definition');
};

done_testing;
