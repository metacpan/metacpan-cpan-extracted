#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";

use Path::Tiny qw(path);
use Module::Runtime qw(require_module);

use Test::Kubernetes::Mock qw(mock_api);
use Kubernetes::REST;
use Kubernetes::REST::V0Group;

# ============================================================================
# The v0 compatibility layer turns $api->Apps->ListNamespacedDeployment(...)
# into an IO::K8s class name, and a wrong name does not degrade - it dies in
# require_module long before any URL is built. Two groups had exactly that
# problem: their IO::K8s classes do not live under IO::K8s::Api::.
#
# This test pins, for every shipped v0 group, both halves of the translation:
# the class name the layer resolves AND the URL a call through it reaches.
# Anything that only checked the mapping function would have passed while
# $api->Apiextensions->ListCustomResourceDefinition still died.
# ============================================================================

# group => [ kind, namespace (undef = cluster-scoped), IO::K8s class, URL ]
my %GROUP = (
    Core => [
        'Pod', 'default',
        'IO::K8s::Api::Core::V1::Pod',
        '/api/v1/namespaces/default/pods',
    ],
    Apps => [
        'Deployment', 'default',
        'IO::K8s::Api::Apps::V1::Deployment',
        '/apis/apps/v1/namespaces/default/deployments',
    ],
    Batch => [
        'Job', 'default',
        'IO::K8s::Api::Batch::V1::Job',
        '/apis/batch/v1/namespaces/default/jobs',
    ],
    Networking => [
        'Ingress', 'default',
        'IO::K8s::Api::Networking::V1::Ingress',
        '/apis/networking.k8s.io/v1/namespaces/default/ingresses',
    ],
    Storage => [
        'StorageClass', undef,
        'IO::K8s::Api::Storage::V1::StorageClass',
        '/apis/storage.k8s.io/v1/storageclasses',
    ],
    Policy => [
        'PodDisruptionBudget', 'default',
        'IO::K8s::Api::Policy::V1::PodDisruptionBudget',
        '/apis/policy/v1/namespaces/default/poddisruptionbudgets',
    ],
    Autoscaling => [
        'HorizontalPodAutoscaler', 'default',
        'IO::K8s::Api::Autoscaling::V1::HorizontalPodAutoscaler',
        '/apis/autoscaling/v1/namespaces/default/horizontalpodautoscalers',
    ],
    RbacAuthorization => [
        'ClusterRole', undef,
        'IO::K8s::Api::Rbac::V1::ClusterRole',
        '/apis/rbac.authorization.k8s.io/v1/clusterroles',
    ],
    Certificates => [
        'CertificateSigningRequest', undef,
        'IO::K8s::Api::Certificates::V1::CertificateSigningRequest',
        '/apis/certificates.k8s.io/v1/certificatesigningrequests',
    ],
    Coordination => [
        'Lease', 'default',
        'IO::K8s::Api::Coordination::V1::Lease',
        '/apis/coordination.k8s.io/v1/namespaces/default/leases',
    ],
    Events => [
        'Event', 'default',
        'IO::K8s::Api::Events::V1::Event',
        '/apis/events.k8s.io/v1/namespaces/default/events',
    ],
    Scheduling => [
        'PriorityClass', undef,
        'IO::K8s::Api::Scheduling::V1::PriorityClass',
        '/apis/scheduling.k8s.io/v1/priorityclasses',
    ],
    Authentication => [
        'TokenReview', undef,
        'IO::K8s::Api::Authentication::V1::TokenReview',
        '/apis/authentication.k8s.io/v1/tokenreviews',
    ],
    Authorization => [
        'SubjectAccessReview', undef,
        'IO::K8s::Api::Authorization::V1::SubjectAccessReview',
        '/apis/authorization.k8s.io/v1/subjectaccessreviews',
    ],
    Admissionregistration => [
        'ValidatingWebhookConfiguration', undef,
        'IO::K8s::Api::Admissionregistration::V1::ValidatingWebhookConfiguration',
        '/apis/admissionregistration.k8s.io/v1/validatingwebhookconfigurations',
    ],
    Apiextensions => [
        'CustomResourceDefinition', undef,
        'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinition',
        '/apis/apiextensions.k8s.io/v1/customresourcedefinitions',
    ],
    Apiregistration => [
        'APIService', undef,
        'IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1::APIService',
        '/apis/apiregistration.k8s.io/v1/apiservices',
    ],
);

