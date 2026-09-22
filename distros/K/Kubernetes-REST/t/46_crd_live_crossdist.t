#!/usr/bin/env perl
# k98 / design D18: the shared LIVE cross-distribution CRD suite for
# IO::K8s + Kubernetes::REST. Everything the two distributions do WITH a
# cluster's custom resources -- installing a typed CRD and waiting for it to
# establish, reading an already-installed foreign CRD, the Unstructured
# fallback, cluster-preferred version resolution, and round-tripping real
# objects through the shipped provider classes -- exercised end to end against
# a real apiserver.
#
# Gated exactly like t/08_crd.t: it needs a real cluster and runs ONLY when
# TEST_KUBERNETES_REST_KUBECONFIG points at a kubeconfig. With the gate unset
# (mock mode) it skips cleanly, so `prove -lr t/` stays green offline.
#
#   Live:
#     TEST_KUBERNETES_REST_KUBECONFIG=~/.kube/config \
#       prove -lv -I$HOME/dev/io-k8s-p5/lib t/46_crd_live_crossdist.t
#
# SAFETY. This suite runs against clusters carrying real workloads. It CREATES
# only two things, both of which it owns and removes again in an END block:
#   (a) one uniquely named throwaway namespace, created only after confirming
#       it does not already exist;
#   (b) the test's own StaticWebSite CRD (group homelab.example.com) and its
#       StaticWebSite CRs inside that namespace.
# Every foreign resource (cert-manager, cilium, ocp, nfd, snapshot, ...) is
# only ever READ. Nothing else is created, updated or deleted.

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock qw(live_api is_live);
use JSON::MaybeXS ();

# The test's own hand-written CRD class (group homelab.example.com).
use My::StaticWebSite;

# ---------------------------------------------------------------------------
# Gate: live cluster only. Mock mode skips the whole file (green offline).
# ---------------------------------------------------------------------------
plan skip_all =>
    'live cluster required: set TEST_KUBERNETES_REST_KUBECONFIG '
  . '(and prepend io-k8s-p5/lib to run the provider round-trip)'
    unless is_live();

my $api = eval { live_api() };
plan skip_all => "no cluster available: $@" if $@ || !$api;

diag "Running against LIVE cluster: $ENV{TEST_KUBERNETES_REST_KUBECONFIG}";

my $json = JSON::MaybeXS->new(canonical => 1, convert_blessed => 1);

# ---------------------------------------------------------------------------
# Throwaway namespace: unique, and confirmed absent before we create it.
# Tracked in END so cleanup only ever removes what THIS run created.
# ---------------------------------------------------------------------------
my $CRD_NAME = 'staticwebsites.homelab.example.com';
my $NS;
my $NS_CREATED  = 0;
my $CRD_CREATED = 0;

