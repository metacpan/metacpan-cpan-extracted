#!/usr/bin/env perl
# k194: map[string][]X (UserInfo.extra, TokenRequestSpec.attestations, ...) used
# to be declared Opaque because the DSL had no form for it. The form is
# HashRef[ArrayRef[X]]: strict (scalars in the arrays are stringified, anything
# that is not an array of scalars is refused at construction), serialized with
# JSON strings, emitted to CRDs as additionalProperties {type: array, items}
# and read back from such a schema by AutoGen as the same strict form.
#
# Fixtures are declared through string eval so that, while the form does not
# exist, the affected subtest fails on its own instead of the whole file dying.
# Wire types are checked over JSON text. No network, no cluster.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use JSON::MaybeXS ();
use YAML::PP ();
use IO::K8s;
use IO::K8s::CRD;
use IO::K8s::AutoGen;

my $k8s  = IO::K8s->new;
my $json = JSON::MaybeXS->new(canonical => 1, convert_blessed => 1);

sub fixture {
    my ($pkg, $base, $body) = @_;
    my $ok = eval "package $pkg; use $base" . ($base =~ /APIObject/
        ? " api_version => 'k194.example.com/v1', resource_plural => '" . lc($pkg =~ s/\W//gr) . "s';"
        : ';') . " $body; 1";
    unless ($ok) {
        diag "fixture $pkg failed: $@";
        return;
    }
    return $pkg;
}

sub flatten {
    my ($v) = @_;
    return { map { $_ => flatten($v->{$_}) } keys %$v } if ref $v eq 'HASH';
    return [ map { flatten($_) } @$v ] if ref $v eq 'ARRAY';
    return $v;
}

subtest 'HashRef[ArrayRef[Str]]: valid values stay, numbers go out as strings' => sub {
    my $class = fixture('Test::K194::Arr', 'IO::K8s::Resource', 'k8s extra => HashRef[ArrayRef[Str]]')
        or return fail('fixture with HashRef[ArrayRef[Str]] declares');
    ok(1, 'fixture declares');

    my $o = $class->new(extra => { groups => [ 'a', 'b' ], none => [] });
    is_deeply($o->extra, { groups => [ 'a', 'b' ], none => [] }, 'valid value kept');
    is($o->to_json, '{"extra":{"groups":["a","b"],"none":[]}}', 'wire: arrays of strings, empty array kept');

    my $n = 7;
    my $num = $class->new(extra => { k => [ $n + 0, 0, 'x' ] });
    my $text = $num->to_json;
    like($text, qr/"k":\["7","0","x"\]/, 'numbers in the array are JSON strings');
    unlike($text, qr/\[\d|,\d/, 'no bare number in any array');
    is($json->encode($num->TO_JSON), $text, 'TO_JSON + canonical re-encode agrees');
};

subtest 'HashRef[ArrayRef[Str]]: wrong shapes are refused at construction' => sub {
    my $class = fixture('Test::K194::Strict', 'IO::K8s::Resource', 'k8s extra => HashRef[ArrayRef[Str]]')
        or return fail('fixture declares');
    ok(1, 'fixture declares');

    dies_ok { $class->new(extra => { k => 'a' }) }            'plain scalar instead of an array';
    dies_ok { $class->new(extra => { k => { a => 1 } }) }     'hashref instead of an array';
    dies_ok { $class->new(extra => { k => undef }) }          'undef instead of an array';
    dies_ok { $class->new(extra => { k => [ { a => 1 } ] }) } 'hashref inside the array';
    dies_ok { $class->new(extra => { k => [ ['a'] ] }) }      'nested arrayref inside the array';
    dies_ok { $class->new(extra => [ 'a' ]) }                 'arrayref instead of the map';
    dies_ok { $class->new(extra => { ok => ['a'], bad => 'b' }) } 'one bad value among good ones';
};

subtest 'round trip: TO_JSON, to_yaml, FROM_HASH' => sub {
    my $class = fixture('Test::K194::Rt', 'IO::K8s::APIObject', 'k8s extra => HashRef[ArrayRef[Str]]')
        or return fail('APIObject fixture declares');
    ok(1, 'fixture declares');

    my $o = $class->new(metadata => { name => 'x' }, extra => { k => [ 'a', 'b' ], j => ['c'] });
    is_deeply($o->TO_JSON->{extra}, { k => [ 'a', 'b' ], j => ['c'] }, 'TO_JSON structure');
    my $back = $class->FROM_HASH($o->TO_JSON);
    is_deeply($back->extra, $o->extra, 'FROM_HASH(TO_JSON) comes back equal');
    is($back->to_json, $o->to_json, 'and serializes identically');

    my $yaml = $o->to_yaml;
    like($yaml, qr/^\s+k:\n\s+- a\n\s+- b$/m, 'to_yaml renders the arrays as sequences');
    my $again = $class->FROM_HASH(YAML::PP->new->load_string($yaml));
    is_deeply($again->extra, $o->extra, 'YAML parse + FROM_HASH comes back equal');
};

subtest 'to_crd: additionalProperties {type: array, items: {type: string}}' => sub {
    my $class = fixture('Test::K194::Crd', 'IO::K8s::APIObject', 'k8s extra => HashRef[ArrayRef[Str]]')
        or return fail('CRD fixture declares');
    ok(1, 'fixture declares');

    my $want = {
        type                 => 'object',
        additionalProperties => { type => 'array', items => { type => 'string' } },
    };
    my $schema = eval { IO::K8s::CRD::_schema_for_class($class) }
        or return fail('_schema_for_class: ' . $@);
    is_deeply(flatten($schema)->{properties}{extra}, $want, '_schema_for_class');
    my $crd = eval { $class->to_crd->TO_JSON } or return fail('to_crd: ' . $@);
    is_deeply(flatten($crd->{spec}{versions}[0]{schema}{openAPIV3Schema}{properties}{extra}), $want,
        'the same through Class->to_crd');
};

subtest 'AutoGen: the CRD schema comes back as the strict HashRef[ArrayRef[Str]]' => sub {
    my $gen = IO::K8s::AutoGen::get_or_generate('com.example.v1.K194Maps', {
        type       => 'object',
        properties => {
            extra => {
                type                 => 'object',
                additionalProperties => { type => 'array', items => { type => 'string' } },
            },
        },
    }, {}, 'IO::K8s::_AUTOGEN_k194');

    my $o;
    lives_ok { $o = $gen->new(extra => { k => ['a'] }) } 'array of strings accepted';
    is($o && $o->to_json, '{"extra":{"k":["a"]}}', 'serializes as arrays');
    like($gen->new(extra => { k => [ 5 + 0 ] })->to_json, qr/"k":\["5"\]/, 'numbers stringified');
    dies_ok { $gen->new(extra => { k => 'a' }) }    'scalar instead of array refused';
    dies_ok { $gen->new(extra => { k => [ {} ] }) } 'hashref in the array refused';
    ok(!$gen->_k8s_attr_info->{extra}{is_hash_opaque}, 'not the opaque map');
};

subtest 'HashRef[ArrayRef[InstanceOf[Class]]]: objects in the arrays round-trip as hashes' => sub {
    fixture('Test::K194::Item', 'IO::K8s::Resource', 'k8s label => Str; k8s weight => Int')
        or return fail('item fixture declares');
    my $class = fixture('Test::K194::Objs', 'IO::K8s::Resource',
        "use Types::Standard qw( InstanceOf ); k8s m => HashRef[ArrayRef[InstanceOf['Test::K194::Item']]]")
        or return fail('HashRef[ArrayRef[InstanceOf[...]]] declares');
    ok(1, 'fixture declares');

    my $doc = { m => { one => [ { label => 'a', weight => 2 }, { label => 'b', weight => 3 } ] } };
    my $o = $class->new($doc);
    isa_ok($o->m->{one}[0], 'Test::K194::Item', 'array element inflated to the class');
    is($o->to_json, '{"m":{"one":[{"label":"a","weight":2},{"label":"b","weight":3}]}}',
        'objects serialize as hashes, Int stays a number');
    is_deeply($o->TO_JSON, $doc, 'TO_JSON equals the input document');
    is_deeply($class->FROM_HASH($o->TO_JSON)->TO_JSON, $doc, 'round trip');
    dies_ok { $class->new(m => { one => ['nope'] }) }         'scalar element refused';
    dies_ok { $class->new(m => { one => { label => 'a' } }) } 'object instead of array refused';
};

subtest 'real class: UserInfo.extra (map[string][]string)' => sub {
    my $info = $k8s->new_object('+IO::K8s::Api::Authentication::V1::UserInfo',
        username => 'alice', extra => { scopes => [ 'a', 'b' ] });
    is($info->to_json, '{"extra":{"scopes":["a","b"]},"username":"alice"}', 'wire form');

    my $back = $k8s->inflate('{"apiVersion":"authentication.k8s.io/v1","kind":"TokenReview",'
        . '"spec":{"token":"t"},"status":{"user":{"username":"alice","extra":{"scopes":["a","b"]}}}}');
    is_deeply($back->status->user->extra, { scopes => [ 'a', 'b' ] }, 'inflate keeps the arrays');
    is_deeply($back->TO_JSON->{status}{user}{extra}, { scopes => [ 'a', 'b' ] }, 'and re-emits them');

    my $n = 3;
    like($k8s->new_object('+IO::K8s::Api::Authentication::V1::UserInfo', extra => { k => [ $n + 0 ] })->to_json,
        qr/"k":\["3"\]/, 'a number in the array goes out as a string');
    dies_ok { $k8s->new_object('+IO::K8s::Api::Authentication::V1::UserInfo', extra => { k => 'a' }) }
        'a scalar instead of an array is refused';
    dies_ok { $k8s->new_object('+IO::K8s::Api::Authentication::V1::UserInfo', extra => { k => [ { a => 1 } ] }) }
        'a hashref inside the array is refused';
};

done_testing;
