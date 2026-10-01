#!/usr/bin/env perl
# k153: a blessed value at an object-bearing position.
#
# k146 made the factory path refuse a defined non-hash value at an object
# position, but deliberately left every blessed value alone:
# _struct_to_object_expanded skipped them and _inflate_struct read them
# through TO_JSON -- or, when there was none, returned {}. So a JSON boolean
# (JSON::PP::Boolean and friends have no TO_JSON) at `metadata`, which is
# what `"metadata": true` decodes to, still came out as an empty ObjectMeta:
#     new_object('Pod', metadata => JSON::PP::true)  ->  metadata: {}
#
# Approved contract:
#   * blessed, no TO_JSON           -> refused like a non-hash value (k146
#                                      message form, the value's class as
#                                      the received form)
#   * blessed, TO_JSON gives a hash -> inflated from that hash, as today
#   * blessed, TO_JSON gives no hash -> refused too
#   * an IO::K8s object of a FOREIGN class -> still converted through its
#     TO_JSON, undeclared fields kept per D1 (dies under strict). AutoGen /
#     CRD classes and core classes of the same shape get mixed in practice
#     (a core LabelSelector handed to a generated selector field); that
#     stays working on purpose.
#   * an instance of the right class, or a subclass of it -> the identical
#     instance, as today.
#
# Messages are matched on class names and forms, never on exact wording.
# Pure local fixtures -- no network, no cluster.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Scalar::Util qw(refaddr);
use JSON::PP ();
use lib 'lib';

use IO::K8s;
use IO::K8s::Api::Core::V1::Pod;
use IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta;
use IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector;

my $META = 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta';
my $PROPS = 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaProps';

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

{
    # Blessed, but nothing to read it through.
    package T153::Opaque;
    sub new { bless {}, shift }
}

{
    # Blessed, TO_JSON hands back something that is not a JSON object.
    package T153::ToJsonArray;
    sub new { bless {}, shift }
    sub TO_JSON { [ 'not', 'an', 'object' ] }
}

{
    # Blessed, not IO::K8s, TO_JSON hands back a proper object.
    package T153::ToJsonHash;
    sub new { bless {}, shift }
    sub TO_JSON { { name => 'from-to-json', labels => { app => 'x' } } }
}

{
    # An IO::K8s class of its own that looks like ObjectMeta plus one field
    # ObjectMeta does not declare.
    package T153::MetaLike;
    use IO::K8s::Resource;
    k8s name  => Str;
    k8s extra => Str;
}

{
    # A CRD whose selector field is typed with its own class, the way a
    # generated class is, rather than with the core LabelSelector.
    package T153::Selector;
    use IO::K8s::Resource;
    k8s matchLabels => { Str => 1 };
}

{
    package T153::Widget;
    use IO::K8s::APIObject api_version => 'test.example.com/v1';
    k8s spec => { selector => '+T153::Selector' };
}

{
    package T153::SubMeta;
    use Moo;
    extends 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta';
}

# Dies naming every pattern in @$res; called once per pattern, the fixtures
# are pure.
sub dies_naming {
    my ($label, $code, @res) = @_;
    for my $re (@res) {
        throws_ok { $code->() } $re, "$label dies matching $re";
    }
}

# ===========================================================================
# RED: blessed values without a usable TO_JSON are refused
# ===========================================================================

# Claim: JSON::PP::true at metadata is not an object and must not become an
# empty ObjectMeta.
subtest 'new_object: metadata => JSON::PP::true dies' => sub {
    dies_naming('metadata=>true',
        sub { IO::K8s->new->new_object('Pod', metadata => JSON::PP::true) },
        qr/ObjectMeta/, qr/JSON::PP::Boolean/);
};

# Claim: a false boolean is refused the same way -- falsiness must not make
# it look like "no value".
subtest 'new_object: metadata => JSON::PP::false dies' => sub {
    dies_naming('metadata=>false',
        sub { IO::K8s->new->new_object('Pod', metadata => JSON::PP::false) },
        qr/ObjectMeta/, qr/JSON::PP::Boolean/);
};

