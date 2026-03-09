#!/usr/bin/env perl
# Tests for auto-generation of classes from OpenAPI spec
#
# Run with mock (default):
#   prove -l t/04_autogen.t
#
# Run against live cluster:
#   TEST_IO_K8S_KUBECONFIG=/path/to/kubeconfig prove -l t/04_autogen.t

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use IO::K8s;
use IO::K8s::AutoGen;

# Test 1: Basic AutoGen module functionality
subtest 'AutoGen module basics' => sub {
    # def_to_class conversion
    is(
        IO::K8s::AutoGen::def_to_class('helm.cattle.io.v1.HelmChart'),
        'IO::K8s::_AUTOGEN::helm::cattle::io::v1::HelmChart',
        'def_to_class with default namespace'
    );

    is(
        IO::K8s::AutoGen::def_to_class('helm.cattle.io.v1.HelmChart', 'MyApp::K8s'),
        'MyApp::K8s::helm::cattle::io::v1::HelmChart',
        'def_to_class with custom namespace'
    );

    # class_to_def conversion
    is(
        IO::K8s::AutoGen::class_to_def('IO::K8s::_AUTOGEN::helm::cattle::io::v1::HelmChart'),
        'helm.cattle.io.v1.HelmChart',
        'class_to_def'
    );

    # is_autogen check
    ok(IO::K8s::AutoGen::is_autogen('IO::K8s::_AUTOGEN::foo::Bar'), 'is_autogen true');
    ok(IO::K8s::AutoGen::is_autogen('IO::K8s::_AUTOGEN_abc123::foo::Bar'), 'is_autogen with id');
    ok(!IO::K8s::AutoGen::is_autogen('IO::K8s::Api::Core::V1::Pod'), 'is_autogen false');
};

# Test 2: IO::K8s attributes
subtest 'IO::K8s autogen attributes' => sub {
    my $k8s = IO::K8s->new;
    ok(!$k8s->has_openapi_spec, 'no openapi_spec by default');
    is_deeply($k8s->class_namespaces, [], 'empty class_namespaces by default');
    like($k8s->_autogen_namespace, qr/^IO::K8s::_AUTOGEN_[0-9a-f]+$/, 'unique autogen namespace');

    # Different instances get different namespaces
    my $k8s2 = IO::K8s->new;
    isnt($k8s->_autogen_namespace, $k8s2->_autogen_namespace, 'different instances, different namespaces');
};

# Test 3: Class generation from schema
subtest 'class generation from schema' => sub {
    IO::K8s::AutoGen::clear_cache();

    my $schema = {
        type => 'object',
        properties => {
            apiVersion => { type => 'string' },
            kind => { type => 'string' },
            name => { type => 'string' },
            replicas => { type => 'integer' },
            enabled => { type => 'boolean' },
            tags => { type => 'array', items => { type => 'string' } },
            labels => { type => 'object', additionalProperties => { type => 'string' } },
        },
    };

    my $class = IO::K8s::AutoGen::get_or_generate(
        'test.example.v1.MyResource',
        $schema,
        {},
        'IO::K8s::_AUTOGEN_test',
    );

    is($class, 'IO::K8s::_AUTOGEN_test::test::example::v1::MyResource', 'correct class name');
    ok($class->can('new'), 'class has new');
    ok($class->can('TO_JSON'), 'class has TO_JSON');
    ok($class->does('IO::K8s::Role::Resource'), 'composes IO::K8s::Role::Resource');

    # Create instance
    my $obj = $class->new(
        apiVersion => 'test.example/v1',
        kind => 'MyResource',
        name => 'test-resource',
        replicas => 3,
        enabled => 1,
        tags => ['foo', 'bar'],
        labels => { app => 'test' },
    );

    ok($obj, 'created instance');
    is($obj->kind, 'MyResource', 'kind attribute');
    is($obj->replicas, 3, 'integer attribute');
    is($obj->enabled, 1, 'boolean attribute');
    is_deeply($obj->tags, ['foo', 'bar'], 'array attribute');
    is_deeply($obj->labels, { app => 'test' }, 'hash attribute');

    # Serialize
    my $json = $obj->TO_JSON;
    is($json->{kind}, 'MyResource', 'TO_JSON kind');
    is($json->{replicas}, 3, 'TO_JSON replicas');
};

