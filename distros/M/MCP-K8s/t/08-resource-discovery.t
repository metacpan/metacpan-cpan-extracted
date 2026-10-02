use strict;
use warnings;
use Test::More;
use JSON::MaybeXS;

use IO::K8s::Unstructured;
use Kubernetes::REST;
use MCP::K8s;

# =================================================================
# Mock API that returns discovery endpoint responses
# =================================================================

{
  package MockDiscoveryAPI;
  use JSON::MaybeXS;

  my $json = JSON::MaybeXS->new(utf8 => 1);

  sub new { bless { calls => [] }, shift }

  sub new_object {
    my ($self, $kind, $args) = @_;
    if ($kind eq 'SelfSubjectRulesReview') {
      return MockSSRR->new($args->{spec}{namespace});
    }
    return MockObj->new(kind => $kind, metadata => $args->{metadata} || {});
  }

  sub create {
    my ($self, $obj) = @_;
    return $obj;
  }

  sub list {
    my ($self, $kind, %args) = @_;
    return MockList->new();
  }

  sub expand_class {
    my ($self, $kind) = @_;
    # Simulate that most classes don't have resource_plural
    return undef;
  }

  sub _request {
    my ($self, $method, $path, $body, %opts) = @_;
    push @{ $self->{calls} }, $path;

    if ($path eq '/api/v1') {
      my $body = $json->encode({
        kind => 'APIResourceList',
        resources => [
          { name => 'pods', kind => 'Pod', namespaced => 1, verbs => ['get', 'list'] },
          { name => 'services', kind => 'Service', namespaced => 1, verbs => ['get', 'list'] },
          { name => 'configmaps', kind => 'ConfigMap', namespaced => 1, verbs => ['get', 'list'] },
          { name => 'pods/log', kind => 'Pod', namespaced => 1, verbs => ['get'] },  # subresource
          { name => 'customwidgets', kind => 'CustomWidget', namespaced => 1, verbs => ['get', 'list'] },
        ],
      });
      return MockHTTPResp->new(200, $body);
    }
    elsif ($path eq '/apis') {
      my $body = $json->encode({
        kind => 'APIGroupList',
        groups => [
          {
            name => 'cilium.io',
            preferredVersion => { groupVersion => 'cilium.io/v2' },
          },
        ],
      });
      return MockHTTPResp->new(200, $body);
    }
    elsif ($path eq '/apis/cilium.io/v2') {
      my $body = $json->encode({
        kind => 'APIResourceList',
        resources => [
          { name => 'ciliumnetworkpolicies', kind => 'CiliumNetworkPolicy', namespaced => 1, verbs => ['get', 'list'] },
          { name => 'ciliumendpoints', kind => 'CiliumEndpoint', namespaced => 1, verbs => ['get', 'list'] },
        ],
      });
      return MockHTTPResp->new(200, $body);
    }
    else {
      return MockHTTPResp->new(404, '{}');
    }
  }
}

# A client whose resource map comes from the cluster, the Kubernetes::REST
# default. Since 1.108 its expand_class resolves names the built-in map (or a
# registered provider) knows without a request, so plural tier 2 asks it.
# Kinds nothing ships come back the way 1.108 returns them: a Kind the
# cluster serves as IO::K8s::Unstructured, anything else as a fabricated
# class name that does not load.
{
  package MockClusterMapAPI;
  our @ISA = ('MockDiscoveryAPI');
  sub resource_map_from_cluster { 1 }
  sub expand_class {
    my ($self, $kind) = @_;
    push @{ $self->{expanded} }, $kind;
    return $kind eq 'StaticWebsite'       ? 'MockCRDClass'
         : $kind eq 'PriorityClass'       ? 'MockBuiltinClass'
         : $kind eq 'CiliumNetworkPolicy' ? 'IO::K8s::Unstructured'
         :                                  'IO::K8s::'.$kind;
  }
}

# A CRD provider class registered with the client.
{
  package MockCRDClass;
  sub resource_plural { 'staticwebsites' }
}

# Stands in for a shipped IO::K8s class; its plural is one tiers 3 and 4
# cannot produce, so only tier 2 can be the source.
{
  package MockBuiltinClass;
  sub resource_plural { 'priorityclasses-from-io-k8s' }
}

