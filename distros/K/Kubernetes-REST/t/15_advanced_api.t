#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";

use Test::Kubernetes::Mock qw(mock_api);
use Kubernetes::REST::HTTPRequest;

# ============================================================================
# HTTPRequest::authenticate()
# ============================================================================

subtest 'HTTPRequest - authenticate with credentials' => sub {
    my $req = Kubernetes::REST::HTTPRequest->new(
        method => 'GET',
        url => 'http://test/api/v1/pods',
        headers => {},
        credentials => Kubernetes::REST::AuthToken->new(token => 'bearer-123'),
    );
    $req->authenticate;
    is $req->headers->{Authorization}, 'Bearer bearer-123',
        'authenticate sets Authorization header';
};

subtest 'HTTPRequest - authenticate without credentials' => sub {
    my $req = Kubernetes::REST::HTTPRequest->new(
        method => 'GET',
        url => 'http://test/api/v1/pods',
        headers => {},
    );
    lives_ok { $req->authenticate } 'authenticate with no credentials does not die';
    ok !exists $req->headers->{Authorization}, 'no Authorization header set';
};

subtest 'HTTPRequest - url builder from server + uri' => sub {
    require Kubernetes::REST::Server;
    my $req = Kubernetes::REST::HTTPRequest->new(
        method => 'GET',
        uri => '/api/v1/pods',
        headers => {},
        server => Kubernetes::REST::Server->new(endpoint => 'https://k8s.local:6443'),
    );
    is $req->url, 'https://k8s.local:6443/api/v1/pods', 'url built from server + uri';
};

# ============================================================================
# REST.pm - fetch_resource_map from aggregated discovery (design D11)
#
# The cluster map is built from GET /api + GET /apis (APIGroupDiscoveryList),
# not from /openapi/v2. The class-name mapping is unchanged (exception tables
# for apiextensions/apiregistration included); only the source moved. The
# per-instance caching, the catalog shape and the pre-1.27 fallback are pinned
# in t/39_aggregated_discovery.t.
# ============================================================================

# Build an APIGroupDiscoveryList for one group with a single served version.
sub disco_group {
    my ($name, $version, @resources) = @_;
    return {
        metadata => { name => $name },
        versions => [ { version => $version, resources => \@resources } ],
    };
}

sub disco_resource {
    my ($plural, $group, $version, $kind, $scope) = @_;
    return {
        resource     => $plural,
        responseKind => { group => $group, version => $version, kind => $kind },
        scope        => $scope // 'Namespaced',
    };
}

subtest 'fetch_resource_map - maps kinds to IO::K8s classes' => sub {
    my $api = mock_api();

    $api->io->add_response('GET', '/api', {
        kind  => 'APIGroupDiscoveryList',
        items => [
            disco_group('', 'v1',
                disco_resource('namespaces', '', 'v1', 'Namespace', 'Cluster'),
                disco_resource('pods',       '', 'v1', 'Pod',       'Namespaced'),
            ),
        ],
    });
    $api->io->add_response('GET', '/apis', {
        kind  => 'APIGroupDiscoveryList',
        items => [
            disco_group('apps', 'v1',
                disco_resource('deployments', 'apps', 'v1', 'Deployment')),
            disco_group('apiextensions.k8s.io', 'v1',
                disco_resource('customresourcedefinitions', 'apiextensions.k8s.io', 'v1',
                    'CustomResourceDefinition', 'Cluster')),
            disco_group('apiregistration.k8s.io', 'v1',
                disco_resource('apiservices', 'apiregistration.k8s.io', 'v1',
                    'APIService', 'Cluster')),
        ],
    });

    my $map = $api->fetch_resource_map;
    ok $map, 'fetch_resource_map returns a hashref';
    is ref $map, 'HASH', 'is a hashref';

    # Core resources
    is $map->{Namespace}, 'Api::Core::V1::Namespace', 'Namespace mapped to Core';
    is $map->{Pod}, 'Api::Core::V1::Pod', 'Pod mapped to Core';

    # Apps group
    is $map->{Deployment}, 'Api::Apps::V1::Deployment', 'Deployment mapped to Apps';

    # Apiextensions (exception table preserved)
    is $map->{CustomResourceDefinition},
        'ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinition',
        'CRD mapped to apiextensions path';

    # Apiregistration (exception table preserved)
    is $map->{APIService},
        'KubeAggregator::Pkg::Apis::Apiregistration::V1::APIService',
        'APIService mapped to apiregistration path';
};

