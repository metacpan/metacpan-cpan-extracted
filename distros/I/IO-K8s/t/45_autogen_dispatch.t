#!/usr/bin/env perl
# Karr #23 -- AutoGen dispatch is apiVersion-aware and deterministic.
#
# Covered here:
#
#   * expand_class($kind, $api_version) with an explicit apiVersion falls
#     through to AutoGen when the resource map has no qualified key -- but
#     only for an EXACT group/version match in the spec's
#     x-kubernetes-group-version-kind metadata. A non-matching apiVersion
#     fails closed (undef from expand_class, clean die from inflate); it
#     never silently falls back to another version.
#   * _find_definition_for_kind no longer takes the first def in hash
#     order. Versionless lookups sort the candidate def_names
#     deterministically; exact lookups filter by group/version and croak
#     when more than one definition matches.
#   * AutoGen _generate_class no longer takes the first GVK entry of a
#     multi-GVK definition. An api_version opt selects the exact matching
#     entry (croak on ambiguity or no match); without the opt the entries
#     are sorted deterministically.
#   * A definition that serves several versions under one def_name gets a
#     GVK-specific package identity, so two apiVersions of the same
#     definition produce distinct classes, each with the right
#     api_version method and correct wire serialization.

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use IO::K8s;
use IO::K8s::AutoGen;

# ---------------------------------------------------------------------------
# Fixture: a small OpenAPI spec. Definitions are inserted deliberately out
# of alphabetical order so any dependence on hash iteration order would
# surface as a wrong pick.
# ---------------------------------------------------------------------------

sub _build_spec {
    return {
        definitions => {
            # Kind with several shipped versions. The v2 def comes first
            # here; sorted-first among the HPA defs is the v1 one.
            'io.k8s.api.autoscaling.v2.HorizontalPodAutoscaler' => {
                type => 'object',
                'x-kubernetes-group-version-kind' => [{
                    group   => 'autoscaling',
                    version => 'v2',
                    kind    => 'HorizontalPodAutoscaler',
                }],
                properties => {
                    spec => {
                        type       => 'object',
                        properties => { maxReplicas => { type => 'integer' } },
                    },
                },
            },
            # Decoy: same Kind, different version. Only an exact
            # group/version request may reach this def.
            'zzz.other.HorizontalPodAutoscaler' => {
                type => 'object',
                'x-kubernetes-group-version-kind' => [{
                    group   => 'autoscaling',
                    version => 'v9',
                    kind    => 'HorizontalPodAutoscaler',
                }],
                properties => {
                    spec => {
                        type       => 'object',
                        properties => { maxReplicas => { type => 'integer' } },
                    },
                },
            },
            'io.k8s.api.autoscaling.v1.HorizontalPodAutoscaler' => {
                type => 'object',
                'x-kubernetes-group-version-kind' => [{
                    group   => 'autoscaling',
                    version => 'v1',
                    kind    => 'HorizontalPodAutoscaler',
                }],
                properties => {
                    spec => {
                        type       => 'object',
                        properties => { minReplicas => { type => 'integer' } },
                    },
                },
            },
            # One definition serving two versions. The v1beta1 GVK entry is
            # deliberately FIRST in the array; sorted-first is the v1 one.
            'com.example.MultiVersion' => {
                type => 'object',
                'x-kubernetes-group-version-kind' => [
                    {
                        group   => 'example.com',
                        version => 'v1beta1',
                        kind    => 'MultiVersion',
                    },
                    {
                        group   => 'example.com',
                        version => 'v1',
                        kind    => 'MultiVersion',
                    },
                ],
                properties => {
                    spec => {
                        type       => 'object',
                        properties => { enabled => { type => 'boolean' } },
                    },
                },
            },
            # Exact GVK ambiguity: two definitions claim the same
            # group/version/kind.
            'beta.Ambiguous' => {
                type => 'object',
                'x-kubernetes-group-version-kind' => [{
                    group   => 'ambig.example.com',
                    version => 'v1',
                    kind    => 'Ambiguous',
                }],
                properties => {},
            },
            'alpha.Ambiguous' => {
                type => 'object',
                'x-kubernetes-group-version-kind' => [{
                    group   => 'ambig.example.com',
                    version => 'v1',
                    kind    => 'Ambiguous',
                }],
                properties => {},
            },
        },
    };
}

# The instance uses an EMPTY resource map so every dispatch goes through
# AutoGen -- none of these kinds is shipped, and the empty map keeps the
# built-in HorizontalPodAutoscaler routes out of the way.
my $spec = _build_spec();
my $k8s  = IO::K8s->new(openapi_spec => $spec, resource_map => {});
my $ns   = $k8s->_autogen_namespace;

# ---- Exact GVK dispatch through AutoGen --------------------------------

