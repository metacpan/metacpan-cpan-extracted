#!/usr/bin/env perl
# karr k24 / design D16 (D13 rung 4): the Unstructured fallback for
# discovery-confirmed Kinds.
#
# A GVK the cluster reports through aggregated discovery, but which resolves to
# no shipped class, no `with` provider and no AutoGen'd class, becomes
# IO::K8s::Unstructured in Kubernetes::REST -- on by DEFAULT (no opt-in), but
# GATED on discovery confirmation. Path building for it takes the resource
# plural and the namespaced/cluster scope from the discovery catalog, because
# Unstructured carries no api_version()/resource_plural()/Namespaced role of
# its own (its apiVersion/kind are data on the instance, not class identity).
#
# The contrast this file pins:
#   - a Kind discovery serves, with nothing else to resolve it, USED to fail
#     closed (the fabricated IO::K8s::<Kind> name that cannot load, per C);
#     with E it resolves to IO::K8s::Unstructured instead (rung 4).
#   - a Kind discovery does NOT serve still fails closed (rung 5).
#   - rungs 1-3 (a `with` provider, a builtin) still win ahead of Unstructured.
#   - the fetch-free cheap path (t/36) is untouched: resolving Pod or a +class
#     never queries discovery.
use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";

use Test::Kubernetes::Mock ();
use Kubernetes::REST;
use Kubernetes::REST::Server;
use Kubernetes::REST::AuthToken;
use IO::K8s::Unstructured;

