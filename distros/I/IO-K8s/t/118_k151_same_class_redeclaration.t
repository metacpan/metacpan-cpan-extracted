#!/usr/bin/env perl
# k151: a class that declared a k8s field could declare it a second time,
# under the same JSON key, with a different specification. The attribute
# registry took the new entry while Moo kept the first attribute (Moo
# refuses has() for an accessor the package already defines, and has('+x')
# would mix the old coercion back in), so serialization and construction
# followed two different declarations of one field: `k8s count => Int`
# then `k8s count => Str` validated an Int and wrote a JSON string.
#
# Claims:
#   * a second declaration of the same field in the same class with a
#     different type, options, required-ness or nested class is refused at
#     class load, naming the class and the field, and leaves the registry
#     and the attribute list as they were -- the wire JSON still follows the
#     first declaration;
#   * an identical second declaration is tolerated and changes nothing, not
#     even the attribute list;
#   * an inline struct is compared field by field: the same struct again is
#     tolerated, a struct with a changed, added or dropped field is refused
#     before anything is added to its inner class;
#   * the metadata adoption keeps working: a hand-written APIObject that
#     also declares `metadata` as ObjectMeta is an identical declaration,
#     one that declares it as something else is refused; AutoGen's adoption
#     is untouched.
#
# Pure local fixtures -- no network, no cluster.
use strict;
use warnings;
use Test::More;
use Test::Exception;
use JSON::MaybeXS ();

use IO::K8s;
use IO::K8s::APIObject ();
use IO::K8s::AutoGen;
use IO::K8s::Resource ();
use Types::Standard qw( Int Str );
use IO::K8s::Types qw( Opaque );

