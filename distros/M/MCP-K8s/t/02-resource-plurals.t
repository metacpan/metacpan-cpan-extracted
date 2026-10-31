use strict;
use warnings;
use Test::More;

# Test the resource plural mapping without connecting to a cluster.

use MCP::K8s;

# Minimal mock API to avoid cluster connection
{
  package MockPluralAPI;
  sub new { bless {}, shift }
  sub expand_class { undef }
  sub _request {
    return MockPluralResp->new(404, '{}');
  }
}

{
  package MockPluralResp;
  sub new { bless { status => $_[1], content => $_[2] }, $_[0] }
  sub status  { $_[0]->{status} }
  sub content { $_[0]->{content} }
}

my $k8s = MCP::K8s->new(
  api        => MockPluralAPI->new,
  namespaces => ['default'],
);

subtest 'common resource plurals' => sub {
  my %expected = (
    Pod                   => 'pods',
    Service               => 'services',
    Deployment            => 'deployments',
    ReplicaSet            => 'replicasets',
    StatefulSet           => 'statefulsets',
    DaemonSet             => 'daemonsets',
    Job                   => 'jobs',
    CronJob               => 'cronjobs',
    ConfigMap             => 'configmaps',
    Secret                => 'secrets',
    Namespace             => 'namespaces',
    Node                  => 'nodes',
    PersistentVolume      => 'persistentvolumes',
    PersistentVolumeClaim => 'persistentvolumeclaims',
    ServiceAccount        => 'serviceaccounts',
    Role                  => 'roles',
    RoleBinding           => 'rolebindings',
    ClusterRole           => 'clusterroles',
    ClusterRoleBinding    => 'clusterrolebindings',
    Ingress               => 'ingresses',
    NetworkPolicy         => 'networkpolicies',
    Event                 => 'events',
    Endpoints             => 'endpoints',
    LimitRange            => 'limitranges',
    ResourceQuota         => 'resourcequotas',
    HorizontalPodAutoscaler => 'horizontalpodautoscalers',
  );

  for my $kind (sort keys %expected) {
    is($k8s->_resource_plural($kind), $expected{$kind},
      "$kind => $expected{$kind}");
  }
};

subtest 'fallback pluralization' => sub {
  # Unknown resources use the lowercase + 's' heuristic
  is($k8s->_resource_plural('Widget'), 'widgets', 'Widget => widgets');
  is($k8s->_resource_plural('CustomThing'), 'customthings', 'CustomThing => customthings');

  # Handles trailing 'y' -> 'ies'
  is($k8s->_resource_plural('Policy'), 'policies', 'Policy => policies (y -> ies)');
  is($k8s->_resource_plural('Gateway'), 'gateways', 'Gateway => gateways (vowel+y keeps its y, k21)');

  # Already ends in 's' - no double 's'
  is($k8s->_resource_plural('Status'), 'status', 'Status => status (no double s)');
};

subtest 'known plurals are stable' => sub {
  # Verify we get the same result on repeated calls
  is($k8s->_resource_plural('Pod'), 'pods', 'Pod consistent (1)');
  is($k8s->_resource_plural('Pod'), 'pods', 'Pod consistent (2)');
};

subtest 'IO::K8s class resource_plural method' => sub {
  # Static map always wins regardless of expand_class
  is($k8s->_resource_plural('Pod'), 'pods',
    'static map wins even if IO::K8s class exists');

  # Full integration test for IO::K8s class resolution is in
  # t/08-resource-discovery.t
};

done_testing;
