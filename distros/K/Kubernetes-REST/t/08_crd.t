#!/usr/bin/env perl
# Tests CRD (Custom Resource Definition) support with a hand-written class.
# Uses a homelab StaticWebSite CRD as the example.
#
# Mock mode (default):
#   prove -l t/08_crd.t
#
# Live mode (requires CRD installed in cluster):
#   kubectl apply -f t/fixtures/staticwebsite-crd.yaml
#   TEST_KUBERNETES_REST_KUBECONFIG=~/.kube/config prove -lv t/08_crd.t

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock qw(mock_api live_api is_live);
use JSON::PP ();

# Load our CRD class
use My::StaticWebSite;

# === Verify CRD class metadata ===
subtest 'CRD class metadata' => sub {
    is(My::StaticWebSite->api_version, 'homelab.example.com/v1', 'api_version');
    is(My::StaticWebSite->kind, 'StaticWebSite', 'kind');
    is(My::StaticWebSite->resource_plural, 'staticwebsites', 'resource_plural');
    ok(My::StaticWebSite->does('IO::K8s::Role::APIObject'), 'has APIObject role');
    ok(My::StaticWebSite->does('IO::K8s::Role::Namespaced'), 'has Namespaced role');
};

# === Build API with CRD registered ===
my $api;
if (is_live()) {
    diag "Running against LIVE cluster: $ENV{TEST_KUBERNETES_REST_KUBECONFIG}";
    $api = eval { live_api() };
    if ($@) {
        plan skip_all => "No cluster available: $@";
    }
    # Merge our CRD class into the live resource map
    $api->resource_map->{StaticWebSite} = '+My::StaticWebSite';
} else {
    diag "Running with MOCK responses";
    # Build mock API with CRD in resource map
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
            StaticWebSite => '+My::StaticWebSite',
        },
        io => Test::Kubernetes::Mock::IO->new,
    );
}

# === Ensure perl-crd-test namespace exists (live only) ===
if (is_live()) {
    eval {
        $api->create($api->new_object(Namespace =>
            metadata => { name => 'perl-crd-test' },
        ));
    };
    # Ignore if already exists
}

# === 1. Create StaticWebSite ===
subtest 'create StaticWebSite' => sub {
    my $site = $api->new_object(StaticWebSite =>
        metadata => {
            name      => 'my-blog',
            namespace => 'perl-crd-test',
        },
        spec => {
            domain   => 'blog.example.com',
            image    => 'nginx:1.27-alpine',
            replicas => 2,
            tls      => JSON::PP::true,
        },
    );
    ok($site, 'new_object works');
    is($site->kind, 'StaticWebSite', 'kind');
    is($site->api_version, 'homelab.example.com/v1', 'api_version');
    ok($site->does('IO::K8s::Role::Namespaced'), 'is namespaced');

    my $created = $api->create($site);
    ok($created, 'create returns object');
    is($created->metadata->name, 'my-blog', 'name matches');
    ok($created->metadata->uid, 'has uid from server');
    ok($created->metadata->creationTimestamp, 'has creationTimestamp');
    is($created->spec->{domain}, 'blog.example.com', 'spec.domain preserved');
    is($created->spec->{replicas}, 2, 'spec.replicas preserved');
};

# === 2. Get StaticWebSite ===
subtest 'get StaticWebSite' => sub {
    my $site = $api->get('StaticWebSite', 'my-blog', namespace => 'perl-crd-test');
    ok($site, 'get returns object');
    is($site->metadata->name, 'my-blog', 'name');
    is($site->kind, 'StaticWebSite', 'kind');
    is($site->api_version, 'homelab.example.com/v1', 'api_version');
    is($site->spec->{domain}, 'blog.example.com', 'spec.domain');
};

# === 3. List StaticWebSites ===
subtest 'list StaticWebSites' => sub {
    my $list = $api->list('StaticWebSite', namespace => 'perl-crd-test');
    ok($list, 'list returns');
    my @items = @{ $list->items };
    ok(scalar @items >= 1, 'has at least 1 item');
    is($items[0]->kind, 'StaticWebSite', 'item kind');
    is($items[0]->metadata->name, 'my-blog', 'item name');
};

# === 4. Update StaticWebSite ===
subtest 'update StaticWebSite' => sub {
    my $site = $api->get('StaticWebSite', 'my-blog', namespace => 'perl-crd-test');
    $site->spec->{replicas} = 3;
    my $updated = $api->update($site);
    ok($updated, 'update returns object');
    is($updated->spec->{replicas}, 3, 'replicas updated');
};

# === 5. Serialization ===
subtest 'CRD serialization' => sub {
    my $site = $api->new_object(StaticWebSite =>
        metadata => {
            name      => 'test-site',
            namespace => 'default',
        },
        spec => {
            domain   => 'test.example.com',
            image    => 'nginx:latest',
            replicas => 1,
            tls      => JSON::PP::false,
        },
    );

    # TO_JSON roundtrip
    my $data = $site->TO_JSON;
    is($data->{kind}, 'StaticWebSite', 'TO_JSON kind');
    is($data->{apiVersion}, 'homelab.example.com/v1', 'TO_JSON apiVersion');
    ok($data->{spec}, 'TO_JSON has spec');

    # YAML
    my $yaml = $site->to_yaml;
    like($yaml, qr/kind:\s*StaticWebSite/, 'YAML has kind');
    like($yaml, qr/apiVersion:\s*homelab\.example\.com\/v1/, 'YAML has apiVersion');
    like($yaml, qr/domain:\s*test\.example\.com/, 'YAML has domain');

    # inflate roundtrip
    my $rt = $api->inflate($data);
    is($rt->metadata->name, 'test-site', 'roundtrip name');
    is($rt->kind, 'StaticWebSite', 'roundtrip kind');
};

# === 6. Delete StaticWebSite ===
subtest 'delete StaticWebSite' => sub {
    ok($api->delete('StaticWebSite', 'my-blog', namespace => 'perl-crd-test'),
        'StaticWebSite deleted');
};

# === Cleanup namespace (live only) ===
if (is_live()) {
    eval { $api->delete('Namespace', 'perl-crd-test') };
}

done_testing;