# Test 4: Live cluster tests (if kubeconfig provided)
SKIP: {
    skip 'Set TEST_IO_K8S_KUBECONFIG for live cluster tests', 1
        unless $ENV{TEST_IO_K8S_KUBECONFIG};

    # Need Kubernetes::REST for this
    eval { require Kubernetes::REST::Kubeconfig };
    if ($@) {
        skip 'Kubernetes::REST::Kubeconfig not available', 1;
    }

    subtest 'live cluster auto-generation' => sub {

        my $kc = Kubernetes::REST::Kubeconfig->new(
            kubeconfig_path => $ENV{TEST_IO_K8S_KUBECONFIG},
        );
        my $api = $kc->api;

        # Fetch OpenAPI spec
        my $resp = $api->_request('GET', '/openapi/v2');
        is($resp->status, 200, 'fetched OpenAPI spec');

        require JSON::MaybeXS;
        my $spec = JSON::MaybeXS->new->decode($resp->content);
        ok($spec->{definitions}, 'spec has definitions');

        # Create IO::K8s with openapi_spec
        IO::K8s::AutoGen::clear_cache();
        my $k8s = IO::K8s->new(
            openapi_spec => $spec,
        );

        # Try to find a CRD type (k3s Addon or HelmChart)
        my @crd_types;
        for my $def (keys %{$spec->{definitions}}) {
            if ($def =~ /^io\.cattle\.(k3s|helm)/) {
                push @crd_types, $def;
            }
        }

        if (!@crd_types) {
            pass('No CRD types found in cluster - skipping CRD tests');
            return;
        }

        diag "Found CRD types: " . join(", ", @crd_types[0..2]) . "...";

        # Try to fetch and inflate an Addon
        my $addon_resp = $api->_request('GET', '/apis/k3s.cattle.io/v1/addons');
        if ($addon_resp->status == 200) {
            my $list = JSON::MaybeXS->new->decode($addon_resp->content);
            if (@{$list->{items} // []}) {
                my $addon_data = $list->{items}[0];
                diag "Testing with Addon: " . $addon_data->{metadata}{name};

                my $addon = $k8s->inflate($addon_data);
                ok($addon, 'inflated Addon');
                isa_ok($addon, 'IO::K8s::Resource');
                ok(IO::K8s::AutoGen::is_autogen(ref($addon)), 'class is auto-generated');
                is($addon->kind, 'Addon', 'kind is Addon');
                ok($addon->metadata, 'has metadata');
                is($addon->metadata->name, $addon_data->{metadata}{name}, 'metadata.name matches');

                # Roundtrip test
                my $roundtrip = $addon->TO_JSON;
                is($roundtrip->{kind}, $addon_data->{kind}, 'roundtrip kind');
                is($roundtrip->{apiVersion}, $addon_data->{apiVersion}, 'roundtrip apiVersion');
                is($roundtrip->{metadata}{name}, $addon_data->{metadata}{name}, 'roundtrip metadata.name');
            }
        }

        # Report generated classes
        my @generated = IO::K8s::AutoGen::generated_classes();
        diag "Generated " . scalar(@generated) . " classes";
    };
}

# Test 5: class_namespaces priority
subtest 'class_namespaces priority' => sub {
    # Create a fake user class
    {
        package MyApp::K8s::Api::Core::V1::Pod;
        use Moo;
        sub custom_method { 'from_user_class' }
        1;
    }

    my $k8s = IO::K8s->new(
        class_namespaces => ['MyApp::K8s'],
    );

    # Should find user class first
    my $class = $k8s->expand_class('Pod');
    is($class, 'MyApp::K8s::Api::Core::V1::Pod', 'user class found first');
    is($class->custom_method, 'from_user_class', 'is the user class');

    # Without class_namespaces, should find built-in
    my $k8s2 = IO::K8s->new;
    my $class2 = $k8s2->expand_class('Pod');
    is($class2, 'IO::K8s::Api::Core::V1::Pod', 'built-in class found');
};

# Test 6: AutoGen with x-kubernetes-group-version-kind (CRD-style)
subtest 'autogen CRD with GVK metadata' => sub {
    IO::K8s::AutoGen::clear_cache();

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
        'IO::K8s::_AUTOGEN_crd_test',
    );

    ok($class, 'got class back');
    ok($class->can('new'), 'class has new');
    ok($class->can('api_version'), 'class has api_version');
    ok($class->can('kind'), 'class has kind');
    ok($class->can('resource_plural'), 'class has resource_plural');
    ok($class->can('metadata'), 'class has metadata (from Role::APIObject)');
    ok($class->can('to_yaml'), 'class has to_yaml (from Role::APIObject)');

    # Verify class methods
    is($class->api_version, 'homelab.example.com/v1', 'api_version method');
    is($class->kind, 'StaticWebSite', 'kind method');
    is($class->resource_plural, undef, 'resource_plural undef (auto-pluralize)');

    # Create instance
    my $obj = $class->new(
        spec => { domain => 'test.example.com', image => 'nginx:latest', replicas => 1 },
    );
    ok($obj, 'created instance');
    is($obj->api_version, 'homelab.example.com/v1', 'instance api_version');
    is($obj->kind, 'StaticWebSite', 'instance kind');
    ok($obj->spec, 'has spec');
    is($obj->spec->{domain}, 'test.example.com', 'spec.domain');

    # Serialization
    my $data = $obj->TO_JSON;
    is($data->{apiVersion}, 'homelab.example.com/v1', 'TO_JSON apiVersion');
    is($data->{kind}, 'StaticWebSite', 'TO_JSON kind');

    # YAML
    my $yaml = $obj->to_yaml;
    like($yaml, qr/apiVersion:\s*homelab\.example\.com\/v1/, 'YAML apiVersion');
    like($yaml, qr/kind:\s*StaticWebSite/, 'YAML kind');
};

