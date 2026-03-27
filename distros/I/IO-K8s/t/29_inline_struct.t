#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

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

done_testing;