subtest 'fetch_resource_map - skips List kinds' => sub {
    my $api = mock_api();

    $api->io->add_response('GET', '/api', {
        kind  => 'APIGroupDiscoveryList',
        items => [
            disco_group('', 'v1', disco_resource('pods', '', 'v1', 'PodList')),
        ],
    });
    $api->io->add_response('GET', '/apis',
        { kind => 'APIGroupDiscoveryList', items => [] });

    my $map = $api->fetch_resource_map;
    ok !exists $map->{PodList}, 'List kinds are skipped';
};

# D17 (was "prefers stable versions"): the OLD claim was that a fixed
# "stable beats alpha/beta" heuristic always picked the stable class,
# regardless of which version the cluster served first. The NEW claim is that
# the map resolves to the version the CLUSTER marks preferred. Here
# networking.k8s.io serves ServiceCIDR in v1beta1 (listed first -> preferred)
# and v1; both classes ship, so the short name must follow the cluster and pick
# the beta one. (The full stop-inventing / provider-fallthrough matrix lives in
# t/43_resolution_order.t.)
subtest 'fetch_resource_map - resolves to the cluster preferred version' => sub {
    plan skip_all =>
        'IO::K8s::Api::Networking::V1beta1::ServiceCIDR not shipped by this IO::K8s'
        unless eval { require IO::K8s::Api::Networking::V1beta1::ServiceCIDR; 1 };

    my $api = mock_api();

    $api->io->add_response('GET', '/api',
        { kind => 'APIGroupDiscoveryList', items => [] });
    # v1beta1 is served first (preferred), v1 second; the map follows the
    # cluster and picks the beta version.
    $api->io->add_response('GET', '/apis', {
        kind  => 'APIGroupDiscoveryList',
        items => [
            {
                metadata => { name => 'networking.k8s.io' },
                versions => [
                    { version => 'v1beta1', resources => [
                        disco_resource('servicecidrs', 'networking.k8s.io',
                            'v1beta1', 'ServiceCIDR', 'Cluster') ] },
                    { version => 'v1', resources => [
                        disco_resource('servicecidrs', 'networking.k8s.io',
                            'v1', 'ServiceCIDR', 'Cluster') ] },
                ],
            },
        ],
    });

    my $map = $api->fetch_resource_map;
    is $map->{ServiceCIDR}, 'Api::Networking::V1beta1::ServiceCIDR',
        'cluster-preferred v1beta1 chosen over stable v1';
};

subtest 'fetch_resource_map - error on 4xx' => sub {
    my $api = mock_api();
    # No discovery response mocked - GET /api gets 404
    throws_ok { $api->fetch_resource_map } qr/Could not load resource map/,
        'throws on 404';
};

# ============================================================================
# REST.pm - _load_resource_map_from_cluster error fallback
# ============================================================================

subtest '_load_resource_map_from_cluster - falls back to defaults on error' => sub {
    my $api = mock_api();
    # No discovery mock → GET /api 404 → should fall back

    my $map;
    {
        # Suppress warning
        local $SIG{__WARN__} = sub {};
        $map = $api->_load_resource_map_from_cluster;
    }
    ok $map, 'fallback returns a map';
    is ref $map, 'HASH', 'is a hashref';
    # Should be the IO::K8s default map
    ok exists $map->{Pod} || exists $map->{Namespace},
        'contains expected default entries';
};

# ============================================================================
# REST.pm - schema_for and compare_schema
# ============================================================================

subtest 'schema_for - by OpenAPI definition name' => sub {
    my $api = mock_api();

    $api->io->add_response('GET', '/openapi/v2', {
        definitions => {
            'io.k8s.api.core.v1.Pod' => {
                type => 'object',
                properties => { metadata => { type => 'object' } },
            },
        },
        paths => {},
    });

    my $schema = $api->schema_for('io.k8s.api.core.v1.Pod');
    ok $schema, 'schema found by OpenAPI name';
    is $schema->{type}, 'object', 'schema type is object';
};

