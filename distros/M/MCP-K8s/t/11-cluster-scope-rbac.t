use strict;
use warnings;
use Test::More;
use JSON::MaybeXS;

use MCP::K8s;

# =================================================================
# The cluster scope of the RBAC map (k20)
#
# A SelfSubjectRulesReview is namespace-scoped by design: the API server
# answers a review without a namespace with 400 "no namespace on request".
# The cluster scope is therefore not reviewed - it is derived from the
# namespace reviews: the rules a ClusterRoleBinding grants show up in
# EVERY namespace review, the rules a RoleBinding grants only in its own.
#
# The mock cluster below has
#   - a ClusterRoleBinding granting the cluster-scoped resources
#     (nodes, namespaces and the cluster-scoped CRD 'widgets')
#   - a RoleBinding in 'app-ns' granting pods and services
# and serves the discovery endpoints, which is what tells the server
# which resources are cluster-scoped and which are namespaced.
# =================================================================

our $NO_NAMESPACE_ERROR =
    'Kubernetes API error (create IO::K8s::Api::Authorization::V1::SelfSubjectRulesReview): 400 '
  . '{"kind":"Status","status":"Failure","reason":"BadRequest",'
  . '"message":"no namespace on request","code":400}'
  . " at lib/Kubernetes/REST.pm line 437.\n";

{
  package MockClusterAPI;
  use JSON::MaybeXS;

  my $json = JSON::MaybeXS->new(utf8 => 1);

  # The resources the API server serves cluster-scoped.
  my %CLUSTER_SCOPED = map { $_ => 1 } qw(Node Namespace Widget);

  sub new { bless { calls => [], reviews => [] }, shift }

  sub new_object {
    my ($self, $kind, $args) = @_;
    return MockSSRR->new($args->{spec}{namespace})
      if $kind eq 'SelfSubjectRulesReview';
    return MockObject->new(kind => $kind, metadata => $args->{metadata} || {});
  }

  sub create {
    my ($self, $obj) = @_;
    if ($obj->can('kind') && $obj->kind eq 'SelfSubjectRulesReview') {
      push @{ $self->{reviews} }, $obj->namespace;
      # The API server rejects a review without a namespace.
      die $NO_NAMESPACE_ERROR if $obj->namespace eq '';
    }
    return $obj;
  }

  sub list {
    my ($self, $kind, %args) = @_;
    push @{ $self->{calls} }, { method => 'list', kind => $kind, %args };
    $self->_reject_namespaced_path($kind, %args);
    return MockList->new($kind, $args{namespace});
  }

  sub get {
    my ($self, $kind, %args) = @_;
    push @{ $self->{calls} }, { method => 'get', kind => $kind, %args };
    $self->_reject_namespaced_path($kind, %args);
    return MockObject->new(
      kind     => $kind,
      metadata => { name => $args{name}, namespace => $args{namespace} },
      status   => { phase => 'Running' },
    );
  }

  # A cluster-scoped resource has no namespaced path: GET
  # /api/v1/namespaces/app-ns/nodes does not exist, the API server answers
  # 404. Reproducing that is what makes a tool call that puts a
  # cluster-scoped resource into a namespace visible.
  sub _reject_namespaced_path {
    my ($self, $kind, %args) = @_;
    return unless $CLUSTER_SCOPED{$kind};
    return unless defined $args{namespace} && length $args{namespace};
    die 'Kubernetes API error (list '.$kind.'): 404 '
      . '{"kind":"Status","status":"Failure","reason":"NotFound",'
      . '"message":"the server could not find the requested resource","code":404}'
      . " at lib/Kubernetes/REST.pm line 437.\n";
  }

  # Real Kubernetes::REST::expand_class always returns a class name, never
  # undef. A Kind nothing ships resolves to a name that just doesn't load,
  # so the caller falls through to the discovery - which is where the scope
  # of a Kind comes from here.
  sub expand_class {
    my ($self, $kind) = @_;
    return 'IO::K8s::Api::Authorization::V1::SelfSubjectRulesReview'
      if $kind eq 'SelfSubjectRulesReview';
    return 'IO::K8s::'.$kind;
  }

  sub _request {
    my ($self, $method, $path) = @_;
    push @{ $self->{requests} ||= [] }, $path;

    if ($path eq '/api/v1') {
      return MockHTTPResp->new(200, $json->encode({
        kind => 'APIResourceList',
        resources => [
          { name => 'pods',       kind => 'Pod',       namespaced => 1, verbs => ['get', 'list'] },
          { name => 'services',   kind => 'Service',   namespaced => 1, verbs => ['get', 'list'] },
          { name => 'nodes',      kind => 'Node',      namespaced => 0, verbs => ['get', 'list'] },
          { name => 'namespaces', kind => 'Namespace', namespaced => 0, verbs => ['get', 'list'] },
          { name => 'pods/log',   kind => 'Pod',       namespaced => 1, verbs => ['get'] },
        ],
      }));
    }
    if ($path eq '/apis') {
      return MockHTTPResp->new(200, $json->encode({
        kind => 'APIGroupList',
        groups => [
          { name => 'example.com', preferredVersion => { groupVersion => 'example.com/v1' } },
        ],
      }));
    }
    if ($path eq '/apis/example.com/v1') {
      return MockHTTPResp->new(200, $json->encode({
        kind => 'APIResourceList',
        resources => [
          { name => 'widgets', kind => 'Widget', namespaced => 0, verbs => ['get', 'list'] },
        ],
      }));
    }
    return MockHTTPResp->new(404, '{}');
  }
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
  sub kind      { 'SelfSubjectRulesReview' }
  sub namespace { $_[0]->{namespace} }
  sub status {
    my ($self) = @_;
    return MockSSRRStatus->new($self->{namespace});
  }
}

