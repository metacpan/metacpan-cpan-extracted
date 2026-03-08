use strict;
use warnings;
use Test::More;
use List::Util qw(first);

use MCP::K8s;
use MCP::K8s::Permissions;
use JSON::MaybeXS;

# =================================================================
# Full mock infrastructure for server building
# =================================================================

{
  package MockK8sAPI;
  sub new { bless { objects => {} }, shift }

  sub new_object {
    my ($self, $kind, $args) = @_;
    if ($kind eq 'SelfSubjectRulesReview') {
      return MockSSRR->new($args->{spec}{namespace});
    }
    return MockK8sObject->new(
      kind     => $kind,
      metadata => $args->{metadata} || {},
      spec     => $args->{spec} || {},
    );
  }

  sub create {
    my ($self, $obj) = @_;
    if ($self->{force_409} && $obj->can('kind') && $obj->kind ne 'SelfSubjectRulesReview') {
      die "409 Conflict: AlreadyExists\n";
    }
    return $obj;
  }

  sub list {
    my ($self, $kind, %args) = @_;
    return MockK8sList->new($kind, $args{namespace});
  }

  sub get {
    my ($self, $kind, %args) = @_;
    return MockK8sObject->new(
      kind     => $kind,
      metadata => {
        name      => $args{name},
        namespace => $args{namespace},
      },
      status => { phase => 'Running' },
    );
  }

  sub delete {
    my ($self, $kind, %args) = @_;
    return 1;
  }

  sub patch {
    my ($self, $kind, $name, %args) = @_;
    return MockK8sObject->new(
      kind     => $kind,
      metadata => { name => $name, namespace => $args{namespace} },
    );
  }

  sub expand_class { 'IO::K8s::Api::Authorization::V1::SelfSubjectRulesReview' }

  sub _request {
    my ($self, $method, $path, $body, %opts) = @_;
    return MockHTTPResponse->new(200, "fake log line 1\nfake log line 2\n");
  }
}

{
  package MockHTTPResponse;
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
      @rules = (
        MockSSRRRule->new(['get', 'list', 'watch', 'create', 'update', 'patch', 'delete'],
                          ['pods', 'services', 'deployments', 'configmaps', 'events',
                           'statefulsets', 'daemonsets']),
        MockSSRRRule->new(['get'], ['pods/log']),
      );
    } elsif ($namespace eq 'other-ns') {
      @rules = (
        MockSSRRRule->new(['get', 'list'], ['pods']),
      );
    } elsif ($namespace eq '') {
      @rules = (MockSSRRRule->new(['list'], ['namespaces']));
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
  package MockK8sObject;
  sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
  }
  sub kind { $_[0]->{kind} }
  sub metadata {
    my ($self) = @_;
    return MockObjMeta->new(%{ $self->{metadata} || {} });
  }
  sub status {
    my ($self) = @_;
    return undef unless $self->{status};
    return MockObjStatus->new(%{ $self->{status} });
  }
  sub spec { undef }
  sub can {
    my ($self, $method) = @_;
    return $self->SUPER::can($method) if $method =~ /^(metadata|kind|status|spec)$/;
    return $self->SUPER::can($method);
  }
  sub TO_JSON {
    my ($self) = @_;
    return {
      kind     => $self->{kind},
      metadata => $self->{metadata},
      ($self->{status} ? (status => $self->{status}) : ()),
      ($self->{spec} ? (spec => $self->{spec}) : ()),
    };
  }
}

{
  package MockObjMeta;
  sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
  }
  sub name              { $_[0]->{name} }
  sub namespace         { $_[0]->{namespace} }
  sub labels            { $_[0]->{labels} }
  sub creationTimestamp  { $_[0]->{creationTimestamp} }
  sub can {
    my ($self, $method) = @_;
    return $self->SUPER::can($method) if $method =~ /^(name|namespace|labels|creationTimestamp)$/;
    return $self->SUPER::can($method);
  }
}

{
  package MockObjStatus;
  sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
  }
  sub phase { $_[0]->{phase} }
  sub can {
    my ($self, $method) = @_;
    return exists $self->{$method} ? $self->SUPER::can($method) : undef
      if $method =~ /^(phase|replicas|readyReplicas|availableReplicas|conditions)$/;
    return $self->SUPER::can($method);
  }
}

