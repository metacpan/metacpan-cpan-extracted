#!/usr/bin/env perl
# k150: IO::K8s::AutoGen declared a top-level class's properties BEFORE it
# composed IO::K8s::Role::APIObject. Role::Tiny's "class wins" then let a
# property whose accessor has the name of a role method (label, save,
# is_ready, spec_get, ...) silently replace that method -- the k144
# declaration preflight only ever sees the other order, role first, which is
# the one the hand-written `use IO::K8s::APIObject` path always takes.
#
# AutoGen now composes the role in that same order -- identity methods, role,
# metadata adoption, then the properties -- so the k144 preflight refuses
# such a property. Refusing is a failed generation run (k149).
#
# Claims:
#   * a top-level property colliding with a Role::APIObject or SpecBuilder
#     method, or with an identity method (api_version, resource_plural), is
#     refused naming the class, the property and the method, through
#     get_or_generate, IO::K8s->inflate with an openapi_spec and add_crd;
#   * the refusal is a failed run: asking again rethrows the remembered
#     error and the class is never listed as generated;
#   * the exceptions k144 set still hold -- a `conditions` property takes
#     over the yielding helper, `metadata` is the adopted role attribute,
#     `apiVersion` and `kind` stay the class's fixed identity -- and the role
#     helpers work on a generated class, all checked on the wire JSON;
#   * a nested class never composes the role, so the same names are plain
#     fields there and round-trip.
#
# Pure local fixtures -- no network, no cluster.
use strict;
use warnings;
use Test::More;
use Test::Exception;
use JSON::MaybeXS ();

use IO::K8s;
use IO::K8s::AutoGen;

my $json = JSON::MaybeXS->new(canonical => 1, utf8 => 1);

sub gvk_def {
    my ($kind, %props) = @_;
    return {
        type => 'object',
        'x-kubernetes-group-version-kind' =>
            [{ group => 'k150.example.com', version => 'v1', kind => $kind }],
        properties => { spec => { type => 'object' }, %props },
    };
}

sub generate {
    my ($kind, $ns, %props) = @_;
    return IO::K8s::AutoGen::get_or_generate(
        "com.example.k150.v1.$kind", gvk_def($kind, %props), {},
        "IO::K8s::_AUTOGEN_k150_$ns",
        api_version => 'k150.example.com/v1', kind => $kind, resource_plural => lc($kind).'s');
}

# k200 changed the outcome of the collision from "refused" to "renamed":
# the claim k150 protects -- a property must never silently replace a role
# method -- is kept, but the property now gets an underscore-prefixed
# accessor with its JSON key unchanged instead of failing the generation.
subtest 'a property named like a role method keeps the method and gets a renamed accessor' => sub {
    for my $case (
        [ label         => { type => 'string' },  'v' ],     # Role::APIObject helper
        [ save          => { type => 'string' },  'v' ],
        [ is_ready      => { type => 'boolean' }, JSON::MaybeXS::true ],
        [ owner_refs    => { type => 'array', items => { type => 'string' } }, ['o'] ],
        [ spec_get      => { type => 'string' },  'v' ],     # SpecBuilder, composed by the role
        [ to_crd        => { type => 'object', properties => { a => { type => 'string' } } }, { a => 'v' } ],
        [ api_version   => { type => 'string' },  'v' ],     # identity methods
        [ resource_plural => { type => 'string' }, 'v' ],
    ) {
        my ($prop, $schema, $value) = @$case;
        (my $kind = "Clash_$prop") =~ s/_(\w)/\u$1/g;
        my $role_method = do {
            # the method as the role (or identity) gives it, before the property exists
            my $probe = IO::K8s::AutoGen::get_or_generate(
                "com.example.k150.v1.${kind}Probe", gvk_def("${kind}Probe"), {},
                "IO::K8s::_AUTOGEN_k150_probe_$prop",
                api_version => 'k150.example.com/v1', kind => "${kind}Probe", resource_plural => lc($kind).'probes');
            $probe->can($prop);
        };
        my $class;
        lives_ok { $class = generate($kind, $prop, $prop => $schema) }
            "$prop is accepted";
        next unless $class;
        ok($class->can("_$prop"), "$prop gets the renamed accessor _$prop");
        my $obj = $class->new($prop => $value);
        is_deeply($obj->TO_JSON->{$prop}, $value, "$prop keeps its JSON key and value on the wire");
        ok($role_method, "$prop is a method of a class without the property");
        # the method of that name is not the property's accessor: it is
        # not the one the renamed attribute reads
        isnt($class->can($prop), $class->can("_$prop"), "$prop is still a method, distinct from the accessor");
    }
};

