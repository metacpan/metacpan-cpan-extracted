use strict;
use warnings;
use Test::More;

use MCP::K8s;
use MCP::K8s::Permissions;

# =================================================================
# Mock infrastructure
# =================================================================

{
  package MockAPI3;
  sub new { bless {}, shift }
  sub new_object {
    my ($self, $kind, $args) = @_;
    return MockReview3->new($args->{spec}{namespace});
  }
  sub create {
    my ($self, $review) = @_;
    return $review;
  }
  # Real Kubernetes::REST::expand_class always returns a class name, never
  # undef; a Kind nothing ships resolves to a name that just doesn't load.
  # Answering with the SSRR class for every Kind (as this used to) is
  # harmless only while nothing in the process has loaded it - k16.
  sub expand_class {
    my ($self, $kind) = @_;
    return 'IO::K8s::Api::Authorization::V1::SelfSubjectRulesReview'
      if $kind eq 'SelfSubjectRulesReview';
    return 'IO::K8s::'.$kind;
  }
}

{
  package MockReview3;
  sub new {
    my ($class, $namespace) = @_;
    bless { namespace => $namespace }, $class;
  }
  sub status {
    my ($self) = @_;
    return MockStatus3->new($self->{namespace});
  }
}

{
  package MockStatus3;
  sub new {
    my ($class, $namespace) = @_;
    my @rules;
    if ($namespace eq 'only-ns' || $namespace eq 'first' || $namespace eq 'second') {
      @rules = (MockRule3->new(['get', 'list'], ['pods']));
    } elsif ($namespace eq 'status-only') {
      # A controller Role: no main endpoint at all, only the subresource.
      @rules = (MockRule3->new(['patch'], ['deployments/status']));
    } elsif ($namespace eq '') {
      @rules = (MockRule3->new(['list'], ['namespaces']));
    }
    bless { rules => \@rules }, $class;
  }
  sub resourceRules { $_[0]->{rules} }
}

{
  package MockRule3;
  sub new {
    my ($class, $verbs, $resources) = @_;
    bless { verbs => $verbs, resources => $resources }, $class;
  }
  sub verbs     { $_[0]->{verbs} }
  sub resources { $_[0]->{resources} }
}

# =================================================================
# Helper
# =================================================================

sub make_k8s_with_namespaces {
  my (@namespaces) = @_;
  my $api = MockAPI3->new;
  my $perms = MCP::K8s::Permissions->new(
    api        => $api,
    namespaces => \@namespaces,
  );
  $perms->discover;

  # Keep $api alive alongside the K8s object
  my $k8s = bless { permissions => $perms, _api_ref => $api }, 'MCP::K8s';
  return $k8s;
}

# =================================================================
# Tests
# =================================================================

subtest 'explicit namespace always used' => sub {
  my $k8s = make_k8s_with_namespaces('first', 'second');

  my $ns = $k8s->_resolve_namespace({ namespace => 'explicit' });
  is($ns, 'explicit', 'explicit namespace returned as-is');
};

subtest 'single namespace auto-fills' => sub {
  my $k8s = make_k8s_with_namespaces('only-ns');

  my $ns = $k8s->_resolve_namespace({});
  is($ns, 'only-ns', 'auto-fills when only one namespace');
};

subtest 'multiple namespaces return undef' => sub {
  my $k8s = make_k8s_with_namespaces('first', 'second');

  my $ns = $k8s->_resolve_namespace({});
  is($ns, undef, 'undef when multiple namespaces and none specified');
};

subtest 'namespace reachable only through a subresource auto-fills' => sub {
  # Since discovery keeps subresource entries, a Role granting nothing but
  # deployments/status still puts its namespace in the map - and being the
  # only one, it auto-fills.
  my $k8s = make_k8s_with_namespaces('status-only');

  is_deeply([$k8s->permissions->allowed_namespaces], ['status-only'],
    'subresource-only namespace counts as reachable');
  is($k8s->_resolve_namespace({}), 'status-only',
    'and auto-fills as the single reachable namespace');
};

subtest 'subresource-only namespace counts against auto-fill' => sub {
  # The user-visible half of the same change: a second namespace that is
  # reachable only through a subresource is still a second candidate, so
  # _resolve_namespace has no single one to pick and falls back to undef.
  # Auto-filling 'only-ns' here would silently aim a tool at the wrong
  # namespace.
  my $k8s = make_k8s_with_namespaces('only-ns', 'status-only');

  is_deeply([$k8s->permissions->allowed_namespaces], ['only-ns', 'status-only'],
    'two reachable namespaces, one of them only via a subresource');
  is($k8s->_resolve_namespace({}), undef,
    'no auto-fill with two candidates');
};

subtest 'empty string namespace not treated as provided' => sub {
  my $k8s = make_k8s_with_namespaces('only-ns');

  my $ns = $k8s->_resolve_namespace({ namespace => '' });
  is($ns, 'only-ns', 'empty string triggers auto-fill');
};

subtest 'undef namespace triggers auto-fill' => sub {
  my $k8s = make_k8s_with_namespaces('only-ns');

  my $ns = $k8s->_resolve_namespace({ namespace => undef });
  is($ns, 'only-ns', 'undef triggers auto-fill');
};

done_testing;
