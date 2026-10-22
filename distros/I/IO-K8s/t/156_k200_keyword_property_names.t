#!/usr/bin/env perl
# k200: a CRD property named like a Moo keyword / imported type (after,
# before, with, extends, has, Str, ...) or like a real method (new, meta,
# does, can, isa, import) made add_crd refuse the whole CRD (Kong's
# KongPlugin has ordering.before / ordering.after). Two JSON keys that
# sanitize to one accessor (a-b, a_b) ended the same way.
#
# Claims, all on the wire JSON and independent of how a colliding accessor
# is renamed:
#   * the CRD loads and the keys survive TO_JSON / to_yaml under their
#     original names, with the right values;
#   * constructing from the original key sets the value, and the round-trip
#     (TO_JSON -> inflate -> TO_JSON) is lossless;
#   * a property colliding with a real method does not stop the CRD and
#     does not break that method;
#   * a-b and a_b in one object are both kept.
#
# Pure local fixtures -- no network, no cluster.
use strict;
use warnings;
use Test::More;
use Test::Exception;
use YAML::XS ();

use IO::K8s;

sub crd {
    my ($kind, $spec_props) = @_;
    return {
        apiVersion => 'apiextensions.k8s.io/v1',
        kind       => 'CustomResourceDefinition',
        metadata   => { name => lc($kind).'s.k200.example.com' },
        spec       => {
            group    => 'k200.example.com',
            names    => { kind => $kind, plural => lc($kind).'s', singular => lc($kind) },
            scope    => 'Namespaced',
            versions => [{
                name    => 'v1',
                served  => \1,
                storage => \1,
                schema  => { openAPIV3Schema => {
                    type       => 'object',
                    properties => {
                        spec => { type => 'object', properties => $spec_props },
                    },
                } },
            }],
        },
    };
}

sub build {
    my ($kind, $props, $spec) = @_;
    my $k8s = IO::K8s->new;
    lives_ok { $k8s->add_crd(crd($kind, $props)) } "$kind: add_crd lives"
        or return;
    my $obj;
    lives_ok {
        $obj = $k8s->new_object($kind, metadata => { name => 'x', namespace => 'd' }, spec => $spec)
    } "$kind: object builds from the original JSON keys"
        or return;
    return ($k8s, $obj);
}

my $kong_props = {
    ordering => { type => 'object', properties => {
        before => { type => 'object', properties => {
            access => { type => 'array', items => { type => 'string' } } } },
        after  => { type => 'object', properties => {
            access => { type => 'array', items => { type => 'string' } } } },
    } },
    with    => { type => 'string' },
    extends => { type => 'string' },
    has     => { type => 'integer' },
    Str     => { type => 'string' },
    around  => { type => 'boolean' },
};
my $kong_spec = {
    ordering => {
        before => { access => ['a1', 'a2'] },
        after  => { access => ['z1'] },
    },
    with => 'w', extends => 'e', has => 7, Str => 's', around => \1,
};

subtest 'Kong-style KongPlugin: keyword-named properties round-trip' => sub {
    my ($k8s, $obj) = build('KongPlugin', $kong_props, $kong_spec);
    return unless $obj;

    my $json = $obj->TO_JSON;
    is_deeply($json->{spec}{ordering}{before}{access}, ['a1', 'a2'], 'ordering.before survives');
    is_deeply($json->{spec}{ordering}{after}{access}, ['z1'], 'ordering.after survives');
    is($json->{spec}{with}, 'w', 'with');
    is($json->{spec}{extends}, 'e', 'extends');
    is($json->{spec}{Str}, 's', 'Str');
    is($json->{spec}{has}, 7, 'has value');
    like($obj->to_json, qr/"has":7\b/, 'integer has is unquoted on the wire');
    like($obj->to_json, qr/"around":true\b/, 'boolean around is a JSON true');

    my $yaml = YAML::XS::Load($obj->to_yaml);
    is($yaml->{spec}{ordering}{after}{access}[0], 'z1', 'to_yaml carries ordering.after');
    is($yaml->{spec}{with}, 'w', 'to_yaml carries with');
    is($yaml->{spec}{Str}, 's', 'to_yaml carries Str');

    my $back = $k8s->inflate($obj->to_json);
    is_deeply($back->TO_JSON, $json, 'TO_JSON -> inflate -> TO_JSON is lossless');
    is($back->api_version, 'k200.example.com/v1', 'identity intact');
    is($back->kind, 'KongPlugin', 'kind intact');
    ok($obj->can('TO_JSON') && $obj->can('spec_get'), 'role methods still present');
};

subtest 'properties colliding with real methods: CRD loads, JSON keys kept' => sub {
    my @names = qw( new meta does can isa import );
    my %props = map +($_ => { type => 'string' }), @names;
    my %spec  = map +($_ => "v_$_"), @names;
    my ($k8s, $obj) = build('Clashy', \%props, \%spec);
    return unless $obj;

    my $json = $obj->TO_JSON;
    is($json->{spec}{$_}, "v_$_", "wire key '$_' kept") for @names;
    my $back = $k8s->inflate($obj->to_json);
    is_deeply($back->TO_JSON, $json, 'round-trip lossless');

    my $spec_class = ref $obj->spec;
    isa_ok($spec_class->new, $spec_class, 'new still constructs');
    ok($spec_class->can('meta'), 'meta still a method');
    ok($spec_class->does('IO::K8s::Role::Resource'), 'does still answers for the role');
    ok($spec_class->isa('Moo::Object'), 'isa still answers');
    ok($spec_class->can('can'), 'can still answers');
    is($spec_class->new(map +($_ => "x_$_"), @names)->TO_JSON->{new}, 'x_new',
        'constructing with the original key sets the value');
};

subtest 'a-b and a_b in one object are both kept' => sub {
    my ($k8s, $obj) = build('Hyphen',
        { 'a-b' => { type => 'string' }, a_b => { type => 'string' } },
        { 'a-b' => 'dash', a_b => 'under' });
    return unless $obj;
    my $json = $obj->TO_JSON;
    is($json->{spec}{'a-b'}, 'dash', 'a-b kept');
    is($json->{spec}{a_b}, 'under', 'a_b kept');
    is_deeply($k8s->inflate($obj->to_json)->TO_JSON, $json, 'round-trip lossless');
};

done_testing;
