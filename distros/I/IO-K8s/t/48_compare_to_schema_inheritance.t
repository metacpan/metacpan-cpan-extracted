#!/usr/bin/env perl
# karr #30: compare_to_schema must be inheritance-aware.
#
# compare_to_schema previously read IO::K8s::Resource::_attr_registry
# directly, so a class_namespaces-style subclass (whose own registry entry
# holds only its locally declared attrs) compared against an empty or
# partial attribute set: inherited attributes were wrongly flagged
# missing_in_schema and inherited type checks never ran. The comparison now
# goes through IO::K8s::Role::Resource::_k8s_attr_info, the same merged
# @ISA view (nearest wins) that inflation and serialization use.
#
# Pure local fixtures — no network, no cluster.

use strict;
use warnings;
use Test::More;
use lib 'lib';

# ----------------------------------------------------------------------------
# Test-local classes. Each gets its own self-bound k8s DSL via
# use IO::K8s::Resource; the subclass re-declares an inherited attr so
# nearest-wins applies.
# ----------------------------------------------------------------------------

{
    package My::SchemaTest::Base;
    use IO::K8s::Resource;
    k8s active      => 'Bool';
    k8s shared      => 'Str';
    k8s only_base   => 'Str';
    k8s extra_local => 'Str';
}

{
    package My::SchemaTest::Sub;
    use IO::K8s::Resource;
    extends 'My::SchemaTest::Base';
    k8s active   => 'Str';    # re-declares inherited Bool: nearest wins
    k8s sub_only => 'Str';
}

# ----------------------------------------------------------------------------
# 1. Subclass: inherited attrs participate in the comparison
# ----------------------------------------------------------------------------

subtest 'subclass compare_to_schema sees inherited attributes' => sub {
    my $schema = {
        properties => {
            active      => { type => 'boolean' },  # conflicts with subclass Str override
            shared      => { type => 'string' },
            only_base   => { type => 'string' },
            sub_only    => { type => 'string' },
            schema_only => { type => 'string' },   # schema-only: missing locally
        },
    };

    my $diff = My::SchemaTest::Sub->compare_to_schema($schema);

    is_deeply(
        [ sort @{$diff->{missing_locally}} ],
        [qw(schema_only)],
        'schema-only property reported in missing_locally',
    );
    is_deeply(
        [ sort @{$diff->{missing_in_schema}} ],
        [qw(extra_local)],
        'inherited attrs present in schema are not flagged missing_in_schema',
    );
    is_deeply(
        $diff->{type_mismatch},
        [ { attr => 'active', local => 'string', schema => 'boolean' } ],
        'subclass Bool->Str override lands in type_mismatch (nearest wins)',
    );
};

# ----------------------------------------------------------------------------
# 2. Base class: own attrs still compared correctly (no behavior change)
# ----------------------------------------------------------------------------

subtest 'base class compare_to_schema unchanged' => sub {
    my $schema = {
        properties => {
            active    => { type => 'boolean' },  # matches base Bool
            shared    => { type => 'string' },
            only_base => { type => 'string' },
        },
    };

    my $diff = My::SchemaTest::Base->compare_to_schema($schema);

    is_deeply($diff->{missing_locally}, [], 'base: no missing locally');
    is_deeply(
        [ sort @{$diff->{missing_in_schema}} ],
        [qw(extra_local)],
        'base: own attr not in schema flagged missing_in_schema',
    );
    is_deeply($diff->{type_mismatch}, [], 'base: no type mismatches');
};

done_testing;
