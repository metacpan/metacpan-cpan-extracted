#!/usr/bin/env perl
# ensure_only prunes: everything labelled in the given kinds/namespaces that is
# not in the object set gets deleted. These tests pin what is NOT deleted as
# much as what is - a key mismatch between the applied objects and the listed
# items deletes the objects that were just applied.
#
# karr k33: the Kind of a listed item used to come from the `kinds` string, the
# Kind of an expected object from its class. A qualified
# 'group/version/Kind' entry never matched, so the applied objects went too.
# karr k34: a hashref manifest resolves through its apiVersion, not through the
# bare Kind's default version.
# karr k39: the key carries the API group - the same Kind name in two groups
# is two resources - but still no version.

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock qw(mock_api);
use Kubernetes::REST;
use Kubernetes::REST::Server;
use Kubernetes::REST::AuthToken;

my $HPA_V1 = '/apis/autoscaling/v1/namespaces/default/horizontalpodautoscalers';
my $HPA_V2 = '/apis/autoscaling/v2/namespaces/default/horizontalpodautoscalers';

# The mock matches on the path including its query string, and ensure_only
# always lists with a labelSelector - and prunes with propagationPolicy
# Background unless told otherwise (karr k49).
my $SEL = q{?labelSelector=app=demo};
my $BG  = q{?propagationPolicy=Background};

sub requests_for {
    my ($io, $method) = @_;
    return [ map { $_->{path} } grep { $_->{method} eq $method } @{ $io->requests } ];
}

sub hpa_item {
    my ($name) = @_;
    return {
        metadata => {
            name      => $name,
            namespace => 'default',
            labels    => { app => 'demo' },
        },
        spec => {
            scaleTargetRef => { apiVersion => 'apps/v1', kind => 'Deployment', name => 'web' },
            maxReplicas    => 3,
        },
    };
}

sub hpa_v1_manifest {
    my ($name) = @_;
    return {
        apiVersion => 'autoscaling/v1',
        kind       => 'HorizontalPodAutoscaler',
        %{ hpa_item($name) },
    };
}

# The server side of one HPA create plus a label-selected list of two items,
# the applied 'keep-me' and a leftover 'stale'. Items carry no kind/apiVersion,
# as in a real list response.
sub mock_hpa_cluster {
    my ($io, $list_path, $list_version) = @_;
    $io->add_response('POST', $HPA_V1, {
        %{ hpa_v1_manifest('keep-me') },
        metadata => { %{ hpa_item('keep-me')->{metadata} }, resourceVersion => '1' },
    });
    $io->add_response('GET', $list_path . $SEL, {
        apiVersion => $list_version,
        kind       => 'HorizontalPodAutoscalerList',
        items      => [ hpa_item('keep-me'), hpa_item('stale') ],
    });
    $io->add_response('DELETE', "$list_path/stale$BG",
        { kind => 'Status', apiVersion => 'v1', status => 'Success' });
}

subtest 'k33: a qualified kinds entry keeps the objects it just applied' => sub {
    my $api = mock_api();
    my $io  = $api->io;
    mock_hpa_cluster($io, $HPA_V1, 'autoscaling/v1');

    my $hpa = $api->k8s->new_object(
        'IO::K8s::Api::Autoscaling::V1::HorizontalPodAutoscaler', hpa_item('keep-me'));

    my @applied = eval {
        $api->ensure_only(
            label      => 'app=demo',
            objects    => [$hpa],
            kinds      => ['autoscaling/v1/HorizontalPodAutoscaler'],
            namespaces => ['default'],
        );
    };
    is($@, '', 'ensure_only does not die');
    is(scalar @applied, 1, 'one applied object returned');

    is_deeply(requests_for($io, 'GET'),
        [ "$HPA_V1/keep-me", $HPA_V1 ],
        'the qualified entry lists the autoscaling/v1 collection');
    is_deeply(requests_for($io, 'DELETE'), [ "$HPA_V1/stale" ],
        'only the unexpected item is deleted, never the applied keep-me');
};