# ============================================================================
# Coverage guard - a new v0 group must not slip in untested
# ============================================================================

subtest 'every shipped v0 group subclass is covered by this test' => sub {
    my $lib = path("$FindBin::Bin/../lib/Kubernetes/REST");
    my @shipped =
        sort
        map  { $_->basename('.pm') }
        grep { $_->slurp_utf8 =~ /extends\s+'Kubernetes::REST::V0Group'/ }
        $lib->children(qr/\.pm$/);

    ok scalar @shipped, 'found v0 group subclasses on disk';
    is_deeply \@shipped, [sort keys %GROUP],
        'shipped v0 group subclasses match the table below';

    for my $group (@shipped) {
        ok(Kubernetes::REST->can($group),
            "Kubernetes::REST has a $group accessor");
    }
};

# ============================================================================
# Class name resolution - _build_class must name a class that exists
# ============================================================================

subtest 'v0 groups resolve to IO::K8s classes that actually load' => sub {
    my $api = mock_api();
    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING} = 1;

    for my $group (sort keys %GROUP) {
        my ($kind, undef, $class) = @{$GROUP{$group}};

        is $api->$group->_build_class($kind), $class,
            "$group->_build_class($kind) is $class";

        lives_ok { require_module($class) }
            "$class is loadable";
    }
};

# ============================================================================
# End-to-end - the real failure mode was a dead call, not a wrong string
# ============================================================================

subtest 'a v0 call through every group reaches the right URL' => sub {
    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING} = 1;

    for my $group (sort keys %GROUP) {
        my ($kind, $namespace, undef, $url) = @{$GROUP{$group}};

        my $api = mock_api();
        $api->io->add_response('GET', $url, {
            apiVersion => 'v1',
            kind       => "${kind}List",
            items      => [],
        });

        # A wrong class dies in require_module; a wrong URL 404s in the mock
        # and croaks in _check_response. Only both being right gets a list.
        my $method = $namespace ? "ListNamespaced$kind" : "List$kind";
        my @args = $namespace ? (namespace => $namespace) : ();

        my $result;
        lives_ok { $result = $api->$group->$method(@args) }
            "\$api->$group->$method reaches $url";
        isa_ok $result, 'IO::K8s::List', "$group->$method result";
    }
};

# ============================================================================
# Regression - the two groups from the bug report, spelled out
# ============================================================================

subtest 'apiextensions and apiregistration are not under IO::K8s::Api' => sub {
    my $api = mock_api();
    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING} = 1;

    isnt $api->Apiextensions->_build_class('CustomResourceDefinition'),
        'IO::K8s::Api::Apiextensions::V1::CustomResourceDefinition',
        'Apiextensions no longer builds the non-existent Api:: name';

    isnt $api->Apiregistration->_build_class('APIService'),
        'IO::K8s::Api::Apiregistration::V1::APIService',
        'Apiregistration no longer builds the non-existent Api:: name';

    is $api->_io_k8s_namespace_for_group_path('Apiextensions'),
        'ApiextensionsApiserver::Pkg::Apis::Apiextensions',
        'group path table knows apiextensions';

    is $api->_io_k8s_namespace_for_group_path('Apiregistration'),
        'KubeAggregator::Pkg::Apis::Apiregistration',
        'group path table knows apiregistration';

    is $api->_io_k8s_namespace_for_group_path('Apps'), 'Api::Apps',
        'everything else still falls through to Api::';
};

# ============================================================================
# The same table, entered from the other side. fetch_resource_map keys on the
# group name a cluster reports, and a cluster serves whatever CRD groups it
# likes - including ones whose first label collides with a built-in group.
# The exception must be an exact match on the full name, never a prefix.
# ============================================================================

