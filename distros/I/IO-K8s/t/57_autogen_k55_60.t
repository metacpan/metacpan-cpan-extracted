#!/usr/bin/env perl
# Regression tests for k55, k56, k57 and k60 -- four independent bugs in
# lib/IO/K8s/AutoGen.pm's schema-to-attribute conversion, all found in the
# same 2026-08-18 core-module review. t/04_autogen.t already covers AutoGen's
# general mechanics (class naming, GVK dispatch, IntOrStr/Quantity/Time); this
# file pins the four fixes plus their explicitly-scoped non-fixes, so a
# regression on any of them fails here instead of only under a live cluster
# nobody runs in CI.
#
# k55 -- additionalProperties: true/false (a JSON boolean, not a schema
#   object) used to die "Not a HASH reference" with no class/field context.
#   Both polarities now fall back to the same opaque { Str => 1 } hash a
#   schemaless object gets. additionalProperties: false does NOT narrow
#   anything -- that is a deliberate non-fix, pinned below as a control. A
#   malformed additionalProperties (an ARRAY/CODE ref -- a broken schema, not
#   a boolean) still refuses, now naming class and field.
#
# k56 -- a property/items/additionalProperties $ref that does not
#   resolve against $all_defs used to be silently skipped: the class built
#   without that attribute, Moo dropped the unknown constructor argument, and
#   TO_JSON never re-emitted it -- silent data loss on every round-trip. The
#   decision was a loud croak instead (fail-closed, the k37/k39 line),
#   naming class and field, at all three call sites. The one carved-out
#   exception: a GVK-bearing class's own 'metadata' property is skipped
#   before any $ref lookup happens at all (the k60 interaction), so the
#   extremely common "single CRD schema whose metadata points at the stock
#   ObjectMeta it never embeds" case keeps working.
#
# k57 -- items: { type: boolean } used to fall into the ["Str"] default,
#   so schema-conforming JSON::PP::Boolean payloads failed ArrayRef[Str]. The
#   fix returns the DSL's [Bool] form (a Type::Tiny object, not the bareword
#   'Bool' -- ['Bool'] would be read by the DSL as an array of instances of a
#   class literally named IO::K8s::Api::Bool). Pinned via the registry's
#   is_array_of_bool flag, so a regression back to the bareword form is
#   visible in the registry even on a run where a Bool-shaped payload happens
#   to still construct.
#
# k60 -- a GVK-bearing generated class installs kind()/api_version() as
#   class methods (constants) after the property loop; if apiVersion/kind
#   were ALSO registered as ordinary k8s attributes, add_symbol('&kind', ...)
#   silently shadowed the accessor ($obj->kind('Other') became a no-op) and,
#   worse, apiVersion stayed a writable attribute whose stored value
#   overwrote the role-correct apiVersion in TO_JSON on every emit. Both
#   properties (plus metadata, see k56 above) are now skipped when building
#   attributes for a class that will get GVK methods, from either source: the
#   schema's own x-kubernetes-group-version-kind, or an explicit
#   --kind/--api_version opt.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use JSON::MaybeXS;
use IO::K8s::AutoGen;
use IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta;

sub json_bool_name { $_[0] ? 'true' : 'false' }

# ============================================================================
# k55 -- additionalProperties as a JSON boolean
# ============================================================================

subtest 'k55: additionalProperties: true falls back to opaque hash, nested roundtrip' => sub {
    IO::K8s::AutoGen::clear_cache();
    my $schema = {
        type       => 'object',
        properties => {
            blob => { type => 'object', additionalProperties => JSON::MaybeXS::true() },
        },
    };
    my $class = IO::K8s::AutoGen::get_or_generate(
        'test.example.v1.Blobby55a', $schema, {}, 'IO::K8s::_AUTOGEN_karr55a',
    );

    my $info = $class->_k8s_attr_info;
    ok($info->{blob}{is_hash_of_str}, 'additionalProperties: true registers as the opaque hash-of-str shape');

    my $nested = { a => 1, b => { c => 2, d => [ 1, 2, 3 ] } };
    my $obj = $class->new(blob => $nested);
    is_deeply($obj->TO_JSON->{blob}, $nested, 'nested structure under additionalProperties: true round-trips untouched');
};