{
  package MockK8sList;
  sub new {
    my ($class, $kind, $namespace) = @_;
    bless {
      items => [
        MockK8sObject->new(
          kind     => $kind,
          metadata => { name => lc($kind) . '-1', namespace => $namespace },
          status   => { phase => 'Running' },
        ),
        MockK8sObject->new(
          kind     => $kind,
          metadata => { name => lc($kind) . '-2', namespace => $namespace },
          status   => { phase => 'Running' },
        ),
      ],
    }, $class;
  }
  sub items { $_[0]->{items} }
}

# =================================================================
# Helper to find a tool by name in the server's tools arrayref
# =================================================================

sub find_tool {
  my ($server, $name) = @_;
  return first { $_->name eq $name } @{ $server->tools };
}

# =================================================================
# Build the actual MCP::K8s with mocks
# =================================================================

my $api = MockK8sAPI->new;
my $k8s = MCP::K8s->new(
  api        => $api,
  namespaces => ['test-ns'],
);

# =================================================================
# Tests
# =================================================================

subtest 'server is an MCP::Server' => sub {
  my $server = $k8s->server;
  isa_ok($server, 'MCP::Server');
};

subtest 'server has correct name and version' => sub {
  my $server = $k8s->server;
  is($server->name, 'MCP-K8s', 'server name');
  is($server->version, ($MCP::K8s::VERSION || 'dev'), 'server version matches module');
};

subtest 'all 10 tools registered' => sub {
  my $server = $k8s->server;
  my @expected_tools = qw(
    k8s_permissions k8s_list k8s_get k8s_create
    k8s_patch k8s_delete k8s_logs
    k8s_events k8s_rollout_restart k8s_apply
  );

  for my $tool_name (@expected_tools) {
    my $tool = find_tool($server, $tool_name);
    ok($tool, "tool '$tool_name' registered");
  }

  is(scalar @{ $server->tools }, 10, 'exactly 10 tools total');
};

subtest 'k8s_permissions tool returns summary' => sub {
  my $tool = find_tool($k8s->server, 'k8s_permissions');
  my $result = $tool->code->($tool, {});
  ok(length($result) > 0, 'permissions summary not empty');
  like($result, qr/test-ns/, 'summary mentions test namespace');
  like($result, qr/pods/, 'summary mentions pods');
};

subtest 'k8s_list tool works' => sub {
  my $tool = find_tool($k8s->server, 'k8s_list');
  my $result = $tool->code->($tool, {
    resource  => 'Pod',
    namespace => 'test-ns',
  });
  my $data = JSON::MaybeXS->new->decode($result);
  is($data->{count}, 2, 'list returns 2 items');
  is(scalar @{$data->{items}}, 2, 'items array has 2 entries');
};

subtest 'k8s_list permission denied' => sub {
  my $tool = find_tool($k8s->server, 'k8s_list');
  my $result = $tool->code->($tool, {
    resource  => 'Secret',
    namespace => 'forbidden-ns',
  });
  like($result, qr/Permission denied/, 'list denied for unknown namespace');
};

subtest 'k8s_get tool works' => sub {
  my $tool = find_tool($k8s->server, 'k8s_get');
  my $result = $tool->code->($tool, {
    resource  => 'Pod',
    name      => 'my-pod',
    namespace => 'test-ns',
  });
  my $data = JSON::MaybeXS->new->decode($result);
  is($data->{name}, 'my-pod', 'get returns correct name');
};

subtest 'k8s_get json output' => sub {
  my $tool = find_tool($k8s->server, 'k8s_get');
  my $result = $tool->code->($tool, {
    resource  => 'Pod',
    name      => 'my-pod',
    namespace => 'test-ns',
    output    => 'json',
  });
  my $data = JSON::MaybeXS->new->decode($result);
  is($data->{kind}, 'Pod', 'json output has kind');
  is($data->{metadata}{name}, 'my-pod', 'json output has name in metadata');
};

subtest 'k8s_get permission denied' => sub {
  my $tool = find_tool($k8s->server, 'k8s_get');
  my $result = $tool->code->($tool, {
    resource  => 'Pod',
    name      => 'some-pod',
    namespace => 'wrong-ns',
  });
  like($result, qr/Permission denied/, 'get denied for wrong namespace');
};