# Detect an RBAC denial and stop with a clear message rather than working
# around it (the suite is not allowed to escalate its own permissions).
sub is_forbidden { ($_[0] // '') =~ /Forbidden|forbidden|\b403\b/ }

# Pick a namespace name that does not already exist.
for my $try (1 .. 5) {
    my $candidate = sprintf 'k8s-crd-live-%d-%d-%d', $$, time, int(rand(1_000_000));
    my $existing = eval { $api->get('Namespace', $candidate) };
    $NS = $candidate, last unless $existing;   # a 404 leaves $existing false
}
plan skip_all => 'could not find a free throwaway namespace name' unless $NS;

# END runs even on die/BAIL: delete ONLY the CRs, the CRD and the namespace,
# and only the ones this run actually created. Each step is eval-guarded so a
# failure in one does not strand the others.
END {
    return unless $api;
    if ($CRD_CREATED) {
        # Removing the CRD garbage-collects its CRs; delete them first anyway
        # so the removal is explicit and order-independent.
        eval {
            my $list = $api->list('StaticWebSite', namespace => $NS);
            $api->delete('StaticWebSite', $_->metadata->name, namespace => $NS)
                for @{ $list->items };
            1;
        };
        eval { $api->delete('CustomResourceDefinition', $CRD_NAME); 1 };
    }
    if ($NS_CREATED) {
        eval { $api->delete('Namespace', $NS); 1 };
    }
}

# Create the throwaway namespace (an explicitly permitted create).
{
    my $ok = eval {
        $api->create($api->new_object(Namespace => metadata => { name => $NS }));
        1;
    };
    my $err = $@;
    if (!$ok) {
        plan skip_all => "RBAC denies namespace create (stopping, no workaround): $err"
            if is_forbidden($err);
        plan skip_all => "could not create throwaway namespace '$NS': $err";
    }
    $NS_CREATED = 1;
    diag "throwaway namespace: $NS";
}

# ===========================================================================
# Claim 1: ensure_crd installs the typed CRD, waits for Established=True, and
# then the custom resource is fully CRUD-able -- WITHOUT the CRD ever being
# pre-installed by kubectl. That is the difference from t/08: here the client
# installs it.  API: Kubernetes::REST->ensure_crd (which calls
# IO::K8s::Role::APIObject->to_crd), then create/get/list/update/delete.
# ===========================================================================
subtest 'claim 1: ensure_crd + Established wait, then CRUD the CR' => sub {
    my @crds = eval {
        $api->ensure_crd(['My::StaticWebSite'], timeout => 60, poll_interval => 1);
    };
    my $err = $@;
    if ($err) {
        BAIL_OUT("RBAC denies CustomResourceDefinition create (stopping): $err")
            if is_forbidden($err);
        die $err;
    }
    $CRD_CREATED = 1;

    is scalar(@crds), 1, 'ensure_crd returned exactly one established CRD';
    my $crd = $crds[0];
    is $crd->kind, 'CustomResourceDefinition', 'returned object is a CRD';
    is $crd->metadata->name, $CRD_NAME, 'the CRD is our staticwebsites CRD';

    # The Established=True condition, checked directly on the returned object.
    ok $api->_crd_established($crd), 'the returned CRD carries Established=True';
    my ($est) = grep { ($_->type // '') eq 'Established' }
        @{ $crd->status->conditions // [] };
    ok $est, 'an Established condition is present on status';
    is $est->status, 'True', 'and its status is True';

    # Register the typed class so the CR resolves to My::StaticWebSite. This
    # MUST happen after ensure_crd: its closing invalidate_discovery clears the
    # resource map (and the inner IO::K8s), so an earlier entry would be lost.
    $api->resource_map->{StaticWebSite} = '+My::StaticWebSite';

    # --- create --------------------------------------------------------------
    my $site = $api->new_object(StaticWebSite =>
        metadata => { name => 'my-blog', namespace => $NS },
        spec     => { domain => 'blog.example.com', image => 'nginx:1.27-alpine' },
    );
    isa_ok $site, 'My::StaticWebSite', 'new_object built the typed class';
    my $created = $api->create($site);
    ok $created, 'create returned an object';
    is $created->metadata->name, 'my-blog', 'created name';
    ok $created->metadata->uid, 'server assigned a uid';
    is $created->spec->{domain}, 'blog.example.com', 'spec.domain survived the round trip';

    # --- get -----------------------------------------------------------------
    my $got = $api->get('StaticWebSite', 'my-blog', namespace => $NS);
    isa_ok $got, 'My::StaticWebSite', 'get returned the typed class';
    is $got->kind, 'StaticWebSite', 'get kind';
    is $got->api_version, 'homelab.example.com/v1', 'get apiVersion';
    is $got->spec->{image}, 'nginx:1.27-alpine', 'get spec.image';

    # --- list ----------------------------------------------------------------
    my $list = $api->list('StaticWebSite', namespace => $NS);
    my @items = @{ $list->items };
    is scalar(@items), 1, 'list has exactly our one CR';
    is $items[0]->metadata->name, 'my-blog', 'list item name';

    # --- update --------------------------------------------------------------
    $got->spec->{domain} = 'www.example.com';
    my $updated = $api->update($got);
    is $updated->spec->{domain}, 'www.example.com', 'update changed spec.domain';

    # --- delete --------------------------------------------------------------
    ok $api->delete('StaticWebSite', 'my-blog', namespace => $NS),
        'delete removed the CR';
};

# ===========================================================================
# Claim 2: read an ALREADY-INSTALLED foreign CRD read-only from the cluster
# and make its Kind usable through IO::K8s -- the "add_crd from the cluster"
# capability. IO::K8s->add_crd exists and accepts a CustomResourceDefinition
# object; the client fetches it with a plain GET. Nothing foreign is written.
# ===========================================================================
subtest 'claim 2: add_crd from a live foreign CRD (read-only)' => sub {
    require IO::K8s;

    # Pick any installed foreign CRD that this distribution ships no provider
    # for, so the demonstration is genuinely "learn the Kind from the cluster".
    my $crd_list = $api->list('CustomResourceDefinition');
    my ($crd_meta) = grep { ($_->spec->{group} // '') =~ /nfd\.k8s-sigs\.io|ocp\./ }
                     @{ $crd_list->items };
    plan skip_all => 'no suitable foreign CRD installed on this cluster'
        unless $crd_meta;

    my $crd_obj = $api->get('CustomResourceDefinition', $crd_meta->metadata->name);
    isa_ok $crd_obj,
        'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinition',
        'the fetched CRD inflated to the typed CustomResourceDefinition class';
    my $kind = $crd_obj->TO_JSON->{spec}{names}{kind};
    ok $kind, "the CRD names a Kind ($kind)";

    # Register the cluster's CRD into a fresh IO::K8s: add_crd generates a
    # typed class per served version from the CRD's own openAPIV3Schema.
    my $k8s = IO::K8s->new;
    my $reg = $k8s->add_crd($crd_obj);
    ok $reg->{$kind}, "add_crd registered the Kind ($kind)";
    ok $reg->{$kind}{storage}, 'the registration records a storage version';

    # The Kind is now usable on that instance: it resolves and constructs.
    my $class = $k8s->expand_class($kind);
    ok $class, "expand_class resolves $kind after add_crd";
    isnt $class, "IO::K8s::$kind",
        'it resolves to a generated class, not the fail-closed bare name';
    my $obj = $k8s->new_object($kind, metadata => { name => 'probe' });
    ok $obj, "new_object($kind) builds an object from the learned CRD";
    is $obj->kind, $kind, 'the built object reports the learned Kind';
};

# ===========================================================================
# Claim 3: a Kind with no shipped class, no provider and no AutoGen resolves
# to IO::K8s::Unstructured (design D16), gated on discovery confirmation, and
# get/list of a real such resource come back as Unstructured objects carrying
# apiVersion/kind/metadata from the wire. Read-only.
# ===========================================================================
subtest 'claim 3: Unstructured fallback for an unknown Kind (read-only)' => sub {
    # Find an installed foreign Kind this distribution ships nothing for AND
    # that has at least one live object to read.
    my @candidates = (
        { kind => 'OCPNode',     namespace => 'ocp-system' },
        { kind => 'NodeFeature', namespace => 'node-feature-discovery' },
    );

    my ($chosen, $items);
    for my $c (@candidates) {
        next unless $api->expand_class($c->{kind}) eq 'IO::K8s::Unstructured';
        my $list = eval { $api->list($c->{kind}, namespace => $c->{namespace}) };
        next if $@ || !$list;
        my @it = @{ $list->items };
        next unless @it;
        $chosen = $c; $items = \@it; last;
    }
    plan skip_all => 'no discovery-confirmed foreign Kind with a live object'
        unless $chosen;

    is $api->expand_class($chosen->{kind}), 'IO::K8s::Unstructured',
        "$chosen->{kind} (no shipped class/provider) resolves to Unstructured";

    isa_ok $items->[0], 'IO::K8s::Unstructured', 'list items are Unstructured';
    is $items->[0]->kind, $chosen->{kind}, 'the item carries its Kind from the wire';
    ok $items->[0]->apiVersion, 'the item carries an apiVersion from the wire';

    # A single get on the discovery-derived path also yields Unstructured.
    my $name = $items->[0]->metadata->name;
    my $one  = $api->get($chosen->{kind}, $name, namespace => $chosen->{namespace});
    isa_ok $one, 'IO::K8s::Unstructured', 'get returns an Unstructured object';
    is $one->metadata->name, $name, 'get resolved the right object';
    ok $one->TO_JSON->{apiVersion}, 'the opaque object re-emits its apiVersion';
};

# ===========================================================================
# Claim 4: for a group that serves a Kind in more than one version, the bare
# short name resolves to the version the CLUSTER marks preferred (design D17),
# read straight from the aggregated-discovery catalog. Read-only.
# ===========================================================================
subtest 'claim 4: the bare Kind resolves to the cluster-preferred version' => sub {
    my $cat = $api->_discovery;

    # autoscaling serves HorizontalPodAutoscaler in both v1 and v2; the cluster
    # marks one preferred. Confirm the multi-version premise from discovery,
    # then that the bare short name maps to the preferred version's class.
    my $group = 'autoscaling';
    my $gdata = $cat->{groups}{$group};
    plan skip_all => 'cluster does not serve the autoscaling group'
        unless $gdata;

    my @versions = grep {
        $gdata->{versions}{$_}{kinds}{HorizontalPodAutoscaler}
    } keys %{ $gdata->{versions} };
    plan skip_all => 'HorizontalPodAutoscaler is not served in >1 version here'
        unless @versions > 1;

    my $preferred = $gdata->{preferred};
    ok $preferred, "the group reports a preferred version ($preferred)";
    ok( (grep { $_ eq $preferred } @versions),
        'the preferred version is one of the served versions' );

    my $mapped = $api->resource_map->{HorizontalPodAutoscaler};
    ok $mapped, "the bare Kind is mapped ($mapped)";

    # The class path's version segment must be the preferred version, e.g.
    # preferred 'v2' -> Api::Autoscaling::V2::HorizontalPodAutoscaler.
    my $seg = ucfirst($preferred);   # v2 -> V2
    like $mapped, qr/Autoscaling::\Q$seg\E::HorizontalPodAutoscaler\z/,
        "the bare Kind resolves to the preferred version ($preferred), "
      . "not another served version";
};

# ===========================================================================
# Claim 5: a shipped provider class round-trips a REAL cluster object with
# fidelity: fetch it, then inflate -> TO_JSON/to_yaml -> inflate and compare
# the canonical JSON. Uses IO::K8s::Cilium (CiliumNode always exists, one per
# node) via with => [...]. Read-only.
# ===========================================================================
subtest 'claim 5: provider classes round-trip a real object' => sub {
    require Kubernetes::REST;
    my $prov = eval {
        Kubernetes::REST->new(
            server      => $api->server,
            credentials => $api->credentials,
            with        => ['IO::K8s::Cilium'],
        );
    };
    plan skip_all => "IO::K8s::Cilium provider not available: $@"
        if $@ || !$prov;

    my $list = eval { $prov->list('CiliumNode') };
    plan skip_all => 'no CiliumNode objects on this cluster'
        if $@ || !$list || !@{ $list->items };

    my $name = $list->items->[0]->metadata->name;
    my $node = $prov->get('CiliumNode', $name);
    isa_ok $node, 'IO::K8s::Cilium::V2::CiliumNode',
        'the real object inflated to the shipped provider class';

    my $canon = $json->encode($node->TO_JSON);

    # Round trip via a hashref (TO_JSON -> inflate -> TO_JSON).
    my $via_hash = $json->encode($prov->inflate($node->TO_JSON)->TO_JSON);
    is $via_hash, $canon, 'round trip through TO_JSON/inflate is lossless';

    # Round trip via YAML (to_yaml -> load_yaml -> TO_JSON).
    my $reload = $prov->load_yaml($node->to_yaml)->[0];
    isa_ok $reload, 'IO::K8s::Cilium::V2::CiliumNode', 'to_yaml reload is the provider class';
    is $json->encode($reload->TO_JSON), $canon,
        'round trip through to_yaml/load_yaml is lossless';
};

done_testing;