subtest 'k55: additionalProperties: false ALSO falls back to the same opaque hash (deliberate non-fix)' => sub {
    IO::K8s::AutoGen::clear_cache();
    my $schema = {
        type       => 'object',
        properties => {
            blob => { type => 'object', additionalProperties => JSON::MaybeXS::false() },
        },
    };
    my $class = IO::K8s::AutoGen::get_or_generate(
        'test.example.v1.Blobby55b', $schema, {}, 'IO::K8s::_AUTOGEN_karr55b',
    );

    my $info = $class->_k8s_attr_info;
    ok($info->{blob}{is_hash_of_str}, 'additionalProperties: false is NOT narrowed -- same opaque hash-of-str shape');

    my $nested = { anything => 'goes', nested => { still => 'accepted' } };
    my $obj;
    lives_ok { $obj = $class->new(blob => $nested) }
        'additionalProperties: false does not reject arbitrary keys at construction';
    is_deeply($obj->TO_JSON->{blob}, $nested,
        'and the value round-trips exactly -- false is not enforced as "no extra properties"');
};

subtest 'k55: additionalProperties as an ARRAY/CODE ref is a broken schema -- croaks naming class and field' => sub {
    for my $case (
        [ ARRAY => [] ],
        [ CODE  => sub { 1 } ],
    ) {
        my ($reftype, $bad) = @$case;
        IO::K8s::AutoGen::clear_cache();
        my $def_name  = "test.example.v1.Junky55$reftype";
        my $namespace = "IO::K8s::_AUTOGEN_karr55c_$reftype";
        my $schema = {
            type       => 'object',
            properties => { junk => { type => 'object', additionalProperties => $bad } },
        };
        my $expect_class = IO::K8s::AutoGen::def_to_class($def_name, $namespace);

        throws_ok {
            IO::K8s::AutoGen::get_or_generate($def_name, $schema, {}, $namespace);
        }
            qr/\QadditionalProperties of field 'junk' of $expect_class is a $reftype reference\E/,
            "$reftype ref additionalProperties: croaks naming the field and the class";
    }
};

# ============================================================================
# k56 -- an unresolvable $ref croaks (fail-closed), not silent data loss
# ============================================================================

subtest 'k56: unresolvable $ref on a plain property croaks naming class and field' => sub {
    IO::K8s::AutoGen::clear_cache();
    my $def_name  = 'test.example.v1.Danglio56';
    my $namespace = 'IO::K8s::_AUTOGEN_karr56a';
    my $schema = { type => 'object', properties => {
        name => { type => 'string' },
        spec => { '$ref' => '#/definitions/com.example.v1.MissingDef' },
    } };
    my $expect_class = IO::K8s::AutoGen::def_to_class($def_name, $namespace);
    my $ref_lit = '$ref';    # single-quoted: a literal dollar sign, not interpolation
    my $expect_msg = "Cannot resolve the $ref_lit 'com.example.v1.MissingDef' for field 'spec' of $expect_class";

    throws_ok { IO::K8s::AutoGen::get_or_generate($def_name, $schema, {}, $namespace) }
        qr/\Q$expect_msg\E/,
        'property $ref: croaks naming the missing ref, the field, and the class';
};

subtest 'k56: unresolvable $ref inside array items croaks naming class and field' => sub {
    IO::K8s::AutoGen::clear_cache();
    my $def_name  = 'test.example.v1.Arrayo56';
    my $namespace = 'IO::K8s::_AUTOGEN_karr56b';
    my $schema = { type => 'object', properties => {
        widgets => { type => 'array', items => { '$ref' => '#/definitions/com.example.v1.MissingItem' } },
    } };
    my $expect_class = IO::K8s::AutoGen::def_to_class($def_name, $namespace);
    my $ref_lit = '$ref';
    my $expect_msg = "Cannot resolve the $ref_lit 'com.example.v1.MissingItem' for the items of field 'widgets' of $expect_class";

    throws_ok { IO::K8s::AutoGen::get_or_generate($def_name, $schema, {}, $namespace) }
        qr/\Q$expect_msg\E/,
        'items.$ref: croaks naming the missing ref, the field, and the class';
};

