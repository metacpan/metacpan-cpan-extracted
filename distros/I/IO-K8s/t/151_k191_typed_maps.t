#!/usr/bin/env perl
# k191: a map-of-Str field (labels, annotations, ConfigMap data, ...) must put
# JSON STRINGS on the wire. Before k191 { Str => 1 } was the opaque map, so a
# numeric Perl value went out as a JSON number and the API server answered 400.
# Design (spec 2026-09-30-io-k8s-typed-maps-design.md, approved by Getty):
#
#   Opaque / HashRef     free map, values copied through (flag is_hash_opaque)
#   HashRef[Str]         string map: strict, scalars stringified (is_hash_of_str)
#   HashRef[X]           typed map, identical to the legacy { X => 1 }
#   { Str => 1 } legacy  string map, lenient: a REF value passes through and
#                        warns once per class+field (is_hash_of_str_lenient)
#
# Every fixture is declared through string eval so that, while the DSL forms
# do not exist yet, the affected subtest fails on its own instead of the whole
# file dying at compile time. Wire types are checked over JSON text (a Perl
# comparison cannot tell 10 from "10"). No network, no cluster.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use JSON::MaybeXS ();
use IO::K8s;
use IO::K8s::CRD;
use IO::K8s::CRD::Emitter;
use IO::K8s::AutoGen;

my $k8s  = IO::K8s->new;
my $true = JSON::MaybeXS::true();
my $json = JSON::MaybeXS->new(canonical => 1, convert_blessed => 1);

# Build a fixture package from DSL source. Returns the package name, or undef
# (and diag) when the declaration does not compile/run.
sub fixture {
    my ($pkg, $base, $body) = @_;
    my $ok = eval "package $pkg; use $base" . ($base =~ /APIObject/
        ? " api_version => 'k191.example.com/v1', resource_plural => '" . lc($pkg =~ s/\W//gr) . "s';"
        : ';') . " $body; 1";
    unless ($ok) {
        diag "fixture $pkg failed: $@";
        return;
    }
    return $pkg;
}

# ============================================================================
# 1. The card's repro
# ============================================================================

subtest 'card repro: numeric values in labels/annotations/data are JSON strings' => sub {
    my $n = 5;
    my $s = '10';
    my $unused = $s + 0;    # $s is now a string used in numeric context
    my $cm = $k8s->new_object('ConfigMap',
        metadata => {
            name        => 'y',
            labels      => { v => $n + 0, s => $s },
            annotations => { a => $n * 3 },
        },
        data => { a => $n * 2, b => $s, c => 'plain' },
    );

    my $text = $cm->to_json;
    like($text, qr/"v":"5"/,   'labels: $n+0 is a JSON string');
    like($text, qr/"s":"10"/,  'labels: string used as number is a JSON string');
    like($text, qr/"a":"15"/,  'annotations: $n*3 is a JSON string');
    like($text, qr/"a":"10"/,  'data: $n*2 is a JSON string');
    like($text, qr/"b":"10"/,  'data: string used as number is a JSON string');
    unlike($text, qr/"(?:v|s|a|b)":\d/, 'no map value is a bare JSON number');

    my $re = $json->encode($cm->TO_JSON);
    like($re, qr/"v":"5"/, 'TO_JSON + canonical re-encode agrees');
    like($re, qr/"a":"10"/, 'TO_JSON data + canonical re-encode agrees');

    my $yaml = $cm->to_yaml;
    like($yaml, qr/^\s+a: '10'$/m, 'to_yaml quotes the stringified value');
    like($yaml, qr/^\s+v: '5'$/m,  'to_yaml quotes the label value');
};

# ============================================================================
# 2. Guard: Opaque and bare HashRef keep numbers
# ============================================================================

subtest 'GUARD: Opaque and HashRef fields keep replicas => 3 as a JSON number' => sub {
    my $class = fixture('Test::K191::Free', 'IO::K8s::APIObject',
        'k8s foo => Opaque; k8s baz => HashRef;')
        or return fail('fixture with Opaque and HashRef declares');
    ok(1, 'fixture with Opaque and HashRef declares');

    my $o = $class->new(
        metadata => { name => 'x' },
        foo      => { replicas => 3, enabled => $true, nested => { n => 1 }, list => [ 1, 2 ] },
        baz      => { replicas => 3, nested => { n => 1 } },
    );
    # Each map is encoded on its own: in canonical order "nested":{...}
    # precedes "replicas", so a regex over the whole document cannot pin
    # replicas to its map with [^}]* (the claim is unchanged).
    my $struct = $o->TO_JSON;
    my ($foo, $baz) = map { $json->encode($struct->{$_}) } qw( foo baz );
    like($foo, qr/"replicas":3(?:,|\})/,  'Opaque: integer stays a number');
    like($foo, qr/"enabled":true/,        'Opaque: boolean stays a boolean');
    like($foo, qr/"n":1(?:,|\})/,         'Opaque: nested integer stays a number');
    like($baz, qr/"replicas":3(?:,|\})/,  'HashRef: integer stays a number');
    like($o->to_json, qr/"replicas":3(?:,|\})/, 'to_json agrees');

    my $info = $class->_k8s_attr_info;
    ok($info->{foo}{is_hash_opaque}, 'Opaque sets is_hash_opaque');
    ok($info->{baz}{is_hash_opaque}, 'bare HashRef sets is_hash_opaque');
    ok(!$info->{$_}{is_hash_of_str}, "$_ is not a string map") for qw( foo baz );
};