subtest 'bare kinds entry: unchanged - the unexpected item goes, the expected stays' => sub {
    my $api = mock_api();
    my $io  = $api->io;
    my $CM  = '/api/v1/namespaces/default/configmaps';
    my $cm_item = sub {
        my ($name) = @_;
        return { metadata => { name => $name, namespace => 'default', labels => { app => 'demo' } } };
    };
    $io->add_response('POST', $CM, {
        apiVersion => 'v1', kind => 'ConfigMap',
        metadata   => { %{ $cm_item->('keep-me')->{metadata} }, resourceVersion => '1' },
    });
    $io->add_response('GET', $CM . $SEL, {
        apiVersion => 'v1', kind => 'ConfigMapList',
        items      => [ $cm_item->('keep-me'), $cm_item->('stale') ],
    });
    $io->add_response('DELETE', "$CM/stale$BG",
        { kind => 'Status', apiVersion => 'v1', status => 'Success' });

    $api->ensure_only(
        label      => 'app=demo',
        objects    => [ $api->k8s->new_object('ConfigMap', $cm_item->('keep-me')) ],
        kinds      => ['ConfigMap'],
        namespaces => ['default'],
    );

    is_deeply(requests_for($io, 'DELETE'), [ "$CM/stale" ],
        'bare Kind: stale deleted, keep-me kept');
};

subtest 'the key is the Kind, not the version: a v1 object survives a bare (v2) listing' => sub {
    # Bare HorizontalPodAutoscaler resolves to autoscaling/v2, the object was
    # applied as autoscaling/v1. Same resource in two representations - keying
    # on the full class name instead of the Kind would delete keep-me here.
    my $api = mock_api();
    my $io  = $api->io;
    mock_hpa_cluster($io, $HPA_V2, 'autoscaling/v2');

    $api->ensure_only(
        label      => 'app=demo',
        objects    => [ $api->k8s->new_object(
            'IO::K8s::Api::Autoscaling::V1::HorizontalPodAutoscaler', hpa_item('keep-me')) ],
        kinds      => ['HorizontalPodAutoscaler'],
        namespaces => ['default'],
    );

    is_deeply(requests_for($io, 'DELETE'), [ "$HPA_V2/stale" ],
        'keep-me listed through v2 is still recognised');
};

subtest 'k34: a hashref in objects resolves through its apiVersion' => sub {
    my $api = mock_api();
    my $io  = $api->io;
    mock_hpa_cluster($io, $HPA_V1, 'autoscaling/v1');

    my @applied = eval {
        $api->ensure_only(
            label      => 'app=demo',
            objects    => [ hpa_v1_manifest('keep-me') ],
            kinds      => ['autoscaling/v1/HorizontalPodAutoscaler'],
            namespaces => ['default'],
        );
    };
    is($@, '', 'ensure_only does not die');
    isa_ok($applied[0], 'IO::K8s::Api::Autoscaling::V1::HorizontalPodAutoscaler',
        'applied object');
    is_deeply(requests_for($io, 'POST'), [ $HPA_V1 ],
        'created on the autoscaling/v1 endpoint, not the v2 default');
    is_deeply(requests_for($io, 'DELETE'), [ "$HPA_V1/stale" ],
        'the applied manifest is recognised in the listing');
};

subtest 'k34: an apiVersion no class serves croaks before anything is applied' => sub {
    my $api = mock_api();
    my $io  = $api->io;

    my $manifest = hpa_v1_manifest('keep-me');
    $manifest->{apiVersion} = 'autoscaling/v9';

    eval {
        $api->ensure_only(
            label   => 'app=demo',
            objects => [ $api->k8s->new_object('ConfigMap',
                metadata => { name => 'first', namespace => 'default' }), $manifest ],
            kinds   => ['HorizontalPodAutoscaler'],
        );
    };
    like($@, qr{autoscaling/v9}, 'the error names the apiVersion');
    like($@, qr{HorizontalPodAutoscaler}, 'the error names the Kind');
    is_deeply($io->requests, [], 'no request was sent - not even for the valid object');
};

