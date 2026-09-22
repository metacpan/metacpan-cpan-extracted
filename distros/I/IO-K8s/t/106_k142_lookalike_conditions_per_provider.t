#!/usr/bin/env perl

# k142: Cilium and ExternalSecrets look-alike status conditions render (and
# type) per-provider again, the way k140 did for cert-manager's
# CertificateRequest.
#
# Six status classes carried `conditions => ['Core::V1::NamespaceCondition']`:
# the upstream condition shape is the 5-key metav1.Condition look-alike
# (lastTransitionTime, message, reason, status, type; required [status,type],
# NO observedGeneration), which matches Core::V1::NamespaceCondition -- and
# NamespaceCondition requires only [status,type], so it SURVIVES the k136
# required filter, a shared-vocab candidate remains, and k139 never fires. The
# emitter kept reusing the domain-foreign core class. Because that reused name
# also happened to be what lib shipped, crd-drift-check reported MATCH: pure
# render fidelity, no drift flag. A global reuse-predicate change was rejected
# in k140 (it cannot tell a genuine core embed -- PrometheusOperator's embedded
# PVC status conditions -- from a look-alike), so k142 fixes it one layer up in
# each provider overlay: maint/crd-render/{Cilium,ExternalSecrets}.yaml list the
# conditions item path under `no_reuse_core` (D5 reuse suppressed) and name it
# at the upstream Go type (D6):
#   Cilium CiliumNetworkPolicyStatus       -> NetworkPolicyCondition
#   ExternalSecrets SecretStoreStatus      -> SecretStoreStatusCondition
#   ExternalSecrets ExternalSecretStatus   -> ExternalSecretStatusCondition
#   ExternalSecrets ClusterPushSecretStatus/PushSecretStatus -> PushSecretStatusCondition (shared)
#   ExternalSecrets GeneratorStateStatus   -> GeneratorStateStatusCondition
# CiliumNetworkPolicy + CiliumClusterwideNetworkPolicy share one status class,
# and SecretStore + ClusterSecretStore likewise, so both GVK entries map the
# conditions item to the SAME overlay name; PushSecret + ClusterPushSecret share
# ONE PushSecretStatusCondition (identical upstream Go type). k140 leaves the
# reuse predicate untouched (t/75_reuse_core.t guards that) and
# maint/crd-drift-check.pl --check guards the per-provider render byte-for-byte.
#
# Per house rule #6 this is about serialization, not accessors: each condition
# must inflate and round-trip as the per-provider class; the ONE upstream enum
# (ExternalSecret's `type` in [Ready,Deleted]) must bite client-side while the
# others stay free; and required => 'schema' must stay permissive at ->new so a
# partial live condition never drops (the k135/k137 footgun).

use strict;
use warnings;
use Test::More;
use Test::Exception;
use IO::K8s;

use IO::K8s::Cilium;
use IO::K8s::Cilium::V2::CiliumNetworkPolicyStatus;
use IO::K8s::Cilium::V2::NetworkPolicyCondition;
use IO::K8s::ExternalSecrets;
use IO::K8s::ExternalSecrets::V1::SecretStoreStatus;
use IO::K8s::ExternalSecrets::V1::SecretStoreStatusCondition;
use IO::K8s::ExternalSecrets::V1::ExternalSecretStatus;
use IO::K8s::ExternalSecrets::V1::ExternalSecretStatusCondition;
use IO::K8s::ExternalSecrets::V1alpha1::ClusterPushSecretStatus;
use IO::K8s::ExternalSecrets::V1alpha1::PushSecretStatus;
use IO::K8s::ExternalSecrets::V1alpha1::PushSecretStatusCondition;
use IO::K8s::ExternalSecrets::V1alpha1::GeneratorStateStatus;
use IO::K8s::ExternalSecrets::V1alpha1::GeneratorStateStatusCondition;

my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium', 'IO::K8s::ExternalSecrets']);

my $NAMESPACE_CONDITION = 'IO::K8s::Api::Core::V1::NamespaceCondition';