subtest 'expand_class dispatches an exact apiVersion to the matching version' => sub {
    my $v1 = $k8s->expand_class('HorizontalPodAutoscaler', 'autoscaling/v1');
    is(
        $v1,
        "${ns}::io::k8s::api::autoscaling::v1::HorizontalPodAutoscaler",
        'autoscaling/v1 resolves to the v1 definition'
    );
    is($v1->api_version, 'autoscaling/v1', 'v1 class api_version') if $v1;

    my $v2 = $k8s->expand_class('HorizontalPodAutoscaler', 'autoscaling/v2');
    is(
        $v2,
        "${ns}::io::k8s::api::autoscaling::v2::HorizontalPodAutoscaler",
        'autoscaling/v2 resolves to the v2 definition'
    );
    is($v2->api_version, 'autoscaling/v2', 'v2 class api_version') if $v2;

    isnt($v1, $v2, 'v1 and v2 are distinct classes');
};

subtest 'exact dispatch reaches the decoy definition when the version matches' => sub {
    my $v9 = $k8s->expand_class('HorizontalPodAutoscaler', 'autoscaling/v9');
    is(
        $v9,
        "${ns}::zzz::other::HorizontalPodAutoscaler",
        'autoscaling/v9 resolves to the zzz decoy def, not the first def'
    );
    is($v9->api_version, 'autoscaling/v9', 'decoy class api_version') if $v9;
};

subtest 'a non-matching apiVersion fails closed (no silent fallback)' => sub {
    is(
        $k8s->expand_class('HorizontalPodAutoscaler', 'autoscaling/v3'),
        undef,
        'autoscaling/v3 (not in the spec) is undef, not a fallback to v1/v2'
    );
    is(
        $k8s->expand_class('HorizontalPodAutoscaler', ''),
        undef,
        'empty apiVersion is undef'
    );

    my $obj = eval {
        $k8s->inflate({
            apiVersion => 'autoscaling/v3',
            kind       => 'HorizontalPodAutoscaler',
            spec       => { minReplicas => 1 },
        });
    };
    is($obj, undef, 'inflate returns nothing for a non-matching apiVersion');
    like($@, qr/Cannot resolve Kubernetes GVK/, 'inflate dies with the resolution error');
    like($@, qr/'autoscaling\/v3'/, 'error names the requested apiVersion');
};

# ---- Versionless fallback stays deterministic ---------------------------

subtest 'versionless lookup picks the lexicographically first definition' => sub {
    my $bare1 = $k8s->expand_class('HorizontalPodAutoscaler');
    is(
        $bare1,
        "${ns}::io::k8s::api::autoscaling::v1::HorizontalPodAutoscaler",
        'no apiVersion picks the v1 def (sorted, not hash order)'
    );
    is($bare1->api_version, 'autoscaling/v1', 'versionless class api_version') if $bare1;

    my $bare2 = $k8s->expand_class('HorizontalPodAutoscaler');
    is($bare2, $bare1, 'repeated versionless lookups are identical');
};

# ---- Multi-GVK definition: exact apiVersion selects the entry -----------

subtest 'multi-GVK definition: exact apiVersion gets a GVK-specific package' => sub {
    my $beta = $k8s->expand_class('MultiVersion', 'example.com/v1beta1');
    is(
        $beta,
        "${ns}::com::example::MultiVersion::example::com::v1beta1",
        'example.com/v1beta1 selects the v1beta1 GVK entry'
    );
    is($beta->api_version, 'example.com/v1beta1', 'v1beta1 class api_version') if $beta;

    my $ga = $k8s->expand_class('MultiVersion', 'example.com/v1');
    is(
        $ga,
        "${ns}::com::example::MultiVersion::example::com::v1",
        'example.com/v1 selects the v1 GVK entry'
    );
    is($ga->api_version, 'example.com/v1', 'v1 class api_version') if $ga;

    isnt($ga, $beta, 'two apiVersions of one definition are distinct classes');
};

subtest 'multi-GVK definition: versionless picks the sorted-first entry' => sub {
    my $bare = $k8s->expand_class('MultiVersion');
    is(
        $bare,
        "${ns}::com::example::MultiVersion",
        'versionless keeps the plain def class name'
    );
    if ($bare) {
        is(
            $bare->api_version,
            'example.com/v1',
            'versionless picks v1 (sorted), not the array-first v1beta1'
        );
    }
};

# ---- Exact ambiguity croaks, deterministically --------------------------

subtest 'an exact apiVersion matching several definitions croaks' => sub {
    my $class = eval { $k8s->expand_class('Ambiguous', 'ambig.example.com/v1') };
    ok(!defined $class, 'no class returned');
    my $err = $@;
    like($err, qr/GVK ambiguity/, 'dies with the ambiguity error');
    like($err, qr/'Ambiguous'/, 'error names the kind');
    like($err, qr/'ambig\.example\.com\/v1'/, 'error names the apiVersion');
    like($err, qr/alpha\.Ambiguous/, 'error lists the first candidate (sorted)');
    like($err, qr/beta\.Ambiguous/, 'error lists the second candidate');
};

