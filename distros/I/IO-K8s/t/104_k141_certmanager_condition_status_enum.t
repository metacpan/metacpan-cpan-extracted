#!/usr/bin/env perl

# k141 (lib-completeness follow-up to k139): the cert-manager-owned condition
# classes IssuerCondition and CertificateCondition omitted the CRD `status`
# enum [True,False,Unknown]. The k139 emitter render carries it (verified
# against the real cert-manager CRD), so crd-drift-check listed both as an
# accepted structural divergence. k141 adds
#   enum => [qw(True False Unknown)]
# to the `status` field of both classes (upstream-faithful; D3 enforces enum
# client-side as a Type::Tiny constraint at construction).
#
# This test is about serialization, not accessors (house rule #6): the enum
# must bite client-side, a real message/reason-less wire condition must still
# round-trip in BOTH directions, and -- the k135/k137 footgun -- required =>
# 'schema' must stay permissive at ->new so a partial live condition never
# drops. `type` is untouched by k141 and stays enum-free here.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use IO::K8s;
use IO::K8s::CertManager;
use IO::K8s::CertManager::V1::IssuerCondition;
use IO::K8s::CertManager::V1::CertificateCondition;

my $k8s = IO::K8s->new(with => ['IO::K8s::CertManager']);

my @COND_CLASSES = qw(
    IO::K8s::CertManager::V1::IssuerCondition
    IO::K8s::CertManager::V1::CertificateCondition
);

subtest 'the status enum bites client-side, type stays free' => sub {
    for my $class (@COND_CLASSES) {
        for my $ok (qw(True False Unknown)) {
            lives_ok { $class->new(type => 'Ready', status => $ok) }
                "$class: status => $ok constructs";
        }
        dies_ok { $class->new(type => 'Ready', status => 'Bogus') }
            "$class: status => Bogus is rejected by the enum constraint";
        dies_ok { $class->new(type => 'Ready', status => 'true') }
            "$class: status => true (wrong case) is rejected";

        # k141 touches only `status`: `type` carries no enum, any string is fine.
        lives_ok { $class->new(type => 'SomethingCustom', status => 'True') }
            "$class: type is not enum-constrained (k141 leaves type alone)";
    }
};

subtest 'required => schema stays permissive at ->new (no drop -- k135/k137 footgun)' => sub {
    for my $class (@COND_CLASSES) {
        # A partial live condition (no type, no lastTransitionTime) must still
        # construct: required=>'schema' records the CRD requirement in the
        # registry but does NOT enforce it at construction.
        lives_ok { $class->new(status => 'True') }
            "$class: a type-less condition still constructs (schema-only required)";
        lives_ok { $class->new(type => 'Ready') }
            "$class: a status-less condition still constructs (schema-only required)";

        my $reg = $IO::K8s::Resource::_attr_registry{$class};
        ok($reg, "$class is registered");
        ok($reg->{status}{required}, "$class: status recorded required (schema fidelity)");
        ok($reg->{type}{required},   "$class: type recorded required (schema fidelity)");
        is_deeply($reg->{status}{options}{enum}, [qw(True False Unknown)],
            "$class: status enum recorded as [True,False,Unknown]");
        ok(!exists $reg->{type}{options}{enum}, "$class: type has no enum (untouched by k141)");
    }
};

subtest 'a message/reason-less wire condition round-trips both directions' => sub {
    for my $class (@COND_CLASSES) {
        my $wire = {
            type               => 'Ready',
            status             => 'False',
            lastTransitionTime => '2026-09-19T00:00:00Z',
            observedGeneration => 2,
            # no message, no reason -- both optional per the CRD
        };
        my $obj = $class->FROM_HASH({ %$wire });

        my $j = $obj->TO_JSON;
        is_deeply($j, $wire, "$class: TO_JSON reproduces the wire object exactly");
        ok(!exists $j->{message}, "$class: absent message stays absent");
        ok(!exists $j->{reason},  "$class: absent reason stays absent");

        my $re = $class->from_json($obj->to_json);
        is_deeply($re->TO_JSON, $wire, "$class: round-trips back identically");
        is($re->status, 'False', "$class: status preserved across round-trip");
    }
};

subtest 'live Issuer + Certificate embed a message-less condition and round-trip' => sub {
    my $iss = $k8s->inflate({
        apiVersion => 'cert-manager.io/v1', kind => 'Issuer',
        metadata   => { name => 'ca', namespace => 'default' },
        spec       => { selfSigned => {} },
        status     => { conditions => [ { type => 'Ready', status => 'Unknown' } ] },
    });
    isa_ok($iss->status->conditions->[0], 'IO::K8s::CertManager::V1::IssuerCondition');
    is($iss->status->conditions->[0]->status, 'Unknown', 'Issuer condition.status preserved');
    is($iss->status->conditions->[0]->message, undef, 'Issuer condition.message optional');
    is($k8s->inflate($k8s->object_to_json($iss))->status->conditions->[0]->status,
        'Unknown', 'Issuer round-trips condition.status');

    my $cert = $k8s->inflate({
        apiVersion => 'cert-manager.io/v1', kind => 'Certificate',
        metadata   => { name => 'web', namespace => 'default' },
        spec       => { secretName => 'web-tls' },
        status     => { conditions => [ { type => 'Ready', status => 'True', observedGeneration => 3 } ] },
    });
    isa_ok($cert->status->conditions->[0], 'IO::K8s::CertManager::V1::CertificateCondition');
    is($cert->status->conditions->[0]->status, 'True', 'Certificate condition.status preserved');
    is($cert->status->conditions->[0]->observedGeneration, 3, 'Certificate condition.observedGeneration preserved');
    is($k8s->inflate($k8s->object_to_json($cert))->status->conditions->[0]->status,
        'True', 'Certificate round-trips condition.status');
};

done_testing;