# parent status class -> per-provider condition class, plus a live (apiVersion,
# kind) whose status.conditions the emitter/inflater must type as that class.
my @SITES = (
    {   status => 'IO::K8s::Cilium::V2::CiliumNetworkPolicyStatus',
        cond   => 'IO::K8s::Cilium::V2::NetworkPolicyCondition',
        av     => 'cilium.io/v2', kind => 'CiliumNetworkPolicy' },
    {   status => 'IO::K8s::ExternalSecrets::V1::SecretStoreStatus',
        cond   => 'IO::K8s::ExternalSecrets::V1::SecretStoreStatusCondition',
        av     => 'external-secrets.io/v1', kind => 'SecretStore' },
    {   status => 'IO::K8s::ExternalSecrets::V1::ExternalSecretStatus',
        cond   => 'IO::K8s::ExternalSecrets::V1::ExternalSecretStatusCondition',
        av     => 'external-secrets.io/v1', kind => 'ExternalSecret' },
    {   status => 'IO::K8s::ExternalSecrets::V1alpha1::ClusterPushSecretStatus',
        cond   => 'IO::K8s::ExternalSecrets::V1alpha1::PushSecretStatusCondition',
        av     => 'external-secrets.io/v1alpha1', kind => 'ClusterPushSecret' },
    {   status => 'IO::K8s::ExternalSecrets::V1alpha1::PushSecretStatus',
        cond   => 'IO::K8s::ExternalSecrets::V1alpha1::PushSecretStatusCondition',
        av     => 'external-secrets.io/v1alpha1', kind => 'PushSecret' },
    {   status => 'IO::K8s::ExternalSecrets::V1alpha1::GeneratorStateStatus',
        cond   => 'IO::K8s::ExternalSecrets::V1alpha1::GeneratorStateStatusCondition',
        av     => 'generators.external-secrets.io/v1alpha1', kind => 'GeneratorState' },
);

# the five distinct per-provider condition classes (PushSecretStatusCondition is
# shared by two sites); ExternalSecretStatusCondition is the only one upstream
# gives a `type` enum.
my $ES_COND = 'IO::K8s::ExternalSecrets::V1::ExternalSecretStatusCondition';
my @COND_CLASSES = (
    'IO::K8s::Cilium::V2::NetworkPolicyCondition',
    'IO::K8s::ExternalSecrets::V1::SecretStoreStatusCondition',
    $ES_COND,
    'IO::K8s::ExternalSecrets::V1alpha1::PushSecretStatusCondition',
    'IO::K8s::ExternalSecrets::V1alpha1::GeneratorStateStatusCondition',
);

subtest 'the k142 fix: each look-alike status.conditions is the per-provider class, not NamespaceCondition' => sub {
    for my $s (@SITES) {
        my $reg = $IO::K8s::Resource::_attr_registry{ $s->{status} };
        ok($reg, "$s->{status} is registered");
        is($reg->{conditions}{class}, $s->{cond},
            "$s->{kind} status.conditions is typed as $s->{cond}");
        isnt($reg->{conditions}{class}, $NAMESPACE_CONDITION,
            "$s->{kind} status.conditions is NOT the domain-foreign Core::V1::NamespaceCondition (k142)");
        ok($reg->{conditions}{is_array_of_objects}, "$s->{kind} conditions is an array of objects");
    }
};

subtest 'PushSecret and ClusterPushSecret share ONE PushSecretStatusCondition (identical upstream Go type)' => sub {
    my $ps  = $IO::K8s::Resource::_attr_registry{'IO::K8s::ExternalSecrets::V1alpha1::PushSecretStatus'}{conditions}{class};
    my $cps = $IO::K8s::Resource::_attr_registry{'IO::K8s::ExternalSecrets::V1alpha1::ClusterPushSecretStatus'}{conditions}{class};
    is($ps, 'IO::K8s::ExternalSecrets::V1alpha1::PushSecretStatusCondition', 'PushSecretStatus uses PushSecretStatusCondition');
    is($cps, $ps, 'ClusterPushSecretStatus reuses the SAME PushSecretStatusCondition class, not a second copy');
};