# Test 7: AutoGen with explicit options (resource_plural, is_namespaced)
subtest 'autogen CRD with explicit options' => sub {
    IO::K8s::AutoGen::clear_cache();

    my $schema = {
        type => 'object',
        properties => {
            apiVersion => { type => 'string' },
            kind       => { type => 'string' },
            spec       => {
                type => 'object',
                properties => {
                    schedule  => { type => 'string' },
                    target    => { type => 'string' },
                    retention => { type => 'integer' },
                },
            },
        },
    };

    my $class = IO::K8s::AutoGen::get_or_generate(
        'com.example.homelab.v1.BackupSchedule',
        $schema,
        {},
        'IO::K8s::_AUTOGEN_crd_opts_test',
        api_version     => 'homelab.example.com/v1',
        kind            => 'BackupSchedule',
        resource_plural => 'backupschedules',
        is_namespaced   => 1,
    );

    ok($class, 'got class back');
    is($class->api_version, 'homelab.example.com/v1', 'api_version from opts');
    is($class->kind, 'BackupSchedule', 'kind from opts');
    is($class->resource_plural, 'backupschedules', 'resource_plural from opts');
    ok($class->does('IO::K8s::Role::Namespaced'), 'is namespaced');
    ok($class->does('IO::K8s::Role::APIObject'), 'has APIObject role');

    # Create instance
    my $obj = $class->new(
        spec => { schedule => '0 2 * * *', target => '/data', retention => 7 },
    );
    is($obj->kind, 'BackupSchedule', 'instance kind');
    is($obj->spec->{schedule}, '0 2 * * *', 'spec.schedule');
};