subtest 'schema_for - by short name' => sub {
    my $api = mock_api();

    $api->io->add_response('GET', '/openapi/v2', {
        definitions => {
            'io.k8s.api.core.v1.Pod' => {
                type => 'object',
                description => 'Pod is a collection of containers',
            },
        },
        paths => {},
    });

    my $schema = $api->schema_for('Pod');
    ok $schema, 'schema found by short name';
    like $schema->{description}, qr/Pod/, 'description matches';
};

subtest 'schema_for - not found returns undef' => sub {
    my $api = mock_api();

    $api->io->add_response('GET', '/openapi/v2', {
        definitions => {},
        paths => {},
    });

    my $schema = $api->schema_for('NonExistent');
    ok !defined $schema, 'returns undef for unknown schema';
};

# ============================================================================
# REST.pm - V0 group accessors
# ============================================================================

subtest 'v0 group accessors return V0Group subclasses' => sub {
    my $api = mock_api();

    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING} = 1;

    for my $group (qw(Core Apps Batch Networking Storage Policy Autoscaling
                       RbacAuthorization Certificates Coordination Events
                       Scheduling Authentication Authorization
                       Admissionregistration Apiextensions Apiregistration)) {
        my $obj = $api->$group;
        ok $obj, "$group accessor returns object";
        isa_ok $obj, 'Kubernetes::REST::V0Group', "$group is a V0Group";
    }
};

subtest 'v0 group classes survive the bareword collision with their accessor' => sub {
    my $api = mock_api();
    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING} = 1;

    # Every accessor shares its name with the class it wraps, so Perl resolves
    # the bareword below against &Kubernetes::REST::Core and calls it without
    # an invocant. The accessor has to hand back the class name for that to
    # land on ->new the way the caller meant it.
    my $group;
    lives_ok { $group = Kubernetes::REST::Core->new(api => $api) }
        'Kubernetes::REST::Core->new survives the bareword collision';
    isa_ok $group, 'Kubernetes::REST::V0Group';

    SKIP: {
        skip 'no group object to dispatch through', 1 unless ref $group;

        $api->io->add_response('GET', '/api/v1/namespaces/myns/pods', {
            kind => 'PodList', items => [],
        });
        isa_ok $group->ListNamespacedPod(namespace => 'myns'), 'IO::K8s::List';
    }

    for my $name (qw(Core Apps Batch Networking Storage Policy Autoscaling
                     RbacAuthorization Certificates Coordination Events
                     Scheduling Authentication Authorization
                     Admissionregistration Apiextensions Apiregistration)) {
        my $class = eval { Kubernetes::REST->can($name)->() };
        is $class, "Kubernetes::REST::$name",
            "$name accessor without invocant returns the class name";
    }
};

subtest 'v0 group AUTOLOAD dispatches to new API' => sub {
    my $api = mock_api();
    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING} = 1;

    # Add mock response for listing namespaces
    $api->io->add_response('GET', '/api/v1/namespaces', {
        kind => 'NamespaceList',
        items => [
            {
                apiVersion => 'v1',
                kind => 'Namespace',
                metadata => { name => 'default', uid => 'uid1' },
            },
        ],
    });

    my $result = $api->Core->ListNamespace;
    isa_ok $result, 'IO::K8s::List', 'v0 ListNamespace returns list';
    ok scalar @{$result->items} > 0, 'list has items';
};

subtest 'v0 group deprecation warning' => sub {
    my $api = mock_api();
    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING};
    delete $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING};

    $api->io->add_response('GET', '/api/v1/namespaces', {
        kind => 'NamespaceList', items => [],
    });

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $api->Core->ListNamespace;
    ok scalar @warnings > 0, 'deprecation warning emitted';
    like $warnings[0], qr/deprecated/, 'warning mentions deprecated';
};

subtest 'v0 group AUTOLOAD - unknown method' => sub {
    my $api = mock_api();
    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING} = 1;

    throws_ok { $api->Core->CompletelyBogusMethod } qr/Unknown method/,
        'unknown method dies';
};