subtest 'a live object of each provider Kind inflates its condition per-provider and round-trips' => sub {
    for my $s (@SITES) {
        my $obj = $k8s->inflate({
            apiVersion => $s->{av}, kind => $s->{kind},
            metadata   => { name => 'x' },
            status     => { conditions => [ { type => 'Ready', status => 'True' } ] },
        });
        my $cond = $obj->status->conditions->[0];
        isa_ok($cond, $s->{cond}, "$s->{kind} inflated condition");
        ok(!$cond->isa($NAMESPACE_CONDITION), "$s->{kind} condition is NOT a NamespaceCondition (k142)");
        is($cond->status, 'True', "$s->{kind} condition.status preserved on inflate");

        my $rt = $k8s->inflate($k8s->object_to_json($obj));
        isa_ok($rt->status->conditions->[0], $s->{cond},
            "$s->{kind} condition stays the per-provider class across a full JSON round-trip");
        is($rt->status->conditions->[0]->status, 'True', "$s->{kind} round-trips condition.status");
    }
};

subtest 'the ExternalSecret type enum bites client-side; the others stay free (D3, upstream-defined only)' => sub {
    for my $ok (qw(Ready Deleted)) {
        lives_ok { $ES_COND->new(status => 'True', type => $ok) } "ExternalSecret type => $ok constructs";
    }
    dies_ok { $ES_COND->new(status => 'True', type => 'Bogus') }
        'ExternalSecret type => Bogus is rejected by the enum constraint';
    my $es_reg = $IO::K8s::Resource::_attr_registry{$ES_COND};
    is_deeply($es_reg->{type}{options}{enum}, [qw(Ready Deleted)],
        'ExternalSecret condition type enum recorded as [Ready,Deleted]');

    # every OTHER per-provider condition leaves `type` unconstrained -- upstream
    # gives those no enum, so any string constructs and no enum is recorded.
    for my $C (grep { $_ ne $ES_COND } @COND_CLASSES) {
        lives_ok { $C->new(status => 'True', type => 'AnythingAtAll') }
            "$C type is not enum-constrained";
        my $reg = $IO::K8s::Resource::_attr_registry{$C};
        ok(!exists $reg->{type}{options}{enum}, "$C records no type enum");
    }
};

subtest 'no status enum on any of these conditions (upstream defines none, unlike cert-manager)' => sub {
    for my $C (@COND_CLASSES) {
        lives_ok { $C->new(status => 'Weird', type => 'Ready') }
            "$C accepts an arbitrary status string (no status enum)";
        my $reg = $IO::K8s::Resource::_attr_registry{$C};
        ok(!exists $reg->{status}{options}{enum}, "$C records no status enum");
    }
};

subtest 'required => schema stays permissive at ->new (no drop -- k135/k137 footgun)' => sub {
    for my $C (@COND_CLASSES) {
        # a valid `type` value keeps ExternalSecret's enum happy while proving
        # the missing partner field does not fail construction.
        lives_ok { $C->new(status => 'True') } "$C: a type-less condition still constructs (schema-only required)";
        lives_ok { $C->new(type => 'Ready') } "$C: a status-less condition still constructs (schema-only required)";
        my $reg = $IO::K8s::Resource::_attr_registry{$C};
        ok($reg->{status}{required}, "$C records status required (schema fidelity)");
        ok($reg->{type}{required},   "$C records type required (schema fidelity)");
    }
};

subtest 'a message/reason-less wire condition round-trips both directions' => sub {
    # NetworkPolicyCondition (no enum) and ExternalSecretStatusCondition (type
    # enum, valid value) exercise both variants; both have the 5-key shape and
    # NO observedGeneration.
    for my $case (
        [ 'IO::K8s::Cilium::V2::NetworkPolicyCondition',              'Valid' ],
        [ 'IO::K8s::ExternalSecrets::V1::ExternalSecretStatusCondition', 'Ready' ],
    ) {
        my ($C, $type) = @$case;
        my $wire = {
            type               => $type,
            status             => 'False',
            lastTransitionTime => '2026-09-19T00:00:00Z',
            # no message, no reason -- both optional; no observedGeneration --
            # these condition classes have no such field.
        };
        my $obj = $C->FROM_HASH({ %$wire });
        my $j   = $obj->TO_JSON;
        is_deeply($j, $wire, "$C: TO_JSON reproduces the wire object exactly");
        ok(!exists $j->{message}, "$C: absent message stays absent");
        ok(!exists $j->{reason},  "$C: absent reason stays absent");

        my $re = $C->from_json($obj->to_json);
        is_deeply($re->TO_JSON, $wire, "$C: round-trips back identically");
        is($re->status, 'False', "$C: status preserved across round-trip");
    }
};

done_testing;