subtest 'k8s_create tool works' => sub {
  my $tool = find_tool($k8s->server, 'k8s_create');
  my $result = $tool->code->($tool, {
    resource  => 'ConfigMap',
    namespace => 'test-ns',
    manifest  => {
      metadata => { name => 'my-config' },
      data     => { key => 'value' },
    },
  });
  my $data = JSON::MaybeXS->new->decode($result);
  is($data->{status}, 'created', 'create returns created status');
  is($data->{kind}, 'ConfigMap', 'create returns correct kind');
};

subtest 'k8s_create permission denied' => sub {
  my $tool = find_tool($k8s->server, 'k8s_create');
  my $result = $tool->code->($tool, {
    resource  => 'Pod',
    namespace => 'wrong-ns',
    manifest  => { metadata => { name => 'test' } },
  });
  like($result, qr/Permission denied/, 'create denied for wrong namespace');
};

subtest 'k8s_patch tool works' => sub {
  my $tool = find_tool($k8s->server, 'k8s_patch');
  my $result = $tool->code->($tool, {
    resource  => 'Deployment',
    name      => 'my-deploy',
    namespace => 'test-ns',
    patch     => { spec => { replicas => 3 } },
  });
  my $data = JSON::MaybeXS->new->decode($result);
  is($data->{status}, 'patched', 'patch returns patched status');
  is($data->{name}, 'my-deploy', 'patch returns correct name');
};

subtest 'k8s_delete tool works' => sub {
  my $tool = find_tool($k8s->server, 'k8s_delete');
  my $result = $tool->code->($tool, {
    resource  => 'Pod',
    name      => 'old-pod',
    namespace => 'test-ns',
  });
  my $data = JSON::MaybeXS->new->decode($result);
  is($data->{status}, 'deleted', 'delete returns deleted status');
  is($data->{name}, 'old-pod', 'delete returns correct name');
};

subtest 'k8s_delete permission denied' => sub {
  my $tool = find_tool($k8s->server, 'k8s_delete');
  my $result = $tool->code->($tool, {
    resource  => 'Pod',
    name      => 'some-pod',
    namespace => 'wrong-ns',
  });
  like($result, qr/Permission denied/, 'delete denied for wrong namespace');
};

subtest 'k8s_logs tool works' => sub {
  my $tool = find_tool($k8s->server, 'k8s_logs');
  my $result = $tool->code->($tool, {
    name      => 'my-pod',
    namespace => 'test-ns',
  });
  like($result, qr/fake log line/, 'logs returns log content');
};

subtest 'k8s_logs requires namespace' => sub {
  my $multi_k8s = MCP::K8s->new(
    api        => $api,
    namespaces => ['test-ns', 'other-ns'],
  );
  my $tool = find_tool($multi_k8s->server, 'k8s_logs');
  my $result = $tool->code->($tool, { name => 'my-pod' });
  like($result, qr/Namespace required/, 'logs requires namespace when multiple');
};

subtest 'k8s_logs permission denied' => sub {
  my $tool = find_tool($k8s->server, 'k8s_logs');
  my $result = $tool->code->($tool, {
    name      => 'my-pod',
    namespace => 'wrong-ns',
  });
  like($result, qr/Permission denied/, 'logs denied for wrong namespace');
};

subtest 'tool descriptions include available resources after discovery' => sub {
  # Descriptions are lazy — trigger update (happens automatically in run_stdio)
  $k8s->_update_tool_descriptions;

  my $list_tool = find_tool($k8s->server, 'k8s_list');
  like($list_tool->description, qr/pods/, 'list description mentions pods');
  like($list_tool->description, qr/test-ns/, 'list description mentions namespace');

  my $get_tool = find_tool($k8s->server, 'k8s_get');
  like($get_tool->description, qr/Available:/, 'get description has Available');

  my $logs_tool = find_tool($k8s->server, 'k8s_logs');
  like($logs_tool->description, qr/test-ns/, 'logs description mentions namespace');
};

subtest 'namespace auto-fill works in tools' => sub {
  my $tool = find_tool($k8s->server, 'k8s_list');
  my $result = $tool->code->($tool, {
    resource => 'Pod',
    # no namespace specified — should auto-fill to test-ns
  });
  my $data = JSON::MaybeXS->new->decode($result);
  is($data->{count}, 2, 'list works with auto-filled namespace');
};