subtest 'v0 group - Read dispatches to get()' => sub {
    my $api = mock_api();
    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING} = 1;

    $api->io->add_response('GET', '/api/v1/namespaces/default', {
        apiVersion => 'v1', kind => 'Namespace',
        metadata => { name => 'default', uid => 'uid1' },
    });

    my $ns = $api->Core->ReadNamespace(name => 'default');
    is $ns->metadata->name, 'default', 'ReadNamespace dispatches to get()';
};

subtest 'v0 group - Delete dispatches to delete()' => sub {
    my $api = mock_api();
    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING} = 1;

    $api->io->add_response('DELETE', '/api/v1/namespaces/test', {
        kind => 'Status', status => 'Success',
    });

    my $result = $api->Core->DeleteNamespace(name => 'test');
    is $result, 1, 'DeleteNamespace dispatches to delete()';
};

subtest 'v0 group - ListNamespacedPod with namespace' => sub {
    my $api = mock_api();
    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING} = 1;

    $api->io->add_response('GET', '/api/v1/namespaces/myns/pods', {
        kind => 'PodList', items => [
            { apiVersion => 'v1', kind => 'Pod', metadata => { name => 'p1', namespace => 'myns' } },
        ],
    });

    my $result = $api->Core->ListNamespacedPod(namespace => 'myns');
    isa_ok $result, 'IO::K8s::List';
    is scalar @{$result->items}, 1, 'got one pod';
};

subtest 'v0 group - ListPodForAllNamespaces (non-namespaced)' => sub {
    my $api = mock_api();
    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING} = 1;

    $api->io->add_response('GET', '/api/v1/pods', {
        kind => 'PodList', items => [],
    });

    my $result = $api->Core->ListPodForAllNamespaces;
    isa_ok $result, 'IO::K8s::List';
};

subtest 'v0 group - Apps group maps correctly' => sub {
    my $api = mock_api();
    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING} = 1;

    $api->io->add_response('GET', '/apis/apps/v1/namespaces/default/deployments', {
        kind => 'DeploymentList', items => [],
    });

    my $result = $api->Apps->ListNamespacedDeployment(namespace => 'default');
    isa_ok $result, 'IO::K8s::List';
};

subtest 'v0 group - can() for v0 methods' => sub {
    my $api = mock_api();
    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING} = 1;

    my $core = $api->Core;
    ok $core->can('ListNamespace'), 'can(ListNamespace) returns true';
    ok $core->can('ReadNamespacedPod'), 'can(ReadNamespacedPod) returns true';
    ok !$core->can('CompletelyBogus'), 'can(CompletelyBogus) returns false';
};

subtest 'v0 group - deprecation warning formats' => sub {
    my $api = mock_api();
    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING};
    delete $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING};

    # Test Read deprecation message
    $api->io->add_response('GET', '/api/v1/namespaces/test', {
        apiVersion => 'v1', kind => 'Namespace',
        metadata => { name => 'test', uid => 'uid1' },
    });

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $api->Core->ReadNamespace(name => 'test');
    like $warnings[0], qr/\$api->get/, 'Read deprecation suggests get()';

    # Test Delete deprecation message
    @warnings = ();
    $api->io->add_response('DELETE', '/api/v1/namespaces/test', {
        kind => 'Status', status => 'Success',
    });
    $api->Core->DeleteNamespace(name => 'test');
    like $warnings[0], qr/\$api->delete/, 'Delete deprecation suggests delete()';
};

subtest 'v0 group - hashref args accepted' => sub {
    my $api = mock_api();
    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING} = 1;

    $api->io->add_response('GET', '/api/v1/namespaces', {
        kind => 'NamespaceList', items => [],
    });

    # Pass args as hashref (old API style)
    my $result = $api->Core->ListNamespace({});
    isa_ok $result, 'IO::K8s::List';
};

# ============================================================================
# REST.pm - _prepare_request with query parameters
# ============================================================================

subtest '_prepare_request - with query parameters' => sub {
    my $api = mock_api();

    my $req = $api->_prepare_request('GET', '/api/v1/pods',
        parameters => {
            watch => 'true',
            timeoutSeconds => 300,
            labelSelector => 'app=web',
        },
    );

    like $req->url, qr/\?/, 'URL has query string';
    like $req->url, qr/watch=true/, 'watch parameter';
    like $req->url, qr/timeoutSeconds=300/, 'timeoutSeconds parameter';
    like $req->url, qr/labelSelector=app=web/, 'labelSelector parameter';
};