{
  package MockSSRRStatus;
  sub new {
    my ($class, $namespace) = @_;

    # Granted by a ClusterRoleBinding: the API server adds those rules to
    # the review of every namespace.
    my @rules = (
      MockSSRRRule->new(['get', 'list'], ['nodes', 'namespaces', 'widgets']),
    );

    # Granted by a RoleBinding in 'app-ns' only.
    if ($namespace eq 'app-ns') {
      push @rules, MockSSRRRule->new(['get', 'list'], ['pods', 'services']);
    }

    bless { rules => \@rules }, $class;
  }
  sub resourceRules { $_[0]->{rules} }
}

{
  package MockSSRRRule;
  sub new {
    my ($class, $verbs, $resources) = @_;
    bless { verbs => $verbs, resources => $resources }, $class;
  }
  sub verbs     { $_[0]->{verbs} }
  sub resources { $_[0]->{resources} }
}

{
  package MockObject;
  sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
  }
  sub kind     { $_[0]->{kind} }
  sub metadata { MockMeta->new(%{ $_[0]->{metadata} || {} }) }
  sub status   { undef }
  sub spec     { undef }
  sub TO_JSON  { { kind => $_[0]->{kind}, metadata => $_[0]->{metadata} } }
}

{
  package MockMeta;
  sub new { bless { @_[1..$#_] }, $_[0] }
  sub name              { $_[0]->{name} }
  sub namespace         { $_[0]->{namespace} }
  sub labels            { undef }
  sub creationTimestamp { undef }
}

{
  package MockList;
  sub new {
    my ($class, $kind, $namespace) = @_;
    bless {
      items => [
        MockObject->new(
          kind     => $kind,
          metadata => { name => lc($kind).'-1', namespace => $namespace },
        ),
      ],
    }, $class;
  }
  sub items { $_[0]->{items} }
}

# =================================================================
# Helper
# =================================================================

sub find_tool {
  my ($server, $name) = @_;
  for my $tool (@{ $server->tools }) {
    return $tool if $tool->name eq $name;
  }
  return;
}

my $api = MockClusterAPI->new;
my $k8s = MCP::K8s->new(
  api        => $api,
  namespaces => ['app-ns', 'other-ns'],
);

# =================================================================
# Tests
# =================================================================

subtest 'the fixture rejects a review without a namespace' => sub {
  # The premise of the whole thing: the API server does not answer a
  # SelfSubjectRulesReview without a namespace.
  ok($NO_NAMESPACE_ERROR =~ /no namespace on request/,
    'the fixture carries the API server\'s answer');

  my $broken = MockClusterAPI->new;
  my $review = $broken->new_object('SelfSubjectRulesReview', {
    spec => { namespace => '' },
  });
  my $ok = eval { $broken->create($review); 1 };
  ok(!$ok, 'a review without a namespace is refused');
  like($@, qr/400/, 'with a 400');
};

subtest 'discovery never reviews without a namespace' => sub {
  my $tool = find_tool($k8s->server, 'k8s_permissions');
  $tool->code->($tool, {});

  my @reviews = @{ $api->{reviews} };
  is_deeply([sort @reviews], ['app-ns', 'other-ns'],
    'one review per namespace, none without one');
};

subtest 'a cluster-scoped Kind is allowed' => sub {
  my $tool = find_tool($k8s->server, 'k8s_list');
  my $result = $tool->code->($tool, { resource => 'Node' });

  unlike($result, qr/Permission denied/,
    'listing the nodes is not refused - the cluster scope is there');
  my $data = eval { JSON::MaybeXS->new->decode($result) };
  ok($data && $data->{count} == 1, 'the list came back');
};

subtest 'a cluster-scoped Kind is fetched without a namespace' => sub {
  my $tool = find_tool($k8s->server, 'k8s_get');
  my $result = $tool->code->($tool, { resource => 'Namespace', name => 'default' });

  unlike($result, qr/Permission denied/, 'getting a namespace is not refused');

  my ($call) = grep { $_->{method} eq 'get' and $_->{kind} eq 'Namespace' }
    @{ $api->{calls} };
  ok($call, 'the API was asked');
  ok(!defined $call->{namespace},
    'and without a namespace - a cluster-scoped resource has none');
};

subtest 'a cluster-scoped CRD is allowed' => sub {
  # The scope of a CRD comes from the discovery, not from a shipped class.
  my $tool = find_tool($k8s->server, 'k8s_list');
  my $result = $tool->code->($tool, { resource => 'Widget' });

  unlike($result, qr/Permission denied/, 'listing the widgets is not refused');
  my $data = eval { JSON::MaybeXS->new->decode($result) };
  ok($data && $data->{count} == 1, 'the list came back');
};

subtest 'a namespaced Kind without a namespace says what is missing' => sub {
  my $tool = find_tool($k8s->server, 'k8s_list');
  my $result = $tool->code->($tool, { resource => 'Pod' });

  like($result, qr/namespace required/,
    'the tool says the namespace is missing');
  unlike($result, qr/Permission denied/,
    'and does not claim the account may not read pods');
  like($result, qr/app-ns/, 'the reachable namespaces are named');
};

subtest 'a namespaced resource is not cluster-scoped' => sub {
  # The rule the pods come from is a RoleBinding in 'app-ns', and pods are
  # namespaced besides. Neither may put them into the cluster scope.
  ok($k8s->permissions->can_do('list', 'pods', 'app-ns'),
    'pods are listable in the namespace');
  ok(!$k8s->permissions->can_do('list', 'pods', ''),
    'but not cluster-wide');
  ok($k8s->permissions->can_do('list', 'nodes', ''),
    'while the ClusterRoleBinding grants the cluster-scoped resources');
};

done_testing;
