#!/usr/bin/env perl

# k139 (from k137/k135): the prometheus-operator monitoringv1.Condition was
# hand-merged in lib into ONE class, but upstream ships two schema-distinct
# variants -- the enum-free Alertmanager/Prometheus `.status.conditions[]` and
# the WorkloadBinding `.conditions[]` whose `type` carries the CRD enum
# [Accepted]. k139 (closing out the reuse_core/D5 domain fix) splits them:
#   IO::K8s::PrometheusOperator::V1::Condition               -- enum-free
#   IO::K8s::PrometheusOperator::V1::WorkloadBindingCondition -- type enum [Accepted]
# Both V1 and V1alpha1 WorkloadBinding reference the V1 WorkloadBindingCondition.
#
# This test is about serialization, not accessors (house rule): a real wire
# object must round-trip in BOTH directions, the type enum must bite
# client-side, and -- the k135/k137 footgun -- a message/reason-less live
# condition must NOT drop (required => 'schema', never plain 'required').

use strict;
use warnings;
use Test::More;
use Test::Exception;
use IO::K8s;
use IO::K8s::PrometheusOperator;
use IO::K8s::PrometheusOperator::V1::WorkloadBindingCondition;
use IO::K8s::PrometheusOperator::V1::WorkloadBinding;
use IO::K8s::PrometheusOperator::V1alpha1::WorkloadBinding;

my $WBCOND = 'IO::K8s::PrometheusOperator::V1::WorkloadBindingCondition';
my $k8s = IO::K8s->new(with => ['IO::K8s::PrometheusOperator']);

subtest 'WorkloadBindingCondition round-trips both directions, message/reason absent' => sub {
    my $wire = {
        type               => 'Accepted',
        status             => 'True',
        lastTransitionTime => '2026-09-18T00:00:00Z',
        observedGeneration => 3,
        # no message, no reason -- both optional per the CRD
    };
    my $obj = $WBCOND->FROM_HASH({ %$wire });

    # Perl -> JSON: no invented message/reason keys, values preserved.
    my $j = $obj->TO_JSON;
    is_deeply($j, $wire, 'TO_JSON reproduces the wire object exactly (no dropped/invented keys)');
    ok(!exists $j->{message}, 'absent message stays absent');
    ok(!exists $j->{reason},  'absent reason stays absent');

    # JSON -> Perl -> JSON again: stable.
    my $re = $WBCOND->from_json($obj->to_json);
    is_deeply($re->TO_JSON, $wire, 'round-trips back identically');
    is($re->observedGeneration, 3, 'observedGeneration (int64) preserved');
};

subtest 'the type enum bites client-side' => sub {
    lives_ok { $WBCOND->new(type => 'Accepted', status => 'True') }
        'type => Accepted constructs';
    dies_ok { $WBCOND->new(type => 'Bogus', status => 'True') }
        'type => Bogus is rejected by the enum constraint';
};

subtest 'required => schema is permissive at construction (no drop)' => sub {
    # The footgun the provider convention avoids: plain `required` would die
    # here (and silently drop a real wire object on inflate). required=>schema
    # records the CRD requirement without enforcing it at ->new.
    lives_ok { $WBCOND->new(status => 'True') }
        'a lastTransitionTime/type-less condition still constructs';
    my $reg = $IO::K8s::Resource::_attr_registry{$WBCOND};
    ok($reg, 'WorkloadBindingCondition is registered');
    ok($reg->{$_}{required}, "$_ recorded required (schema fidelity)")
        for qw(lastTransitionTime status type);
    ok(!$reg->{$_}{required}, "$_ NOT required (matches CRD)")
        for qw(message reason observedGeneration);
    ok($reg->{type}{is_str}, 'type is a string');
    ok($reg->{observedGeneration}{is_int}, 'observedGeneration is integer (int64)');
};

subtest 'a live WorkloadBinding embeds the condition and round-trips (both versions)' => sub {
    for my $wb_class (
        'IO::K8s::PrometheusOperator::V1::WorkloadBinding',
        'IO::K8s::PrometheusOperator::V1alpha1::WorkloadBinding',
    ) {
        my $wire = {
            group      => 'monitoring.coreos.com',
            name       => 'main',
            namespace  => 'monitoring',
            resource   => 'prometheuses',
            conditions => [ { type => 'Accepted', status => 'True',
                              lastTransitionTime => '2026-09-18T00:00:00Z' } ],
        };
        my $wb;
        lives_ok { $wb = $wb_class->FROM_HASH({ %$wire }) }
            "$wb_class inflates a message/reason-less binding condition";
        isa_ok($wb->conditions->[0], $WBCOND, "$wb_class condition is WorkloadBindingCondition");
        is($wb->conditions->[0]->message, undef, "$wb_class condition.message optional");
        is_deeply($wb->TO_JSON, $wire, "$wb_class round-trips the whole binding exactly");
    }
};

done_testing;