# Claim: the case the card is about -- `"metadata": true` in decoded JSON --
# is refused on the two-argument json_to_object path, whatever boolean class
# the JSON backend uses.
subtest 'json_to_object: {"metadata":true} dies' => sub {
    dies_naming('json_to_object metadata:true',
        sub { IO::K8s->new->json_to_object('Pod', '{"metadata":true}') },
        qr/ObjectMeta/, qr/Boolean/);
};

# Claim: the kind-detecting inflate path refuses it too.
subtest 'inflate: metadata:true dies' => sub {
    dies_naming('inflate metadata:true',
        sub { IO::K8s->new->inflate('{"apiVersion":"v1","kind":"Pod","metadata":true}') },
        qr/ObjectMeta/, qr/Boolean/);
};

# Claim: an array element is an object position too. Before, the swallowed
# {} surfaced as Container's "Missing required arguments: name", naming
# neither the boolean nor the real problem.
subtest 'nested: spec.containers => [ JSON::PP::true ] dies naming Container' => sub {
    my $code = sub {
        IO::K8s->new->new_object('Pod',
            metadata => { name => 'p' },
            spec     => { containers => [ JSON::PP::true ] });
    };
    dies_naming('containers=>[true]', $code, qr/Container/, qr/JSON::PP::Boolean/);
    throws_ok { $code->() } qr/element 0/, 'the element index is named';
    eval { $code->() };
    unlike($@, qr/Missing required/, 'not the misleading required-field error');
};

# Claim: a hash-of-objects value is an object position as well.
subtest 'nested: hash of objects with a boolean value dies naming the value class' => sub {
    dies_naming('counters=>{a=>true}',
        sub {
            IO::K8s->new->struct_to_object('IO::K8s::Api::Resource::V1::CounterSet',
                { name => 'c', counters => { a => JSON::PP::true } });
        },
        qr/Counter\b/, qr/JSON::PP::Boolean/, qr/counters/);
};

# Claim: any blessed value without TO_JSON is refused, not only booleans;
# the message names its class.
subtest 'struct_to_object: metadata => an arbitrary object without TO_JSON dies' => sub {
    dies_naming('metadata=>T153::Opaque',
        sub { IO::K8s->new->struct_to_object('Pod', { metadata => T153::Opaque->new }) },
        qr/ObjectMeta/, qr/T153::Opaque/);
};

# Claim: FROM_HASH handed a blessed value at the top level refuses it rather
# than building an empty object of the class.
subtest 'FROM_HASH: a JSON boolean as the whole struct dies' => sub {
    dies_naming('Pod->FROM_HASH(true)',
        sub { IO::K8s::Api::Core::V1::Pod->FROM_HASH(JSON::PP::true) },
        qr/Api::Core::V1::Pod\b/, qr/JSON::PP::Boolean/);
};

# Claim: the constructor's nested coercion reaches the same inflation and
# refuses the same value (the direct attribute check is Moo's, see GUARD).
subtest 'constructor coercion: Pod->new(spec => { containers => [true] }) dies naming Container' => sub {
    dies_naming('Pod->new spec.containers=>[true]',
        sub { IO::K8s::Api::Core::V1::Pod->new(spec => { containers => [ JSON::PP::true ] }) },
        qr/Container/, qr/JSON::PP::Boolean/);
};

# Claim: a TO_JSON that does not produce a JSON object is refused, naming the
# object's class and what TO_JSON returned.
subtest 'metadata => an object whose TO_JSON returns an array dies' => sub {
    dies_naming('metadata=>T153::ToJsonArray',
        sub { IO::K8s->new->new_object('Pod', metadata => T153::ToJsonArray->new) },
        qr/ObjectMeta/, qr/T153::ToJsonArray/, qr/ARRAY/);
};

# ===========================================================================
# GUARDS: what keeps working
# ===========================================================================