subtest 'k56: unresolvable $ref inside additionalProperties croaks naming class and field' => sub {
    IO::K8s::AutoGen::clear_cache();
    my $def_name  = 'test.example.v1.Mappo56';
    my $namespace = 'IO::K8s::_AUTOGEN_karr56c';
    my $schema = { type => 'object', properties => {
        m => { type => 'object', additionalProperties => { '$ref' => '#/definitions/com.example.v1.MissingMap' } },
    } };
    my $expect_class = IO::K8s::AutoGen::def_to_class($def_name, $namespace);
    my $ref_lit = '$ref';
    my $expect_msg = "Cannot resolve the $ref_lit 'com.example.v1.MissingMap' for the additionalProperties of field 'm' of $expect_class";

    throws_ok { IO::K8s::AutoGen::get_or_generate($def_name, $schema, {}, $namespace) }
        qr/\Q$expect_msg\E/,
        'additionalProperties.$ref: croaks naming the missing ref, the field, and the class';
};

subtest 'k56/k60: a GVK class\'s own metadata $ref is skipped before lookup -- the realistic single-CRD-schema case' => sub {
    # A CRD schema shipped on its own very commonly references the stock
    # ObjectMeta for 'metadata' without embedding ObjectMeta's own
    # definition -- $all_defs is empty here on purpose. Without the k60 skip,
    # this would trip the k56 refusal above over a field the APIObject role
    # supplies anyway.
    my $make_schema = sub {
        my (%gvk) = @_;
        return {
            type => 'object',
            (%gvk ? ('x-kubernetes-group-version-kind' => [ \%gvk ]) : ()),
            properties => {
                apiVersion => { type => 'string' },
                kind       => { type => 'string' },
                metadata   => { '$ref' => '#/definitions/io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta' },
                spec       => { type => 'object', properties => { domain => { type => 'string' } } },
            },
        };
    };

    # Path 1: GVK comes from the schema's own x-kubernetes-group-version-kind.
    IO::K8s::AutoGen::clear_cache();
    my $class_a;
    lives_ok {
        $class_a = IO::K8s::AutoGen::get_or_generate(
            'com.example.homelab.v1.SiteA56',
            $make_schema->(group => 'homelab.example.com', version => 'v1', kind => 'SiteA'),
            {}, 'IO::K8s::_AUTOGEN_karr56d',
        );
    } 'schema-GVK class with an unresolvable metadata $ref generates without dying';

    # D10: spec (`type: object` with properties) is now a typed nested class
    # rather than the opaque hash it used to be, so it needs an instance of
    # that class -- incidental to what this subtest actually pins (the
    # metadata $ref skip), but construction still has to match the shape.
    my $obj_a = $class_a->new(
        spec     => "${class_a}::Spec"->new(domain => 'a.example.com'),
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(name => 'site-a'),
    );
    isa_ok($obj_a->metadata, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta',
        'metadata is the real stock ObjectMeta, not an opaque fallback');
    is($obj_a->TO_JSON->{metadata}{name}, 'site-a', 'metadata round-trips through TO_JSON');
    is($obj_a->TO_JSON->{apiVersion}, 'homelab.example.com/v1', 'apiVersion comes from the GVK, not a skipped property');
    is($obj_a->TO_JSON->{kind}, 'SiteA', 'kind comes from the GVK, not a skipped property');

    # Path 2: GVK comes from explicit opts instead -- no schema GVK at all.
    IO::K8s::AutoGen::clear_cache();
    my $class_b;
    lives_ok {
        $class_b = IO::K8s::AutoGen::get_or_generate(
            'com.example.homelab.v1.SiteB56', $make_schema->(),
            {}, 'IO::K8s::_AUTOGEN_karr56e',
            api_version => 'homelab.example.com/v1', kind => 'SiteB',
        );
    } 'opts-GVK class with an unresolvable metadata $ref generates without dying';

    my $obj_b = $class_b->new(
        spec     => "${class_b}::Spec"->new(domain => 'b.example.com'),
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(name => 'site-b'),
    );
    is($obj_b->TO_JSON->{apiVersion}, 'homelab.example.com/v1', 'apiVersion comes from the opt');
    is($obj_b->TO_JSON->{kind}, 'SiteB', 'kind comes from the opt');

    # Control: WITHOUT a GVK, the same metadata $ref is NOT exempt -- it goes
    # through the ordinary property path and hits the k56 refusal like any
    # other unresolved $ref. This is what proves the skip is tied to
    # role_supplied (GVK-bearing classes only), not a blanket "always skip
    # metadata" shortcut that would quietly reintroduce k56 for a class that
    # never gets the APIObject role to supply metadata for it.
    IO::K8s::AutoGen::clear_cache();
    my $ref_lit = '$ref';
    throws_ok {
        IO::K8s::AutoGen::get_or_generate(
            'com.example.homelab.v1.SiteC56', $make_schema->(),
            {}, 'IO::K8s::_AUTOGEN_karr56f',
        );
    }
        qr/\QCannot resolve the $ref_lit 'io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta' for field 'metadata'\E/,
        'without a GVK, the same metadata $ref is NOT exempt and croaks like any other unresolved $ref';
};

