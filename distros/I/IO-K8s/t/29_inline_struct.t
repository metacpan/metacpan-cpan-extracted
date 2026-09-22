#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use IO::K8s;

# --- Define a test class with inline struct ---

{
    package TestInlineStruct::Widget;
    use IO::K8s::Resource;

    k8s name => Str;
    k8s spec => {
        replicas => Int,
        selector => Str,
        labels   => { Str => 1 },
    };
    k8s status => {
        ready    => Bool,
        message  => Str,
    };
}

# --- Inner classes generated ---

subtest 'inner classes exist' => sub {
    ok(TestInlineStruct::Widget->can('spec'), 'spec accessor exists');
    ok(TestInlineStruct::Widget->can('status'), 'status accessor exists');

    # Inner classes should have been generated
    my $spec_class = 'TestInlineStruct::Widget::_Spec';
    my $status_class = 'TestInlineStruct::Widget::_Status';

    ok($spec_class->can('replicas'), 'inner spec class has replicas');
    ok($spec_class->can('selector'), 'inner spec class has selector');
    ok($spec_class->can('labels'), 'inner spec class has labels');
    ok($status_class->can('ready'), 'inner status class has ready');
    ok($status_class->can('message'), 'inner status class has message');
};

# --- Attribute registry ---

subtest 'attribute registry' => sub {
    my $info = $IO::K8s::Resource::_attr_registry{'TestInlineStruct::Widget'};
    ok($info->{spec}{is_object}, 'spec registered as is_object');
    ok($info->{spec}{is_inline_struct}, 'spec registered as is_inline_struct');
    is($info->{spec}{class}, 'TestInlineStruct::Widget::_Spec', 'spec class correct');

    # Inner class registry
    my $spec_info = $IO::K8s::Resource::_attr_registry{'TestInlineStruct::Widget::_Spec'};
    ok($spec_info->{replicas}{is_int}, 'spec.replicas is int');
    ok($spec_info->{selector}{is_str}, 'spec.selector is str');
    ok($spec_info->{labels}{is_hash_of_str}, 'spec.labels is hash_of_str');
};

# --- Construction with hashref coercion ---

subtest 'hashref coercion on construction' => sub {
    my $w = TestInlineStruct::Widget->new(
        name   => 'test',
        spec   => { replicas => 3, selector => 'app=test', labels => { app => 'test' } },
        status => { ready => 1, message => 'ok' },
    );

    isa_ok($w->spec, 'TestInlineStruct::Widget::_Spec');
    is($w->spec->replicas, 3, 'spec.replicas');
    is($w->spec->selector, 'app=test', 'spec.selector');
    is_deeply($w->spec->labels, { app => 'test' }, 'spec.labels');

    isa_ok($w->status, 'TestInlineStruct::Widget::_Status');
    is($w->status->ready, 1, 'status.ready');
    is($w->status->message, 'ok', 'status.message');
};

# --- TO_JSON serialization ---

subtest 'TO_JSON round-trip' => sub {
    my $w = TestInlineStruct::Widget->new(
        name   => 'test',
        spec   => { replicas => 3, selector => 'app=test' },
    );

    my $json = $w->TO_JSON;
    is($json->{name}, 'test', 'name in JSON');
    is(ref $json->{spec}, 'HASH', 'spec serialized to hash');
    is($json->{spec}{replicas}, 3, 'spec.replicas in JSON');
    is($json->{spec}{selector}, 'app=test', 'spec.selector in JSON');
};

# --- Optional (undef when not set) ---

subtest 'optional inline struct' => sub {
    my $w = TestInlineStruct::Widget->new(name => 'bare');
    is($w->spec, undef, 'spec is undef when not set');
    is($w->status, undef, 'status is undef when not set');
};

# --- Nested inline struct ---

{
    package TestInlineStruct::Nested;
    use IO::K8s::Resource;

    k8s name => Str;
    k8s outer => {
        inner => {
            value => Str,
            count => Int,
        },
        label => Str,
    };
}

subtest 'nested inline structs' => sub {
    my $n = TestInlineStruct::Nested->new(
        name  => 'nested',
        outer => {
            inner => { value => 'hello', count => 42 },
            label => 'test',
        },
    );

    isa_ok($n->outer, 'TestInlineStruct::Nested::_Outer');
    isa_ok($n->outer->inner, 'TestInlineStruct::Nested::_Outer::_Inner');
    is($n->outer->inner->value, 'hello', 'nested inner value');
    is($n->outer->inner->count, 42, 'nested inner count');
    is($n->outer->label, 'test', 'outer label');

    # Serialization
    my $json = $n->TO_JSON;
    is($json->{outer}{inner}{value}, 'hello', 'nested TO_JSON');
    is($json->{outer}{label}, 'test', 'outer TO_JSON');
};