{
  package MockHTTPResp;
  sub new {
    my ($class, $status, $content) = @_;
    bless { status => $status, content => $content }, $class;
  }
  sub status  { $_[0]->{status} }
  sub content { $_[0]->{content} }
}

{
  package MockSSRR;
  sub new {
    my ($class, $namespace) = @_;
    bless { namespace => $namespace // '' }, $class;
  }
  sub status {
    my ($self) = @_;
    return MockSSRRStatus->new($self->{namespace});
  }
}

{
  package MockSSRRStatus;
  sub new {
    my ($class, $namespace) = @_;
    my @rules;
    if ($namespace eq 'test-ns') {
      @rules = (MockRule->new(['get', 'list'], ['pods', 'services', 'events']));
    } elsif ($namespace eq '') {
      @rules = (MockRule->new(['list'], ['namespaces']));
    }
    bless { rules => \@rules }, $class;
  }
  sub resourceRules { $_[0]->{rules} }
}

{
  package MockRule;
  sub new {
    my ($class, $verbs, $resources) = @_;
    bless { verbs => $verbs, resources => $resources }, $class;
  }
  sub verbs     { $_[0]->{verbs} }
  sub resources { $_[0]->{resources} }
}

{
  package MockObj;
  sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
  }
  sub kind     { $_[0]->{kind} }
  sub metadata { MockMeta->new(%{ $_[0]->{metadata} || {} }) }
  sub status   { undef }
  sub spec     { undef }
  sub can {
    my ($self, $method) = @_;
    return $self->SUPER::can($method) if $method =~ /^(metadata|kind|status|spec)$/;
    return $self->SUPER::can($method);
  }
}

