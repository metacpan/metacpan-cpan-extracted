#!/usr/bin/env perl

# k137 (from k135): a real, installed prometheus-operator Prometheus /
# Alertmanager / WorkloadBinding was dropped on inflate because its status
# condition omitted `message` (and/or `reason`).
#
# The four status classes (V1::AlertmanagerStatus, V1::PrometheusStatus,
# V1::WorkloadBinding, V1alpha1::WorkloadBinding) reused the shared
# Meta::V1::Condition, whose message/reason/lastTransitionTime are marked
# required -- correct for the real apimachinery metav1.Condition, but WRONG
# for prometheus-operator, whose CRDs (v0.93.1) require only
# [lastTransitionTime, status, type] on conditions[]. A live condition with
# no `message`/`reason` croaked on inflate ("Missing required arguments") and
# the whole object was lost.
#
# The fix gives prometheus-operator its own monitoringv1.Condition class
# (IO::K8s::PrometheusOperator::V1::Condition) with message/reason/
# observedGeneration optional and lastTransitionTime/status/type required.
#
# NOTE on the required flavor: prometheus-operator's classes use
# `required => 'schema'` throughout (58 files, zero plain 'required') -- the
# provider convention records required-ness in the attribute registry (for
# the emitter, compare_to_schema and to_crd) WITHOUT enforcing it at
# construction, so a partial live document never drops. This class follows
# that convention, unlike cert-manager's k135 classes which used plain
# 'required'. So the fidelity guarantee ("these three stay required") is
# asserted against the registry, not against a constructor that dies.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use IO::K8s;
use IO::K8s::PrometheusOperator;
use IO::K8s::PrometheusOperator::V1::Condition;
use IO::K8s::PrometheusOperator::V1::WorkloadBindingCondition;
use IO::K8s::PrometheusOperator::V1::WorkloadBinding;
use IO::K8s::PrometheusOperator::V1alpha1::WorkloadBinding;

my $k8s = IO::K8s->new(with => ['IO::K8s::PrometheusOperator']);

my $COND = 'IO::K8s::PrometheusOperator::V1::Condition';
# k139 split the hand-merged monitoringv1.Condition into two lib classes: the
# enum-free Condition (Alertmanager/Prometheus .status.conditions[]) and the
# WorkloadBinding-specific WorkloadBindingCondition, whose `type` carries the
# CRD's enum [Accepted]. The k137 claim below (message/reason-less conditions
# never drop) holds for BOTH; only the class a WorkloadBinding points at changed.
my $WBCOND = 'IO::K8s::PrometheusOperator::V1::WorkloadBindingCondition';

# A Prometheus exactly as a live cluster returns it: an Available condition
# with NO `message` and NO `reason` (both optional per the CRD).
my %live_prometheus = (
    apiVersion => 'monitoring.coreos.com/v1',
    kind       => 'Prometheus',
    metadata   => { name => 'main', namespace => 'monitoring' },
    spec       => {},
    status     => {
        availableReplicas => 1,
        replicas          => 1,
        conditions        => [
            {
                type               => 'Available',
                status             => 'True',
                lastTransitionTime => '2026-09-18T00:00:00Z',
                observedGeneration => 1,
                # no `message`, no `reason`
            },
        ],
    },
);

subtest 'message/reason-less Prometheus inflates instead of croaking (the k137 bug)' => sub {
    my $obj;
    lives_ok { $obj = $k8s->inflate({ %live_prometheus }) }
        'inflate of a message/reason-less Prometheus no longer dies';
    isa_ok($obj, 'IO::K8s::PrometheusOperator::V1::Prometheus');
    isa_ok($obj->status, 'IO::K8s::PrometheusOperator::V1::PrometheusStatus');
    my $cond = $obj->status->conditions->[0];
    isa_ok($cond, $COND, 'condition is the prometheus-operator-owned type');
    is($cond->type,   'Available', 'condition.type preserved');
    is($cond->status, 'True',      'condition.status preserved');
    is($cond->lastTransitionTime, '2026-09-18T00:00:00Z', 'condition.lastTransitionTime preserved');
    is($cond->observedGeneration, 1, 'condition.observedGeneration preserved');
    is($cond->message, undef, 'condition.message is undef, not required');
    is($cond->reason,  undef, 'condition.reason is undef, not required');
};