# --- k116: an inline-struct field copies, it does not alias ---
#
# The inline-struct coercer used to be a branch of its own in
# IO::K8s::Resource::_k8s doing `$ic->new(%{$_[0]})`. Flattening the
# hashref means the inner class receives the caller's own containers, and
# stores them by reference -- so a plain container INSIDE an inline struct
# (an opaque `{ Str => 1 }` map, a `[Str]` list) stayed shared with the
# caller's structure. Every other route into that very same field --
# inflate(), struct_to_object(), FROM_HASH() -- goes through
# IO::K8s::_inflate_struct and copies it one level (k54). One class, one
# field, two semantics, decided by how the object happened to be built.
# That is an accident of ordering, not a design: the coercer arrived with
# the inline-struct DSL in 2c0c6d02, k54 landed five months later in
# 5ab95ca3 and touched _inflate_struct and TO_JSON without reaching it.
# The branch is gone; is_inline_struct falls through to the is_object
# coercer k100 introduced, i.e. onto the copying side.
#
# Nothing in the suite failed when that branch was deleted -- neither
# semantics was pinned anywhere, which is why this subtest exists. Note
# which shape it has to use: an inline struct nested in an inline struct
# never showed the bug, because the inner hashref is itself coerced into an
# object on the way in. Only a field holding a PLAIN container did, so that
# is what is fixtured here.
#
# It asserts the rule and the agreement between the routes, not the
# mechanism: a later refactor may move the coercion elsewhere as long as all
# four routes still copy.

{
    package TestInlineStruct::Copying;
    use IO::K8s::Resource;

    k8s name => Str;
    k8s spec => {
        replicas => Int,
        labels   => { Str => 1 },   # opaque map -- used to stay shared
        tags     => [Str],          # scalar list -- used to stay shared
    };
}

subtest 'k116: an inline-struct field copies one level, on every route' => sub {
    my $mk_source = sub {
        return {
            replicas => 1,
            labels   => { app => 'original', nested => { deep => 'original' } },
            tags     => ['original'],
        };
    };

    # ->new: the route that used to alias
    my $src = $mk_source->();
    my $obj = TestInlineStruct::Copying->new(name => 'n', spec => $src);
    isa_ok($obj->spec, 'TestInlineStruct::Copying::_Spec', 'hashref still coerced');

    $src->{labels}{app} = 'MUTATED-VIA-SOURCE';
    is($obj->spec->labels->{app}, 'original',
        '->new: mutating the source map does not reach the object');

    push @{ $src->{tags} }, 'MUTATED-VIA-SOURCE';
    is_deeply($obj->spec->tags, ['original'],
        '->new: mutating the source list does not reach the object');

    # The copy is deliberately one level deep, the same limit TO_JSON and
    # _inflate_struct document (k54, t/56) -- pinned here so "copies" is not
    # read as "deep-copies" by the next person to touch this.
    $src->{labels}{nested}{deep} = 'STILL-SHARED-AT-DEPTH-2';
    is($obj->spec->labels->{nested}{deep}, 'STILL-SHARED-AT-DEPTH-2',
        '->new: depth 2 still aliases -- same documented limit as everywhere else');

    # ...and the routes that always copied still do, with the same result, so
    # the four agree rather than each merely being self-consistent. A fresh
    # ->new object is the reference: $obj above was deliberately mutated
    # through the source at depth 2 and no longer holds the pristine values.
    my $reference = TestInlineStruct::Copying->new(name => 'n', spec => $mk_source->());
    my $k8s = IO::K8s->new;
    for my $route (
        [ 'struct_to_object' => sub {
            $k8s->struct_to_object('+TestInlineStruct::Copying', $_[0]) } ],
        [ 'FROM_HASH'        => sub {
            TestInlineStruct::Copying->FROM_HASH($_[0]) } ],
    ) {
        my ($name, $build) = @$route;
        my $s = { name => 'n', spec => $mk_source->() };
        my $o = $build->($s);
        isa_ok($o->spec, 'TestInlineStruct::Copying::_Spec', "$name: coerced");
        $s->{spec}{labels}{app} = 'MUTATED';
        push @{ $s->{spec}{tags} }, 'MUTATED';
        is($o->spec->labels->{app}, 'original',
            "$name: mutating the source map does not reach the object either");
        is_deeply($o->spec->tags, ['original'],
            "$name: mutating the source list does not reach the object either");
        is_deeply($o->TO_JSON->{spec}, $reference->TO_JSON->{spec},
            "$name: same wire structure as ->new");
    }

    # An already-built inner object is still passed through untouched, and a
    # value that is neither hashref nor object is still left to `isa`.
    my $inner = TestInlineStruct::Copying::_Spec->new(replicas => 3);
    my $obj3  = TestInlineStruct::Copying->new(name => 'n', spec => $inner);
    is($obj3->spec, $inner, 'an already-built object is passed through, not rebuilt');
    throws_ok { TestInlineStruct::Copying->new(name => 'n', spec => 'nope') }
        qr/type constraint/,
        'a non-hashref, non-object is still rejected by the type constraint';
};

done_testing;
