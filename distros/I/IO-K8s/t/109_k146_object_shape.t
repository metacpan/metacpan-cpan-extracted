#!/usr/bin/env perl
# k146: the factory inflation path silently turns a wrongly-shaped value at
# an object position into an empty object instead of refusing it.
#
# lib/IO/K8s.pm:1098's `_inflate_struct`:
#     return {} unless ref $params eq 'HASH';
# is reached from `_struct_to_object_expanded` (~926-940) for every
# is_object-typed field. Confirmed repro:
#     IO::K8s->new(strict => 1)->new_object('Pod', metadata => [])
# succeeds and emits `metadata: {}`, with or without strict -- strict only
# governs undeclared keys (BUILD's D1 bag), not shape. Meanwhile
#     IO::K8s::Api::Core::V1::Pod->new(metadata => [])
# already fails correctly: the object-field coercer (_object_coercer)
# returns a non-HASH value unchanged, so Moo's own
# Maybe[InstanceOf[...ObjectMeta]] check catches it directly -- this file
# does not touch that path and asserts it keeps failing (a GUARD, not a RED
# case).
#
# Approved fix (NOT implemented by this file): in _struct_to_object_expanded,
# after the blessed-passthrough and the FROM_STRUCT delegation, refuse a
# defined non-HASH value destined for an ordinary object class. The error is
# expected to name the target class and the form actually received; since
# the exact wording isn't fixed yet, class-name checks use a plain
# case-insensitive class-name match and form checks use a tolerant ref()-name
# match (ARRAY/CODE/SCALAR), per the ticket's own guidance -- never an exact
# message string.
#
# Pure local fixtures -- no network, no cluster.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Scalar::Util qw(refaddr);
use lib 'lib';

use IO::K8s;
use IO::K8s::Api::Core::V1::Pod;
use IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta;
use JSON::MaybeXS;

my $PROPS = 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaProps';

# Asserts $code->() dies naming the target class, and -- when the received
# form has an unambiguous ref() name worth pinning down -- dies naming that
# form too. $code is called once per check; these fixtures are pure (no
# shared mutable state beyond memoized class loading), so re-invoking is
# safe and deterministic.
sub assert_shape_rejected {
    my (%o) = @_;
    my ($label, $code, $class_re, $form_re) = @o{qw(label code class_re form_re)};
    throws_ok { $code->() } $class_re, "$label dies naming the target class";
    throws_ok { $code->() } $form_re, "$label dies naming the received form"
        if $form_re;
}

# ============================================================================
# RED: a wrongly-shaped defined value at an object position must be refused,
# never silently turned into {}.
# ============================================================================

# Claim: new_object with an array at an object position must die, not build
# a Pod with a silently-emptied ObjectMeta.
subtest "new_object('Pod', metadata => []) dies" => sub {
    assert_shape_rejected(
        label    => 'new_object metadata=>[]',
        code     => sub { IO::K8s->new->new_object('Pod', metadata => []) },
        class_re => qr/ObjectMeta/i,
        form_re  => qr/ARRAY|array/i,
    );
};

# Claim: strict => 1 governs undeclared keys, not shape -- it must not make
# this case pass silently either.
subtest "new_object('Pod', metadata => []) dies under strict => 1 too" => sub {
    assert_shape_rejected(
        label    => 'new_object metadata=>[] (strict)',
        code     => sub { IO::K8s->new(strict => 1)->new_object('Pod', metadata => []) },
        class_re => qr/ObjectMeta/i,
        form_re  => qr/ARRAY|array/i,
    );
};

# Claim: a plain string at an object position is exactly as wrong as an
# array and must be refused too.
subtest "new_object('Pod', metadata => 'text') dies" => sub {
    assert_shape_rejected(
        label    => "new_object metadata=>'text'",
        code     => sub { IO::K8s->new->new_object('Pod', metadata => 'text') },
        class_re => qr/ObjectMeta/i,
    );
};

# Claim: inflate() routes through the same _inflate_struct call and must
# refuse the same malformed document.
subtest "inflate({ ..., metadata => [] }) dies" => sub {
    assert_shape_rejected(
        label    => 'inflate metadata=>[]',
        code     => sub { IO::K8s->new->inflate({ apiVersion => 'v1', kind => 'Pod', metadata => [] }) },
        class_re => qr/ObjectMeta/i,
        form_re  => qr/ARRAY|array/i,
    );
};

# Claim: the bug reaches nested object positions too. Today this already
# dies -- but only because the swallowed {} then fails Container's own
# required `name` check ("Missing required arguments: name"), a message that
# names neither Container nor the real problem. The fix must refuse the bad
# element directly, naming Container.
subtest "nested: new_object('Pod', ..., spec => { containers => ['bad'] }) dies naming Container" => sub {
    assert_shape_rejected(
        label    => 'nested spec.containers=>["bad"]',
        code     => sub {
            IO::K8s->new->new_object('Pod',
                metadata => { name => 'p' },
                spec     => { containers => ['bad'] },
            );
        },
        class_re => qr/Container/i,
    );
};

# Claim: FROM_HASH -- the class-method entry point ->from_json and any
# direct struct consumer uses -- must refuse the same malformed shape.
subtest "Pod->FROM_HASH({ metadata => [] }) dies" => sub {
    assert_shape_rejected(
        label    => 'FROM_HASH metadata=>[]',
        code     => sub { IO::K8s::Api::Core::V1::Pod->FROM_HASH({ metadata => [] }) },
        class_re => qr/ObjectMeta/i,
        form_re  => qr/ARRAY|array/i,
    );
};