# Claim: a blessed non-IO::K8s value with a TO_JSON that yields a hash is
# still inflated from that hash.
subtest 'GUARD: an object whose TO_JSON returns a hash still inflates' => sub {
    my $pod = IO::K8s->new->new_object('Pod', metadata => T153::ToJsonHash->new);
    isa_ok($pod->metadata, $META);
    is($pod->metadata->name, 'from-to-json', 'name taken from TO_JSON');
    is_deeply($pod->metadata->labels, { app => 'x' }, 'labels taken from TO_JSON');
};

# Claim: an IO::K8s object of a foreign class is still converted through its
# TO_JSON; the field the target does not declare survives per D1 and is
# re-emitted on the wire.
subtest 'GUARD: a foreign IO::K8s object is converted, undeclared fields kept' => sub {
    my $like = T153::MetaLike->new(name => 'p', extra => 'kept');
    my $pod = IO::K8s->new->new_object('Pod', metadata => $like);
    isa_ok($pod->metadata, $META, 'converted to the declared class');
    isnt(refaddr($pod->metadata), refaddr($like), 'a new object, not the foreign one');
    is($pod->metadata->name, 'p', 'declared field carried over');
    is($pod->TO_JSON->{metadata}{extra}, 'kept', 'undeclared field re-emitted');
};

# Claim: strict governs that undeclared field exactly as it would in a plain
# hash -- the conversion does not smuggle it past strict.
subtest 'GUARD: under strict the foreign object\'s undeclared field dies' => sub {
    throws_ok {
        IO::K8s->new(strict => 1)->new_object('Pod',
            metadata => T153::MetaLike->new(name => 'p', extra => 'kept'));
    } qr/Unknown field 'extra'/, 'strict names the undeclared field';
};

# Claim: the practical case behind the foreign-class rule -- a core
# LabelSelector handed to a CRD field typed with its own selector class --
# keeps building.
subtest 'GUARD: a core LabelSelector at a CRD selector field converts' => sub {
    my $core = IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector->new(
        matchLabels => { app => 'web' });
    my $w = IO::K8s->new->new_object('+T153::Widget',
        metadata => { name => 'w' },
        spec     => { selector => $core });
    isa_ok($w->spec->selector, 'T153::Selector');
    is_deeply($w->spec->selector->matchLabels, { app => 'web' }, 'matchLabels carried over');
    is_deeply($w->TO_JSON->{spec}{selector}, { matchLabels => { app => 'web' } }, 'wire form unchanged');
};

# Claim: an instance of the declared class is reused, not rebuilt.
subtest 'GUARD: an ObjectMeta instance passes through identically' => sub {
    my $om = IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(name => 'p');
    my $pod = IO::K8s->new->new_object('Pod', metadata => $om);
    is(refaddr($pod->metadata), refaddr($om), 'identical instance');
};

# Claim: so is an instance of a subclass -- isa, not an exact class match.
subtest 'GUARD: a subclass instance passes through identically' => sub {
    my $sub = T153::SubMeta->new(name => 'p');
    my $pod = IO::K8s->new->new_object('Pod', metadata => $sub);
    is(refaddr($pod->metadata), refaddr($sub), 'identical subclass instance');
    isa_ok($pod->metadata, 'T153::SubMeta');
};

# Claim: the union classes still take decoded JSON booleans through
# FROM_STRUCT, which runs before the new check.
subtest 'GUARD: additionalProperties: true from JSON text still inflates' => sub {
    my $k8s = IO::K8s->new;
    my $open = $k8s->json_to_object($PROPS, '{"type":"object","additionalProperties":true}');
    is($open->additionalProperties->allows, 1, 'true arm');
    my $closed = $k8s->json_to_object($PROPS, '{"type":"object","additionalProperties":false}');
    is($closed->additionalProperties->allows, 0, 'false arm');
};

# Claim: absence and undef stay allowed.
subtest 'GUARD: undef metadata still allowed' => sub {
    my $pod = IO::K8s->new->new_object('Pod', metadata => undef);
    ok(!defined $pod->metadata, 'metadata unset');
};

done_testing;