# ---------------------------------------------------------------------------
# Unstructured items: their Kind is instance data, the class name is just
# 'Unstructured'. Keying on the class name would make every Unstructured Kind
# collide - a stale Gadget named like an applied Widget would survive.
# ---------------------------------------------------------------------------
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
                            resource     => 'gadgets',
                            responseKind => { group => 'example.com', version => 'v1', kind => 'Gadget' },
                            scope        => 'Namespaced',
                        },
                    ],
                },
            ],
        },
    ],
);

subtest 'Unstructured: the key uses the item Kind, not the class name' => sub {
    my $io = Test::Kubernetes::Mock::IO->new;
    $io->add_response('GET', '/api',  \%CORE_DISCOVERY);
    $io->add_response('GET', '/apis', \%GROUPED_DISCOVERY);
    my $api = Kubernetes::REST->new(
        server      => Kubernetes::REST::Server->new(endpoint => 'http://mock.local'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'MockToken'),
        io          => $io,
    );

    my $WIDGETS = '/apis/example.com/v1/namespaces/default/widgets';
    my $GADGETS = '/apis/example.com/v1/namespaces/default/gadgets';
    my $item = sub {
        my ($kind, $name) = @_;
        return {
            apiVersion => 'example.com/v1',
            kind       => $kind,
            metadata   => { name => $name, namespace => 'default', labels => { app => 'demo' } },
        };
    };

    $io->add_response('POST', $WIDGETS, $item->('Widget', 'foo'));
    $io->add_response('GET', $WIDGETS . $SEL, {
        apiVersion => 'example.com/v1', kind => 'WidgetList',
        items      => [ $item->('Widget', 'foo'), $item->('Widget', 'stale') ],
    });
    $io->add_response('GET', $GADGETS . $SEL, {
        apiVersion => 'example.com/v1', kind => 'GadgetList',
        items      => [ $item->('Gadget', 'foo') ],
    });
    my $ok = { kind => 'Status', apiVersion => 'v1', status => 'Success' };
    $io->add_response('DELETE', "$WIDGETS/stale$BG", $ok);
    $io->add_response('DELETE', "$GADGETS/foo$BG", $ok);

    my @applied = eval {
        $api->ensure_only(
            label      => 'app=demo',
            objects    => [ $item->('Widget', 'foo') ],
            kinds      => [qw( Widget Gadget )],
            namespaces => ['default'],
        );
    };
    is($@, '', 'ensure_only does not die');
    isa_ok($applied[0], 'IO::K8s::Unstructured', 'applied object');

    is_deeply([ sort @{ requests_for($io, 'DELETE') } ],
        [ "$GADGETS/foo", "$WIDGETS/stale" ],
        'the applied Widget foo stays; the stale Widget and the same-named Gadget go');
};

# ---------------------------------------------------------------------------
# karr k39: Istio's Gateway (networking.istio.io) and the Gateway API's
# Gateway (gateway.networking.k8s.io) share a Kind name. With the same
# namespace and name they are still two resources: a labelled one that is not
# in the object set must go, whichever group the applied one is in.
# ---------------------------------------------------------------------------
my $ISTIO_GW = '/apis/networking.istio.io/v1/namespaces/default/gateways';
my $API_GW   = '/apis/gateway.networking.k8s.io/v1/namespaces/default/gateways';

sub gateway_item {
    my ($name) = @_;
    return {
        metadata => { name => $name, namespace => 'default', labels => { app => 'demo' } },
        spec     => { selector => 'ingress' },
    };
}