# ============================================================================
# k57 -- items: { type: boolean } generates [Bool], not ['Str']
# ============================================================================

subtest 'k57: boolean array items produce the [Bool] Type::Tiny form, not the bareword class-name trap' => sub {
    IO::K8s::AutoGen::clear_cache();
    my $schema = { type => 'object', properties => {
        flags => { type => 'array', items => { type => 'boolean' } },
    } };
    my $class = IO::K8s::AutoGen::get_or_generate(
        'test.example.v1.Flaggy57', $schema, {}, 'IO::K8s::_AUTOGEN_karr57',
    );

    my $info = $class->_k8s_attr_info;
    ok($info->{flags}{is_array_of_bool}, 'registry marks flags as is_array_of_bool');
    # The bareword-fallback trap this pins against: ['Bool'] (a plain string,
    # not the Type::Tiny object) is read by the DSL as a class name and would
    # register as is_array_of_objects pointing at a class IO::K8s::Api::Bool.
    ok(!$info->{flags}{is_array_of_objects}, 'flags did NOT fall back to the bareword/class-name misparse');
    ok(!$info->{flags}{class}, 'flags carries no object class -- confirms the [Bool] Type::Tiny path was taken');

    # Every input form a Kubernetes client might hand in normalizes to a real
    # plain 0/1 and serializes as a real JSON boolean -- the same matrix
    # t/53_bool_normalization.t pins for is_bool/is_array_of_bool generally,
    # proven reachable here for an AutoGen-generated attribute specifically.
    my @in   = ( JSON::MaybeXS::true(), JSON::MaybeXS::false(), 'true', 'false', 1, 0, \1, \0 );
    my @want = ( 1, 0, 1, 0, 1, 0, 1, 0 );

    my $obj = $class->new(flags => \@in);
    is_deeply($obj->flags, \@want, 'every input form normalizes to plain 0/1');

    my $expected_json = '{"flags":[' . join(',', map { json_bool_name($_) } @want) . ']}';
    is($obj->to_json, $expected_json, 'array of bool serializes as real JSON booleans, not quoted strings');

    # k51 interplay: an undef ELEMENT still passes the constructor (the
    # [Bool] coercer's `return undef` keeps the array position, same as any
    # other is_array_of_bool attribute) and only dies later, in TO_JSON,
    # naming field and index. The message itself is pinned by the other
    # agent's lane (t/53_bool_normalization.t /
    # t/56_serialization_k51_54_59.t); this only needs to confirm a
    # generated class reaches the same coercer and the same TO_JSON refusal,
    # not a different (or missing) one.
    my $obj_with_undef;
    lives_ok { $obj_with_undef = $class->new(flags => [ JSON::MaybeXS::true(), undef ]) }
        'an undef element in a generated is_array_of_bool attribute still passes the constructor (k51 semantics)';
    dies_ok { $obj_with_undef->TO_JSON }
        'but TO_JSON refuses to serialize it rather than silently emitting a false for that element';
};

# ============================================================================
# k60 -- kind()/apiVersion() are real class-method constants; the
# properties are excluded from the k8s attribute registry entirely
# ============================================================================

