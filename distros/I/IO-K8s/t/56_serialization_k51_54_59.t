#!/usr/bin/env perl
# Regression tests for k54 and k59, both in lib/IO/K8s/Role/Resource.pm
# and lib/IO/K8s.pm's shared inflation path.
#
# k54: TO_JSON's is_array_of_str / is_hash_of_str (and raw array/hash
# attribute) branches used to hand back the attribute's own reference
# uncopied, so mutating the struct TO_JSON returned silently mutated the
# object -- and every later serialization carried the edit. The symmetric
# input-side bug lived in IO::K8s::_inflate_struct: an inflated object shared
# references with the source struct, so mutating the caller's struct after
# inflate()/struct_to_object() silently mutated the object. Both directions
# now shallow-copy ARRAY/HASH containers one level deep -- deliberately one
# level only, so a nested structure under an opaque free-form hash attribute
# (fieldsV1) still aliases at depth 2. That limit is pinned here as
# intentional, not left for a future change to break silently.
#
# k59: FROM_HASH (and from_json, which sits on top of it) used to be a
# bare $class->new(%$hash) with no inflation, asymmetric with TO_JSON -- a
# struct with any nested object-typed field died on a bare Moo type-
# constraint error. FROM_HASH now routes through the same
# _struct_to_object_expanded/_inflate_struct pipeline struct_to_object and
# json_to_object use, so a round-trip through the CLASS entry point (not just
# the $k8s instance entry points) works, nested fields are real typed
# instances, sanitized attribute names and union FROM_STRUCT classes are
# handled identically, an already-blessed instance of the right class passes
# through unchanged, and bad data gets the k42 diagnostic (class + field
# in the message) instead of an anonymous type-constraint failure.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Scalar::Util qw(refaddr blessed);
use JSON::MaybeXS ();

use IO::K8s;
use IO::K8s::Api::Core::V1::ConfigMap ();
use IO::K8s::Api::Core::V1::Container ();
use IO::K8s::Api::Core::V1::SecurityContext ();
use IO::K8s::Api::Core::V1::ContainerStatus ();
use IO::K8s::Api::Apps::V1::Deployment ();
use IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ManagedFieldsEntry ();
use IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaProps ();
use IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaPropsOrBool ();

my $k8s = IO::K8s->new;

# ============================================================================
# k54: output side (TO_JSON must not alias the object)
# ============================================================================

subtest 'k54: TO_JSON does not alias the object (scalar array/hash attrs)' => sub {
    my $cm = $k8s->new_object('ConfigMap', {
        metadata => { name => 'x' },
        data     => { key => 'original' },
    });
    my $struct = $cm->TO_JSON;
    $struct->{data}{key} = 'MUTATED';
    is($cm->data->{key}, 'original',
        'mutating TO_JSON->{data}{key} does not mutate the object');

    my $container = IO::K8s::Api::Core::V1::Container->new(
        name => 'c', image => 'img', command => ['echo', 'hi'],
    );
    my $cstruct = $container->TO_JSON;
    push @{ $cstruct->{command} }, 'EXTRA';
    is_deeply($container->command, ['echo', 'hi'],
        'pushing onto TO_JSON->{command} does not mutate the object');
};

subtest 'k54: the documented depth limit -- fieldsV1 aliases one level down' => sub {
    my $mfe = IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ManagedFieldsEntry->new(
        manager  => 'kubectl',
        fieldsV1 => { 'f:metadata' => { 'f:labels' => { 'f:app' => {} } } },
    );
    my $struct = $mfe->TO_JSON;

    # Depth 1 (the fieldsV1 hash itself) is copied: a new top-level key added
    # to the struct must not reach the object.
    $struct->{fieldsV1}{'f:new-top-level-key'} = 1;
    ok(!exists $mfe->fieldsV1->{'f:new-top-level-key'},
        'a new top-level key added to the TO_JSON struct does not appear on the object (depth 1 copied)');

    # Depth 2 is documented to still alias: fieldsV1 is a free-form HashRef
    # (no inner type constraint -- k48/k54's own comments call this
    # out), and Role::Resource::TO_JSON's ARRAY/HASH shallow copy
    # ([@$value]/{%$value}) is one level deep only. Pinned here deliberately:
    # this is intentional, so a future deep-copy change (or a regression back
    # to no copy at all) shows up as a test failure instead of a silent
    # behaviour change.
    $struct->{fieldsV1}{'f:metadata'}{'f:labels'}{'f:app'} = 'MUTATED-DEPTH-2';
    is($mfe->fieldsV1->{'f:metadata'}{'f:labels'}{'f:app'}, 'MUTATED-DEPTH-2',
        'mutating a nested (depth-2) value through the struct DOES reach the object -- documented limit, not a bug');
};