# =================================================================
# Additional tool tests
# =================================================================

subtest 'k8s_events tool works' => sub {
  my $tool = find_tool($k8s->server, 'k8s_events');
  ok($tool, 'k8s_events tool exists');

  my $result = $tool->code->($tool, {
    namespace => 'test-ns',
  });
  my $data = JSON::MaybeXS->new->decode($result);
  is($data->{count}, 2, 'events returns items');
};

subtest 'k8s_events with involved_object filter' => sub {
  my $tool = find_tool($k8s->server, 'k8s_events');
  my $result = $tool->code->($tool, {
    namespace       => 'test-ns',
    involved_object => 'my-pod',
  });
  my $data = JSON::MaybeXS->new->decode($result);
  ok($data->{count}, 'events with involved_object filter returns results');
};

subtest 'k8s_events permission denied' => sub {
  my $tool = find_tool($k8s->server, 'k8s_events');
  my $result = $tool->code->($tool, {
    namespace => 'wrong-ns',
  });
  like($result, qr/Permission denied/, 'events denied for wrong namespace');
};

subtest 'k8s_rollout_restart tool works' => sub {
  my $tool = find_tool($k8s->server, 'k8s_rollout_restart');
  ok($tool, 'k8s_rollout_restart tool exists');

  my $result = $tool->code->($tool, {
    resource  => 'Deployment',
    name      => 'my-deploy',
    namespace => 'test-ns',
  });
  my $data = JSON::MaybeXS->new->decode($result);
  is($data->{status}, 'restarting', 'rollout_restart returns restarting status');
  is($data->{kind}, 'Deployment', 'rollout_restart returns correct kind');
  is($data->{name}, 'my-deploy', 'rollout_restart returns correct name');
  like($data->{restartAt}, qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/,
    'restartAt is ISO 8601 timestamp');
};

subtest 'k8s_rollout_restart permission denied' => sub {
  my $tool = find_tool($k8s->server, 'k8s_rollout_restart');
  my $result = $tool->code->($tool, {
    resource  => 'Deployment',
    name      => 'my-deploy',
    namespace => 'wrong-ns',
  });
  like($result, qr/Permission denied/, 'rollout_restart denied for wrong namespace');
};

subtest 'k8s_apply creates new resource' => sub {
  my $tool = find_tool($k8s->server, 'k8s_apply');
  ok($tool, 'k8s_apply tool exists');

  my $result = $tool->code->($tool, {
    resource  => 'ConfigMap',
    namespace => 'test-ns',
    manifest  => {
      metadata => { name => 'my-config' },
      data     => { key => 'value' },
    },
  });
  my $data = JSON::MaybeXS->new->decode($result);
  is($data->{status}, 'created', 'apply creates new resource');
  is($data->{kind}, 'ConfigMap', 'apply returns correct kind');
};

subtest 'k8s_apply falls back to patch on 409' => sub {
  # Enable 409 simulation
  $api->{force_409} = 1;

  my $tool = find_tool($k8s->server, 'k8s_apply');
  my $result = $tool->code->($tool, {
    resource  => 'ConfigMap',
    namespace => 'test-ns',
    manifest  => {
      metadata => { name => 'existing-config' },
      data     => { key => 'updated-value' },
    },
  });
  my $data = JSON::MaybeXS->new->decode($result);
  is($data->{status}, 'updated', 'apply falls back to patch on 409');
  is($data->{name}, 'existing-config', 'apply returns correct name after update');

  # Disable 409 simulation
  $api->{force_409} = 0;
};

subtest 'k8s_apply requires metadata.name' => sub {
  my $tool = find_tool($k8s->server, 'k8s_apply');
  my $result = $tool->code->($tool, {
    resource  => 'ConfigMap',
    namespace => 'test-ns',
    manifest  => {
      data => { key => 'value' },
    },
  });
  like($result, qr/metadata\.name/, 'apply requires metadata.name');
};

subtest 'k8s_apply permission denied' => sub {
  my $tool = find_tool($k8s->server, 'k8s_apply');
  my $result = $tool->code->($tool, {
    resource  => 'ConfigMap',
    namespace => 'wrong-ns',
    manifest  => {
      metadata => { name => 'test' },
    },
  });
  like($result, qr/Permission denied/, 'apply denied for wrong namespace');
};

done_testing;