subtest 'group namespace lookup matches the full group name exactly' => sub {
    my $api = mock_api();

    is $api->_io_k8s_namespace_for_group('apiextensions.k8s.io'),
        'ApiextensionsApiserver::Pkg::Apis::Apiextensions',
        'apiextensions.k8s.io hits the exception';
    is $api->_io_k8s_namespace_for_group('apiregistration.k8s.io'),
        'KubeAggregator::Pkg::Apis::Apiregistration',
        'apiregistration.k8s.io hits the exception';

    # A CRD may live in any group. These are ordinary groups that merely start
    # with the same label, and dragging them into the staging namespaces would
    # be wrong - the staging layout belongs to the k8s.io groups alone.
    is $api->_io_k8s_namespace_for_group('apiextensions.example.com'),
        'Api::Apiextensions',
        'a CRD group starting with apiextensions stays under Api::';
    is $api->_io_k8s_namespace_for_group('apiregistration.acme.io'),
        'Api::Apiregistration',
        'a CRD group starting with apiregistration stays under Api::';

    is $api->_io_k8s_namespace_for_group(''), 'Api::Core',
        'the empty group is core';
    is $api->_io_k8s_namespace_for_group('apps'), 'Api::Apps',
        'an unqualified group keeps its name';
    is $api->_io_k8s_namespace_for_group('rbac.authorization.k8s.io'),
        'Api::Rbac',
        'a qualified group is cut down to its first label';
};

subtest 'fetch_resource_map keeps colliding CRD groups out of the exception' => sub {
    my $api = mock_api();

    $api->io->add_response('GET', '/openapi/v2', {
        paths => {
            '/apis/apiextensions.k8s.io/v1/customresourcedefinitions' => {
                get => {
                    'x-kubernetes-group-version-kind' => {
                        group => 'apiextensions.k8s.io',
                        version => 'v1',
                        kind => 'CustomResourceDefinition',
                    },
                },
            },
            '/apis/apiextensions.example.com/v1/widgets' => {
                get => {
                    'x-kubernetes-group-version-kind' => {
                        group => 'apiextensions.example.com',
                        version => 'v1',
                        kind => 'Widget',
                    },
                },
            },
            '/apis/apiregistration.acme.io/v1/gadgets' => {
                get => {
                    'x-kubernetes-group-version-kind' => {
                        group => 'apiregistration.acme.io',
                        version => 'v1',
                        kind => 'Gadget',
                    },
                },
            },
        },
    });

    my $map = $api->fetch_resource_map;

    is $map->{CustomResourceDefinition},
        'ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinition',
        'the real apiextensions group still gets the staging namespace';
    is $map->{Widget}, 'Api::Apiextensions::V1::Widget',
        'a CRD in apiextensions.example.com stays under Api::';
    is $map->{Gadget}, 'Api::Apiregistration::V1::Gadget',
        'a CRD in apiregistration.acme.io stays under Api::';
};

# ============================================================================
# The old %group_map carried identity entries for three groups that ship no
# subclass and no accessor. Dropping them must not change what V0Group builds
# for a group name it has no entry for.
# ============================================================================

subtest 'group names without a map entry fall through unchanged' => sub {
    my $api = mock_api();
    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING} = 1;

    my %fallthrough = (
        Discovery => ['EndpointSlice', 'IO::K8s::Api::Discovery::V1::EndpointSlice'],
        Node      => ['RuntimeClass',  'IO::K8s::Api::Node::V1::RuntimeClass'],
        Rbac      => ['ClusterRole',   'IO::K8s::Api::Rbac::V1::ClusterRole'],
    );

    for my $group (sort keys %fallthrough) {
        my ($kind, $class) = @{$fallthrough{$group}};
        my $wrapper = Kubernetes::REST::V0Group->new(api => $api, group => $group);
        is $wrapper->_build_class($kind), $class,
            "$group falls through to $class";
        lives_ok { require_module($class) } "$class is loadable";
    }
};

# ============================================================================
# The version attribute still feeds the class name
# ============================================================================

subtest 'non-default version reaches the class name' => sub {
    my $api = mock_api();
    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING} = 1;

    my $beta = Kubernetes::REST::V0Group->new(
        api => $api, group => 'Storage', version => 'v1beta1',
    );
    is $beta->_build_class('CSIStorageCapacity'),
        'IO::K8s::Api::Storage::V1beta1::CSIStorageCapacity',
        'version is capitalised into the class name';

    my $crd_beta = Kubernetes::REST::V0Group->new(
        api => $api, group => 'Apiextensions', version => 'v1beta1',
    );
    is $crd_beta->_build_class('CustomResourceDefinition'),
        'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1beta1::CustomResourceDefinition',
        'the special namespace applies to every version, not just v1';
};

done_testing;
