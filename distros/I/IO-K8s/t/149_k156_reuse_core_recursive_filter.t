#!/usr/bin/env perl
# k156: the recursive reuse-compatibility check (k148's _field_compatible /
# _class_compatible) now runs as a FILTER over the reuse candidates AHEAD of
# the wire-identical tie-break in IO::K8s::AutoGen::_core_class_for, rather
# than as a gate on the single class the tie-break already picked (k148's
# original placement).
#
# k148 deliberately left every one of the 882 provider reuse decisions
# unchanged: as a post-tie-break gate the recursive check could only ever
# WITHDRAW a reuse. As a filter ahead of the tie-break it can also DECIDE one.
# A {metadata,spec} shape matches every shipped *TemplateSpec by name and by
# coarse type (both fields are objects), so the tie-break used to refuse them
# all as "not wire-identical" -- their `spec` targets differ (PodSpec vs
# PersistentVolumeClaimSpec vs JobSpec vs ResourceClaimSpec). Dropping the
# recursively-incompatible candidates FIRST leaves the single one whose deep
# `spec` shape the schema actually fits, and that one is reused.
#
# The 7 reuses this turns on, all verified against the shipped CRDs by
# maint/crd-drift-check.pl --check: AgentSandbox Sandbox/SandboxTemplate
# podTemplate -> Core::V1::PodTemplateSpec (x2) and all three Kinds'
# volumeClaimTemplates -> Core::V1::PersistentVolumeClaimTemplate (x3);
# PrometheusOperator Prometheus/PrometheusAgent storage.ephemeral.
# volumeClaimTemplate -> Core::V1::PersistentVolumeClaimTemplate (x2). The
# AgentSandbox end-to-end reuse and round-trip are pinned by
# t/28_agent_sandbox.t; this file pins the _core_class_for decision itself.
#
# Pure local fixtures -- no network, no cluster.

use strict;
use warnings;
use Test::More;
use lib 'lib';

use IO::K8s::AutoGen;

my $POD_TEMPLATE_SPEC = 'IO::K8s::Api::Core::V1::PodTemplateSpec';
my $PVC_TEMPLATE      = 'IO::K8s::Api::Core::V1::PersistentVolumeClaimTemplate';
my $HTTP_HEADER       = 'IO::K8s::Api::Core::V1::HTTPHeader';
my $LABEL_SEL_REQ     = 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelectorRequirement';

# A {metadata,spec} object schema whose `spec` carries the given properties.
sub metadata_spec_schema {
    my ($spec_props) = @_;
    return {
        type       => 'object',
        properties => {
            metadata => { type => 'object' },
            spec     => { type => 'object', properties => $spec_props },
        },
    };
}

# ============================================================================
# GREEN (k156): a {metadata,spec} shape now reuses the single candidate whose
# deep `spec` shape fits -- where k148's post-tie-break gate left it nested.
# ============================================================================

subtest 'k156: {metadata,spec} with a PodSpec-shaped spec reuses PodTemplateSpec' => sub {
    # `containers` is a PodSpec field no other {metadata,spec} candidate's
    # spec declares, so only PodTemplateSpec survives the recursive filter.
    my $schema = metadata_spec_schema({
        containers => { type => 'array', items => { type => 'object',
            properties => { name => { type => 'string' }, image => { type => 'string' } } } },
    });
    is(IO::K8s::AutoGen::_core_class_for($schema), $POD_TEMPLATE_SPEC,
        'the sole candidate whose spec holds a PodSpec is reused (pre-k156: undef, refused as not wire-identical)');
};

subtest 'k156: {metadata,spec} with a PVC-spec-shaped spec reuses PersistentVolumeClaimTemplate' => sub {
    # `accessModes` is a PersistentVolumeClaimSpec field no other candidate's
    # spec declares.
    my $schema = metadata_spec_schema({
        accessModes => { type => 'array', items => { type => 'string' } },
        volumeName  => { type => 'string' },
    });
    is(IO::K8s::AutoGen::_core_class_for($schema), $PVC_TEMPLATE,
        'the sole candidate whose spec holds a PVC spec is reused (pre-k156: undef)');
};

# End-to-end: a generated Kind whose nested `podTemplate` reuses PodTemplateSpec
# inflates the schema's own data into the core classes and TO_JSON reproduces it.
subtest 'k156: a reused PodTemplateSpec inflates and round-trips through the core class' => sub {
    my $schema = {
        type       => 'object',
        properties => {
            spec => { type => 'object', properties => {
                podTemplate => metadata_spec_schema({
                    containers => { type => 'array', items => { type => 'object',
                        properties => { name => { type => 'string' }, image => { type => 'string' } } } },
                }),
            } },
        },
    };
    my $class = IO::K8s::AutoGen::get_or_generate(
        'review.WithTemplate', $schema, {}, 'IO::K8s::_AUTOGEN_k156',
        api_version => 'review.example/v1', kind => 'WithTemplate', resource_plural => 'withtemplates', is_namespaced => 1,
    );
    my $pt_class = $class->_k8s_attr_info->{spec}{class}->_k8s_attr_info->{podTemplate}{class};
    is($pt_class, $POD_TEMPLATE_SPEC, 'the nested podTemplate field is typed as the core PodTemplateSpec');

    my $data = {
        podTemplate => {
            metadata => { labels => { app => 'x' } },
            spec     => { containers => [ { name => 'c', image => 'img' } ] },
        },
    };
    my $obj = $class->FROM_HASH({ spec => $data });
    isa_ok($obj->spec->podTemplate, $POD_TEMPLATE_SPEC);
    isa_ok($obj->spec->podTemplate->spec, 'IO::K8s::Api::Core::V1::PodSpec');
    isa_ok($obj->spec->podTemplate->spec->containers->[0], 'IO::K8s::Api::Core::V1::Container');
    is_deeply($obj->TO_JSON, { apiVersion => 'review.example/v1', kind => 'WithTemplate', spec => $data },
        'the schema\'s own data round-trips byte-identically through the reused core classes');
};

# ============================================================================
# GUARDS: k156 must not over-reuse, and must leave the pre-k156 reuses intact.
# ============================================================================

# A {metadata,spec} whose `spec` is a bare, property-less object is opaque: no
# candidate's structured `spec` class can be shown to hold it, so the recursive
# filter drops them all and nothing is reused -- the same verdict
# t/75_reuse_core.t's `template` fixture gets, now reached one step earlier.
subtest 'GUARD: a bare/opaque {metadata,spec} still stays a nested class' => sub {
    my $schema = {
        type       => 'object',
        properties => { metadata => { type => 'object' }, spec => { type => 'object' } },
    };
    is(IO::K8s::AutoGen::_core_class_for($schema), undef,
        'an opaque spec matches no candidate deeply, so the shape is not reused');
};

# The wire-identical tie-break still sees the same set it did before k156:
# wire-identical candidates share their recursive verdict, so the filter
# neither splits nor reorders them.
subtest 'GUARD: established wire-identical reuses are unchanged' => sub {
    is(IO::K8s::AutoGen::_core_class_for({ type => 'object',
        properties => { name => { type => 'string' }, value => { type => 'string' } } }),
        $HTTP_HEADER, '{name,value} still reuses HTTPHeader');
    is(IO::K8s::AutoGen::_core_class_for({ type => 'object', properties => {
        key      => { type => 'string' },
        operator => { type => 'string' },
        values   => { type => 'array', items => { type => 'string' } } } }),
        $LABEL_SEL_REQ, '{key,operator,values} still reuses LabelSelectorRequirement');
};

done_testing;
