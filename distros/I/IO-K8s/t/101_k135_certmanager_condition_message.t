#!/usr/bin/env perl

# k135: a real, installed cert-manager ClusterIssuer/Issuer/Certificate was
# silently dropped on inflate because its status condition omitted `message`.
#
# The three status classes reused shared condition types
# (Meta::V1::Condition, Core::V1::NamespaceCondition) whose `message` was
# marked required -- correct for the real apimachinery metav1.Condition, but
# WRONG for cert-manager, whose own CRD schema (v1.21.1) requires only
# `type` and `status` on conditions[]. The fix gives cert-manager its own
# condition classes (IssuerCondition / CertificateCondition /
# CertificateRequestCondition) with message/reason/lastTransitionTime
# optional. This test proves a message-less condition inflates cleanly,
# round-trips both directions, and is no longer dropped -- while type/status
# stay required.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use IO::K8s;
use IO::K8s::CertManager;

my $k8s = IO::K8s->new(with => ['IO::K8s::CertManager']);

# A selfsigned ClusterIssuer exactly as a live cluster returns it: a Ready
# condition with NO `message` key (upstream marks message optional).
my %live_clusterissuer = (
    apiVersion => 'cert-manager.io/v1',
    kind       => 'ClusterIssuer',
    metadata   => { name => 'selfsigned-issuer' },
    spec       => { selfSigned => {} },
    status     => {
        conditions => [
            {
                type               => 'Ready',
                status             => 'True',
                reason             => 'IsReady',
                lastTransitionTime => '2026-09-18T00:00:00Z',
                observedGeneration => 1,
                # no `message`
            },
        ],
    },
);

subtest 'message-less ClusterIssuer inflates instead of croaking (the k135 bug)' => sub {
    my $obj;
    lives_ok { $obj = $k8s->inflate({ %live_clusterissuer }) }
        'inflate of a message-less ClusterIssuer no longer dies';
    isa_ok($obj, 'IO::K8s::CertManager::V1::ClusterIssuer');
    isa_ok($obj->status, 'IO::K8s::CertManager::V1::IssuerStatus');
    my $cond = $obj->status->conditions->[0];
    isa_ok($cond, 'IO::K8s::CertManager::V1::IssuerCondition',
        'condition is the cert-manager-owned type');
    is($cond->type, 'Ready', 'condition.type preserved');
    is($cond->status, 'True', 'condition.status preserved');
    is($cond->reason, 'IsReady', 'condition.reason preserved');
    is($cond->observedGeneration, 1, 'condition.observedGeneration preserved');
    is($cond->message, undef, 'condition.message is undef, not required');
};