subtest 'message-less item is not dropped when wrapped in a List' => sub {
    my $list = $k8s->inflate({
        apiVersion => 'monitoring.coreos.com/v1',
        kind       => 'PrometheusList',
        items      => [ { %live_prometheus } ],
    });
    my @items = @{ $list->items // [] };
    is(scalar(@items), 1, 'PrometheusList yields 1 item, not 0');
    isa_ok($items[0], 'IO::K8s::PrometheusOperator::V1::Prometheus');
};

subtest 'round-trips both directions with message/reason absent' => sub {
    my $obj = $k8s->inflate({ %live_prometheus });

    # Perl -> JSON: the emitted condition must not invent message/reason keys.
    my $json = $obj->TO_JSON;
    my $cj   = $json->{status}{conditions}[0];
    ok(!exists $cj->{message}, 'TO_JSON omits the absent message key');
    ok(!exists $cj->{reason},  'TO_JSON omits the absent reason key');
    is($cj->{type}, 'Available', 'TO_JSON condition.type');
    is($cj->{observedGeneration}, 1, 'TO_JSON condition.observedGeneration');

    # JSON -> Perl again: still clean, still no message/reason.
    my $re = $k8s->inflate($k8s->object_to_json($obj));
    isa_ok($re, 'IO::K8s::PrometheusOperator::V1::Prometheus');
    is($re->status->conditions->[0]->message, undef, 'round-trip keeps message undef');
    is($re->status->conditions->[0]->type, 'Available', 'round-trip keeps type');
};

subtest 'Alertmanager + WorkloadBinding also accept message/reason-less conditions' => sub {
    my $am = $k8s->inflate({
        apiVersion => 'monitoring.coreos.com/v1', kind => 'Alertmanager',
        metadata   => { name => 'main', namespace => 'monitoring' },
        spec       => {},
        status     => {
            availableReplicas => 1, replicas => 1,
            conditions => [ { type => 'Available', status => 'True',
                              lastTransitionTime => '2026-09-18T00:00:00Z' } ],
        },
    });
    isa_ok($am->status->conditions->[0], $COND);
    is($am->status->conditions->[0]->message, undef, 'Alertmanager condition.message optional');

    for my $wb_class (
        'IO::K8s::PrometheusOperator::V1::WorkloadBinding',
        'IO::K8s::PrometheusOperator::V1alpha1::WorkloadBinding',
    ) {
        my $wb;
        lives_ok { $wb = $wb_class->FROM_HASH({
            group     => 'monitoring.coreos.com',
            name      => 'main',
            namespace => 'monitoring',
            resource  => 'prometheuses',
            conditions => [ { type => 'Accepted', status => 'True',
                              lastTransitionTime => '2026-09-18T00:00:00Z' } ],
        }) } "$wb_class inflates a message/reason-less binding condition";
        isa_ok($wb->conditions->[0], $WBCOND, "$wb_class condition type (k139: WorkloadBindingCondition)");
        is($wb->conditions->[0]->message, undef, "$wb_class condition.message optional");
    }
};

subtest 'required set matches the CRD: [lastTransitionTime, status, type] recorded required' => sub {
    my $reg = $IO::K8s::Resource::_attr_registry{$COND};
    ok($reg, 'Condition class is in the attribute registry');
    for my $req (qw(lastTransitionTime status type)) {
        ok($reg->{$req}{required}, "$req recorded required (schema fidelity)");
    }
    for my $opt (qw(message reason observedGeneration)) {
        ok(!$reg->{$opt}{required}, "$opt NOT required (matches CRD)");
    }
    # observedGeneration is the int64 field.
    ok($reg->{observedGeneration}{is_int}, 'observedGeneration is integer');
};

subtest 'the status/binding classes point their conditions at the right owned class (k139 split)' => sub {
    # Alertmanager/Prometheus .status.conditions[] -> the enum-free Condition.
    for my $status_class (qw(
        IO::K8s::PrometheusOperator::V1::AlertmanagerStatus
        IO::K8s::PrometheusOperator::V1::PrometheusStatus
    )) {
        my $c = $IO::K8s::Resource::_attr_registry{$status_class}{conditions};
        is($c->{class}, $COND, "$status_class conditions -> $COND");
        ok($c->{is_array_of_objects}, "$status_class conditions is an array of objects");
    }
    # WorkloadBinding .conditions[] (both versions) -> the enum-bearing
    # WorkloadBindingCondition; the V1alpha1 class references the V1 class.
    for my $wb_class (qw(
        IO::K8s::PrometheusOperator::V1::WorkloadBinding
        IO::K8s::PrometheusOperator::V1alpha1::WorkloadBinding
    )) {
        my $c = $IO::K8s::Resource::_attr_registry{$wb_class}{conditions};
        is($c->{class}, $WBCOND, "$wb_class conditions -> $WBCOND");
        ok($c->{is_array_of_objects}, "$wb_class conditions is an array of objects");
    }
};

subtest 'follows the provider required=>schema convention (permissive at construction)' => sub {
    # Unlike the shared metav1.Condition, this class does NOT Moo-enforce its
    # required fields -- the whole point of the fix, and the provider-wide
    # convention. A partial condition constructs rather than dropping.
    lives_ok { $COND->new(type => 'Available', status => 'True') }
        'a lastTransitionTime-less condition still constructs (no drop)';
    lives_ok { $COND->new(status => 'True') }
        'construction is not Moo-enforced (required is schema-only)';

    # Contrast: the shared metav1.Condition (deliberately untouched by k137)
    # still enforces message/reason at construction.
    require IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::Condition;
    dies_ok {
        IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::Condition->new(
            type => 'Available', status => 'True',
            lastTransitionTime => '2026-09-18T00:00:00Z')
    } 'shared metav1.Condition still requires message/reason (unchanged)';
};

done_testing;
