#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Scalar::Util qw(blessed);
use IO::K8s;

my $io = IO::K8s->new;

# ======================================================================
# 1. Typed object in array field (the PVC-in-StatefulSet case)
# ======================================================================
subtest 'array field: pre-built objects pass through' => sub {

    # Build a PVC object first
    my $pvc = $io->struct_to_object(
        'IO::K8s::Api::Core::V1::PersistentVolumeClaim',
        {
            metadata => { name => 'data' },
            spec     => {
                accessModes => ['ReadWriteOnce'],
                resources   => { requests => { storage => '10Gi' } },
            },
        },
    );
    isa_ok($pvc, 'IO::K8s::Api::Core::V1::PersistentVolumeClaim',
        'PVC object built successfully');

    # Now pass the pre-built PVC into a StatefulSet
    my $sts = $io->struct_to_object(
        'IO::K8s::Api::Apps::V1::StatefulSet',
        {
            metadata => { name => 'my-sts' },
            spec     => {
                selector    => { matchLabels => { app => 'db' } },
                serviceName => 'db',
                template    => {
                    metadata => { labels => { app => 'db' } },
                    spec     => {
                        containers => [{ name => 'db', image => 'postgres:16' }],
                    },
                },
                volumeClaimTemplates => [$pvc],
            },
        },
    );

    isa_ok($sts, 'IO::K8s::Api::Apps::V1::StatefulSet');

    my $vcts = $sts->spec->volumeClaimTemplates;
    is(scalar @$vcts, 1, 'volumeClaimTemplates has 1 entry');
    isa_ok($vcts->[0], 'IO::K8s::Api::Core::V1::PersistentVolumeClaim',
        'array element is still a PVC object');

    # Crucially: the data must survive
    is($vcts->[0]->metadata->name, 'data', 'PVC metadata.name preserved');
    is_deeply(
        $vcts->[0]->spec->resources->requests,
        { storage => '10Gi' },
        'PVC spec.resources.requests preserved',
    );
};

