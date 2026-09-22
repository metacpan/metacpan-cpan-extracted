#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

use IO::K8s::Cilium::V2::CiliumNetworkPolicy;
use IO::K8s::Traefik::V1alpha1::IngressRoute;
use IO::K8s::Traefik::V1alpha1::IngressRouteSpec;
use IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta;

# Traefik's IngressRouteSpec is a full-depth typed class (k95/D5): 'spec' is
# an IngressRouteSpec object, not an opaque hashref, so a nested-object seed
# (tls, routes) goes through spec_merge/spec_set (which coerce, walking the
# typed registry per IO::K8s::Role::SpecBuilder) rather than a raw
# ->new(spec => {...}) -- direct ->new does not coerce a hashref into a
# named nested class at any depth (k100). A seed that is only a fresh empty
# IngressRouteSpec object needs no coercion at all and is passed directly.

# --- spec_get ---

subtest 'spec_get' => sub {
    my $ir = IO::K8s::Traefik::V1alpha1::IngressRoute->new(
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(
            name => 'test-route',
        ),
    );
    $ir->spec_merge(
        entryPoints => ['web', 'websecure'],
        routes => [
            {
                match    => 'Host(`example.com`)',
                kind     => 'Rule',
                services => [{ name => 'app', port => 8080 }],
            },
        ],
        tls => { secretName => 'my-cert' },
    );

    is_deeply($ir->spec_get('entryPoints'), ['web', 'websecure'], 'top-level array');
    is($ir->spec_get('tls.secretName'), 'my-cert', 'nested value');
    is($ir->spec_get('routes.0.match'), 'Host(`example.com`)', 'array index');
    is_deeply([ map { $_->TO_JSON } @{ $ir->spec_get('routes.0.services') } ],
        [{ name => 'app', port => 8080 }], 'nested array');
    is($ir->spec_get('routes.0.services.0.name'), 'app', 'deep nested via array');
    is($ir->spec_get('nonexistent'), undef, 'missing key returns undef');
    is($ir->spec_get('tls.nonexistent'), undef, 'missing nested key');
};

subtest 'spec_get with no spec' => sub {
    my $ir = IO::K8s::Traefik::V1alpha1::IngressRoute->new(
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(
            name => 'empty',
        ),
    );

    is($ir->spec_get('anything'), undef, 'undef when spec is undef');
};

# --- spec_set ---

subtest 'spec_set' => sub {
    my $ir = IO::K8s::Traefik::V1alpha1::IngressRoute->new(
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(
            name => 'test-route',
        ),
        spec => IO::K8s::Traefik::V1alpha1::IngressRouteSpec->new,
    );

    $ir->spec_set('tls.secretName', 'my-cert');
    is($ir->spec_get('tls.secretName'), 'my-cert', 'set nested value with auto-vivify');

    $ir->spec_set('simple', 'value');
    is($ir->spec_get('simple'), 'value', 'set simple value');
};

subtest 'spec_set creates spec if missing' => sub {
    my $ir = IO::K8s::Traefik::V1alpha1::IngressRoute->new(
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(
            name => 'test-route',
        ),
    );

    $ir->spec_set('tls.secretName', 'cert');
    is($ir->spec_get('tls.secretName'), 'cert', 'spec auto-created');
};

subtest 'spec_set chaining' => sub {
    my $ir = IO::K8s::Traefik::V1alpha1::IngressRoute->new(
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(
            name => 'test-route',
        ),
        spec => IO::K8s::Traefik::V1alpha1::IngressRouteSpec->new,
    );

    my $result = $ir->spec_set('a', 1)->spec_set('b', 2);
    is($result, $ir, 'chaining returns self');
    is($ir->spec_get('a'), 1, 'chained set 1');
    is($ir->spec_get('b'), 2, 'chained set 2');
};

# --- spec_push ---

subtest 'spec_push' => sub {
    # 'rules' is not a field IO::K8s::Cilium::V2::Rule declares (D5) --
    # spec_push routes an undeclared key into the class's _unknown_fields
    # bag (D1), which is what this subtest actually exercises, not an
    # opaque spec. No seed needed: spec_push auto-vivifies a typed spec
    # from nothing (k90).
    my $cnp = IO::K8s::Cilium::V2::CiliumNetworkPolicy->new(
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(
            name => 'test-policy',
        ),
    );

    $cnp->spec_push('rules', { action => 'allow' });
    is(scalar @{$cnp->spec_get('rules')}, 1, 'pushed one item');

    $cnp->spec_push('rules', { action => 'deny' });
    is(scalar @{$cnp->spec_get('rules')}, 2, 'pushed second item');
    is($cnp->spec_get('rules.0.action'), 'allow', 'first item correct');
    is($cnp->spec_get('rules.1.action'), 'deny', 'second item correct');
};

subtest 'spec_push creates array if missing' => sub {
    my $cnp = IO::K8s::Cilium::V2::CiliumNetworkPolicy->new(
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(
            name => 'test-policy',
        ),
    );

    $cnp->spec_push('rules', { action => 'allow' });
    is(ref $cnp->spec_get('rules'), 'ARRAY', 'array created');
    is(scalar @{$cnp->spec_get('rules')}, 1, 'one item pushed');
};

# --- spec_merge ---

subtest 'spec_merge' => sub {
    my $ir = IO::K8s::Traefik::V1alpha1::IngressRoute->new(
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(
            name => 'test-route',
        ),
    );
    $ir->spec_merge(existing => 'value');

    $ir->spec_merge(entryPoints => ['web'], newKey => 'newVal');
    is($ir->spec_get('existing'), 'value', 'existing preserved');
    is_deeply($ir->spec_get('entryPoints'), ['web'], 'merged array');
    is($ir->spec_get('newKey'), 'newVal', 'merged scalar');
};

# --- spec_delete ---

subtest 'spec_delete' => sub {
    my $ir = IO::K8s::Traefik::V1alpha1::IngressRoute->new(
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(
            name => 'test-route',
        ),
    );
    $ir->spec_merge(
        tls    => { secretName => 'cert', options => {} },
        routes => [],
    );

    $ir->spec_delete('tls');
    is($ir->spec_get('tls'), undef, 'top-level key deleted');
    is_deeply($ir->spec_get('routes'), [], 'other keys preserved');
};

subtest 'spec_delete nested' => sub {
    my $ir = IO::K8s::Traefik::V1alpha1::IngressRoute->new(
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(
            name => 'test-route',
        ),
    );
    $ir->spec_merge(
        tls => { secretName => 'cert', options => { minVersion => 'VersionTLS12' } },
    );

    $ir->spec_delete('tls.options');
    is($ir->spec_get('tls.secretName'), 'cert', 'sibling preserved');
    is($ir->spec_get('tls.options'), undef, 'nested key deleted');
};

subtest 'spec_delete on missing is safe' => sub {
    my $ir = IO::K8s::Traefik::V1alpha1::IngressRoute->new(
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(
            name => 'test-route',
        ),
        spec => IO::K8s::Traefik::V1alpha1::IngressRouteSpec->new,
    );

    lives_ok { $ir->spec_delete('nonexistent') } 'deleting missing key does not die';
    lives_ok { $ir->spec_delete('a.b.c') } 'deleting deeply missing key does not die';
};

done_testing;