# Mock IO that records every request (METHOD PATH), as in t/36/t/41.
{
    package Counting::Mock::IO;
    use Moo;
    extends 'Test::Kubernetes::Mock::IO';

    has calls => (is => 'ro', default => sub { [] });

    around call => sub {
        my ($orig, $self, $req) = @_;
        (my $path = $req->url // '') =~ s{^https?://[^/]+}{};
        push @{$self->calls}, ($req->method // 'GET') . ' ' . $path;
        return $self->$orig($req);
    };
}

sub count_calls {
    my ($io, $wanted) = @_;
    return scalar grep { $_ eq $wanted } @{$io->calls};
}

# ---------------------------------------------------------------------------
# Aggregated discovery v2 (APIGroupDiscoveryList).
# ---------------------------------------------------------------------------

# GET /api -> the core group, so a core Kind has a real discovery entry too.
my %CORE_DISCOVERY = (
    kind       => 'APIGroupDiscoveryList',
    apiVersion => 'apidiscovery.k8s.io/v2',
    items      => [
        {
            metadata => { name => '' },
            versions => [
                {
                    version   => 'v1',
                    resources => [
                        {
                            resource     => 'pods',
                            responseKind => { group => '', version => 'v1', kind => 'Pod' },
                            scope        => 'Namespaced',
                        },
                    ],
                },
            ],
        },
    ],
);

# GET /apis -> foreign group 'example.com' (no bundled class, no provider,
# no spec) serving a namespaced Widget and a cluster-scoped ClusterWidget, plus
# the Gateway API group (a bundled provider exists for it) to prove rung 2 wins.
my %GROUPED_DISCOVERY = (
    kind  => 'APIGroupDiscoveryList',
    items => [
        {
            metadata => { name => 'example.com' },
            versions => [
                {
                    version   => 'v1',
                    resources => [
                        {
                            resource     => 'widgets',
                            responseKind => { group => 'example.com', version => 'v1', kind => 'Widget' },
                            scope        => 'Namespaced',
                        },
                        {
                            resource     => 'clusterwidgets',
                            responseKind => { group => 'example.com', version => 'v1', kind => 'ClusterWidget' },
                            scope        => 'Cluster',
                        },
                    ],
                },
            ],
        },
        {
            metadata => { name => 'gateway.networking.k8s.io' },
            versions => [
                {
                    version   => 'v1',
                    resources => [
                        {
                            resource     => 'gateways',
                            responseKind => { group => 'gateway.networking.k8s.io', version => 'v1', kind => 'Gateway' },
                            scope        => 'Namespaced',
                        },
                    ],
                },
            ],
        },
    ],
);

sub disco_api {
    my (%extra) = @_;
    my $io = Counting::Mock::IO->new;
    $io->add_response('GET', '/api',  \%CORE_DISCOVERY);
    $io->add_response('GET', '/apis', \%GROUPED_DISCOVERY);
    my $api = Kubernetes::REST->new(
        server      => Kubernetes::REST::Server->new(endpoint => 'http://mock.local'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'MockToken'),
        io          => $io,
        %extra,
    );
    return ($api, $io);
}

# ---------------------------------------------------------------------------
# The core of E: a discovery-confirmed foreign Kind resolves to Unstructured.
# ---------------------------------------------------------------------------
subtest 'D16 rung 4: a discovery-confirmed foreign Kind resolves to Unstructured' => sub {
    my ($api, $io) = disco_api();

    is $api->expand_class('Widget'), 'IO::K8s::Unstructured',
        'Widget (in discovery, no class/provider/spec) resolves to Unstructured';
    is $api->expand_class('ClusterWidget'), 'IO::K8s::Unstructured',
        'the cluster-scoped Kind resolves to Unstructured too';

    # Discovery was fetched (to confirm the GVK), /openapi/v2 was not.
    is count_calls($io, 'GET /apis'), 1, 'discovery fetched once for the fallthrough';
    is count_calls($io, 'GET /openapi/v2'), 0, 'never touched /openapi/v2';
};

# ---------------------------------------------------------------------------
# Path building for Unstructured pulls plural + scope from the catalog.
# ---------------------------------------------------------------------------
subtest 'build_path takes plural and scope from discovery for Unstructured' => sub {
    my ($api) = disco_api();

    my $class = $api->expand_class('Widget');

    # Namespaced: /apis/<group>/<version>/namespaces/<ns>/<plural>/<name>.
    # The plural ('widgets') and the namespaced scope both come from discovery,
    # NOT from the Unstructured class (which knows neither). The seam consumer
    # passes the Kind via `kind => ...` (what the CRUD methods thread in).
    is $api->build_path($class, name => 'w1', namespace => 'ns', kind => 'Widget'),
        '/apis/example.com/v1/namespaces/ns/widgets/w1',
        'namespaced Unstructured path uses the discovery plural and scope';

    is $api->build_path($class, namespace => 'ns', kind => 'Widget'),
        '/apis/example.com/v1/namespaces/ns/widgets',
        'the collection path for a namespaced Unstructured Kind';

    # Cluster-scoped: the namespace is dropped even when one is passed, because
    # discovery reports scope Cluster for ClusterWidget.
    is $api->build_path($class, name => 'cw1', namespace => 'ns', kind => 'ClusterWidget'),
        '/apis/example.com/v1/clusterwidgets/cw1',
        'cluster-scoped Unstructured path omits the namespace segment';

    # Without a Kind, build_path for Unstructured cannot know the resource.
    throws_ok { $api->build_path($class, name => 'w1') }
        qr/needs a Kind/,
        'build_path croaks for Unstructured without a Kind';
};

# ---------------------------------------------------------------------------
# k27: the OTHER path metadata source for Unstructured -- api_version,
# resource and namespaced given directly, bypassing discovery entirely. This
# is the branch Net::Async::Kubernetes takes: it already has the resource's
# metadata from its own bookkeeping and calls the published build_path() seam
# without paying for (or needing) a discovery round-trip. Untouched by any
# test until now.
# ---------------------------------------------------------------------------
subtest 'build_path honours explicit api_version/resource/namespaced overrides, no discovery (k27)' => sub {
    # 'MyCRD'/'mycrds' is in NEITHER discovery catalog above (only widgets,
    # clusterwidgets, gateways exist there), and this IO has no /api or /apis
    # fixture at all -- lever (a): if a regression reinstates the discovery
    # lookup on this branch, it falls through to the "no discovery entry for
    # Kind 'MyCRD'" croak in _build_path, which takes the whole file down
    # with it, instead of quietly building a plausible-looking path.
    my $io = Counting::Mock::IO->new;
    my $api = Kubernetes::REST->new(
        server      => Kubernetes::REST::Server->new(endpoint => 'http://mock.local'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'MockToken'),
        io          => $io,
        # resource_map_from_cluster is left at its default (1) on purpose: the
        # override branch must stay fetch-free even though a cluster fetch
        # would otherwise be allowed, not merely because it's disabled.
    );

    is $api->build_path('IO::K8s::Unstructured',
            kind => 'MyCRD', api_version => 'example.com/v1',
            resource => 'mycrds', namespaced => 1,
            name => 'my-instance', namespace => 'default'),
        '/apis/example.com/v1/namespaces/default/mycrds/my-instance',
        'namespaced path with a name, straight from the overrides';

    # The async-wrapper call shape: no `kind` at all. Weg 2 does not need it --
    # a caller that already has api_version/resource/namespaced from its own
    # bookkeeping (Net::Async::Kubernetes) has no reason to also thread the
    # Kind through. `kind` must stay optional here, not become a precondition.
    is $api->build_path('IO::K8s::Unstructured',
            api_version => 'example.com/v1',
            resource => 'mycrds', namespaced => 1,
            name => 'my-instance', namespace => 'default'),
        '/apis/example.com/v1/namespaces/default/mycrds/my-instance',
        'the same path with no kind hint at all -- the pure async-wrapper call';

    is $api->build_path('IO::K8s::Unstructured',
            kind => 'MyCRD', api_version => 'example.com/v1',
            resource => 'mycrds', namespaced => 1,
            namespace => 'default'),
        '/apis/example.com/v1/namespaces/default/mycrds',
        'the collection form (no name) for a namespaced override';

    is $api->build_path('IO::K8s::Unstructured',
            kind => 'MyCRD', api_version => 'example.com/v1',
            resource => 'mycrds', namespaced => 1,
            name => 'my-instance'),
        '/apis/example.com/v1/mycrds/my-instance',
        'namespaced => 1 but no namespace argument: the namespaces segment is absent';

    is $api->build_path('IO::K8s::Unstructured',
            kind => 'MyCRD', api_version => 'example.com/v1',
            resource => 'mycrds', namespaced => 0,
            name => 'my-instance', namespace => 'default'),
        '/apis/example.com/v1/mycrds/my-instance',
        'namespaced => 0 is cluster-scoped: a passed namespace is discarded';

    is count_calls($io, 'GET /api'), 0, 'no core discovery fetch on this branch';
    is count_calls($io, 'GET /apis'), 0, 'no grouped discovery fetch on this branch';
};

subtest 'explicit overrides win over a contradicting discovery entry (k27)' => sub {
    my ($api, $io) = disco_api();

    # Widget IS discovery-confirmed here (plural 'widgets', Namespaced -- see
    # %GROUPED_DISCOVERY above). Passing kind => 'Widget' alongside overrides
    # that CONTRADICT the catalog (a different plural, cluster-scoped) proves
    # the overrides are taken as-is, never reconciled against the catalog --
    # lever (b): if a regression reinstates the lookup on this branch, the
    # catalog wins and the path below reverts to the discovery-derived one
    # (.../namespaces/ns/widgets/w1), turning this assertion red.
    is $api->build_path('IO::K8s::Unstructured',
            kind => 'Widget', api_version => 'example.com/v1',
            resource => 'not-the-catalog-plural', namespaced => 0,
            name => 'w1', namespace => 'ns'),
        '/apis/example.com/v1/not-the-catalog-plural/w1',
        'the override plural and scope win over the catalog, not the other way round';

    is count_calls($io, 'GET /apis'), 0, 'still no discovery fetch when all three overrides are given';
};

subtest 'an incomplete override combo falls back to the discovery path, and needs a Kind' => sub {
    my ($api) = disco_api();

    # api_version + resource without namespaced is not "all three" -- pins the
    # override branch's precondition. With no kind to fall back to discovery
    # with, this must croak rather than silently guessing the scope.
    throws_ok {
        $api->build_path('IO::K8s::Unstructured',
            api_version => 'example.com/v1', resource => 'mycrds',
            name => 'my-instance');
    } qr/needs a Kind/,
      'api_version + resource alone is not "all three": falls to the discovery path and needs a Kind';
};

# ---------------------------------------------------------------------------
# k28: a discovery fetch that fails outright (cluster unreachable, expired
# token -- in the mock, a 404 on GET /api) must not look identical to a
# healthy catalog that simply lacks the Kind. _discovery_path_meta wraps the
# fetch in a bare `eval { $self->_discovery }` and returns undef either way,
# so _build_path's "no discovery entry for Kind '$kind' ..." croak fires
# whether discovery answered and said no, or never answered at all --
# whoever's cluster is unreachable is told the Kind doesn't exist.
# ---------------------------------------------------------------------------
subtest 'a failing discovery fetch is named in the croak, not disguised as a missing entry (k28)' => sub {
    # No /api or /apis fixture at all, so the mock answers 404 to the very
    # first discovery request and _fetch_discovery's own status check croaks
    # before any catalog is built.
    my $io = Counting::Mock::IO->new;
    my $api = Kubernetes::REST->new(
        server      => Kubernetes::REST::Server->new(endpoint => 'http://mock.local'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'MockToken'),
        io          => $io,
        # resource_map_from_cluster is left at its default (1), as in the k27
        # subtests above: this IS the discovery-confirmation path, and the
        # fetch must actually be attempted (and fail), not skipped.
    );

    eval {
        $api->build_path('IO::K8s::Unstructured',
            kind => 'MyCRD', name => 'my-instance', namespace => 'default');
    };
    my $err = $@;
    ok $err, 'build_path dies when discovery itself fails';
    like $err, qr/discovery failed/, 'the croak says discovery failed';
    like $err, qr/Kind 'MyCRD'/, 'names the Kind that was being resolved';
    like $err, qr/IO::K8s::Unstructured/, 'names the class the path was for';
    like $err, qr/Kubernetes API error \(discovery GET \/api\): 404 /,
        'carries the underlying reason from the discovery fetch';
    unlike $err, qr/no discovery entry/,
        'does not claim the catalog was consulted and came up empty';

    cmp_ok count_calls($io, 'GET /api'), '>=', 1,
        'the discovery fetch was actually attempted, not silently skipped';
};

subtest 'a healthy catalog without the Kind still reports a missing entry and does not blame discovery (k28)' => sub {
    my ($api) = disco_api();

    # 'Nope' is in neither discovery catalog: this is today's ordinary
    # fail-closed case, and the k28 fix must not leak "discovery failed" into
    # it -- discovery answered fine, it just doesn't serve this Kind.
    eval {
        $api->build_path('IO::K8s::Unstructured',
            kind => 'Nope', name => 'n1', namespace => 'default');
    };
    my $err = $@;
    ok $err, 'build_path dies for a Kind the catalog does not serve';
    like $err, qr/no discovery entry for Kind 'Nope'/,
        'the missing-entry message is unchanged for a healthy catalog';
    unlike $err, qr/discovery failed/,
        'a healthy catalog is never blamed as a discovery failure';
};

subtest 'a recorded discovery failure does not go stale once discovery recovers (k28)' => sub {
    # Same empty mock as the first k28 subtest: the first attempt must fail
    # with "discovery failed".
    my $io = Counting::Mock::IO->new;
    my $api = Kubernetes::REST->new(
        server      => Kubernetes::REST::Server->new(endpoint => 'http://mock.local'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'MockToken'),
        io          => $io,
    );

    eval {
        $api->build_path('IO::K8s::Unstructured',
            kind => 'Widget', name => 'w1', namespace => 'ns');
    };
    like $@, qr/discovery failed/, 'the first attempt dies with the discovery failure';

    # Discovery recovers: fixtures added to the SAME io/api, no
    # invalidate_discovery call -- the lazy _discovery attribute must not be
    # left holding a cached failure.
    $io->add_response('GET', '/api',  \%CORE_DISCOVERY);
    $io->add_response('GET', '/apis', \%GROUPED_DISCOVERY);

    is $api->build_path('IO::K8s::Unstructured',
            kind => 'Widget', name => 'w1', namespace => 'ns'),
        '/apis/example.com/v1/namespaces/ns/widgets/w1',
        'once discovery answers, build_path uses the catalog path -- no stale failure cached';

    # And a genuinely absent Kind is now reported as a healthy-catalog miss,
    # not as a leftover discovery failure.
    eval {
        $api->build_path('IO::K8s::Unstructured',
            kind => 'Nope', name => 'n1', namespace => 'default');
    };
    my $err = $@;
    ok $err, 'a Kind the recovered catalog does not serve still dies';
    like $err, qr/no discovery entry/,
        'reported as a missing entry now that the catalog is healthy';
    unlike $err, qr/discovery failed/,
        'no longer blamed on a failed fetch once discovery has recovered';
};

# ---------------------------------------------------------------------------
# A full CRUD round-trip through the pipeline: get() -> Unstructured object.
# ---------------------------------------------------------------------------
subtest 'get() inflates an Unstructured object with apiVersion/kind from data' => sub {
    my ($api, $io) = disco_api();

    $io->add_response('GET', '/apis/example.com/v1/namespaces/ns/widgets/w1', {
        apiVersion => 'example.com/v1',
        kind       => 'Widget',
        metadata   => { name => 'w1', namespace => 'ns' },
        spec       => { color => 'blue', size => 7 },
    });

    my $obj = $api->get('Widget', 'w1', namespace => 'ns');
    isa_ok $obj, 'IO::K8s::Unstructured', 'the returned object';
    is $obj->kind, 'Widget', 'kind comes from the response body';
    is $obj->apiVersion, 'example.com/v1', 'apiVersion comes from the response body';
    is $obj->metadata->name, 'w1', 'metadata.name inflated';

    # The GET landed on the discovery-derived path (namespaced, plural widgets).
    is count_calls($io, 'GET /apis/example.com/v1/namespaces/ns/widgets/w1'), 1,
        'the request used the discovery-built path';

    # The opaque spec round-trips through the unknown-fields bag.
    is $obj->TO_JSON->{spec}{color}, 'blue', 'the opaque spec is preserved on the object';
};

subtest 'list() inflates a list of Unstructured objects' => sub {
    my ($api, $io) = disco_api();

    $io->add_response('GET', '/apis/example.com/v1/namespaces/ns/widgets', {
        apiVersion => 'example.com/v1',
        kind       => 'WidgetList',
        items      => [
            { apiVersion => 'example.com/v1', kind => 'Widget',
              metadata => { name => 'a', namespace => 'ns' }, spec => { color => 'red' } },
            { apiVersion => 'example.com/v1', kind => 'Widget',
              metadata => { name => 'b', namespace => 'ns' }, spec => { color => 'green' } },
        ],
    });

    my $list = $api->list('Widget', namespace => 'ns');
    is scalar($list->items->@*), 2, 'two items inflated';
    isa_ok $list->items->[0], 'IO::K8s::Unstructured', 'first item';
    is $list->items->[1]->metadata->name, 'b', 'second item name';
    is count_calls($io, 'GET /apis/example.com/v1/namespaces/ns/widgets'), 1,
        'the list request used the discovery-built collection path';
};

# ---------------------------------------------------------------------------
# karr k40: a qualified name keeps its group and version on the way to the
# path. 'example.org/v1/Widget' is confirmed as that exact GVK; the path must
# not then fall back to whichever group serving a Widget sorts first.
# ---------------------------------------------------------------------------
subtest 'a qualified name builds its path in its own group, not the first one serving the Kind' => sub {
    my $widgets_in = sub {
        my ($group) = @_;
        return {
            metadata => { name => $group },
            versions => [ {
                version   => 'v1',
                resources => [ {
                    resource     => 'widgets',
                    responseKind => { group => $group, version => 'v1', kind => 'Widget' },
                    scope        => 'Namespaced',
                } ],
            } ],
        };
    };
    my $io = Counting::Mock::IO->new;
    $io->add_response('GET', '/api', \%CORE_DISCOVERY);
    # a.example.org sorts ahead of example.org - the group a bare 'Widget'
    # would pick.
    $io->add_response('GET', '/apis', {
        kind  => 'APIGroupDiscoveryList',
        items => [ $widgets_in->('a.example.org'), $widgets_in->('example.org') ],
    });
    my $api = Kubernetes::REST->new(
        server      => Kubernetes::REST::Server->new(endpoint => 'http://mock.local'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'MockToken'),
        io          => $io,
    );

    my $WIDGETS = '/apis/example.org/v1/namespaces/ns/widgets';
    my $w1 = {
        apiVersion => 'example.org/v1', kind => 'Widget',
        metadata   => { name => 'w1', namespace => 'ns' },
    };
    $io->add_response('GET', $WIDGETS,
        { apiVersion => 'example.org/v1', kind => 'WidgetList', items => [ $w1 ] });
    $io->add_response('GET', "$WIDGETS/w1", $w1);
    $io->add_response('DELETE', "$WIDGETS/w1",
        { kind => 'Status', apiVersion => 'v1', status => 'Success' });

    is $api->expand_class('example.org/v1/Widget'), 'IO::K8s::Unstructured',
        'the qualified name resolves to Unstructured';

    my $list = eval { $api->list('example.org/v1/Widget', namespace => 'ns') };
    is $@, '', 'list does not die';
    is count_calls($io, "GET $WIDGETS"), 1, 'list: the example.org collection';

    my $obj = eval { $api->get('example.org/v1/Widget', 'w1', namespace => 'ns') };
    is $@, '', 'get does not die';
    is count_calls($io, "GET $WIDGETS/w1"), 1, 'get: the example.org object';

    eval { $api->delete('example.org/v1/Widget', 'w1', namespace => 'ns') };
    is $@, '', 'delete does not die';
    is count_calls($io, "DELETE $WIDGETS/w1"), 1, 'delete: the example.org object';

    is_deeply [ grep { m{a\.example\.org} } @{ $io->calls } ], [],
        'nothing went to a.example.org';
};

# ---------------------------------------------------------------------------
# karr k43: a qualified name is fail-closed on its own group and version. A
# cluster that does not serve exactly that group/version has not confirmed
# the GVK (D16), even when another group - or another version of the same
# group - serves a Kind of that name, so nothing resolves and nothing is sent
# there. Only a bare Kind goes to whichever group serves it (D17). In
# disco_api() example.com/v1 is the only group/version serving Widget.
# ---------------------------------------------------------------------------
subtest 'k43: a qualified name whose group/version is not served fails closed' => sub {
    my ($api, $io) = disco_api();

    is $api->expand_class('other.example.com/v1/Widget'), undef,
        'another group: the qualified name does not resolve';
    is $api->expand_class('Widget', 'other.example.com/v1'), undef,
        'nor does the same GVK as Kind plus apiVersion';
    is $api->expand_class('example.com/v2/Widget'), undef,
        'another version of the serving group does not resolve either';
    is $api->expand_class('Widget', 'example.com/v2'), undef,
        'nor as Kind plus apiVersion';

    is $api->expand_class('example.com/v1/Widget'), 'IO::K8s::Unstructured',
        'the served group/version still resolves';
    is $api->expand_class('Widget'), 'IO::K8s::Unstructured',
        'a bare Kind still resolves through the group that serves it';

    my $mark = @{ $io->calls };
    for my $name (qw( other.example.com/v1/Widget example.com/v2/Widget )) {
        ok !eval { $api->list($name, namespace => 'ns', labelSelector => 'app=x'); 1 },
            "list $name dies";
        ok !eval { $api->get($name, 'w1', namespace => 'ns'); 1 },
            "get $name dies";
        ok !eval { $api->delete($name, 'w1', namespace => 'ns'); 1 },
            "delete $name dies";
    }
    is_deeply [ @{ $io->calls }[ $mark .. $#{ $io->calls } ] ], [],
        'no request went anywhere - above all not to example.com/v1';
};

subtest 'k43: an object of an unserved group/version is not sent to another group' => sub {
    my ($api, $io) = disco_api();

    throws_ok {
        $api->build_path('IO::K8s::Unstructured', kind => 'Widget',
            api_version => 'other.example.com/v1', name => 'w1', namespace => 'ns');
    } qr{no discovery entry for Kind 'Widget' in apiVersion 'other\.example\.com/v1'},
      'build_path names the Kind and the apiVersion it cannot confirm';

    my $widget = IO::K8s::Unstructured->FROM_HASH({
        apiVersion => 'other.example.com/v1',
        kind       => 'Widget',
        metadata   => { name => 'w1', namespace => 'ns' },
    });
    my $mark = @{ $io->calls };
    for my $method (qw( create update delete ensure )) {
        ok !eval { $api->$method($widget); 1 }, "$method dies";
    }
    throws_ok {
        $api->ensure({
            apiVersion => 'other.example.com/v1',
            kind       => 'Widget',
            metadata   => { name => 'w1', namespace => 'ns' },
        });
    } qr{no IO::K8s class for apiVersion 'other\.example\.com/v1', kind 'Widget'},
      'ensure of a manifest croaks naming its apiVersion and Kind';
    is_deeply [ @{ $io->calls }[ $mark .. $#{ $io->calls } ] ], [],
        'no request went anywhere - above all not to example.com/v1';
};

# ---------------------------------------------------------------------------
# Rung 5 still holds: a Kind discovery does not serve stays fail-closed.
# ---------------------------------------------------------------------------
subtest 'a Kind not in discovery stays fail-closed (rung 5, not Unstructured)' => sub {
    my ($api) = disco_api();

    # 'Ghost' is in no group discovery reports. It must NOT become Unstructured;
    # the fabricated IO::K8s::Ghost name is kept so the load error names it.
    my $resolved = $api->expand_class('Ghost');
    isnt $resolved, 'IO::K8s::Unstructured',
        'an unknown Kind is not diverted to Unstructured';
    is $resolved, 'IO::K8s::Ghost',
        'the fail-open bare name is returned unchanged (fails closed at use)';

    throws_ok { $api->get('Ghost', 'g1', namespace => 'ns') }
        qr/Ghost/,
        'using the unresolved Kind fails closed, naming the Kind';
};

# ---------------------------------------------------------------------------
# Rung 2 wins: a `with` provider resolves the Kind before Unstructured.
# ---------------------------------------------------------------------------
subtest 'a `with` provider wins over Unstructured (rung 2 before rung 4)' => sub {
    plan skip_all => 'IO::K8s::GatewayAPI not available'
        unless eval { require IO::K8s::GatewayAPI; 1 };

    my ($api) = disco_api(with => ['IO::K8s::GatewayAPI']);

    # Gateway is served by discovery AND provided by IO::K8s::GatewayAPI: the
    # provider class must win, not Unstructured.
    is $api->expand_class('Gateway'), 'IO::K8s::GatewayAPI::V1::Gateway',
        'the provider Kind resolves to the provider class, not Unstructured';

    # And a foreign Kind the provider does NOT supply still becomes Unstructured.
    is $api->expand_class('Widget'), 'IO::K8s::Unstructured',
        'a Kind the provider does not cover still falls to Unstructured';
};

# ---------------------------------------------------------------------------
# Core kinds are unchanged.
# ---------------------------------------------------------------------------
subtest 'core kinds resolve to their typed classes, unchanged' => sub {
    my ($api) = disco_api();

    is $api->expand_class('Pod'), 'IO::K8s::Api::Core::V1::Pod',
        'a core Kind resolves to its typed class, never Unstructured';
    is $api->expand_class('Namespace'), 'IO::K8s::Api::Core::V1::Namespace',
        'another core Kind resolves typed';
};

# ---------------------------------------------------------------------------
# The fetch-free cheap path (t/36) is untouched: Unstructured only engages on
# the cluster-backed fallthrough, never for a name the built-in map answers.
# ---------------------------------------------------------------------------
subtest 'the cheap path stays fetch-free (no discovery for Pod or a +class)' => sub {
    my ($api, $io) = disco_api();

    is $api->expand_class('Pod'), 'IO::K8s::Api::Core::V1::Pod', 'Pod from the built-in map';
    is $api->expand_class('+My::Own::Widget'), 'My::Own::Widget', '+class returned as-is';

    is_deeply $io->calls, [], 'neither resolution made any HTTP request';
};

# ---------------------------------------------------------------------------
# resource_map_from_cluster => 0: no cluster, so no discovery confirmation ->
# an unknown Kind stays fail-closed rather than becoming Unstructured.
# ---------------------------------------------------------------------------
subtest 'without a cluster (resource_map_from_cluster => 0) there is no Unstructured' => sub {
    my ($api, $io) = disco_api(resource_map_from_cluster => 0);

    isnt $api->expand_class('Widget'), 'IO::K8s::Unstructured',
        'no discovery to confirm the GVK -> not Unstructured';
    is_deeply $io->calls, [], 'and nothing was fetched';
};

done_testing;