subtest 'k39: the same Kind in another group is another resource' => sub {
    my $api = mock_api();
    my $io  = $api->io;
    my $ok  = { kind => 'Status', apiVersion => 'v1', status => 'Success' };

    $io->add_response('POST', $API_GW, {
        apiVersion => 'gateway.networking.k8s.io/v1', kind => 'Gateway',
        %{ gateway_item('web') },
    });
    # Items carry no kind/apiVersion, as in a real list response - the group
    # comes from the class each collection was listed through.
    $io->add_response('GET', $API_GW . $SEL, {
        apiVersion => 'gateway.networking.k8s.io/v1', kind => 'GatewayList',
        items      => [ gateway_item('web') ],
    });
    $io->add_response('GET', $ISTIO_GW . $SEL, {
        apiVersion => 'networking.istio.io/v1', kind => 'GatewayList',
        items      => [ gateway_item('web') ],
    });
    $io->add_response('DELETE', "$API_GW/web$BG",   $ok);
    $io->add_response('DELETE', "$ISTIO_GW/web$BG", $ok);

    my @applied = eval {
        $api->ensure_only(
            label      => 'app=demo',
            objects    => [ $api->k8s->new_object('+My::GatewayApi::Gateway', gateway_item('web')) ],
            kinds      => [qw( +My::GatewayApi::Gateway +My::Istio::Gateway )],
            namespaces => ['default'],
        );
    };
    is($@, '', 'ensure_only does not die');
    is(scalar @applied, 1, 'one applied object returned');

    is_deeply(requests_for($io, 'GET'),
        [ "$API_GW/web", $API_GW, $ISTIO_GW ],
        'both groups were listed');
    is_deeply(requests_for($io, 'DELETE'), [ "$ISTIO_GW/web" ],
        'the Istio Gateway web goes; the applied Gateway API Gateway web stays');
};

subtest 'k39: an Unstructured item keys on the group in its own apiVersion' => sub {
    # The applied object is a typed Istio Gateway; the bare 'Gateway' entry
    # resolves through discovery to Unstructured in another group, whose item
    # carries its group in its apiVersion. Same Kind, namespace and name -
    # different resource.
    my $io = Test::Kubernetes::Mock::IO->new;
    $io->add_response('GET', '/api', \%CORE_DISCOVERY);
    $io->add_response('GET', '/apis', {
        kind  => 'APIGroupDiscoveryList',
        items => [ {
            metadata => { name => 'gateway.example.com' },
            versions => [ {
                version   => 'v1',
                resources => [ {
                    resource     => 'gateways',
                    responseKind => { group => 'gateway.example.com', version => 'v1', kind => 'Gateway' },
                    scope        => 'Namespaced',
                } ],
            } ],
        } ],
    });
    my $api = Kubernetes::REST->new(
        server      => Kubernetes::REST::Server->new(endpoint => 'http://mock.local'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'MockToken'),
        io          => $io,
    );

    my $OTHER_GW = '/apis/gateway.example.com/v1/namespaces/default/gateways';
    $io->add_response('POST', $ISTIO_GW, {
        apiVersion => 'networking.istio.io/v1', kind => 'Gateway',
        %{ gateway_item('web') },
    });
    $io->add_response('GET', $OTHER_GW . $SEL, {
        apiVersion => 'gateway.example.com/v1', kind => 'GatewayList',
        items      => [ {
            apiVersion => 'gateway.example.com/v1', kind => 'Gateway',
            %{ gateway_item('web') },
        } ],
    });
    $io->add_response('DELETE', "$OTHER_GW/web$BG",
        { kind => 'Status', apiVersion => 'v1', status => 'Success' });

    eval {
        $api->ensure_only(
            label      => 'app=demo',
            objects    => [ $api->k8s->new_object('+My::Istio::Gateway', gateway_item('web')) ],
            kinds      => ['Gateway'],
            namespaces => ['default'],
        );
    };
    is($@, '', 'ensure_only does not die');
    is_deeply(requests_for($io, 'POST'), [ $ISTIO_GW ], 'the Istio Gateway was applied');
    is_deeply(requests_for($io, 'DELETE'), [ "$OTHER_GW/web" ],
        'the Unstructured gateway.example.com Gateway web goes');
};

