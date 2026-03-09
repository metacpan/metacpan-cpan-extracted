#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use YAML::PP;
use JSON::PP ();

use IO::K8s;

my $k8s = IO::K8s->new;

{
    package My::BoolCRD;
    use IO::K8s::APIObject
        api_version     => 'example.com/v1',
        resource_plural => 'boolcrds';

    with 'IO::K8s::Role::Namespaced';
    k8s spec => { Str => 1 };
}

subtest 'ConfigMap to_yaml' => sub {
    my $cm = $k8s->new_object('ConfigMap', {
        metadata => { name => 'test-config', namespace => 'default' },
        data => { 'key1' => 'value1', 'key2' => 'value2' },
    });

    ok $cm->can('to_yaml'), 'ConfigMap has to_yaml method';
    ok $cm->can('TO_YAML'), 'ConfigMap has TO_YAML method';

    my $yaml = $cm->to_yaml;
    ok $yaml, 'to_yaml returns content';
    like $yaml, qr/kind:\s*ConfigMap/, 'YAML contains kind';
    like $yaml, qr/name:\s*test-config/, 'YAML contains name';
    like $yaml, qr/key1:\s*value1/, 'YAML contains data';

    # Verify it's valid YAML
    my $parsed = YAML::PP::Load($yaml);
    is $parsed->{kind}, 'ConfigMap', 'Parsed kind is correct';
    is $parsed->{metadata}{name}, 'test-config', 'Parsed name is correct';
    is $parsed->{data}{key1}, 'value1', 'Parsed data is correct';
};

subtest 'Pod to_yaml' => sub {
    my $pod = $k8s->new_object('Pod', {
        metadata => { name => 'test-pod', namespace => 'default' },
        spec => {
            containers => [{
                name => 'main',
                image => 'nginx:latest',
            }],
        },
    });

    my $yaml = $pod->to_yaml;
    ok $yaml, 'to_yaml returns content';
    like $yaml, qr/kind:\s*Pod/, 'YAML contains kind';
    like $yaml, qr/apiVersion:\s*v1/, 'YAML contains apiVersion';

    my $parsed = YAML::PP::Load($yaml);
    is $parsed->{kind}, 'Pod', 'Parsed kind is correct';
    is $parsed->{apiVersion}, 'v1', 'Parsed apiVersion is correct';
    is $parsed->{spec}{containers}[0]{name}, 'main', 'Container name is correct';
    is $parsed->{spec}{containers}[0]{image}, 'nginx:latest', 'Container image is correct';
};

subtest 'Deployment to_yaml' => sub {
    my $deploy = $k8s->new_object('Deployment', {
        metadata => { name => 'test-deploy', namespace => 'default' },
        spec => {
            replicas => 3,
            selector => { matchLabels => { app => 'test' } },
            template => {
                metadata => { labels => { app => 'test' } },
                spec => {
                    containers => [{
                        name => 'app',
                        image => 'myapp:v1',
                    }],
                },
            },
        },
    });

    my $yaml = $deploy->to_yaml;
    ok $yaml, 'to_yaml returns content';
    like $yaml, qr/kind:\s*Deployment/, 'YAML contains kind';
    like $yaml, qr/apiVersion:\s*apps\/v1/, 'YAML contains apiVersion';

    my $parsed = YAML::PP::Load($yaml);
    is $parsed->{kind}, 'Deployment', 'Parsed kind is correct';
    is $parsed->{apiVersion}, 'apps/v1', 'Parsed apiVersion is correct';
    is $parsed->{spec}{replicas}, 3, 'Replicas is correct';
};

subtest 'TO_YAML vs to_yaml' => sub {
    my $cm = $k8s->new_object('ConfigMap', {
        metadata => { name => 'test' },
        data => { key => 'value' },
    });

    my $to_yaml = $cm->to_yaml;
    my $TO_YAML = $cm->TO_YAML;

    is $to_yaml, $TO_YAML, 'to_yaml and TO_YAML return same content';
};

subtest 'CRD to_yaml handles JSON booleans in passthrough spec hash' => sub {
    require IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta;

    my $obj = My::BoolCRD->new(
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(
            name => 'bool-crd',
            namespace => 'default',
        ),
        spec => {
            enabled => JSON::PP::true,
            tls     => JSON::PP::false,
        },
    );

    my $yaml = $obj->to_yaml;
    ok $yaml, 'to_yaml returns content';
    like $yaml, qr/enabled:\s*true/, 'boolean true serialized';
    like $yaml, qr/tls:\s*false/, 'boolean false serialized';
};

done_testing;
