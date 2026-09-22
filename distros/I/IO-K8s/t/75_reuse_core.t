#!/usr/bin/env perl
# D5: a nested schema whose property set is exactly a shipped core class's
# key set is typed as that class instead of a nested AutoGen class.
use strict;
use warnings;
use Test::More;
use Test::Exception;

use IO::K8s;
use IO::K8s::AutoGen;

IO::K8s::AutoGen::clear_cache();

my $label_selector = {
    type => 'object',
    properties => {
        matchLabels      => { type => 'object', additionalProperties => { type => 'string' } },
        matchExpressions => {
            type  => 'array',
            items => {
                type => 'object',
                properties => {
                    key      => { type => 'string' },
                    operator => { type => 'string' },
                    values   => { type => 'array', items => { type => 'string' } },
                },
            },
        },
    },
};

my $schema = {
    type => 'object',
    'x-kubernetes-group-version-kind' => [ { group => 'reuse.example.com', version => 'v1', kind => 'Thing' } ],
    properties => {
        apiVersion => { type => 'string' }, kind => { type => 'string' }, metadata => { type => 'object' },
        spec => {
            type => 'object',
            properties => {
                selector    => $label_selector,
                requirement => {                      # {key,operator,values}: wire-identical, reused
                    type => 'object',
                    properties => {
                        key      => { type => 'string' },
                        operator => { type => 'string' },
                        values   => { type => 'array', items => { type => 'string' } },
                    },
                },
                header => {                           # {name,value}: wire-identical, reused
                    type => 'object',
                    properties => { name => { type => 'string' }, value => { type => 'string' } },
                },
                partial => {                          # LabelSelector minus one field: 1 key, never reused
                    type => 'object',
                    properties => { matchLabels => { type => 'object', additionalProperties => { type => 'string' } } },
                },
                counter => {                          # {value} alone: 1 key, never reused
                    type => 'object',
                    properties => { value => { type => 'string' } },
                },
                template => {                         # {metadata,spec}: several, NOT wire-identical (differing
                    type => 'object',                 # target class per candidate) -- stays nested
                    properties => { metadata => { type => 'object' }, spec => { type => 'object' } },
                },
            },
        },
    },
};

my $class = IO::K8s::AutoGen::get_or_generate('com.example.reuse.v1.Thing', $schema, {}, 'IO::K8s::_AUTOGEN_reuse',
    api_version => 'reuse.example.com/v1', kind => 'Thing', resource_plural => 'things', is_namespaced => 1);
my $spec = $class->_k8s_attr_info->{spec}{class}->_k8s_attr_info;

