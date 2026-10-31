use strict;
use warnings;
use Test::More;

use MCP::K8s::Permissions;

# The API server's answer to a SelfSubjectRulesReview without a namespace.
our $NO_NAMESPACE_ERROR =
    'Kubernetes API error (create IO::K8s::Api::Authorization::V1::SelfSubjectRulesReview): 400 '
  . '{"kind":"Status","status":"Failure","reason":"BadRequest",'
  . '"message":"no namespace on request","code":400}'
  . " at lib/Kubernetes/REST.pm line 437.\n";

# The scope of the resources the mock grants. In a real cluster the API
# discovery knows this for every resource the server serves; it is what
# keeps a namespaced resource out of the cluster-scope map.
my %RESOURCE_SCOPE = (
  pods         => 1,
  'pods/log'   => 1,
  services     => 1,
  deployments  => 1,
  replicasets  => 1,
  configmaps   => 1,
  secrets      => 1,
  events       => 1,
  statefulsets => 1,
  daemonsets   => 1,
  namespaces   => 0,
  nodes        => 0,
);

# =================================================================
# Mock infrastructure
# =================================================================

{
  package MockAPI;
  sub new { bless { reviews => [] }, shift }
  sub new_object {
    my ($self, $kind, $args) = @_;
    return MockReview->new($args->{spec}{namespace});
  }
  sub create {
    my ($self, $review) = @_;
    push @{ $self->{reviews} }, $review->namespace;
    # The API server rejects a review without a namespace: the review is
    # namespace-scoped by design. Reproduced here so a discovery that asks
    # for the cluster scope this way fails instead of quietly returning
    # nothing for it.
    die $NO_NAMESPACE_ERROR if $review->namespace eq '';
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
  package MockReview;
  sub new {
    my ($class, $namespace) = @_;
    bless { namespace => $namespace }, $class;
  }
  sub namespace { $_[0]->{namespace} }
  sub status {
    my ($self) = @_;
    return MockStatus->new($self->{namespace});
  }
}

{
  package MockStatus;
  sub new {
    my ($class, $namespace) = @_;
    my $rules = _rules_for($namespace);
    bless { rules => $rules }, $class;
  }
  sub resourceRules { $_[0]->{rules} }

  # The cluster-scoped grants come from a ClusterRoleBinding. Such a rule
  # shows up in the review of EVERY namespace - the API server adds the
  # ClusterRoleBindings to every review - which is what makes the cluster
  # scope derivable from the namespace reviews.
  my @CLUSTER_RULES = (
    MockRule->new(['list'], ['namespaces']),
    MockRule->new(['get'], ['nodes']),
  );

  sub _rules_for {
    my ($namespace) = @_;
    if ($namespace eq 'default') {
      return [
        MockRule->new(['get', 'list', 'watch'], ['pods', 'services', 'deployments']),
        MockRule->new(['get'], ['pods/log']),
        MockRule->new(['create', 'delete'], ['configmaps']),
        @CLUSTER_RULES,
      ];
    } elsif ($namespace eq 'admin') {
      return [
        MockRule->new(['*'], ['*']),
      ];
    } elsif ($namespace eq 'readonly') {
      return [
        MockRule->new(['get', 'list'], ['pods', 'services']),
        @CLUSTER_RULES,
      ];
    } elsif ($namespace eq 'deployer') {
      return [
        MockRule->new(['get', 'list', 'watch'], ['pods', 'deployments', 'replicasets']),
        MockRule->new(['update', 'patch'], ['deployments']),
        MockRule->new(['create'], ['pods']),
        MockRule->new(['get'], ['pods/log']),
        @CLUSTER_RULES,
      ];
    } elsif ($namespace eq 'status-writer') {
      # A correctly narrow Role for a controller that only writes status
      return [
        MockRule->new(['patch'], ['deployments/status']),
      ];
    } elsif ($namespace eq 'status-both') {
      return [
        MockRule->new(['patch'], ['deployments', 'deployments/status']),
      ];
    } elsif ($namespace eq 'wildcard-verb') {
      return [
        MockRule->new(['*'], ['configmaps', 'secrets']),
      ];
    } elsif ($namespace eq 'empty') {
      return [];
    }
    return [];
  }
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

# Helper: create Permissions with strong API ref kept alive
sub make_perms {
  my (@namespaces) = @_;
  my $api = MockAPI->new;
  my $perms = MCP::K8s::Permissions->new(
    api        => $api,
    namespaces => \@namespaces,
    scope_resolver => sub { $RESOURCE_SCOPE{ $_[0] } },
  );
  $perms->discover;
  # Return both to keep $api alive (weak_ref in Permissions)
  return ($perms, $api);
}

# =================================================================
# Tests
# =================================================================

subtest 'basic permission discovery' => sub {
  my ($perms, $api) = make_perms('default');

  # Explicit grants
  ok($perms->can_do('list', 'pods', 'default'), 'can list pods');
  ok($perms->can_do('get', 'pods', 'default'), 'can get pods');
  ok($perms->can_do('watch', 'services', 'default'), 'can watch services');
  ok($perms->can_do('get', 'deployments', 'default'), 'can get deployments');
  ok($perms->can_do('create', 'configmaps', 'default'), 'can create configmaps');
  ok($perms->can_do('delete', 'configmaps', 'default'), 'can delete configmaps');

  # Not granted
  ok(!$perms->can_do('create', 'pods', 'default'), 'cannot create pods');
  ok(!$perms->can_do('delete', 'pods', 'default'), 'cannot delete pods');
  ok(!$perms->can_do('patch', 'pods', 'default'), 'cannot patch pods');
  ok(!$perms->can_do('update', 'services', 'default'), 'cannot update services');
  ok(!$perms->can_do('list', 'secrets', 'default'), 'cannot list secrets');
  ok(!$perms->can_do('create', 'deployments', 'default'), 'cannot create deployments');
};

subtest 'wildcard resource (*) permissions' => sub {
  my ($perms, $api) = make_perms('admin');

  ok($perms->can_do('get', 'pods', 'admin'), 'wildcard: get pods');
  ok($perms->can_do('list', 'pods', 'admin'), 'wildcard: list pods');
  ok($perms->can_do('create', 'deployments', 'admin'), 'wildcard: create deployments');
  ok($perms->can_do('delete', 'secrets', 'admin'), 'wildcard: delete secrets');
  ok($perms->can_do('patch', 'anything', 'admin'), 'wildcard: patch anything');
  ok($perms->can_do('watch', 'customresource', 'admin'), 'wildcard: watch unknown resource');
  ok($perms->can_do('update', 'nodes', 'admin'), 'wildcard: update nodes');
};

subtest 'wildcard verb (*) on specific resources' => sub {
  my ($perms, $api) = make_perms('wildcard-verb');

  ok($perms->can_do('get', 'configmaps', 'wildcard-verb'), 'verb wildcard: get configmaps');
  ok($perms->can_do('list', 'configmaps', 'wildcard-verb'), 'verb wildcard: list configmaps');
  ok($perms->can_do('create', 'configmaps', 'wildcard-verb'), 'verb wildcard: create configmaps');
  ok($perms->can_do('delete', 'configmaps', 'wildcard-verb'), 'verb wildcard: delete configmaps');
  ok($perms->can_do('patch', 'secrets', 'wildcard-verb'), 'verb wildcard: patch secrets');

  ok(!$perms->can_do('list', 'pods', 'wildcard-verb'), 'verb wildcard: cannot list pods');
};

subtest 'deployer role (mixed permissions)' => sub {
  my ($perms, $api) = make_perms('deployer');

  # Read access
  ok($perms->can_do('get', 'pods', 'deployer'), 'deployer: get pods');
  ok($perms->can_do('list', 'deployments', 'deployer'), 'deployer: list deployments');
  ok($perms->can_do('watch', 'replicasets', 'deployer'), 'deployer: watch replicasets');

  # Write access (specific)
  ok($perms->can_do('update', 'deployments', 'deployer'), 'deployer: update deployments');
  ok($perms->can_do('patch', 'deployments', 'deployer'), 'deployer: patch deployments');
  ok($perms->can_do('create', 'pods', 'deployer'), 'deployer: create pods');

  # Not granted
  ok(!$perms->can_do('delete', 'pods', 'deployer'), 'deployer: cannot delete pods');
  ok(!$perms->can_do('create', 'services', 'deployer'), 'deployer: cannot create services');
  ok(!$perms->can_do('update', 'pods', 'deployer'), 'deployer: cannot update pods');
};

subtest 'cluster-scoped permissions' => sub {
  my ($perms, $api) = make_perms('default');

  ok($perms->can_do('list', 'namespaces', ''), 'cluster: list namespaces');
  ok($perms->can_do('get', 'nodes', ''), 'cluster: get nodes');
  ok(!$perms->can_do('create', 'namespaces', ''), 'cluster: cannot create namespaces');
  ok(!$perms->can_do('delete', 'nodes', ''), 'cluster: cannot delete nodes');
};

subtest 'the cluster scope is derived, never reviewed on its own' => sub {
  # A SelfSubjectRulesReview without a namespace is rejected by the API
  # server (400 no namespace on request), so the cluster scope cannot be
  # discovered by reviewing it. It is derived from the namespace reviews.
  my ($perms, $api) = make_perms('default');

  ok(!(grep { $_ eq '' } @{ $api->{reviews} }),
    'no review was submitted without a namespace');
  ok($perms->can_do('list', 'namespaces', ''),
    'the cluster scope is there anyway');
};

subtest 'a namespaced resource stays out of the cluster scope' => sub {
  # 'pods' is granted in every namespace review, so it survives the
  # derivation - but it is namespaced, so it belongs to its namespace and
  # not to the cluster.
  my ($perms, $api) = make_perms('default', 'readonly');

  ok($perms->can_do('list', 'pods', 'default'), 'pods are listable in a namespace');
  ok(!$perms->can_do('list', 'pods', ''), 'pods are not cluster-scoped');
  ok(!$perms->can_do('list', 'configmaps', ''), 'and neither are configmaps');
};

subtest 'a RoleBinding grant does not leak into the cluster scope' => sub {
  # 'configmaps create' comes from a RoleBinding in 'default' only. What
  # only one namespace knows is what that namespace may do - not the cluster.
  my ($perms, $api) = make_perms('default', 'readonly');

  ok($perms->can_do('create', 'configmaps', 'default'), 'configmaps are creatable in default');
  ok(!$perms->can_do('create', 'configmaps', ''), 'and not cluster-wide');
  ok($perms->can_do('list', 'namespaces', ''),
    'what the ClusterRoleBinding grants stays cluster-wide');
};

subtest 'unknown namespace denied' => sub {
  my ($perms, $api) = make_perms('default');

  ok(!$perms->can_do('list', 'pods', 'nonexistent'), 'unknown ns: denied');
  ok(!$perms->can_do('get', 'pods', 'production'), 'undiscovered ns: denied');
};

subtest 'empty namespace (no rules)' => sub {
  my ($perms, $api) = make_perms('empty');

  ok(!$perms->can_do('list', 'pods', 'empty'), 'empty: no list');
  ok(!$perms->can_do('get', 'pods', 'empty'), 'empty: no get');
};

subtest 'allowed_namespaces' => sub {
  my ($perms, $api) = make_perms('default', 'admin', 'readonly');

  my @ns = $perms->allowed_namespaces;
  is_deeply([sort @ns], ['admin', 'default', 'readonly'],
    'all three namespaces discovered');
};

subtest 'allowed_namespaces excludes empty results' => sub {
  my ($perms, $api) = make_perms('default', 'empty');

  my @ns = $perms->allowed_namespaces;
  is_deeply(\@ns, ['default'], 'empty namespace excluded');
};

subtest 'allowed_namespaces keeps a subresource-only namespace' => sub {
  # 'status-writer' grants nothing but patch on deployments/status. Discovery
  # stores what it got, so the namespace lands in the map and counts as
  # reachable - it is, that Role can do real work there. Were the subresource
  # filtered out at discovery time, %ns_rules would come back empty and
  # discover() would drop the namespace entirely.
  my ($perms, $api) = make_perms('status-writer');

  my @ns = $perms->allowed_namespaces;
  is_deeply(\@ns, ['status-writer'],
    'a Role granting only a subresource still makes its namespace reachable');

  # And it is reachable while presenting nothing: allowed_resources filters
  # subresources out again, so the namespace shows up with an empty resource
  # list rather than a fabricated main endpoint.
  is_deeply([$perms->allowed_resources('patch', 'status-writer')], [],
    'without any main-endpoint resource to present');
};

subtest 'allowed_resources for list' => sub {
  my ($perms, $api) = make_perms('default');

  my @resources = $perms->allowed_resources('list', 'default');
  ok((grep { $_ eq 'pods' } @resources), 'pods listable');
  ok((grep { $_ eq 'services' } @resources), 'services listable');
  ok((grep { $_ eq 'deployments' } @resources), 'deployments listable');
  ok(!(grep { $_ eq 'configmaps' } @resources), 'configmaps NOT listable');
  ok(!(grep { $_ eq 'secrets' } @resources), 'secrets NOT listable');
};

subtest 'allowed_resources for create' => sub {
  my ($perms, $api) = make_perms('default');

  my @resources = $perms->allowed_resources('create', 'default');
  ok((grep { $_ eq 'configmaps' } @resources), 'configmaps creatable');
  ok(!(grep { $_ eq 'pods' } @resources), 'pods NOT creatable');
  ok(!(grep { $_ eq 'deployments' } @resources), 'deployments NOT creatable');
};

subtest 'allowed_resources with wildcard' => sub {
  my ($perms, $api) = make_perms('admin');

  my @resources = $perms->allowed_resources('list', 'admin');
  ok((grep { $_ eq '*' } @resources), 'wildcard in allowed resources');
};

subtest 'allowed_resources excludes subresources' => sub {
  my ($perms, $api) = make_perms('default');

  my @resources = $perms->allowed_resources('get', 'default');
  ok(!(grep { $_ eq 'pods/log' } @resources), 'pods/log excluded from resource list');
  ok((grep { $_ eq 'pods' } @resources), 'pods still included');
};

subtest 'can_read_logs - explicit pods/log permission' => sub {
  my ($perms, $api) = make_perms('default');
  ok($perms->can_read_logs('default'), 'logs via pods/log permission');
};

subtest 'can_read_logs - wildcard resource' => sub {
  my ($perms, $api) = make_perms('admin');
  ok($perms->can_read_logs('admin'), 'logs via wildcard resource');
};

subtest 'can_read_logs - pods get implies logs' => sub {
  my ($perms, $api) = make_perms('readonly');
  ok($perms->can_read_logs('readonly'), 'logs via pods get permission');
};

subtest 'can_read_logs denied' => sub {
  my ($perms, $api) = make_perms('empty');

  ok(!$perms->can_read_logs('empty'), 'no log access in empty ns');
  ok(!$perms->can_read_logs('nonexistent'), 'no log access in unknown ns');
};

subtest 'discover returns self for chaining' => sub {
  my $api = MockAPI->new;
  my $perms = MCP::K8s::Permissions->new(
    api        => $api,
    namespaces => ['default'],
  );
  my $ret = $perms->discover;
  is($ret, $perms, 'discover returns $self');
};

subtest 'summary - basic structure' => sub {
  my ($perms, $api) = make_perms('default', 'admin');

  my $summary = $perms->summary;
  ok(length($summary) > 0, 'summary is not empty');
  like($summary, qr/# Kubernetes RBAC Permissions/, 'has title');
  like($summary, qr/## Namespace: default/, 'has default namespace section');
  like($summary, qr/## Namespace: admin/, 'has admin namespace section');
};

subtest 'summary - read-only namespace' => sub {
  my ($perms, $api) = make_perms('default');

  my $summary = $perms->summary;
  like($summary, qr/\*\*get\*\*/, 'summary lists get verb');
  like($summary, qr/\*\*list\*\*/, 'summary lists list verb');
  like($summary, qr/pods/, 'summary mentions pods');
  like($summary, qr/services/, 'summary mentions services');
};

subtest 'summary - full access namespace' => sub {
  my ($perms, $api) = make_perms('admin');

  my $summary = $perms->summary;
  like($summary, qr/Full access/, 'admin shows full access');
};

subtest 'summary - cluster-scoped' => sub {
  my ($perms, $api) = make_perms('default');

  my $summary = $perms->summary;
  like($summary, qr/Cluster-scoped/, 'summary has cluster section');
  like($summary, qr/namespaces/, 'cluster section mentions namespaces');
};

subtest 'summary - no permissions' => sub {
  my ($perms, $api) = make_perms('empty');

  my $summary = $perms->summary;
  like($summary, qr/No namespace permissions discovered/, 'shows no-permissions message');
};

subtest 'multiple namespace cross-isolation' => sub {
  my ($perms, $api) = make_perms('default', 'deployer');

  ok($perms->can_do('list', 'pods', 'default'), 'default: list pods');
  ok(!$perms->can_do('create', 'pods', 'default'), 'default: no create pods');

  ok($perms->can_do('create', 'pods', 'deployer'), 'deployer: create pods');
  ok(!$perms->can_do('delete', 'pods', 'deployer'), 'deployer: no delete pods');

  ok(!$perms->can_do('patch', 'deployments', 'default'), 'default: no patch deployments');
  ok($perms->can_do('patch', 'deployments', 'deployer'), 'deployer: patch deployments');
};

# =================================================================
# Subresources in the permission map
#
# RBAC treats a subresource as a resource in its own right: patch on
# 'deployments' does not grant patch on 'deployments/status'. Discovery has to
# keep those entries so can_do can see them, or a Role that grants the
# subresource correctly gets a false denial.
# =================================================================

subtest 'can_do sees a narrowly granted subresource' => sub {
  my ($perms, $api) = make_perms('status-writer');

  ok($perms->can_do('patch', 'deployments/status', 'status-writer'),
    'a Role granting only deployments/status can patch it');
  ok(!$perms->can_do('patch', 'deployments', 'status-writer'),
    'and that does not leak into the main endpoint');
};

subtest 'can_do separates a resource from its status subresource' => sub {
  my ($perms, $api) = make_perms('status-both');

  ok($perms->can_do('patch', 'deployments', 'status-both'),
    'main endpoint granted');
  ok($perms->can_do('patch', 'deployments/status', 'status-both'),
    'status subresource granted');
};

subtest 'patch on a resource does not grant patch on its status' => sub {
  # The load-bearing one: 'deployer' grants patch on deployments and nothing
  # on deployments/status. A status write must stay denied - granting it here
  # would hand out a permission RBAC never gave.
  my ($perms, $api) = make_perms('deployer');

  ok($perms->can_do('patch', 'deployments', 'deployer'),
    'deployer patches deployments');
  ok(!$perms->can_do('patch', 'deployments/status', 'deployer'),
    'deployer does NOT get deployments/status for free');
};

subtest 'wildcard resource covers subresources' => sub {
  my ($perms, $api) = make_perms('admin');

  ok($perms->can_do('patch', 'deployments/status', 'admin'),
    'resources: ["*"] covers subresources, as in Kubernetes');
};

subtest 'subresources stay out of allowed_resources' => sub {
  # Discovery collects, presentation filters: allowed_resources feeds the tool
  # descriptions, which must not grow subresource entries.
  my ($perms, $api) = make_perms('status-both');

  my @resources = $perms->allowed_resources('patch', 'status-both');
  ok((grep { $_ eq 'deployments' } @resources), 'base resource listed');
  ok(!(grep { m{/} } @resources), 'no subresource in the presented list');
};

done_testing;