subtest 'message-less item is not dropped when wrapped in a List' => sub {
    my $list = $k8s->inflate({
        apiVersion => 'cert-manager.io/v1',
        kind       => 'ClusterIssuerList',
        items      => [ { %live_clusterissuer } ],
    });
    my @items = @{ $list->items // [] };
    is(scalar(@items), 1, 'list('.q{ClusterIssuer}.') yields 1 item, not 0');
    isa_ok($items[0], 'IO::K8s::CertManager::V1::ClusterIssuer');
};

subtest 'round-trips both directions with message absent' => sub {
    my $obj  = $k8s->inflate({ %live_clusterissuer });

    # Perl -> JSON: the emitted condition must not invent a `message` key.
    my $json = $obj->TO_JSON;
    my $cj   = $json->{status}{conditions}[0];
    ok(!exists $cj->{message}, 'TO_JSON omits the absent message key');
    is($cj->{type}, 'Ready', 'TO_JSON condition.type');
    is($cj->{observedGeneration}, 1, 'TO_JSON condition.observedGeneration');

    # JSON -> Perl again: still clean, still no message.
    my $re = $k8s->inflate($k8s->object_to_json($obj));
    isa_ok($re, 'IO::K8s::CertManager::V1::ClusterIssuer');
    is($re->status->conditions->[0]->message, undef, 'round-trip keeps message undef');
    is($re->status->conditions->[0]->reason, 'IsReady', 'round-trip keeps reason');
};

subtest 'Issuer + Certificate + CertificateRequest also accept message-less conditions' => sub {
    my $iss = $k8s->inflate({
        apiVersion => 'cert-manager.io/v1', kind => 'Issuer',
        metadata   => { name => 'ca', namespace => 'default' },
        spec       => { selfSigned => {} },
        status     => { conditions => [ { type => 'Ready', status => 'True' } ] },
    });
    isa_ok($iss->status->conditions->[0], 'IO::K8s::CertManager::V1::IssuerCondition');
    is($iss->status->conditions->[0]->message, undef, 'Issuer condition.message optional');

    my $cert = $k8s->inflate({
        apiVersion => 'cert-manager.io/v1', kind => 'Certificate',
        metadata   => { name => 'web', namespace => 'default' },
        spec       => { secretName => 'web-tls' },
        status     => { conditions => [ { type => 'Ready', status => 'True', observedGeneration => 3 } ] },
    });
    isa_ok($cert->status->conditions->[0], 'IO::K8s::CertManager::V1::CertificateCondition');
    is($cert->status->conditions->[0]->message, undef, 'Certificate condition.message optional');
    is($cert->status->conditions->[0]->observedGeneration, 3, 'Certificate condition.observedGeneration');

    my $cr = $k8s->inflate({
        apiVersion => 'cert-manager.io/v1', kind => 'CertificateRequest',
        metadata   => { name => 'web-cr', namespace => 'default' },
        spec       => { request => 'csr', issuerRef => { name => 'ca' } },
        status     => { conditions => [ { type => 'Approved', status => 'True' } ] },
    });
    isa_ok($cr->status->conditions->[0], 'IO::K8s::CertManager::V1::CertificateRequestCondition');
    is($cr->status->conditions->[0]->message, undef, 'CertificateRequest condition.message optional');
};

subtest 'type and status stay required (schema fidelity) on the cert-manager condition classes' => sub {
    # These classes follow the cert-manager provider's required=>'schema'
    # convention (like the k137 PrometheusOperator::V1::Condition): required-ness
    # is recorded in the attribute registry -- for the emitter, compare_to_schema
    # and to_crd -- but NOT enforced at construction, so a partial live document
    # never drops. The required SET ([type,status]) is asserted against the
    # registry; construction is deliberately permissive.
    for my $class (qw(
        IO::K8s::CertManager::V1::IssuerCondition
        IO::K8s::CertManager::V1::CertificateCondition
        IO::K8s::CertManager::V1::CertificateRequestCondition
    )) {
        my $reg = $IO::K8s::Resource::_attr_registry{$class};
        ok($reg, "$class is in the attribute registry");
        ok($reg->{type}{required},   "$class: type recorded required");
        ok($reg->{status}{required}, "$class: status recorded required");
        for my $opt (qw(message reason lastTransitionTime observedGeneration)) {
            next unless exists $reg->{$opt};   # CertificateRequestCondition has no observedGeneration
            ok(!$reg->{$opt}{required}, "$class: $opt NOT required (matches cert-manager CRD)");
        }
        # required=>'schema' is not Moo-enforced: construction is permissive.
        lives_ok { $class->new(type => 'Ready') }
            "$class constructs without status (required is schema-only, not enforced)";
        lives_ok { $class->new(status => 'True') }
            "$class constructs without type (required is schema-only, not enforced)";
        lives_ok { $class->new(type => 'Ready', status => 'True') }
            "$class constructs with type + status";
    }
};

subtest 'CertificateRequestCondition has no observedGeneration attribute (upstream shape)' => sub {
    my $c = IO::K8s::CertManager::V1::CertificateRequestCondition->new(
        type => 'Ready', status => 'True');
    ok(!$c->can('observedGeneration'),
        'CertificateRequestCondition does not declare observedGeneration');
    for my $class (qw(
        IO::K8s::CertManager::V1::IssuerCondition
        IO::K8s::CertManager::V1::CertificateCondition
    )) {
        ok($class->new(type => 'Ready', status => 'True')->can('observedGeneration'),
            "$class declares observedGeneration");
    }
};

done_testing;