# ---------------------------------------------------------------------------
# karr k37: a prune that did nothing must not look like one that worked. A
# failed list or delete warns with what was skipped and why, and the prune
# goes on with the rest. A 404 stays silent: the cluster does not serve the
# Kind, or the object is already gone. The return value is the applied
# objects either way.
# ---------------------------------------------------------------------------
{
    package Test::EnsureOnly::FailingIO;
    use Moo;
    extends 'Test::Kubernetes::Mock::IO';

    use JSON::MaybeXS ();

    # 'METHOD /path?query' => status. Those requests fail with a Status body
    # naming the status; everything else goes to the mock, which answers 200
    # for a registered response and 404 for anything else.
    has fail => (is => 'ro', default => sub { {} });

    my $wire_json = JSON::MaybeXS->new(utf8 => 1, canonical => 1);

    around call => sub {
        my ($orig, $self, $req) = @_;
        (my $path = $req->url) =~ s{\Ahttps?://[^/]+}{};
        my $status = $self->fail->{ $req->method . ' ' . $path }
            or return $self->$orig($req);
        (my $clean_path = $path) =~ s{\?.*}{};
        push @{ $self->requests },
            { method => $req->method, path => $clean_path, content => $req->content };
        return Test::Kubernetes::Mock::Response->new(
            status  => $status,
            content => $wire_json->encode({
                kind => 'Status', apiVersion => 'v1', status => 'Failure',
                code => $status, message => "mock refuses with $status",
            }),
        );
    };
}

sub failing_api {
    my (%fail) = @_;
    return Kubernetes::REST->new(
        server      => Kubernetes::REST::Server->new(endpoint => 'http://mock.local'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'MockToken'),
        resource_map_from_cluster => 0,
        io          => Test::EnsureOnly::FailingIO->new(fail => \%fail),
    );
}

my $CM_DEFAULT = '/api/v1/namespaces/default/configmaps';
my $CM_OTHER   = '/api/v1/namespaces/other/configmaps';

sub cm_item {
    my ($name, $ns) = @_;
    return { metadata => { name => $name, namespace => $ns // 'default', labels => { app => 'demo' } } };
}

sub keep_me_cm {
    my ($api) = @_;
    return $api->k8s->new_object('ConfigMap', cm_item('keep-me'));
}

# keep-me is created in default; each given collection lists the given items.
sub mock_cm_cluster {
    my ($io, %items_in) = @_;
    $io->add_response('POST', $CM_DEFAULT, {
        apiVersion => 'v1', kind => 'ConfigMap',
        metadata   => { %{ cm_item('keep-me')->{metadata} }, resourceVersion => '1' },
    });
    for my $collection (sort keys %items_in) {
        $io->add_response('GET', $collection . $SEL, {
            apiVersion => 'v1', kind => 'ConfigMapList', items => $items_in{$collection},
        });
    }
}

my $DELETED = { kind => 'Status', apiVersion => 'v1', status => 'Success' };

sub ensure_only_warnings {
    my ($api, %args) = @_;
    my @warnings;
    my @applied = do {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        $api->ensure_only(label => 'app=demo', %args);
    };
    return (\@warnings, \@applied);
}

subtest 'k37: a Kind the cluster does not serve (list 404) is skipped silently' => sub {
    my $api = failing_api();
    my $io  = $api->io;
    mock_cm_cluster($io, $CM_DEFAULT => [ cm_item('keep-me'), cm_item('stale') ]);
    $io->add_response('DELETE', "$CM_DEFAULT/stale$BG", $DELETED);
    # No Role list registered: the mock answers 404, like a cluster that
    # does not serve the Kind.

    my ($warnings, $applied) = ensure_only_warnings($api,
        objects    => [ keep_me_cm($api) ],
        kinds      => [qw( Role ConfigMap )],
        namespaces => ['default'],
    );
    is_deeply($warnings, [], 'no warning for a 404 list');
    is(scalar @$applied, 1, 'the applied object is returned');
    ok((grep { $_ eq '/apis/rbac.authorization.k8s.io/v1/namespaces/default/roles' }
        @{ requests_for($io, 'GET') }), 'the Role list was attempted');
    is_deeply(requests_for($io, 'DELETE'), [ "$CM_DEFAULT/stale" ],
        'the next kinds entry is still pruned');
};

subtest 'k37: a failed list warns with Kind, namespace and reason; the rest still runs' => sub {
    my $api = failing_api("GET $CM_DEFAULT$SEL" => 403);
    my $io  = $api->io;
    mock_cm_cluster($io, $CM_OTHER => [ cm_item('stale', 'other') ]);
    $io->add_response('DELETE', "$CM_OTHER/stale$BG", $DELETED);

    my ($warnings, $applied) = ensure_only_warnings($api,
        objects    => [ keep_me_cm($api) ],
        kinds      => ['ConfigMap'],
        namespaces => [qw( default other )],
    );
    is(scalar @$warnings, 1, 'one warning') or diag explain $warnings;
    my $w = $warnings->[0] // '';
    like($w, qr/\Aensure_only: cannot list ConfigMap in namespace 'default'/,
        'it names the Kind and the namespace');
    like($w, qr/403/, 'it names the status');
    like($w, qr/mock refuses with 403/, 'it carries the server message');
    like($w, qr/ at \Q${\ __FILE__}\E line \d+\.\n\z/, 'it points at the caller, once');
    unlike($w, qr/ line \d+\..* line \d+\./s, 'no second location from the caught croak');

    is(scalar @$applied, 1, 'the applied object is still returned');
    is_deeply(requests_for($io, 'DELETE'), [ "$CM_OTHER/stale" ],
        'the other namespace is still pruned');
};

subtest 'k37: a failed cluster-scoped list says so' => sub {
    my $CLUSTER_ROLES = '/apis/rbac.authorization.k8s.io/v1/clusterroles';
    my $api = failing_api("GET $CLUSTER_ROLES$SEL" => 500);

    my ($warnings, $applied) = ensure_only_warnings($api,
        objects => [],
        kinds   => ['ClusterRole'],
    );
    is(scalar @$warnings, 1, 'one warning') or diag explain $warnings;
    like($warnings->[0] // '', qr/cannot list ClusterRole at cluster scope/,
        'it names the Kind and cluster scope');
    like($warnings->[0] // '', qr/500/, 'it names the status');
    is_deeply($applied, [], 'the return value is still the (empty) applied list');
};

subtest 'k37: a kinds entry no class resolves warns, it is not taken for a 404' => sub {
    my $api = failing_api();

    my ($warnings) = ensure_only_warnings($api,
        objects    => [],
        kinds      => ['NoSuchKind'],
        namespaces => ['default'],
    );
    is(scalar @$warnings, 1, 'one warning') or diag explain $warnings;
    like($warnings->[0] // '', qr/cannot list NoSuchKind in namespace 'default'/,
        'it names the kinds entry');
    is_deeply($api->io->requests, [], 'nothing was sent');
};

subtest 'k37: a delete 404 is silent, a failed delete warns and the prune goes on' => sub {
    my $api = failing_api("DELETE $CM_DEFAULT/locked$BG" => 403);
    my $io  = $api->io;
    mock_cm_cluster($io, $CM_DEFAULT =>
        [ map { cm_item($_) } qw( keep-me gone locked stale ) ]);
    # No DELETE registered for gone: the mock answers 404 - already deleted.
    $io->add_response('DELETE', "$CM_DEFAULT/stale$BG", $DELETED);

    my ($warnings, $applied) = ensure_only_warnings($api,
        objects    => [ keep_me_cm($api) ],
        kinds      => ['ConfigMap'],
        namespaces => ['default'],
    );
    is(scalar @$warnings, 1, 'one warning, for locked only') or diag explain $warnings;
    my $w = $warnings->[0] // '';
    like($w, qr/\Aensure_only: cannot delete ConfigMap 'locked' in namespace 'default'/,
        'it names the Kind, the name and the namespace');
    like($w, qr/403/, 'it names the status');
    like($w, qr/mock refuses with 403/, 'it carries the server message');

    is_deeply(requests_for($io, 'DELETE'),
        [ map { "$CM_DEFAULT/$_" } qw( gone locked stale ) ],
        'every unexpected item was tried, stale after the failed locked');
    is(scalar @$applied, 1, 'the applied object is returned');
};

subtest 'k37: the warnings can be promoted to errors' => sub {
    my $api = failing_api("GET $CM_DEFAULT$SEL" => 403);
    mock_cm_cluster($api->io);

    my @applied = eval {
        local $SIG{__WARN__} = sub { die @_ };
        $api->ensure_only(
            label      => 'app=demo',
            objects    => [ keep_me_cm($api) ],
            kinds      => ['ConfigMap'],
            namespaces => ['default'],
        );
    };
    like($@, qr/cannot list ConfigMap in namespace 'default'/, 'ensure_only dies with the warning');
    is(scalar @applied, 0, 'and returns nothing');
};

# ---------------------------------------------------------------------------
# karr k43: a qualified kinds entry names one group/version. When the cluster
# does not serve exactly that one, the entry resolves to no class and is
# warned about like any other such entry (k37) - it is never listed, let alone
# pruned, in another group or version that happens to serve the Kind. In
# %GROUPED_DISCOVERY example.com/v1 is the only group/version serving Widget.
# ---------------------------------------------------------------------------
subtest 'k43: a qualified kinds entry of an unserved group/version prunes nothing elsewhere' => sub {
    my $WIDGETS = '/apis/example.com/v1/namespaces/default/widgets';
    my $widget_cluster = sub {
        my $io = Test::Kubernetes::Mock::IO->new;
        $io->add_response('GET', '/api',  \%CORE_DISCOVERY);
        $io->add_response('GET', '/apis', \%GROUPED_DISCOVERY);
        $io->add_response('GET', $WIDGETS . $SEL, {
            apiVersion => 'example.com/v1', kind => 'WidgetList',
            items      => [ {
                apiVersion => 'example.com/v1', kind => 'Widget',
                metadata   => { name => 'stale', namespace => 'default', labels => { app => 'demo' } },
            } ],
        });
        $io->add_response('DELETE', "$WIDGETS/stale$BG", $DELETED);
        my $api = Kubernetes::REST->new(
            server      => Kubernetes::REST::Server->new(endpoint => 'http://mock.local'),
            credentials => Kubernetes::REST::AuthToken->new(token => 'MockToken'),
            io          => $io,
        );
        return ($api, $io);
    };

    for my $entry (qw( other.example.com/v1/Widget example.com/v2/Widget )) {
        my ($api, $io) = $widget_cluster->();
        my ($warnings, $applied) = ensure_only_warnings($api,
            objects    => [],
            kinds      => [$entry],
            namespaces => ['default'],
        );
        is_deeply(requests_for($io, 'DELETE'), [], "$entry: nothing deleted");
        is_deeply([ grep { m{/widgets} } @{ requests_for($io, 'GET') } ], [],
            "$entry: the example.com/v1 Widgets are not even listed");
        is(scalar @$warnings, 1, "$entry: one warning") or diag explain $warnings;
        like($warnings->[0] // '',
            qr/\Aensure_only: cannot list \Q$entry\E in namespace 'default', nothing pruned there/,
            "$entry: it names the entry and the namespace");
    }

    # The bare Kind is unchanged: it resolves through the group serving it
    # (D17) and prunes there.
    my ($api, $io) = $widget_cluster->();
    my ($warnings) = ensure_only_warnings($api,
        objects    => [],
        kinds      => ['Widget'],
        namespaces => ['default'],
    );
    is_deeply($warnings, [], 'bare Widget: no warning');
    is_deeply(requests_for($io, 'DELETE'), [ "$WIDGETS/stale" ],
        'bare Widget: the stale example.com Widget goes');
};

done_testing;