# ---- inflate dispatches by wire apiVersion, and serializes correctly ----

subtest 'inflate uses the wire apiVersion and TO_JSON carries it back' => sub {
    my $v1 = eval {
        $k8s->inflate({
            apiVersion => 'autoscaling/v1',
            kind       => 'HorizontalPodAutoscaler',
            spec       => { minReplicas => 2 },
        });
    };
    ok($v1, 'inflate v1 succeeds') or diag $@;
    if ($v1) {
        isa_ok($v1, "${ns}::io::k8s::api::autoscaling::v1::HorizontalPodAutoscaler",
            'inflate v1 object');
        is($v1->api_version, 'autoscaling/v1', 'inflated v1 api_version');
        is($v1->kind, 'HorizontalPodAutoscaler', 'inflated kind');
    }

    my $v2 = eval {
        $k8s->inflate({
            apiVersion => 'autoscaling/v2',
            kind       => 'HorizontalPodAutoscaler',
            spec       => { maxReplicas => 4 },
        });
    };
    ok($v2, 'inflate v2 succeeds') or diag $@;
    if ($v2) {
        isa_ok($v2, "${ns}::io::k8s::api::autoscaling::v2::HorizontalPodAutoscaler",
            'inflate v2 object');
        isnt(ref($v2), ref($v1), 'v1 and v2 inflate to different classes');

        my $data = $v1->TO_JSON;
        is($data->{apiVersion}, 'autoscaling/v1', 'TO_JSON wire apiVersion (v1)');
        is($data->{kind}, 'HorizontalPodAutoscaler', 'TO_JSON wire kind');
        like(
            $v1->to_json,
            qr/"apiVersion":"autoscaling\/v1"/,
            'to_json carries the v1 apiVersion'
        );
        like(
            $v2->to_json,
            qr/"apiVersion":"autoscaling\/v2"/,
            'to_json carries the v2 apiVersion'
        );
    }
};

# ---- Cache/package identity is GVK-specific -----------------------------

subtest 'same definition, two apiVersions: distinct classes, correct identity' => sub {
    my $mv1 = eval {
        $k8s->inflate({
            apiVersion => 'example.com/v1',
            kind       => 'MultiVersion',
            spec       => { enabled => 1 },
        });
    };
    ok($mv1, 'inflate MultiVersion v1 succeeds') or diag $@;

    my $mv2 = eval {
        $k8s->inflate({
            apiVersion => 'example.com/v1beta1',
            kind       => 'MultiVersion',
            spec       => { enabled => 1 },
        });
    };
    ok($mv2, 'inflate MultiVersion v1beta1 succeeds') or diag $@;

    if ($mv1 && $mv2) {
        isnt(ref($mv1), ref($mv2), 'different classes for different apiVersions');
        is($mv1->api_version, 'example.com/v1', 'first inflate api_version');
        is($mv2->api_version, 'example.com/v1beta1', 'second inflate api_version');

        my $back = $k8s->inflate($mv1->TO_JSON);
        is(ref($back), ref($mv1), 'round-trip preserves the class identity');

        is($mv1->TO_JSON->{apiVersion}, 'example.com/v1', 'v1 wire apiVersion');
        is($mv2->TO_JSON->{apiVersion}, 'example.com/v1beta1', 'v1beta1 wire apiVersion');
    }
};

# ---- Direct AutoGen API ------------------------------------------------

subtest 'get_or_generate with an api_version opt selects the matching GVK entry' => sub {
    IO::K8s::AutoGen::clear_cache();
    my $direct_ns = 'IO::K8s::_AUTOGEN_t45direct';
    my $schema    = $spec->{definitions}{'com.example.MultiVersion'};
    my $all_defs  = $spec->{definitions};

    my $beta = IO::K8s::AutoGen::get_or_generate(
        'com.example.MultiVersion', $schema, $all_defs, $direct_ns,
        api_version => 'example.com/v1beta1',
    );
    is(
        $beta,
        "${direct_ns}::com::example::MultiVersion::example::com::v1beta1",
        'api_version opt yields a GVK-specific class'
    );
    is($beta->api_version, 'example.com/v1beta1', 'selected api_version') if $beta;

    my $ga = IO::K8s::AutoGen::get_or_generate(
        'com.example.MultiVersion', $schema, $all_defs, $direct_ns,
    );
    is(
        $ga,
        "${direct_ns}::com::example::MultiVersion",
        'versionless keeps the plain def class name'
    );
    if ($ga) {
        is(
            $ga->api_version,
            'example.com/v1',
            'versionless picks sorted-first (v1 < v1beta1)'
        );
    }
};

done_testing;