subtest 'exact core shapes are referenced' => sub {
    is($spec->{selector}{class}, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector', 'LabelSelector reused');
    is($spec->{header}{class}, 'IO::K8s::Api::Core::V1::HTTPHeader', 'wire-identical shape reused as the preferred candidate');
    is($spec->{requirement}{class}, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelectorRequirement',
        'wire-identical shape reused as the preferred candidate, even split across API areas');
    like($spec->{partial}{class}, qr/::Spec::Partial$/, 'a single-key shape stays a nested class');
    like($spec->{counter}{class}, qr/::Spec::Counter$/, 'a single-key shape stays a nested class even though Counter is type-compatible');
    like($spec->{template}{class}, qr/::Spec::Template$/,
        'several candidates that are NOT wire-identical (PodTemplateSpec vs. JobTemplateSpec vs. ResourceClaimTemplateSpec, ...) stay a nested class');
};

subtest 'inflate resolves the requirement inside a reused LabelSelector' => sub {
    my $k8s = IO::K8s->new;
    $k8s->add({ Thing => "+$class" });
    my $t = $k8s->inflate({ apiVersion => 'reuse.example.com/v1', kind => 'Thing', metadata => { name => 't' },
        spec => { selector => { matchExpressions => [ { key => 'k', operator => 'In', values => ['a'] } ] } } });
    isa_ok($t->spec->selector, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector');
    isa_ok($t->spec->selector->matchExpressions->[0], 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelectorRequirement');
    is_deeply($t->TO_JSON->{spec}{selector}{matchExpressions}[0], { key => 'k', operator => 'In', values => ['a'] }, 'round-trips');
};

subtest 'reuse_core => 0 keeps nested classes' => sub {
    IO::K8s::AutoGen::clear_cache();
    my $c = IO::K8s::AutoGen::get_or_generate('com.example.reuse.v1.Thing', $schema, {}, 'IO::K8s::_AUTOGEN_noreuse',
        api_version => 'reuse.example.com/v1', kind => 'Thing', resource_plural => 'things', is_namespaced => 1, reuse_core => 0);
    like($c->_k8s_attr_info->{spec}{class}->_k8s_attr_info->{selector}{class}, qr/::Spec::Selector$/, 'nested class');
};

subtest 'core_class_for_shape lists candidates in preference order' => sub {
    my @c = IO::K8s::AutoGen::core_class_for_shape([qw(key operator values)]);
    ok(@c > 1, 'several candidates');
    is($c[0], 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelectorRequirement', 'Meta::V1 first');
};

subtest 'metadata is part of an embedded type\'s shape, not a top-level Kind\'s' => sub {
    # PodTemplateSpec ({metadata,spec}) is an embedded type (no api_version/
    # kind of its own), so its `metadata` is a real, schema-visible field
    # and stays in its indexed shape. It is one of SEVERAL classes sharing
    # this exact key set, not the sole match -- see the 'template' field
    # above for why that keeps a {metadata,spec} schema from being reused
    # automatically: they are not wire-identical (each has its own `spec`
    # target class).
    my @c = IO::K8s::AutoGen::core_class_for_shape([qw(metadata spec)]);
    is_deeply(
        \@c,
        [ qw(
            IO::K8s::Api::Core::V1::PersistentVolumeClaimTemplate
            IO::K8s::Api::Core::V1::PodTemplateSpec
            IO::K8s::Api::Batch::V1::JobTemplateSpec
            IO::K8s::Api::Resource::V1::ResourceClaimTemplateSpec
            IO::K8s::Api::Resource::V1alpha3::ResourceClaimTemplateSpec
            IO::K8s::Api::Resource::V1beta1::ResourceClaimTemplateSpec
            IO::K8s::Api::Resource::V1beta2::ResourceClaimTemplateSpec
        ) ],
        'every shipped {metadata,spec} class is listed, PodTemplateSpec included',
    );
};

# k139: a shipped condition-shaped struct (the metav1.Condition 6-key shape,
# with observedGeneration) matches a shared-vocab candidate
# (Meta::V1::Condition) on shape, but that candidate over-requires relative
# to a CRD condition that requires only [status,type] (or
# [lastTransitionTime,status,type]) -- so the k136 required filter drops it.
# reuse must then fall back to the provider's own nested class, NOT to an
# unrelated domain-foreign class that merely shares the shape and the
# narrower required set (Autoscaling::V2::HorizontalPodAutoscalerCondition).
subtest 'k139: a rank-3 fallback after the required filter drops the shared-vocab candidate is not reused' => sub {
    my %cond6 = (
        lastTransitionTime => { type => 'string', format => 'date-time' },
        message            => { type => 'string' },
        observedGeneration => { type => 'integer' },
        reason             => { type => 'string' },
        status             => { type => 'string' },
        type               => { type => 'string' },
    );
    is(IO::K8s::AutoGen::_core_class_for({ type => 'object', required => [qw(status type)], properties => { %cond6 } }),
        undef, 'cert-manager IssuerCondition shape ([status,type] required) is not reused as HorizontalPodAutoscalerCondition');
    is(IO::K8s::AutoGen::_core_class_for({ type => 'object', required => [qw(lastTransitionTime status type)], properties => { %cond6 } }),
        undef, 'prometheus-operator Condition shape ([lastTransitionTime,status,type] required) likewise falls back to a provider class');

    # Scope guard: the rule fires only once the required filter has removed a
    # shared-vocab candidate. With no `required` at all the filter never runs,
    # the shared-vocab metav1.Condition survives, and it is still reused --
    # unchanged from before k139 (a schema that states no required set makes
    # no required-ness claim, see _overrequires).
    is(IO::K8s::AutoGen::_core_class_for({ type => 'object', properties => { %cond6 } }),
        'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::Condition',
        'the same shape without a required list keeps reusing metav1.Condition');
};

# k139: the regression guard for the established, wanted reuses. These shapes
# have NO Meta/Core candidate at all -- the rank-3 class is the genuine, sole
# embedded upstream type -- so k139 must leave them reusable. Breaking any of
# these would regress Cilium, ExternalSecrets, AgentSandbox or
# PrometheusOperator, all --check-green on these classes today.
subtest 'k139: genuine sole-family rank-3 reuses (no shared-vocab candidate) are preserved' => sub {
    is(IO::K8s::AutoGen::_core_class_for({ type => 'object', properties => {
        endPort => { type => 'integer' }, port => { type => 'integer' }, protocol => { type => 'string' } } }),
        'IO::K8s::Api::Networking::V1::NetworkPolicyPort',
        'NetworkPolicyPort {endPort,port,protocol} still reused (Cilium PortRule/PortDenyRule)');
    is(IO::K8s::AutoGen::_core_class_for({ type => 'object', properties => {
        apiVersion => { type => 'string' }, kind => { type => 'string' }, name => { type => 'string' } } }),
        'IO::K8s::Api::Autoscaling::V1::CrossVersionObjectReference',
        'CrossVersionObjectReference {apiVersion,kind,name} still reused (ExternalSecrets store refs)');

    # And a genuine shared-vocab reuse stays green: the LabelSelector shape,
    # whose candidate is Meta::V1 (rank below @CORE_PREFERENCE), is untouched.
    is(IO::K8s::AutoGen::_core_class_for({ type => 'object', properties => {
        matchLabels      => { type => 'object', additionalProperties => { type => 'string' } },
        matchExpressions => { type => 'array', items => { type => 'object', properties => {
            key => { type => 'string' }, operator => { type => 'string' }, values => { type => 'array', items => { type => 'string' } } } } } } }),
        'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector',
        'LabelSelector still reused');

    # k140: the reuse predicate is deliberately LEFT returning
    # NamespaceCondition for the 5-key CertificateRequest condition shape (no
    # observedGeneration). That shape reuses Core::V1::NamespaceCondition, which
    # requires only [status,type] and therefore SURVIVES the k136 required
    # filter -- a shared-vocab candidate still remains, so k139 never fires.
    # k140 did NOT touch this predicate (a global predicate was rejected: it
    # cannot tell a genuine core embed like PVC from a domain look-alike). It
    # suppressed the reuse one layer up, in the CertManager emitter overlay
    # (no_reuse_core on the conditions item path + a D6 name), so the emitter
    # now renders the per-provider CertificateRequestCondition while this
    # predicate stays exactly as it was. This assertion now guards that the
    # predicate is untouched; the per-provider render and its serialization are
    # guarded by t/105_k140_certmanager_certificaterequest_condition.t and by
    # maint/crd-drift-check.pl --check.
    is(IO::K8s::AutoGen::_core_class_for({ type => 'object', required => [qw(status type)], properties => {
        lastTransitionTime => { type => 'string', format => 'date-time' }, message => { type => 'string' },
        reason => { type => 'string' }, status => { type => 'string' }, type => { type => 'string' } } }),
        'IO::K8s::Api::Core::V1::NamespaceCondition',
        'k140 leaves the reuse predicate untouched: the 5-key shape still resolves to NamespaceCondition (the fix is the CertManager overlay no_reuse_core, not the predicate)');
};

done_testing;