# ============================================================================
# 3. HashRef[Str]: strict
# ============================================================================

subtest 'HashRef[Str] rejects reference values and stringifies scalars' => sub {
    my $class = fixture('Test::K191::StrMap', 'IO::K8s::Resource', 'k8s m => HashRef[Str]')
        or return fail('fixture with HashRef[Str] declares');
    ok(1, 'fixture with HashRef[Str] declares');

    throws_ok { $class->new(m => { a => { x => 1 } }) } qr/m|Str|HashRef/, 'hashref value rejected';
    throws_ok { $class->new(m => { a => [1] }) }        qr/m|Str|HashRef/, 'arrayref value rejected';

    my $n = 7;
    my $o = $class->new(m => { a => $n + 0, b => 'x', c => 0 });
    my $text = $o->to_json;
    like($text, qr/"a":"7"/, 'number is a JSON string');
    like($text, qr/"b":"x"/, 'string stays a string');
    like($text, qr/"c":"0"/, 'zero is a JSON string');
    unlike($text, qr/"[abc]":\d/, 'no bare number');
    is($class->new(m => { a => 1 })->TO_JSON->{m}{a}, '1', 'TO_JSON value is the string');

    my $info = $class->_k8s_attr_info->{m};
    ok($info->{is_hash_of_str},           'is_hash_of_str set');
    ok(!$info->{is_hash_of_str_lenient},  'strict form: no lenient marker');
    ok(!$info->{is_hash_opaque},          'not opaque');
};

# ============================================================================
# 4. Legacy { Str => 1 }: lenient, one warning per class+field
# ============================================================================