sub registry_for {
    my ($class) = @_;
    return { %{ $IO::K8s::Resource::_attr_registry{$class} // {} } };
}

sub attributes_for {
    my ($class) = @_;
    no strict 'refs';
    return [ @{ "${class}::_k8s_attributes" } ];
}

# Declares $field on a fresh class with @first, then tries @second; returns
# the class so the caller can look at what survived.
my $n = 0;
sub redeclare {
    my ($first, $second, $label, $field) = @_;
    $field //= 'count';
    my $class = 'TestK151::Case' . ++$n;
    IO::K8s::Resource->_setup_class($class);
    my $k8s = $class->can('k8s');
    $k8s->($field, @$first);
    my $registry   = registry_for($class);
    my $attributes = attributes_for($class);
    throws_ok { $k8s->($field, @$second) }
        qr/k8s: field '\Q$field\E' of \Q$class\E is already declared in \Q$class\E with a different/,
        "$label is refused, naming the class and the field";
    is_deeply(registry_for($class), $registry, "$label leaves the registry as it was");
    is_deeply(attributes_for($class), $attributes, "$label leaves the attribute list as it was");
    return $class;
}

subtest 'a different type is refused and the wire JSON follows the first declaration' => sub {
    my $class = redeclare([ Int ], [ Str ], 'Int then Str');
    is($class->new(count => 5)->to_json, '{"count":5}',
        'count still goes out as a JSON number, not the string the Str redeclaration would write');
    throws_ok { $class->new(count => 'five') } qr/count/, 'and Moo still validates it as an Int';

    my $bool = redeclare([ 'Bool' ], [ 'Str' ], 'Bool then Str', 'enabled');
    is($bool->new(enabled => 'false')->to_json, '{"enabled":false}',
        'enabled still normalizes to a JSON boolean');
};

subtest 'different options, required-ness or nested class are refused' => sub {
    redeclare([ 'Str' ], [ 'Str', { enum => [qw(a b)] } ], 'an added enum');
    redeclare([ 'Str', { enum => [qw(a b)] } ], [ 'Str', { enum => [qw(a c)] } ], 'a changed enum');
    redeclare([ 'Int', { minimum => 0 } ], [ 'Int', { minimum => 1 } ], 'a changed minimum');
    redeclare([ 'Str', { pattern => qr/\A[a-z]+\z/ } ], [ 'Str', { pattern => qr/\A[a-z0-9]+\z/ } ],
        'a changed pattern');
    redeclare([ 'Str', { description => 'one' } ], [ 'Str', { description => 'two' } ],
        'a changed description');
    redeclare([ 'Str' ], [ 'Str', 'required' ], 'added required');
    redeclare([ 'Str', { required => 'schema' } ], [ 'Str', { required => 1 } ],
        'schema-only required turned into an enforced one');
    redeclare([ 'Str' ], [ ['Str'] ], 'a scalar turned into an array');
    redeclare([ 'Core::V1::PodSpec' ], [ 'Core::V1::Container' ], 'another nested class', 'spec');
    redeclare([ { Str => 1 } ], [ { Int => 1 } ], 'another map value type', 'data');
    my $class = redeclare([ 'Core::V1::PodSpec' ], [ { replicas => 'Int' } ],
        'a named class turned into an inline struct', 'spec');
    ok(!"${class}::_Spec"->can('new'), '... and no inline-struct class is built for it');
};

subtest 'an identical second declaration changes nothing' => sub {
    for my $case (
        [ scalar  => [ 'Str' ] ],
        [ tt      => [ Int, { minimum => 0, maximum => 9, default => 3 } ] ],
        [ enum    => [ ['Str'], { enum => [qw(a b)], description => 'tags' } ] ],
        [ pattern => [ 'Str', { pattern => qr/\A[a-z]+\z/ } ] ],
        [ req     => [ 'Str', 'required' ] ],
        [ object  => [ 'Core::V1::PodSpec' ] ],
        # k191: { Str => 1 } is the string map; the opaque map is Opaque.
        [ strmap  => [ { Str => 1 } ] ],
        [ opaque  => [ Opaque ] ],
        [ dashed  => [ 'Str' ], 'x-dashed' ],
    ) {
        my ($label, $decl, $field) = @$case;
        $field //= 'value';
        my $class = 'TestK151::Same::' . ucfirst $label;
        IO::K8s::Resource->_setup_class($class);
        my $k8s = $class->can('k8s');
        $k8s->($field, @$decl);
        my $registry   = registry_for($class);
        my $attributes = attributes_for($class);
        lives_ok { $k8s->($field, @$decl) } "$label: the identical declaration again is tolerated";
        is_deeply(registry_for($class), $registry, "$label: registry unchanged");
        is_deeply(attributes_for($class), $attributes, "$label: attribute list unchanged, no second entry");
    }
};

subtest 'an inline struct is compared field by field' => sub {
    my $class = 'TestK151::Inline';
    IO::K8s::Resource->_setup_class($class);
    my $k8s = $class->can('k8s');
    my $struct = { replicas => 'Int', mode => [ 'Str', { enum => [qw(fast safe)] } ],
                   inner => { depth => 'Int' } };
    $k8s->(spec => $struct);
    my $inner       = "${class}::_Spec";
    my $inner_reg   = registry_for($inner);
    my $inner_attrs = attributes_for($inner);

    lives_ok { $k8s->(spec => { %$struct }) } 'the same inline struct again is tolerated';

    for my $case (
        [ 'a changed field type' => { %$struct, replicas => 'Str' } ],
        [ 'a changed field option' => { %$struct, mode => [ 'Str', { enum => [qw(fast)] } ] } ],
        [ 'an added field' => { %$struct, extra => 'Str' } ],
        [ 'a dropped field' => { replicas => 'Int', inner => { depth => 'Int' } } ],
        [ 'a changed nested struct' => { %$struct, inner => { depth => 'Str' } } ],
    ) {
        my ($label, $changed) = @$case;
        throws_ok { $k8s->(spec => $changed) } qr/already declared in \S+ with a different/,
            "$label is refused";
        is_deeply(registry_for($inner), $inner_reg, "$label leaves the inner class's registry as it was");
        is_deeply(attributes_for($inner), $inner_attrs, "$label adds nothing to the inner class");
    }
    ok(!$inner->can('extra'), 'no accessor for the refused added field');

    my $obj = $class->new(spec => { replicas => '3', mode => 'fast', inner => { depth => 2 } });
    is($obj->to_json, '{"spec":{"inner":{"depth":2},"mode":"fast","replicas":3}}',
        'the wire JSON follows the first struct');
};

subtest 'metadata adoption is not broken' => sub {
    my $same = 'TestK151::Meta::Same';
    eval "package $same; IO::K8s::APIObject->import(api_version => 'k151.example.com/v1', "
        . "resource_plural => 'sames'); k8s(metadata => 'Meta::V1::ObjectMeta'); 1" or die $@;
    my $obj = $same->new(metadata => { name => 'm' });
    isa_ok($obj->metadata, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta',
        'an identical metadata declaration next to the adoption');
    is($obj->to_json, '{"apiVersion":"k151.example.com/v1","kind":"Same","metadata":{"name":"m"}}',
        'and it reaches the wire JSON');

    my $other = 'TestK151::Meta::Other';
    eval "package $other; IO::K8s::APIObject->import(api_version => 'k151.example.com/v1', "
        . "resource_plural => 'others'); 1" or die $@;
    throws_ok { $other->can('k8s')->(metadata => { Str => 1 }) }
        qr/field 'metadata' of \Q$other\E is already declared in \Q$other\E with a different/,
        'metadata redeclared as an opaque map is refused';
    isa_ok($other->new(metadata => { name => 'o' })->metadata,
        'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta', 'the adopted metadata is still ObjectMeta');

    my $generated = IO::K8s::AutoGen::get_or_generate('com.example.k151.v1.Gen',
        { type => 'object', properties => { spec => { type => 'object' } } }, {},
        'IO::K8s::_AUTOGEN_k151', api_version => 'k151.example.com/v1', kind => 'Gen');
    is($generated->new(metadata => { name => 'g' })->to_json,
        '{"apiVersion":"k151.example.com/v1","kind":"Gen","metadata":{"name":"g"}}',
        'AutoGen adoption: metadata reaches the wire JSON');
};

done_testing;