# ============================================================================
# k54: input side (inflate/struct_to_object must not alias the source)
# ============================================================================

subtest 'k54: inflate()/struct_to_object() do not alias the source struct' => sub {
    my $src = {
        apiVersion => 'v1', kind => 'ConfigMap',
        metadata   => { name => 'x' },
        data       => { key => 'original' },
    };
    my $cm = $k8s->inflate($src);
    $src->{data}{key} = 'MUTATED-AFTER-INFLATE';
    is($cm->data->{key}, 'original',
        'mutating the source struct after inflate() does not mutate the object');

    my $src2 = {
        metadata => { name => 'x' },
        spec     => { containers => [
            { name => 'c', image => 'img', command => ['echo'] },
        ] },
    };
    my $pod = $k8s->struct_to_object('Pod', $src2);
    push @{ $src2->{spec}{containers}[0]{command} }, 'EXTRA-SOURCE-MUTATION';
    is_deeply($pod->spec->containers->[0]->command, ['echo'],
        'mutating the source struct after struct_to_object() does not mutate the object');
};

subtest 'k54: input-side depth limit matches the output side (fieldsV1)' => sub {
    my $src = {
        manager  => 'kubectl',
        fieldsV1 => { 'f:metadata' => { 'f:labels' => { 'f:app' => {} } } },
    };
    my $mfe = $k8s->struct_to_object(
        '+IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ManagedFieldsEntry', $src);

    $src->{fieldsV1}{'f:new-key'} = 1;
    ok(!exists $mfe->fieldsV1->{'f:new-key'},
        'depth 1 of fieldsV1 is copied on the input side too');

    $src->{fieldsV1}{'f:metadata'}{'f:labels'}{'f:app'} = 'MUTATED-VIA-SOURCE';
    is($mfe->fieldsV1->{'f:metadata'}{'f:labels'}{'f:app'}, 'MUTATED-VIA-SOURCE',
        'depth 2 still aliases the source on the input side too -- same documented limit as TO_JSON');
};

# ============================================================================
# k59: Class->from_json byte-identical deep round-trip
# ============================================================================

subtest 'k59: Class->from_json deep round-trip is byte-identical' => sub {
    my $deploy = $k8s->new_object('Deployment', {
        metadata => {
            name      => 'webapp',
            namespace => 'production',
            labels    => { app => 'webapp', tier => 'backend' },
        },
        spec => {
            replicas => 3,
            selector => { matchLabels => { app => 'webapp' } },
            template => {
                metadata => { labels => { app => 'webapp' } },
                spec     => {
                    containers => [
                        {
                            name      => 'app',
                            image     => 'nginx:1.25',
                            resources => {
                                requests => { cpu => '100m', memory => '128Mi' },
                                limits   => { cpu => '500m', memory => '256Mi' },
                            },
                            ports => [ { containerPort => 8080 } ],
                        },
                    ],
                },
            },
        },
    });

    my $json1 = $deploy->to_json;
    my $back  = IO::K8s::Api::Apps::V1::Deployment->from_json($json1);
    isa_ok($back, 'IO::K8s::Api::Apps::V1::Deployment');

    # Nested fields are real typed instances, not hashrefs left over from a
    # shallow ->new(%$hash).
    isa_ok($back->spec, 'IO::K8s::Api::Apps::V1::DeploymentSpec');
    isa_ok($back->spec->template->spec->containers->[0], 'IO::K8s::Api::Core::V1::Container');
    isa_ok($back->spec->template->spec->containers->[0]->resources,
        'IO::K8s::Api::Core::V1::ResourceRequirements');
    is($back->spec->template->spec->containers->[0]->resources->requests->{cpu}, '100m',
        'nested resource request survives inflation');

    is($back->to_json, $json1, 'Class->from_json(to_json) is byte-identical');
};

# ============================================================================
# k59: sanitized attribute names and union FROM_STRUCT classes
# ============================================================================