subtest 'legacy { Str => 1 }: ref value passes through, one warning per class+field' => sub {
    my $a = fixture('Test::K191::LegA', 'IO::K8s::Resource',
        'k8s alphafield => { Str => 1 }; k8s betafield => { Str => 1 }')
        or return fail('legacy fixture A declares');
    my $b = fixture('Test::K191::LegB', 'IO::K8s::Resource',
        'k8s alphafield => { Str => 1 }')
        or return fail('legacy fixture B declares');
    ok(1, 'legacy fixtures declare');

    my $info = $a->_k8s_attr_info->{alphafield};
    ok($info->{is_hash_of_str},         'legacy: is_hash_of_str set');
    ok($info->{is_hash_of_str_lenient}, 'legacy: is_hash_of_str_lenient set');

    my @warn;
    local $SIG{__WARN__} = sub { push @warn, "@_" };
    my $count = sub {
        my ($class, $field) = @_;
        scalar grep { /Opaque|HashRef\[/ && /\Q$class\E/ && /\b\Q$field\E\b/ } @warn;
    };

    # scalars alone never warn, and are stringified
    my $plain = $a->new(alphafield => { v => 5 + 0 });
    like($plain->to_json, qr/"v":"5"/, 'legacy map stringifies scalars');
    is(scalar(@warn), 0, 'scalar values produce no warning') or diag explain \@warn;

    my $o1 = $a->new(alphafield => { x => { n => 1 } });
    my $t1 = $o1->to_json;
    like($t1, qr/"x":\{"n":1\}/, 'ref value passes through unchanged (nested number kept)');
    is_deeply($o1->TO_JSON->{alphafield}, { x => { n => 1 } }, 'TO_JSON structure unchanged');
    $o1->to_json;
    is($count->($a, 'alphafield'), 1, 'serialized twice: exactly one warning');

    $a->new(alphafield => { y => [ 1, 2 ] })->to_json;
    is($count->($a, 'alphafield'), 1, 'second instance: still one warning');

    $a->new(betafield => { z => { n => 1 } })->to_json;
    is($count->($a, 'betafield'), 1, 'another field of the same class warns on its own');
    is($count->($a, 'alphafield'), 1, 'and the first field is not warned again');

    $b->new(alphafield => { x => { n => 1 } })->to_json;
    is($count->($b, 'alphafield'), 1, 'same field name in another class warns on its own');
    is(scalar(@warn), 3, 'three warnings in total') or diag explain \@warn;
};

# ============================================================================
# 5. HashRef[X] == { X => 1 }
# ============================================================================

my %VALID = (
    Int      => { a => 5, b => 0 },
    Num      => { a => 1.5, b => 2 },
    Bool     => { a => 1, b => 0 },
    IntOrStr => { a => 8080, b => 'http' },
    Quantity => { a => '100m', b => 100 },
    Time     => { a => '2026-09-27T12:00:00Z' },
);
my %INVALID = (
    Int => 'abc', Num => 'abc', Bool => 'maybe', IntOrStr => [],
    Quantity => 'banana', Time => 'yesterday',
);
my %FLAG = (
    Int => 'is_hash_of_int', Num => 'is_hash_of_num', Bool => 'is_hash_of_bool',
    IntOrStr => 'is_hash_of_int_or_string', Quantity => 'is_hash_of_quantity',
    Time => 'is_hash_of_time',
);

sub map_flags {
    my ($info) = @_;
    return { map { $_ => 1 } grep { /^is_hash_/ && $info->{$_} } keys %$info };
}

for my $x (sort keys %FLAG) {
    subtest "HashRef[$x] is equivalent to { $x => 1 }" => sub {
        my $legacy = fixture("Test::K191::Legacy$x", 'IO::K8s::Resource', "k8s m => { $x => 1 }")
            or return fail("legacy { $x => 1 } declares");
        my $typed = fixture("Test::K191::Typed$x", 'IO::K8s::Resource', "k8s m => HashRef[$x]")
            or return fail("HashRef[$x] declares");
        ok(1, 'both forms declare');

        my ($li, $ti) = map { $_->_k8s_attr_info->{m} } $legacy, $typed;
        ok($ti->{ $FLAG{$x} }, "HashRef[$x] sets $FLAG{$x}");
        is_deeply(map_flags($ti), map_flags($li), 'same registry flags');

        lives_ok { $legacy->new(m => $VALID{$x}); $typed->new(m => $VALID{$x}) } 'valid values accepted by both';
        dies_ok  { $legacy->new(m => { bad => $INVALID{$x} }) } 'legacy rejects an invalid value';
        dies_ok  { $typed->new(m => { bad => $INVALID{$x} }) }  'HashRef[X] rejects an invalid value';

        is($typed->new(m => $VALID{$x})->to_json, $legacy->new(m => $VALID{$x})->to_json,
            'same TO_JSON: ' . $legacy->new(m => $VALID{$x})->to_json);
    };
}

subtest 'HashRef[InstanceOf[Class]] is equivalent to the object map { Class => 1 }' => sub {
    fixture('Test::K191::Item', 'IO::K8s::Resource', 'k8s label => Str; k8s weight => Int')
        or return fail('item fixture declares');
    my $legacy = fixture('Test::K191::LegacyObjs', 'IO::K8s::Resource',
        "k8s m => { '+Test::K191::Item' => 1 }")
        or return fail('object map declares');
    my $typed = fixture('Test::K191::TypedObjs', 'IO::K8s::Resource',
        "use Types::Standard qw( InstanceOf ); k8s m => HashRef[InstanceOf['Test::K191::Item']]")
        or return fail('HashRef[InstanceOf[...]] declares');
    ok(1, 'both forms declare');

    my ($li, $ti) = map { $_->_k8s_attr_info->{m} } $legacy, $typed;
    ok($ti->{is_hash_of_objects}, 'is_hash_of_objects set');
    is($ti->{class}, 'Test::K191::Item', 'class recorded');
    is($ti->{class}, $li->{class}, 'same class as the legacy form');
    is_deeply(map_flags($ti), map_flags($li), 'same registry flags');

    my $doc = { m => { one => { label => 'a', weight => 2 } } };
    is($typed->new($doc)->to_json, $legacy->new($doc)->to_json, 'same TO_JSON');
    isa_ok($typed->new($doc)->m->{one}, 'Test::K191::Item', 'value inflated to the class');
    dies_ok { $typed->new(m => { one => 'nope' }) } 'non-object value rejected';
};

# ============================================================================
# 6. Opaque is not parameterizable
# ============================================================================

subtest 'Opaque[...] is a declaration error' => sub {
    ok(eval "package Test::K191::OpaqueOk; use IO::K8s::Resource; k8s x => Opaque; 1",
        'positive control: bare Opaque declares') or diag $@;

    my $ok = eval "package Test::K191::OpaqueBad; use IO::K8s::Resource; k8s x => Opaque[Str]; 1";
    my $err = $@;
    ok(!$ok, 'Opaque[Str] dies at declaration, before any ->new');
    like($err, qr/Opaque/, 'the error names Opaque');
    unlike($err, qr/Bareword|syntax error/, 'and is not merely "Opaque is not imported"');

    require IO::K8s::Types;
    my $type = eval { IO::K8s::Types->get_type('Opaque') };
    ok($type, 'IO::K8s::Types declares Opaque') or return;
    dies_ok { $type->parameterize(IO::K8s::Types->get_type('Str') // Types::Standard::Str()) }
        'Opaque->parameterize dies';
};

# ============================================================================
# 7. CRD, both directions
# ============================================================================

sub flatten {
    my ($v) = @_;
    return { map { $_ => flatten($v->{$_}) } keys %$v } if ref $v eq 'HASH';
    return [ map { flatten($_) } @$v ] if ref $v eq 'ARRAY';
    return ($v ? 1 : 0) if Scalar::Util::blessed($v) && (Scalar::Util::reftype($v) // '') eq 'SCALAR';
    return $v;
}

subtest 'to_crd: string maps -> additionalProperties string, opaque -> preserve-unknown' => sub {
    my $class = fixture('Test::K191::CrdThing', 'IO::K8s::APIObject',
        'k8s legacy => { Str => 1 }; k8s strmap => HashRef[Str]; k8s opq => Opaque; k8s raw => HashRef; k8s ints => HashRef[Int]')
        or return fail('CRD fixture declares');
    ok(1, 'CRD fixture declares');

    my $props = flatten(IO::K8s::CRD::_schema_for_class($class))->{properties};
    my $strmap = { type => 'object', additionalProperties => { type => 'string' } };
    my $opaque = { type => 'object', 'x-kubernetes-preserve-unknown-fields' => 1 };
    is_deeply($props->{legacy}, $strmap, '{ Str => 1 }');
    is_deeply($props->{strmap}, $strmap, 'HashRef[Str]');
    is_deeply($props->{opq},    $opaque, 'Opaque');
    is_deeply($props->{raw},    $opaque, 'HashRef');
    is_deeply($props->{ints}, { type => 'object', additionalProperties => { type => 'integer' } }, 'HashRef[Int]');

    my $crd = $class->to_crd->TO_JSON;
    is_deeply(flatten($crd->{spec}{versions}[0]{schema}{openAPIV3Schema}{properties}{strmap}), $strmap,
        'the same through Class->to_crd');
};

subtest 'AutoGen: schema shapes -> string map, Opaque, typed map (no lenient marker)' => sub {
    my $gen = IO::K8s::AutoGen::get_or_generate('com.example.v1.K191Maps', {
        type       => 'object',
        properties => {
            strs => { type => 'object', additionalProperties => { type => 'string' } },
            free => { type => 'object' },
            pres => { type => 'object', 'x-kubernetes-preserve-unknown-fields' => $true },
            ints => { type => 'object', additionalProperties => { type => 'integer' } },
        },
    }, {}, 'IO::K8s::_AUTOGEN_k191');
    my $info = $gen->_k8s_attr_info;

    ok($info->{strs}{is_hash_of_str}, 'additionalProperties string: is_hash_of_str');
    ok(!$info->{strs}{is_hash_of_str_lenient}, '... without the lenient marker');
    ok(!$info->{strs}{is_hash_opaque}, '... and not opaque');
    for my $f (qw( free pres )) {
        ok($info->{$f}{is_hash_opaque}, "$f: is_hash_opaque");
        ok(!$info->{$f}{is_hash_of_str}, "$f: not a string map");
    }
    ok($info->{ints}{is_hash_of_int}, 'additionalProperties integer: is_hash_of_int');

    my $o = $gen->new(strs => { a => 10 + 0 }, free => { replicas => 3 });
    like($o->to_json, qr/"a":"10"/, 'generated string map stringifies');
    like($o->to_json, qr/"replicas":3(?:,|\})/, 'generated opaque map keeps the number');
};

subtest 'Emitter: every map form survives render -> compile' => sub {
    my $class = fixture('Test::K191::EmitThing', 'IO::K8s::Resource',
        'k8s legacy => { Str => 1 }; k8s strmap => HashRef[Str]; k8s opq => Opaque; k8s ints => HashRef[Int]')
        or return fail('emitter fixture declares');
    ok(1, 'emitter fixture declares');

    my $files;
    lives_ok { $files = IO::K8s::CRD::Emitter->new(base => 'TestK191Emit::V1')->render($class) }
        'render does not croak on the new map flags' or return;
    my ($src) = values %$files;
    ok(eval "$src\n1;", 'emitted source compiles') or return diag $@;

    my $orig = $class->_k8s_attr_info;
    my $back = TestK191Emit::V1::EmitThing->_k8s_attr_info;
    for my $f (qw( strmap opq ints )) {
        is_deeply(map_flags($back->{$f}), map_flags($orig->{$f}), "$f: same map flags after the round trip");
    }
    ok($back->{strmap}{is_hash_of_str} && !$back->{strmap}{is_hash_of_str_lenient},
        'HashRef[Str] comes back strict');
    ok($back->{opq}{is_hash_opaque}, 'Opaque comes back opaque');
    ok($back->{legacy}{is_hash_of_str}, '{ Str => 1 } comes back as a string map');
};

done_testing;
