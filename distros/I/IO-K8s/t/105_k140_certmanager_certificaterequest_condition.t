#!/usr/bin/env perl

# k140: cert-manager's CertificateRequest conditions render per-provider again.
#
# The 5-key CertificateRequest condition shape (lastTransitionTime, message,
# reason, status, type; required [status,type], NO observedGeneration) matched
# Core::V1::NamespaceCondition, which requires only [status,type] and so
# SURVIVES the k136 required filter -- a shared-vocab candidate remained, k139
# never fired, and the emitter reused the domain-foreign NamespaceCondition.
# A global reuse-predicate change was rejected (it cannot tell a genuine core
# embed from a look-alike), so k140 fixes it one layer up, in the CertManager
# emitter overlay: maint/crd-render/CertManager.yaml lists the conditions item
# path under `no_reuse_core` (D5 reuse suppressed) and names it
# CertificateRequestCondition (D6) -- exactly how PrometheusOperator handles its
# WorkloadBinding condition. That drops the two parked drift-check exceptions
# (ignore_unrendered CertificateRequestCondition + accept_structural_divergence
# CertificateRequestStatus); maint/crd-drift-check.pl --check guards the render.
#
# lib already typed CertificateRequestStatus.conditions as the per-provider
# CertificateRequestCondition -- it was the RENDER that drifted. This test pins
# the shipped consumer-facing shape so lib is never "reconciled" back to
# NamespaceCondition, and (k141-style lib completeness) locks the CRD `status`
# enum [True,False,Unknown] that k140 added while regrouping the class to a
# byte-identical MATCH. Per house rule #6 this is about serialization, not
# accessors: the enum must bite client-side, required => 'schema' must stay
# permissive at ->new so a partial live condition never drops, and a
# message/reason-less wire condition must round-trip in BOTH directions.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use IO::K8s;
use IO::K8s::CertManager;
use IO::K8s::CertManager::V1::CertificateRequestStatus;
use IO::K8s::CertManager::V1::CertificateRequestCondition;

my $k8s = IO::K8s->new(with => ['IO::K8s::CertManager']);

my $STATUS_CLASS = 'IO::K8s::CertManager::V1::CertificateRequestStatus';
my $COND_CLASS   = 'IO::K8s::CertManager::V1::CertificateRequestCondition';
my $NAMESPACE_CONDITION = 'IO::K8s::Api::Core::V1::NamespaceCondition';

subtest 'the k140 fix: CertificateRequest conditions are the per-provider class, not NamespaceCondition' => sub {
    my $reg = $IO::K8s::Resource::_attr_registry{$STATUS_CLASS};
    ok($reg, "$STATUS_CLASS is registered");
    is($reg->{conditions}{class}, $COND_CLASS,
        'CertificateRequestStatus.conditions is typed as the per-provider CertificateRequestCondition');
    isnt($reg->{conditions}{class}, $NAMESPACE_CONDITION,
        'CertificateRequestStatus.conditions is NOT the domain-foreign Core::V1::NamespaceCondition (k140)');
    ok($reg->{conditions}{is_array_of_objects}, 'conditions is an array of objects');
};

subtest 'a live CertificateRequest inflates its condition as the per-provider class and round-trips' => sub {
    my $cr = $k8s->inflate({
        apiVersion => 'cert-manager.io/v1', kind => 'CertificateRequest',
        metadata   => { name => 'cr', namespace => 'default' },
        spec       => { request => 'Zm9v', issuerRef => { name => 'ca' } },
        status     => { conditions => [ { type => 'Ready', status => 'True' } ] },
    });
    my $cond = $cr->status->conditions->[0];
    isa_ok($cond, $COND_CLASS,
        'inflated CertificateRequest condition is a CertificateRequestCondition');
    ok(!$cond->isa($NAMESPACE_CONDITION),
        'inflated condition is NOT a NamespaceCondition (k140)');
    is($cond->status, 'True', 'condition.status preserved on inflate');

    my $rt = $k8s->inflate($k8s->object_to_json($cr));
    isa_ok($rt->status->conditions->[0], $COND_CLASS,
        'condition stays a CertificateRequestCondition across a full JSON round-trip');
    is($rt->status->conditions->[0]->status, 'True',
        'CertificateRequest round-trips condition.status');
};

subtest 'the status enum bites client-side, type stays free (k141-style completeness)' => sub {
    for my $ok (qw(True False Unknown)) {
        lives_ok { $COND_CLASS->new(type => 'Ready', status => $ok) }
            "status => $ok constructs";
    }
    dies_ok { $COND_CLASS->new(type => 'Ready', status => 'Bogus') }
        'status => Bogus is rejected by the enum constraint';
    dies_ok { $COND_CLASS->new(type => 'Ready', status => 'true') }
        'status => true (wrong case) is rejected';

    # k140 adds an enum only to `status`; the CRD lists none on `type`
    # (known values Ready/InvalidRequest/Approved/Denied are documentation).
    lives_ok { $COND_CLASS->new(type => 'InvalidRequest', status => 'True') }
        'type is not enum-constrained -- any string is fine';

    my $reg = $IO::K8s::Resource::_attr_registry{$COND_CLASS};
    is_deeply($reg->{status}{options}{enum}, [qw(True False Unknown)],
        'status enum recorded as [True,False,Unknown]');
    ok(!exists $reg->{type}{options}{enum}, 'type has no enum');
};

subtest 'required => schema stays permissive at ->new (no drop -- k135/k137 footgun)' => sub {
    # required => 'schema' records the CRD requirement in the registry but does
    # NOT enforce it at construction, so a partial live condition still builds.
    lives_ok { $COND_CLASS->new(status => 'True') }
        'a type-less condition still constructs (schema-only required)';
    lives_ok { $COND_CLASS->new(type => 'Ready') }
        'a status-less condition still constructs (schema-only required)';

    my $reg = $IO::K8s::Resource::_attr_registry{$COND_CLASS};
    ok($reg->{status}{required}, 'status recorded required (schema fidelity)');
    ok($reg->{type}{required},   'type recorded required (schema fidelity)');
};

subtest 'a message/reason-less wire condition round-trips both directions' => sub {
    my $wire = {
        type               => 'Ready',
        status             => 'False',
        lastTransitionTime => '2026-09-19T00:00:00Z',
        # no message, no reason -- both optional per the CRD; no
        # observedGeneration -- CertificateRequestCondition has no such field.
    };
    my $obj = $COND_CLASS->FROM_HASH({ %$wire });

    my $j = $obj->TO_JSON;
    is_deeply($j, $wire, 'TO_JSON reproduces the wire object exactly');
    is($j->{status}, 'False', 'status serialises as the wire string');
    ok(!exists $j->{message}, 'absent message stays absent');
    ok(!exists $j->{reason},  'absent reason stays absent');

    my $re = $COND_CLASS->from_json($obj->to_json);
    is_deeply($re->TO_JSON, $wire, 'round-trips back identically');
    is($re->status, 'False', 'status preserved across round-trip');
};

done_testing;
