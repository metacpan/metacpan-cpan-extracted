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

subtest 'a property named like a role method is refused, naming class, property and method' => sub {
    for my $case (
        [ label         => { type => 'string' } ],     # Role::APIObject helper
        [ save          => { type => 'string' } ],
        [ is_ready      => { type => 'boolean' } ],
        [ owner_refs    => { type => 'array', items => { type => 'string' } } ],
        [ spec_get      => { type => 'string' } ],     # SpecBuilder, composed by the role
        [ to_crd        => { type => 'object' } ],
        [ api_version   => { type => 'string' } ],     # identity methods
        [ resource_plural => { type => 'string' } ],
    ) {
        my ($prop, $schema) = @$case;
        (my $kind = "Clash_$prop") =~ s/_(\w)/\u$1/g;
        my $class = IO::K8s::AutoGen::def_to_class("com.example.k150.v1.$kind", "IO::K8s::_AUTOGEN_k150_$prop");
        throws_ok { generate($kind, $prop, $prop => $schema) }
            qr/field '\Q$prop\E' of \Q$class\E collides with the method '\Q$prop\E'/,
            "$prop is refused, naming the class, the property and the method";
    }
};

subtest 'the refusal is a failed generation run (k149)' => sub {
    my $class = IO::K8s::AutoGen::def_to_class('com.example.k150.v1.Remembered', 'IO::K8s::_AUTOGEN_k150_run');
    throws_ok { generate('Remembered', 'run', add_label => { type => 'string' }) }
        qr/field 'add_label' of \Q$class\E collides with the method 'add_label'/,
        'first request dies on the collision';
    throws_ok { generate('Remembered', 'run', add_label => { type => 'string' }) }
        qr/\Q$class\E failed to generate earlier in this namespace.*collides with the method 'add_label'/s,
        'second request rethrows the remembered original error';
    ok(!(grep { $_ eq $class } IO::K8s::AutoGen::generated_classes()),
        'the class is never listed as generated');
};

subtest 'the openapi_spec and add_crd routes refuse it as well' => sub {
    my $k8s = IO::K8s->new(openapi_spec => { definitions => {
        'com.example.k150.v1.Dial' => gvk_def('Dial', match_labels => { type => 'string' }),
    } });
    throws_ok { $k8s->inflate({ apiVersion => 'k150.example.com/v1', kind => 'Dial', match_labels => 'x' }) }
        qr/field 'match_labels' of \S+::Dial collides with the method 'match_labels'/,
        'inflate through an openapi_spec';

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
    throws_ok { IO::K8s->new->add_crd($crd) }
        qr/field 'annotation' of \S+::Knob collides with the method 'annotation'/,
        'add_crd';
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