subtest 'k60: GVK properties excluded from the registry (schema-GVK path)' => sub {
    IO::K8s::AutoGen::clear_cache();
    my $schema = {
        type                                 => 'object',
        'x-kubernetes-group-version-kind' => [{
            group => 'homelab.example.com', version => 'v1', kind => 'StaticWebSite60',
        }],
        properties => {
            apiVersion => { type => 'string' },
            kind       => { type => 'string' },
            metadata   => { '$ref' => '#/definitions/io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta' },
            spec       => { type => 'object', properties => { domain => { type => 'string' } } },
        },
    };
    my $class = IO::K8s::AutoGen::get_or_generate(
        'com.example.homelab.v1.StaticWebSite60', $schema, {}, 'IO::K8s::_AUTOGEN_karr60a',
    );

    my $info = $class->_k8s_attr_info;
    ok(!exists $info->{apiVersion}, 'registry has no apiVersion entry -- it is not a k8s data field');
    ok(!exists $info->{kind}, 'registry has no kind entry -- it is not a k8s data field');
    ok(exists $info->{spec}, 'registry still carries the real data field spec');

    ok(!$class->can('apiVersion'), 'apiVersion has no accessor at all on a GVK class');

    # D10: spec is a typed nested class now, not the opaque hash it used to
    # be -- incidental to what this subtest pins (the GVK-property exclusion).
    my $obj = $class->new(
        spec     => "${class}::Spec"->new(domain => 'x.example.com'),
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(name => 'site'),
    );

    # k60's more severe half: apiVersion used to stay a writable
    # attribute whose stored value overwrote the role-correct apiVersion in
    # TO_JSON on every emit. With no accessor at all, there is no write path
    # left to smuggle a false GVK through -- pin that the method plainly does
    # not exist, not merely that it happens to be a documented no-op.
    throws_ok { $obj->apiVersion('other/v9') }
        qr/Can't locate object method "apiVersion"/,
        'apiVersion has no setter -- calling it dies outright instead of silently accepting a fake GVK';
    is($obj->TO_JSON->{apiVersion}, 'homelab.example.com/v1',
        'TO_JSON apiVersion is unaffected by the (nonexistent) write attempt');

    # kind() IS defined (as the GVK class method) but is derived and read-only.
    # k67 turned the former silent no-op into a fail-closed croak, so a
    # caller who believes they retargeted the object finds out at once.
    throws_ok { $obj->kind('Other') }
        qr/kind is fixed for this class and cannot be set/,
        'kind("Other") croaks -- a fixed identity accessor rejects a write (k67)';
    is($obj->kind, 'StaticWebSite60', 'kind is unchanged -- the rejected call wrote nothing');
    is($obj->TO_JSON->{kind}, 'StaticWebSite60', 'TO_JSON kind still reports the real GVK kind');
};

subtest 'k60: GVK properties excluded from the registry (opts-only path -- --api_version/--kind)' => sub {
    IO::K8s::AutoGen::clear_cache();
    my $schema = { type => 'object', properties => {
        apiVersion => { type => 'string' },
        kind       => { type => 'string' },
        spec       => { type => 'object', properties => { schedule => { type => 'string' } } },
    } };
    my $class = IO::K8s::AutoGen::get_or_generate(
        'com.example.homelab.v1.BackupSchedule60', $schema, {}, 'IO::K8s::_AUTOGEN_karr60b',
        api_version     => 'homelab.example.com/v1',
        kind            => 'BackupSchedule60',
        resource_plural => 'backupschedules60',
        is_namespaced   => 1,
    );

    my $info = $class->_k8s_attr_info;
    ok(!exists $info->{apiVersion}, 'opts path: no apiVersion entry either');
    ok(!exists $info->{kind}, 'opts path: no kind entry either');
    ok(!$class->can('apiVersion'), 'opts path: apiVersion has no accessor');

    my $obj = $class->new(spec => "${class}::Spec"->new(schedule => '0 2 * * *'));
    is($obj->TO_JSON->{apiVersion}, 'homelab.example.com/v1', 'TO_JSON apiVersion comes from the opt');
    is($obj->TO_JSON->{kind}, 'BackupSchedule60', 'TO_JSON kind comes from the opt');
    throws_ok { $obj->apiVersion('nope/v1') }
        qr/Can't locate object method "apiVersion"/,
        'opts path: apiVersion still has no setter';
};

done_testing;