subtest '_prepare_request - without body' => sub {
    my $api = mock_api();

    my $req = $api->_prepare_request('GET', '/api/v1/pods');
    is $req->method, 'GET', 'method set';
    ok !defined $req->content, 'no content for GET';
    is $req->headers->{Accept}, 'application/json', 'Accept header set';
};

subtest '_prepare_request - with body' => sub {
    my $api = mock_api();

    my $req = $api->_prepare_request('POST', '/api/v1/namespaces',
        body => { metadata => { name => 'test' } },
    );
    is $req->method, 'POST', 'method is POST';
    ok defined $req->content, 'content set for POST';
    like $req->content, qr/"name"/, 'body contains name';
};

# ============================================================================
# REST.pm - _check_response
# ============================================================================

subtest '_check_response - success' => sub {
    my $api = mock_api();
    my $res = Kubernetes::REST::HTTPResponse->new(status => 200, content => 'ok');
    lives_ok { $api->_check_response($res, 'test') } 'no error on 200';
};

subtest '_check_response - error' => sub {
    my $api = mock_api();
    my $res = Kubernetes::REST::HTTPResponse->new(status => 404, content => 'not found');
    throws_ok { $api->_check_response($res, 'test') }
        qr/Kubernetes API error \(test\): 404/,
        'throws on 404 with context';
};

subtest '_check_response - 500 error' => sub {
    my $api = mock_api();
    my $res = Kubernetes::REST::HTTPResponse->new(status => 500, content => 'internal');
    throws_ok { $api->_check_response($res, 'server error') }
        qr/Kubernetes API error \(server error\): 500/,
        'throws on 500';
};

# ============================================================================
# REST.pm - get() argument forms
# ============================================================================

subtest 'get - various argument forms' => sub {
    my $api = mock_api();

    $api->io->add_response('GET', '/api/v1/namespaces/default', {
        apiVersion => 'v1', kind => 'Namespace',
        metadata => { name => 'default', uid => 'uid1' },
    });

    # get('Kind', 'name')
    my $ns = $api->get('Namespace', 'default');
    is $ns->metadata->name, 'default', 'get(Kind, name) works';

    # get('Kind', name => 'name')
    $ns = $api->get('Namespace', name => 'default');
    is $ns->metadata->name, 'default', 'get(Kind, name => name) works';
};

subtest 'get - without name dies' => sub {
    my $api = mock_api();
    throws_ok { $api->get('Namespace') } qr/name required/,
        'get without name dies';
};

# ============================================================================
# REST.pm - delete() argument forms
# ============================================================================

subtest 'delete - by name' => sub {
    my $api = mock_api();

    # delete returns 200 with status object
    $api->io->add_response('DELETE', '/api/v1/namespaces/test', {
        kind => 'Status', status => 'Success',
    });

    my $result = $api->delete('Namespace', 'test');
    is $result, 1, 'delete returns 1 on success';
};

subtest 'delete - by name with namespace' => sub {
    my $api = mock_api();

    $api->io->add_response('DELETE', '/api/v1/namespaces/myns/pods/mypod', {
        kind => 'Status', status => 'Success',
    });

    my $result = $api->delete('Pod', 'mypod', namespace => 'myns');
    is $result, 1, 'delete with namespace works';
};

subtest 'delete - without name dies' => sub {
    my $api = mock_api();
    throws_ok { $api->delete('Namespace') } qr/name required/,
        'delete without name dies';
};

# ============================================================================
# REST.pm - cluster_version
# ============================================================================

subtest 'cluster_version - success' => sub {
    my $api = mock_api();

    $api->io->add_response('GET', '/version', {
        gitVersion => 'v1.31.0',
        major => '1',
        minor => '31',
    });

    is $api->cluster_version, 'v1.31.0', 'cluster version parsed';
};

subtest 'cluster_version - error returns unknown' => sub {
    my $api = mock_api();
    # No /version mock → 404
    is $api->cluster_version, 'unknown', 'returns unknown on error';
};

done_testing;

# We need AuthToken for HTTPRequest tests
BEGIN { require Kubernetes::REST::AuthToken }