{
  package MockMeta;
  sub new { bless { @_[1..$#_] }, $_[0] }
  sub name              { $_[0]->{name} }
  sub namespace         { $_[0]->{namespace} }
  sub labels            { undef }
  sub creationTimestamp  { undef }
  sub can {
    my ($self, $method) = @_;
    return $self->SUPER::can($method) if $method =~ /^(name|namespace|labels|creationTimestamp)$/;
    return $self->SUPER::can($method);
  }
}

{
  package MockList;
  sub new { bless { items => [] }, $_[0] }
  sub items { $_[0]->{items} }
}

# =================================================================
# Tests
# =================================================================

my $api = MockDiscoveryAPI->new;
my $k8s = MCP::K8s->new(
  api        => $api,
  namespaces => ['test-ns'],
);

subtest 'static map takes priority' => sub {
  # Pod is in %RESOURCE_PLURALS, should not trigger discovery
  is($k8s->_resource_plural('Pod'), 'pods', 'Pod resolved from static map');
  is($k8s->_resource_plural('Deployment'), 'deployments', 'Deployment resolved from static map');
  is($k8s->_resource_plural('Ingress'), 'ingresses', 'Ingress resolved from static map');
};

subtest 'discovery populates cache for unknown kinds' => sub {
  # CustomWidget is NOT in the static map, should trigger API discovery
  my $plural = $k8s->_resource_plural('CustomWidget');
  is($plural, 'customwidgets', 'CustomWidget resolved via API discovery');

  # Verify discovery was called
  my @discovery_calls = grep { m{^/api} } @{ $api->{calls} };
  ok(scalar @discovery_calls > 0, 'API discovery endpoints were called');
};

subtest 'CRD kinds resolved via discovery' => sub {
  # CiliumNetworkPolicy from the cilium.io group
  my $plural = $k8s->_resource_plural('CiliumNetworkPolicy');
  is($plural, 'ciliumnetworkpolicies', 'CiliumNetworkPolicy resolved via API group discovery');

  my $plural2 = $k8s->_resource_plural('CiliumEndpoint');
  is($plural2, 'ciliumendpoints', 'CiliumEndpoint resolved via API group discovery');
};

subtest 'cache is populated after first discovery' => sub {
  my $cache = $k8s->_resource_plurals_cache;
  ok(keys %$cache > 0, 'cache has entries after discovery');
  is($cache->{'CustomWidget'}, 'customwidgets', 'CustomWidget in cache');
  is($cache->{'CiliumNetworkPolicy'}, 'ciliumnetworkpolicies', 'CiliumNetworkPolicy in cache');
  is($cache->{'Service'}, 'services', 'Service in cache (from /api/v1)');
};

subtest 'subresources excluded from cache' => sub {
  my $cache = $k8s->_resource_plurals_cache;
  # pods/log is a subresource and should not create a cache entry
  ok(!exists $cache->{'pods/log'}, 'subresource pods/log not in cache');
};

subtest 'heuristic fallback for truly unknown kinds' => sub {
  # Something not in static map, not in IO::K8s, not from API discovery
  my $plural = $k8s->_resource_plural('ZzzzUnknownThing');
  is($plural, 'zzzzunknownthings', 'unknown kind falls back to heuristic');
};

subtest 'discovery called only once (cached)' => sub {
  my $call_count_before = scalar @{ $api->{calls} };

  # These should all use cache, no new API calls
  $k8s->_resource_plural('CustomWidget');
  $k8s->_resource_plural('CiliumNetworkPolicy');
  $k8s->_resource_plural('Service');

  my $call_count_after = scalar @{ $api->{calls} };
  is($call_count_after, $call_count_before, 'no additional API calls after cache populated');
};

subtest 'tier 2 answers with resource_map_from_cluster set' => sub {
  my $cluster_api = MockClusterMapAPI->new;
  my $cluster_k8s = MCP::K8s->new(
    api        => $cluster_api,
    namespaces => ['test-ns'],
  );

  # Neither Kind is in the static map or the discovery endpoints, and no
  # discovery request is made: the class the client resolves is the source.
  is($cluster_k8s->_resource_plural('PriorityClass'), 'priorityclasses-from-io-k8s',
    'built-in class resource_plural() answers');
  is($cluster_k8s->_resource_plural('StaticWebsite'), 'staticwebsites',
    'registered CRD class resource_plural() answers');
  is_deeply($cluster_api->{expanded}, ['PriorityClass', 'StaticWebsite'],
    'expand_class was consulted for both');
  is(scalar @{ $cluster_api->{calls} }, 0,
    'tier 2 answered before any discovery request');

  is($cluster_k8s->_resource_plural('Pod'), 'pods',
    'static map still answers first');
  is(scalar @{ $cluster_api->{expanded} }, 2,
    'static map hit does not reach expand_class');
};

subtest 'tier 2 falls through for Kinds without a class' => sub {
  my $cluster_api = MockClusterMapAPI->new;
  my $cluster_k8s = MCP::K8s->new(
    api        => $cluster_api,
    namespaces => ['test-ns'],
  );

  is($cluster_k8s->_resource_plural('CiliumNetworkPolicy'), 'ciliumnetworkpolicies',
    'Unstructured has no resource_plural - tier 3 discovery answers');
  ok(scalar @{ $cluster_api->{calls} }, 'discovery endpoints were asked');
  is($cluster_k8s->_resource_plural('ZzzzUnknownThing'), 'zzzzunknownthings',
    'fabricated class name does not load - heuristic answers');
};

# The upstream contract the 1.108 floor rests on: the real client resolves a
# built-in Kind to a class carrying its plural without any request, even with
# resource_map_from_cluster at its default. _request is replaced, so nothing
# here can reach the network.
subtest 'Kubernetes::REST expand_class is fetch-free for built-ins' => sub {
  my @requests;
  no warnings 'redefine';
  local *Kubernetes::REST::_request = sub {
    push @requests, $_[2];
    die "unexpected request $_[1] $_[2]\n";
  };
  my $real_api = Kubernetes::REST->new(
    server      => { endpoint => 'http://127.0.0.1:1' },
    credentials => { token => 'unused' },
  );
  ok($real_api->resource_map_from_cluster, 'client default fetches its map');
  my $real_k8s = MCP::K8s->new(
    api        => $real_api,
    namespaces => ['test-ns'],
  );

  my %expected = (
    PriorityClass            => 'priorityclasses',
    StorageClass             => 'storageclasses',
    IngressClass             => 'ingressclasses',
    Lease                    => 'leases',
    EndpointSlice            => 'endpointslices',
    CustomResourceDefinition => 'customresourcedefinitions',
  );
  for my $kind (sort keys %expected) {
    is($real_k8s->_resource_plural($kind), $expected{$kind},
      $kind.' => '.$expected{$kind});
  }
  is_deeply(\@requests, [], 'no request made');
};

done_testing;
