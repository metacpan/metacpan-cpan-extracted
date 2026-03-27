#!/usr/bin/env perl
# Tests CRD support using AutoGen-generated classes (no hand-written .pm files).
# This simulates a user who dynamically generates CRD classes from the cluster's
# OpenAPI spec instead of writing them by hand.
#
# Mock mode (default):
#   prove -l t/09_crd_autogen.t
#
# Live mode:
#   kubectl apply -f t/fixtures/staticwebsite-crd.yaml
#   TEST_KUBERNETES_REST_KUBECONFIG=~/.kube/config prove -lv t/09_crd_autogen.t

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock qw(mock_api live_api is_live);
use IO::K8s;
use IO::K8s::AutoGen;
use JSON::PP ();

# === Generate CRD class using AutoGen ===
subtest 'generate CRD class via AutoGen' => sub {
    IO::K8s::AutoGen::clear_cache();

    # Simulate what you'd get from the cluster's OpenAPI spec for a CRD
    my $schema = {
        type => 'object',
        'x-kubernetes-group-version-kind' => [{
            group   => 'homelab.example.com',
            version => 'v1',
            kind    => 'StaticWebSite',
        }],
        properties => {
            apiVersion => { type => 'string' },
            kind       => { type => 'string' },
            metadata   => { '$ref' => '#/definitions/io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta' },
            spec       => {
                type => 'object',
                properties => {
                    domain   => { type => 'string' },
                    image    => { type => 'string' },
                    replicas => { type => 'integer' },
                    tls      => { type => 'boolean' },
                },
            },
            status => {
                type => 'object',
                properties => {
                    readyReplicas => { type => 'integer' },
                    url           => { type => 'string' },
                },
            },
        },
    };

    my $class = IO::K8s::AutoGen::get_or_generate(
        'com.example.homelab.v1.StaticWebSite',
        $schema,
        {},
        'IO::K8s::_AUTOGEN_crd_rest_test',
        resource_plural => 'staticwebsites',
        is_namespaced   => 1,
    );

    ok($class, 'AutoGen class generated');
    is($class->api_version, 'homelab.example.com/v1', 'api_version');
    is($class->kind, 'StaticWebSite', 'kind');
    is($class->resource_plural, 'staticwebsites', 'resource_plural');
    ok($class->does('IO::K8s::Role::Namespaced'), 'is namespaced');
    ok($class->does('IO::K8s::Role::APIObject'), 'has APIObject role');
};

# === Get the generated class name for the rest of the test ===
my $crd_class = 'IO::K8s::_AUTOGEN_crd_rest_test::com::example::homelab::v1::StaticWebSite';

# === Build API with AutoGen CRD registered ===
my $api;
if (is_live()) {
    diag "Running against LIVE cluster: $ENV{TEST_KUBERNETES_REST_KUBECONFIG}";
    $api = eval { live_api() };
    if ($@) {
        plan skip_all => "No cluster available: $@";
    }
    $api->resource_map->{StaticWebSiteAG} = "+$crd_class";
} else {
    diag "Running with MOCK responses";
    require Kubernetes::REST;
    require Kubernetes::REST::Server;
    require Kubernetes::REST::AuthToken;

    my $default_map = IO::K8s->default_resource_map;
    $api = Kubernetes::REST->new(
        server => Kubernetes::REST::Server->new(endpoint => 'http://mock.local'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'MockToken'),
        resource_map_from_cluster => 0,
        resource_map => {
            %$default_map,
            StaticWebSiteAG => "+$crd_class",
        },
        io => Test::Kubernetes::Mock::IO->new,
    );
}

# === Ensure perl-crd-ag-test namespace exists (live only) ===
if (is_live()) {
    eval {
        $api->create($api->new_object(Namespace =>
            metadata => { name => 'perl-crd-ag-test' },
        ));
    };
}

# === 1. Create with AutoGen class ===
subtest 'create with AutoGen CRD class' => sub {
    # Use struct_to_object so the metadata gets properly inflated
    my $site = $api->k8s->struct_to_object($crd_class, {
        metadata => {
            name      => 'my-blog',
            namespace => 'perl-crd-ag-test',
        },
        spec => {
            domain   => 'blog.example.com',
            image    => 'nginx:1.27-alpine',
            replicas => 2,
            tls      => JSON::PP::true,
        },
    });

    ok($site, 'created AutoGen instance');
    is($site->kind, 'StaticWebSite', 'kind');
    is($site->api_version, 'homelab.example.com/v1', 'api_version');
    is($site->metadata->name, 'my-blog', 'metadata.name');

    my $created = $api->create($site);
    ok($created, 'create returns object');
    is($created->metadata->name, 'my-blog', 'name');
    is($created->spec->{domain}, 'blog.example.com', 'spec.domain');
};

# === 2. Get with AutoGen class ===
subtest 'get with AutoGen CRD class' => sub {
    my $site = $api->get('StaticWebSiteAG', 'my-blog', namespace => 'perl-crd-ag-test');
    ok($site, 'get returns object');
    is($site->metadata->name, 'my-blog', 'name');
    is($site->kind, 'StaticWebSite', 'kind');
};

# === 3. List with AutoGen class ===
subtest 'list with AutoGen CRD class' => sub {
    my $list = $api->list('StaticWebSiteAG', namespace => 'perl-crd-ag-test');
    ok($list, 'list returns');
    my @items = @{ $list->items };
    ok(scalar @items >= 1, 'has items');
    is($items[0]->metadata->name, 'my-blog', 'item name');
};

# === 4. Update with AutoGen class ===
subtest 'update with AutoGen CRD class' => sub {
    my $site = $api->get('StaticWebSiteAG', 'my-blog', namespace => 'perl-crd-ag-test');
    $site->spec->{replicas} = 3;
    my $updated = $api->update($site);
    ok($updated, 'update returns');
    is($updated->spec->{replicas}, 3, 'replicas updated');
};

# === 5. Delete with AutoGen class ===
subtest 'delete with AutoGen CRD class' => sub {
    ok($api->delete('StaticWebSiteAG', 'my-blog', namespace => 'perl-crd-ag-test'),
        'deleted');
};

# === Cleanup (live only) ===
if (is_live()) {
    eval { $api->delete('Namespace', 'perl-crd-ag-test') };
}

done_testing;