# Claim: struct_to_object, the public two-argument entry point, must refuse
# the same malformed shape.
subtest "struct_to_object('Pod', { metadata => [] }) dies" => sub {
    assert_shape_rejected(
        label    => 'struct_to_object metadata=>[]',
        code     => sub { IO::K8s->new->struct_to_object('Pod', { metadata => [] }) },
        class_re => qr/ObjectMeta/i,
        form_re  => qr/ARRAY|array/i,
    );
};

# Claim: json_to_object, which decodes JSON text and then calls the same
# machinery, must refuse the same malformed shape.
subtest "json_to_object('Pod', '...') with metadata:[] dies" => sub {
    assert_shape_rejected(
        label    => 'json_to_object metadata=>[]',
        code     => sub { IO::K8s->new->json_to_object('Pod', '{"metadata":[]}') },
        class_re => qr/ObjectMeta/i,
        form_re  => qr/ARRAY|array/i,
    );
};

# Claim: a CODE reference at an object position is exactly as wrong as an
# array or a plain string.
subtest "new_object('Pod', metadata => CODE ref) dies" => sub {
    assert_shape_rejected(
        label    => 'new_object metadata=>CODEref',
        code     => sub { IO::K8s->new->new_object('Pod', metadata => sub { 1 }) },
        class_re => qr/ObjectMeta/i,
        form_re  => qr/CODE/i,
    );
};

# Claim: a SCALAR reference at an object position is exactly as wrong.
subtest "new_object('Pod', metadata => SCALAR ref) dies" => sub {
    my $x = 'x';
    assert_shape_rejected(
        label    => 'new_object metadata=>SCALARref',
        code     => sub { IO::K8s->new->new_object('Pod', metadata => \$x) },
        class_re => qr/ObjectMeta/i,
        form_re  => qr/SCALAR/i,
    );
};

# ============================================================================
# GUARDS: legitimate shapes and paths must keep working exactly as they do
# today.
# ============================================================================

# Claim: a genuinely valid hash at an object position still builds a typed
# object, unaffected by the fix.
subtest 'GUARD: a valid metadata hash still inflates normally' => sub {
    my $obj = IO::K8s->new->new_object('Pod', metadata => { name => 'p' });
    isa_ok($obj->metadata, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta');
    is($obj->metadata->name, 'p', 'metadata.name survives inflate');
};

# Claim: omitting metadata entirely still works -- the new check must fire
# only on a defined, wrongly-shaped value, never on plain absence.
subtest 'GUARD: omitted metadata still works' => sub {
    my $obj = IO::K8s->new->new_object('Pod',
        spec => { containers => [ { name => 'app', image => 'nginx' } ] });
    ok(!defined $obj->metadata, 'metadata stays unset, as today');
};

# Claim: an explicit undef for metadata still works -- same reasoning as
# omission, from the caller's side rather than by leaving the key out.
subtest 'GUARD: explicit undef metadata still works' => sub {
    my $obj = IO::K8s->new->new_object('Pod',
        metadata => undef,
        spec     => { containers => [ { name => 'app', image => 'nginx' } ] });
    ok(!defined $obj->metadata, 'metadata stays unset when explicitly undef');
};

# Claim: an already-blessed ObjectMeta of the right class passes straight
# through -- literally the same instance, not a rebuilt copy.
subtest 'GUARD: an already-blessed ObjectMeta passes through unchanged' => sub {
    my $om = IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(name => 'p');
    my $obj = IO::K8s->new->new_object('Pod', metadata => $om);
    is(refaddr($obj->metadata), refaddr($om), 'the identical ObjectMeta instance is reused, not copied');
};

# Claim: the direct constructor's own Moo type check must keep refusing
# metadata => [] exactly as it does today -- this fix is only about the
# factory path, not about weakening the constructor's own type constraint.
subtest 'GUARD: direct ->new(metadata => []) keeps failing at the type constraint' => sub {
    throws_ok { IO::K8s::Api::Core::V1::Pod->new(metadata => []) }
        qr/ObjectMeta/i,
        'direct construction still refuses a non-hash metadata';
};

# Claim: the apiextensions JSONSchemaProps union types self-inflate via
# FROM_STRUCT, which _struct_to_object_expanded delegates to BEFORE the new
# shape check would run -- so a schema fragment that is legitimately a bare
# array, a bare boolean or a tuple of schemas must keep inflating exactly as
# it does today (fixtures mirror t/31_apiextensions_unions.t).
subtest 'GUARD: JSONSchemaProps union forms via FROM_STRUCT keep working' => sub {
    my $k8s = IO::K8s->new;

    my $single = $k8s->struct_to_object($PROPS, { type => 'array', items => { type => 'string' } });
    ok($single->items->is_schema, 'single-schema items arm still inflates');
    is($single->items->schema->type, 'string', 'wrapped schema type preserved');

    my $tuple = $k8s->struct_to_object($PROPS, {
        type  => 'array',
        items => [ { type => 'string' }, { type => 'integer' } ],
    });
    ok(!$tuple->items->is_schema, 'tuple items arm still inflates');
    is(scalar @{ $tuple->items->schemas }, 2, 'both tuple schemas present');

    my $closed = $k8s->struct_to_object($PROPS, { type => 'object', additionalProperties => JSON::MaybeXS::false });
    is($closed->additionalProperties->allows, 0, 'additionalProperties:false union arm still inflates');

    my $open = $k8s->struct_to_object($PROPS, { type => 'object', additionalProperties => JSON::MaybeXS::true });
    is($open->additionalProperties->allows, 1, 'additionalProperties:true union arm still inflates');
};

done_testing;