subtest 'a colliding property no longer fails the generation run (k149 remembered failures stay in t/110)' => sub {
    my $class = IO::K8s::AutoGen::def_to_class('com.example.k150.v1.Remembered', 'IO::K8s::_AUTOGEN_k150_run');
    my $first;
    lives_ok { $first = generate('Remembered', 'run', add_label => { type => 'string' }) }
        'first request generates the class';
    is(eval { generate('Remembered', 'run', add_label => { type => 'string' }) }, $first,
        'second request returns the same class');
    ok((grep { $_ eq $class } IO::K8s::AutoGen::generated_classes()),
        'the class is listed as generated');
    ok($first->can('_add_label'), 'add_label property got the renamed accessor');
    is($first->new(add_label => 'x')->TO_JSON->{add_label}, 'x', 'and keeps its JSON key');
    my $o = $first->new(metadata => { name => 'x' });
    $o->add_label(tier => 'web');
    ok($o->has_label('tier'), 'the role helper add_label is still the role helper');
};

subtest 'the openapi_spec and add_crd routes rename it as well' => sub {
    my $k8s = IO::K8s->new(openapi_spec => { definitions => {
        'com.example.k150.v1.Dial' => gvk_def('Dial', match_labels => { type => 'string' }),
    } });
    my $dial;
    lives_ok { $dial = $k8s->inflate({ apiVersion => 'k150.example.com/v1', kind => 'Dial', match_labels => 'x' }) }
        'inflate through an openapi_spec';
    is($dial && $dial->TO_JSON->{match_labels}, 'x', 'match_labels keeps its JSON key on the wire') if $dial;
    ok($dial && $dial->can('_match_labels'), 'and gets the renamed accessor') if $dial;

    my $crd = {
        apiVersion => 'apiextensions.k8s.io/v1',
        kind       => 'CustomResourceDefinition',
        metadata   => { name => 'knobs.k150.example.com' },
        spec       => {
            group => 'k150.example.com',
            names => { kind => 'Knob', plural => 'knobs', singular => 'knob', listKind => 'KnobList' },
            scope => 'Namespaced',
            versions => [{
                name => 'v1', served => JSON::MaybeXS::true, storage => JSON::MaybeXS::true,
                schema => { openAPIV3Schema => {
                    type => 'object',
                    properties => { spec => { type => 'object' }, annotation => { type => 'string' } },
                } },
            }],
        },
    };
    my $k = IO::K8s->new;
    lives_ok { $k->add_crd($crd) } 'add_crd';
    my $knob = eval { $k->new_object('Knob', metadata => { name => 'k' }, annotation => 'a') };
    is($knob && $knob->TO_JSON->{annotation}, 'a', 'annotation keeps its JSON key on the wire');
    ok($knob && $knob->can('_annotation'), 'and gets the renamed accessor');
};

subtest 'conditions, metadata, apiVersion and kind keep their k144 treatment on the wire' => sub {
    my $class = generate('Healthy', 'ok',
        apiVersion => { type => 'string' },
        kind       => { type => 'string' },
        metadata   => { '$ref' => '#/definitions/io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta' },
        conditions => { type => 'array', items => {
            type => 'object',
            properties => { type => { type => 'string' }, status => { type => 'string' } },
        } },
        status => { type => 'object', properties => { phase => { type => 'string' } } },
    );
    my $doc = {
        apiVersion => 'k150.example.com/v1',
        kind       => 'Healthy',
        metadata   => { name => 'h1', labels => { app => 'x' } },
        spec       => { anything => 'goes' },
        status     => { phase => 'Running' },
        conditions => [ { type => 'Ready', status => 'True' } ],
    };
    my $obj = IO::K8s->new->struct_to_object("+$class", $doc);

    is($json->encode($json->decode($obj->to_json)), $json->encode($doc),
        'the document round-trips unchanged to the wire JSON');
    ok($obj->is_ready, 'the conditions field feeds the role condition helpers');
    is($obj->conditions->[0]->status, 'True', 'conditions is the declared field');
    isa_ok($obj->metadata, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta', 'metadata');
    throws_ok { $obj->kind('Other') } qr/kind is fixed/, 'kind is the fixed identity, not a field';

    # the role helpers are really there, and write through to the wire
    $obj->add_label(tier => 'web');
    ok($obj->has_label('tier'), 'add_label/has_label work on the generated class');
    is($json->decode($obj->to_json)->{metadata}{labels}{tier}, 'web',
        'the label added through the role reaches the wire JSON');
    is($obj->spec_get('anything'), 'goes', 'SpecBuilder is composed');
};

subtest 'a nested class has no role, so the same names are plain fields' => sub {
    my $class = generate('Holder', 'nested',
        spec => { type => 'object', properties => {
            label    => { type => 'string' },
            is_ready => { type => 'boolean' },
            save     => { type => 'integer' },
        } },
    );
    my $doc = {
        apiVersion => 'k150.example.com/v1',
        kind       => 'Holder',
        spec       => { label => 'l', is_ready => JSON::MaybeXS::false, save => 3 },
    };
    my $obj = IO::K8s->new->struct_to_object("+$class", $doc);
    is($json->encode($json->decode($obj->to_json)), $json->encode($doc),
        'nested label/is_ready/save round-trip as fields');
    is($obj->spec->label, 'l', 'nested label is the field');
};

done_testing;