# Test 8: AutoGen recognizes IntOrString types
subtest 'autogen IntOrString support' => sub {
    IO::K8s::AutoGen::clear_cache();

    my $schema = {
        type => 'object',
        properties => {
            name => { type => 'string' },
            port => {
                '$ref' => '#/definitions/io.k8s.apimachinery.pkg.util.intstr.IntOrString',
            },
            targetPort => {
                type   => 'string',
                format => 'int-or-string',
            },
            replicas => { type => 'integer' },
        },
    };

    my $class = IO::K8s::AutoGen::get_or_generate(
        'test.intorstr.v1.TestService',
        $schema,
        {},
        'IO::K8s::_AUTOGEN_intorstr_test',
    );

    ok($class, 'IntOrString class generated');

    # Check attr registry
    my $info = $class->_k8s_attr_info;
    ok($info->{port}{is_int_or_string}, 'port via $ref has is_int_or_string');
    ok($info->{targetPort}{is_int_or_string}, 'targetPort via format has is_int_or_string');
    ok($info->{replicas}{is_int}, 'replicas is still plain Int');
    ok($info->{name}{is_str}, 'name is still plain Str');

    # Serialization: numeric -> integer, string -> string
    my $obj = $class->new(
        name       => 'web',
        port       => '8080',
        targetPort => 'http',
        replicas   => 3,
    );
    my $data = $obj->TO_JSON;
    is($data->{port}, 8080, 'IntOrStr $ref: numeric becomes integer');
    is($data->{targetPort}, 'http', 'IntOrStr format: named port stays string');
    is($data->{replicas}, 3, 'Int stays integer');

    # JSON encoding check
    require JSON::MaybeXS;
    my $json_str = JSON::MaybeXS->new(utf8 => 0, canonical => 1)->encode($data);
    like($json_str, qr/"port":8080\b/, 'JSON: port as integer');
    like($json_str, qr/"targetPort":"http"/, 'JSON: targetPort as string');
};

# Test 9: AutoGen recognizes Quantity and Time types
subtest 'autogen Quantity and Time support' => sub {
    IO::K8s::AutoGen::clear_cache();

    my $schema = {
        type => 'object',
        properties => {
            name => { type => 'string' },
            capacity => {
                '$ref' => '#/definitions/io.k8s.apimachinery.pkg.api.resource.Quantity',
            },
            creationTimestamp => {
                '$ref' => '#/definitions/io.k8s.apimachinery.pkg.apis.meta.v1.Time',
            },
            eventTime => {
                '$ref' => '#/definitions/io.k8s.apimachinery.pkg.apis.meta.v1.MicroTime',
            },
            lastUpdate => {
                type   => 'string',
                format => 'date-time',
            },
            replicas => { type => 'integer' },
        },
    };

    my $class = IO::K8s::AutoGen::get_or_generate(
        'test.qttime.v1.TestResource',
        $schema,
        {},
        'IO::K8s::_AUTOGEN_qttime_test',
    );

    ok($class, 'Quantity/Time class generated');

    my $info = $class->_k8s_attr_info;
    ok($info->{capacity}{is_quantity}, 'capacity via $ref has is_quantity');
    ok($info->{creationTimestamp}{is_time}, 'creationTimestamp via Time $ref has is_time');
    ok($info->{eventTime}{is_time}, 'eventTime via MicroTime $ref has is_time');
    ok($info->{lastUpdate}{is_time}, 'lastUpdate via format: date-time has is_time');
    ok($info->{replicas}{is_int}, 'replicas still plain Int');
    ok($info->{name}{is_str}, 'name still plain Str');

    # Serialization: all stay as strings
    my $obj = $class->new(
        name              => 'test',
        capacity          => '100Gi',
        creationTimestamp  => '2024-01-15T10:30:45Z',
        eventTime          => '2024-01-15T10:30:45.123456Z',
        lastUpdate         => '2026-02-28T00:00:00Z',
        replicas           => 3,
    );
    my $data = $obj->TO_JSON;
    is($data->{capacity}, '100Gi', 'Quantity stays string');
    is($data->{creationTimestamp}, '2024-01-15T10:30:45Z', 'Time stays string');
    is($data->{eventTime}, '2024-01-15T10:30:45.123456Z', 'MicroTime stays string');
    is($data->{lastUpdate}, '2026-02-28T00:00:00Z', 'date-time format stays string');
    is($data->{replicas}, 3, 'Int stays integer');

    # JSON encoding: all are quoted strings
    require JSON::MaybeXS;
    my $json_str = JSON::MaybeXS->new(utf8 => 0, canonical => 1)->encode($data);
    like($json_str, qr/"capacity":"100Gi"/, 'JSON: Quantity as string');
    like($json_str, qr/"creationTimestamp":"2024-01-15T10:30:45Z"/, 'JSON: Time as string');
    like($json_str, qr/"replicas":3\b/, 'JSON: replicas as integer');
};

done_testing;