subtest 'k59: sanitized names ($ref, x-kubernetes-list-type) and union FROM_STRUCT round-trip' => sub {
    my $struct = {
        '$ref'                     => '#/definitions/io.k8s.api.core.v1.Pod',
        type                       => 'object',
        'x-kubernetes-list-type'   => 'atomic',
        additionalProperties       => { type => 'string' },
    };

    my $props = IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaProps
        ->FROM_HASH($struct);
    isa_ok($props, 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaProps');
    is($props->_ref, '#/definitions/io.k8s.api.core.v1.Pod',
        q{sanitized '$ref' -> _ref accessor});
    is($props->x_kubernetes_list_type, 'atomic',
        q{sanitized 'x-kubernetes-list-type' -> x_kubernetes_list_type accessor});

    # additionalProperties is the union type: a hashref inflates through its
    # own FROM_STRUCT hook into the schema arm, never a bare hashref.
    isa_ok($props->additionalProperties,
        'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaPropsOrBool');
    ok($props->additionalProperties->is_schema, 'additionalProperties resolved to the schema arm');
    isa_ok($props->additionalProperties->schema,
        'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaProps');
    is($props->additionalProperties->schema->type, 'string',
        'nested schema arm field survives inflation');

    is_deeply($props->TO_JSON, $struct,
        'TO_JSON round-trips the sanitized names and the union arm back to the wire shape');

    # The boolean arm too, via Class->FROM_HASH -- k59's own entry
    # point, not just struct_to_object.
    my $props2 = IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaProps
        ->FROM_HASH({ additionalProperties => JSON::MaybeXS::false() });
    ok(!$props2->additionalProperties->is_schema, 'boolean arm (false) resolved, not treated as schema');
    is($props2->additionalProperties->allows, 0, 'boolean arm value preserved');
};

# ============================================================================
# k59: blessed input of the correct class passes through unchanged
# ============================================================================

subtest 'k59: an already-blessed instance of the right class passes through unchanged' => sub {
    my $sc = IO::K8s::Api::Core::V1::SecurityContext->new(privileged => 1);

    my $via_from_hash = IO::K8s::Api::Core::V1::SecurityContext->FROM_HASH($sc);
    is(refaddr($via_from_hash), refaddr($sc),
        'FROM_HASH returns the SAME instance, not a copy, when already the right class');

    my $via_struct_to_object = $k8s->struct_to_object('Api::Core::V1::SecurityContext', $sc);
    is(refaddr($via_struct_to_object), refaddr($sc),
        'struct_to_object returns the SAME instance too');
};

# ============================================================================
# k59 (and k42): FROM_HASH now carries the k42 diagnostic
# ============================================================================

subtest 'k59: FROM_HASH gets the k42 diagnostic (class + field) on bad data' => sub {
    throws_ok {
        IO::K8s::Api::Core::V1::Pod->FROM_HASH({ spec => { hostNetwork => {} } });
    }
        qr/Bool value must be a scalar or scalar ref, got HASH while inflating IO::K8s::Api::Core::V1::PodSpec field hostNetwork/,
        'FROM_HASH: bad Bool data names class and field, not a bare Moo type-constraint error';

    throws_ok {
        IO::K8s::Api::Core::V1::Pod->FROM_HASH({ spec => { hostNetwork => \\0 } });
    }
        qr/Bool scalar ref dereferenced to another reference \(SCALAR\), not a boolean while inflating IO::K8s::Api::Core::V1::PodSpec field hostNetwork/,
        'FROM_HASH: \\0 dies with the same class/field context, not silently true';
};

# k59: a required Bool explicitly set to undef in a FROM_HASH struct
# dies with Moo's "Missing required arguments", not a type-constraint error.
# _inflate_struct skips any key whose value is undef entirely
# (`next unless defined $value`), so a required attribute given as undef
# never reaches $class->new() at all -- it fails on being absent, not on
# being the wrong type. This is a convergence with struct_to_object, not a
# FROM_HASH-only quirk: both share _inflate_struct, and struct_to_object
# already failed exactly this way before k59 changed FROM_HASH to use
# the same pipeline. Contrast with k48's own test file
# (t/53_bool_normalization.t), where ContainerStatus->new(ready => undef)
# succeeds -- that is the DIRECT constructor path, where Bool's own
# undef-tolerance applies because the argument is actually passed.
subtest 'k59: FROM_HASH on a required Bool given as undef dies as Missing required arguments' => sub {
    throws_ok {
        IO::K8s::Api::Core::V1::ContainerStatus->FROM_HASH({
            name         => 'c',
            image        => 'busybox',
            imageID      => 'docker-pullable://busybox@sha256:deadbeef',
            restartCount => 0,
            ready        => undef,
        });
    }
        qr/Missing required arguments: ready/,
        'FROM_HASH: required Bool "ready" set to undef dies as a missing argument';

    throws_ok {
        $k8s->struct_to_object('Api::Core::V1::ContainerStatus', {
            name         => 'c',
            image        => 'busybox',
            imageID      => 'docker-pullable://busybox@sha256:deadbeef',
            restartCount => 0,
            ready        => undef,
        });
    }
        qr/Missing required arguments: ready/,
        'struct_to_object: same input, same failure -- FROM_HASH converges with the existing behaviour, not a special case';
};

done_testing;