# ======================================================================
# 2. Typed object in single-object field (ObjectMeta passed pre-built)
# ======================================================================
subtest 'single-object field: pre-built ObjectMeta passes through' => sub {

    my $meta = $io->struct_to_object(
        'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta',
        { name => 'my-pod', namespace => 'prod', labels => { app => 'web' } },
    );
    isa_ok($meta, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta');

    my $pod = $io->struct_to_object(
        'IO::K8s::Api::Core::V1::Pod',
        {
            metadata => $meta,
            spec     => {
                containers => [{ name => 'app', image => 'nginx' }],
            },
        },
    );

    isa_ok($pod, 'IO::K8s::Api::Core::V1::Pod');
    isa_ok($pod->metadata, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta');
    is($pod->metadata->name, 'my-pod', 'metadata.name preserved');
    is($pod->metadata->namespace, 'prod', 'metadata.namespace preserved');
    is_deeply($pod->metadata->labels, { app => 'web' }, 'metadata.labels preserved');
};

# ======================================================================
# 3. Typed object in single-object field (nested spec)
# ======================================================================
subtest 'single-object field: pre-built PodSpec passes through' => sub {

    my $spec = $io->struct_to_object(
        'IO::K8s::Api::Core::V1::PodSpec',
        { containers => [{ name => 'app', image => 'nginx:latest' }] },
    );
    isa_ok($spec, 'IO::K8s::Api::Core::V1::PodSpec');

    my $pod = $io->struct_to_object(
        'IO::K8s::Api::Core::V1::Pod',
        {
            metadata => { name => 'test-pod' },
            spec     => $spec,
        },
    );

    isa_ok($pod, 'IO::K8s::Api::Core::V1::Pod');
    isa_ok($pod->spec, 'IO::K8s::Api::Core::V1::PodSpec');
    is($pod->spec->containers->[0]->name, 'app', 'container name preserved');
    is($pod->spec->containers->[0]->image, 'nginx:latest', 'container image preserved');
};

# ======================================================================
# 4. Typed object in hash-of-objects field
# ======================================================================
subtest 'hash-of-objects field: pre-built objects pass through' => sub {

    my $attr_obj = $io->struct_to_object(
        'IO::K8s::Api::Resource::V1alpha3::DeviceAttribute',
        { string => 'gpu-model-a100', int => 80 },
    );
    isa_ok($attr_obj, 'IO::K8s::Api::Resource::V1alpha3::DeviceAttribute');

    my $device = $io->struct_to_object(
        'IO::K8s::Api::Resource::V1alpha3::BasicDevice',
        {
            attributes => {
                'model' => $attr_obj,
            },
            capacity => { memory => '80Gi' },
        },
    );

    isa_ok($device, 'IO::K8s::Api::Resource::V1alpha3::BasicDevice');

    my $attrs = $device->attributes;
    ok(exists $attrs->{model}, 'hash key "model" exists');
    isa_ok($attrs->{model}, 'IO::K8s::Api::Resource::V1alpha3::DeviceAttribute',
        'hash value is a DeviceAttribute object');
    is($attrs->{model}->string, 'gpu-model-a100', 'DeviceAttribute.string preserved');
    is($attrs->{model}->int, 80, 'DeviceAttribute.int preserved');
};

# ======================================================================
# 5. Mixed array: some elements are hashrefs, some are pre-built objects
# ======================================================================
subtest 'mixed array: hashrefs and pre-built objects together' => sub {

    # Build one container as an object
    my $container_obj = $io->struct_to_object(
        'IO::K8s::Api::Core::V1::Container',
        { name => 'sidecar', image => 'envoy:latest' },
    );
    isa_ok($container_obj, 'IO::K8s::Api::Core::V1::Container');

    # Pass mixed array: one hashref, one pre-built object
    my $pod = $io->struct_to_object(
        'IO::K8s::Api::Core::V1::Pod',
        {
            metadata => { name => 'mixed-pod' },
            spec     => {
                containers => [
                    { name => 'main', image => 'myapp:v1' },      # hashref
                    $container_obj,                                  # pre-built
                ],
            },
        },
    );

    isa_ok($pod, 'IO::K8s::Api::Core::V1::Pod');
    my $containers = $pod->spec->containers;
    is(scalar @$containers, 2, 'two containers');

    isa_ok($containers->[0], 'IO::K8s::Api::Core::V1::Container');
    is($containers->[0]->name, 'main', 'hashref container name');
    is($containers->[0]->image, 'myapp:v1', 'hashref container image');

    isa_ok($containers->[1], 'IO::K8s::Api::Core::V1::Container');
    is($containers->[1]->name, 'sidecar', 'pre-built container name');
    is($containers->[1]->image, 'envoy:latest', 'pre-built container image');
};

# ======================================================================
# 6. Nested passthrough: objects containing objects containing objects
# ======================================================================
subtest 'nested passthrough: three levels deep' => sub {

    # Level 3: build EnvVar objects
    my $env = $io->struct_to_object(
        'IO::K8s::Api::Core::V1::EnvVar',
        { name => 'DB_HOST', value => 'postgres.default' },
    );
    isa_ok($env, 'IO::K8s::Api::Core::V1::EnvVar');

    # Level 2: build Container with pre-built EnvVar
    my $container = $io->struct_to_object(
        'IO::K8s::Api::Core::V1::Container',
        {
            name  => 'app',
            image => 'myapp:v2',
            env   => [$env],
        },
    );
    isa_ok($container, 'IO::K8s::Api::Core::V1::Container');
    is($container->env->[0]->name, 'DB_HOST', 'env var name in container');

    # Level 1: build PodSpec with pre-built Container
    my $spec = $io->struct_to_object(
        'IO::K8s::Api::Core::V1::PodSpec',
        { containers => [$container] },
    );
    isa_ok($spec, 'IO::K8s::Api::Core::V1::PodSpec');

    # Level 0: build Pod with pre-built PodSpec
    my $pod = $io->struct_to_object(
        'IO::K8s::Api::Core::V1::Pod',
        {
            metadata => { name => 'nested-pod' },
            spec     => $spec,
        },
    );

    isa_ok($pod, 'IO::K8s::Api::Core::V1::Pod');
    is($pod->metadata->name, 'nested-pod', 'pod name');

    # Walk all three levels
    my $got_spec = $pod->spec;
    isa_ok($got_spec, 'IO::K8s::Api::Core::V1::PodSpec');
    my $got_container = $got_spec->containers->[0];
    isa_ok($got_container, 'IO::K8s::Api::Core::V1::Container');
    is($got_container->name, 'app', 'container name');
    is($got_container->image, 'myapp:v2', 'container image');
    my $got_env = $got_container->env->[0];
    isa_ok($got_env, 'IO::K8s::Api::Core::V1::EnvVar');
    is($got_env->name, 'DB_HOST', 'env var name through three levels');
    is($got_env->value, 'postgres.default', 'env var value through three levels');
};

# ======================================================================
# 7. TO_JSON produces correct output in all passthrough cases
# ======================================================================
subtest 'TO_JSON round-trip for passthrough objects' => sub {

    # Build a full StatefulSet with pre-built nested objects
    my $meta = $io->struct_to_object(
        'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta',
        { name => 'json-sts', namespace => 'test', labels => { app => 'db' } },
    );

    my $pvc = $io->struct_to_object(
        'IO::K8s::Api::Core::V1::PersistentVolumeClaim',
        {
            metadata => { name => 'data-vol' },
            spec     => {
                accessModes => ['ReadWriteOnce'],
                resources   => { requests => { storage => '5Gi' } },
            },
        },
    );

    my $container = $io->struct_to_object(
        'IO::K8s::Api::Core::V1::Container',
        { name => 'db', image => 'postgres:16', env => [{ name => 'PGDATA', value => '/data' }] },
    );

    my $sts = $io->struct_to_object(
        'IO::K8s::Api::Apps::V1::StatefulSet',
        {
            metadata => $meta,
            spec     => {
                selector    => { matchLabels => { app => 'db' } },
                serviceName => 'db-svc',
                template    => {
                    metadata => { labels => { app => 'db' } },
                    spec     => { containers => [$container] },
                },
                volumeClaimTemplates => [$pvc],
            },
        },
    );

    my $json_struct = $sts->TO_JSON;

    # Top-level metadata
    is($json_struct->{apiVersion}, 'apps/v1', 'apiVersion in JSON');
    is($json_struct->{kind}, 'StatefulSet', 'kind in JSON');
    is($json_struct->{metadata}{name}, 'json-sts', 'metadata.name in JSON');
    is($json_struct->{metadata}{namespace}, 'test', 'metadata.namespace in JSON');

    # Template container (pre-built, passed through)
    my $tmpl_containers = $json_struct->{spec}{template}{spec}{containers};
    is(scalar @$tmpl_containers, 1, 'one container in template');
    is($tmpl_containers->[0]{name}, 'db', 'container name in JSON');
    is($tmpl_containers->[0]{image}, 'postgres:16', 'container image in JSON');
    is($tmpl_containers->[0]{env}[0]{name}, 'PGDATA', 'env var name in JSON');

    # VolumeClaimTemplates (pre-built PVC, passed through)
    my $vcts = $json_struct->{spec}{volumeClaimTemplates};
    is(scalar @$vcts, 1, 'one VCT in JSON');
    is($vcts->[0]{metadata}{name}, 'data-vol', 'VCT metadata.name in JSON');
    is_deeply(
        $vcts->[0]{spec}{resources}{requests},
        { storage => '5Gi' },
        'VCT resources.requests in JSON',
    );

    # Round-trip: JSON -> object -> JSON
    my $json_str = $io->object_to_json($sts);
    ok(length($json_str) > 100, 'JSON string is non-trivial');

    my $roundtrip = $io->json_to_object($json_str);
    isa_ok($roundtrip, 'IO::K8s::Api::Apps::V1::StatefulSet');
    is($roundtrip->metadata->name, 'json-sts', 'round-trip metadata.name');
    is($roundtrip->spec->volumeClaimTemplates->[0]->metadata->name,
        'data-vol', 'round-trip VCT name');
};

# ======================================================================
# 8. struct_to_object returns exact same object for matching class
# ======================================================================
subtest 'struct_to_object returns same ref for matching class' => sub {

    my $meta = $io->struct_to_object(
        'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta',
        { name => 'identity-test' },
    );

    my $same = $io->struct_to_object(
        'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta',
        $meta,
    );

    # It should be the exact same reference, not a copy
    is($same, $meta, 'struct_to_object returns same ref for matching class');
    is($same->name, 'identity-test', 'data preserved');
};

# ======================================================================
# 9. new_object with pre-built nested objects
# ======================================================================
subtest 'new_object with pre-built nested objects' => sub {

    my $container = $io->struct_to_object(
        'IO::K8s::Api::Core::V1::Container',
        { name => 'web', image => 'nginx:1.25' },
    );

    my $pod = $io->new_object('Pod',
        metadata => { name => 'new-obj-pod' },
        spec     => {
            containers => [$container],
        },
    );

    isa_ok($pod, 'IO::K8s::Api::Core::V1::Pod');
    isa_ok($pod->spec->containers->[0], 'IO::K8s::Api::Core::V1::Container');
    is($pod->spec->containers->[0]->name, 'web', 'container name via new_object');
    is($pod->spec->containers->[0]->image, 'nginx:1.25', 'container image via new_object');
};

# ======================================================================
# 10. Multiple pre-built PVCs in volumeClaimTemplates (real-world case)
# ======================================================================
subtest 'multiple pre-built PVCs in array field' => sub {

    my $pvc_data = $io->struct_to_object(
        'IO::K8s::Api::Core::V1::PersistentVolumeClaim',
        {
            metadata => { name => 'data' },
            spec     => {
                accessModes => ['ReadWriteOnce'],
                resources   => { requests => { storage => '50Gi' } },
            },
        },
    );

    my $pvc_log = $io->struct_to_object(
        'IO::K8s::Api::Core::V1::PersistentVolumeClaim',
        {
            metadata => { name => 'logs' },
            spec     => {
                accessModes => ['ReadWriteOnce'],
                resources   => { requests => { storage => '10Gi' } },
            },
        },
    );

    my $sts = $io->struct_to_object(
        'IO::K8s::Api::Apps::V1::StatefulSet',
        {
            metadata => { name => 'multi-pvc-sts' },
            spec     => {
                selector    => { matchLabels => { app => 'db' } },
                serviceName => 'db',
                template    => {
                    metadata => { labels => { app => 'db' } },
                    spec     => {
                        containers => [{ name => 'db', image => 'postgres:16' }],
                    },
                },
                volumeClaimTemplates => [$pvc_data, $pvc_log],
            },
        },
    );

    my $vcts = $sts->spec->volumeClaimTemplates;
    is(scalar @$vcts, 2, 'two VCTs');
    is($vcts->[0]->metadata->name, 'data', 'first VCT name');
    is($vcts->[1]->metadata->name, 'logs', 'second VCT name');
    is_deeply(
        $vcts->[0]->spec->resources->requests,
        { storage => '50Gi' },
        'first VCT storage',
    );
    is_deeply(
        $vcts->[1]->spec->resources->requests,
        { storage => '10Gi' },
        'second VCT storage',
    );

    # Verify JSON output has both
    my $json = $sts->TO_JSON;
    is(scalar @{$json->{spec}{volumeClaimTemplates}}, 2,
        'JSON has two VCTs');
    is($json->{spec}{volumeClaimTemplates}[0]{metadata}{name}, 'data',
        'first VCT name in JSON');
    is($json->{spec}{volumeClaimTemplates}[1]{metadata}{name}, 'logs',
        'second VCT name in JSON');
};

# ======================================================================
# 11. Hash-of-objects with mixed pre-built and hashref values
# ======================================================================
subtest 'hash-of-objects: mixed pre-built and hashref values' => sub {

    my $attr_prebuilt = $io->struct_to_object(
        'IO::K8s::Api::Resource::V1alpha3::DeviceAttribute',
        { string => 'vendor-nvidia' },
    );

    my $device = $io->struct_to_object(
        'IO::K8s::Api::Resource::V1alpha3::BasicDevice',
        {
            attributes => {
                'vendor'  => $attr_prebuilt,                        # pre-built
                'version' => { version => '2.0.0' },               # hashref
            },
        },
    );

    isa_ok($device, 'IO::K8s::Api::Resource::V1alpha3::BasicDevice');

    my $attrs = $device->attributes;
    isa_ok($attrs->{vendor}, 'IO::K8s::Api::Resource::V1alpha3::DeviceAttribute');
    is($attrs->{vendor}->string, 'vendor-nvidia', 'pre-built value preserved');

    isa_ok($attrs->{version}, 'IO::K8s::Api::Resource::V1alpha3::DeviceAttribute');
    is($attrs->{version}->version, '2.0.0', 'hashref value inflated correctly');
};

done_testing;
