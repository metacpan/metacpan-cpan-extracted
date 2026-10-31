use strict;
use warnings;
use Test::More;

use MCP::K8s;
use JSON::MaybeXS;

# Create bare K8s object with JSON encoder
my $k8s = bless {
  json => JSON::MaybeXS->new(utf8 => 1, pretty => 1, canonical => 1, convert_blessed => 1),
}, 'MCP::K8s';

# =================================================================
# Mock K8s-like objects for format testing
# =================================================================

{
  package MockMeta;
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
    return exists $self->{$method} ? $self->SUPER::can($method) : undef
      if $method =~ /^(name|namespace|labels|creationTimestamp)$/;
    return $self->SUPER::can($method);
  }
}

{
  package MockPodStatus;
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
  package MockContainer;
  sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
  }
  sub name { $_[0]->{name} }
}

{
  package MockPodSpec;
  sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
  }
  sub containers { $_[0]->{containers} }
  sub can {
    my ($self, $method) = @_;
    return exists $self->{$method} ? $self->SUPER::can($method) : undef
      if $method =~ /^(containers|replicas|type|ports)$/;
    return $self->SUPER::can($method);
  }
}

{
  package MockPod;
  sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
  }
  sub metadata { $_[0]->{metadata} }
  sub kind     { $_[0]->{kind} }
  sub status   { $_[0]->{status} }
  sub spec     { $_[0]->{spec} }
  sub can {
    my ($self, $method) = @_;
    return exists $self->{$method} ? $self->SUPER::can($method) : undef
      if $method =~ /^(metadata|kind|status|spec)$/;
    return $self->SUPER::can($method);
  }
}

{
  package MockPort;
  sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
  }
  sub port       { $_[0]->{port} }
  sub targetPort { $_[0]->{targetPort} }
  sub protocol   { $_[0]->{protocol} }
  sub can {
    my ($self, $method) = @_;
    return exists $self->{$method} ? $self->SUPER::can($method) : undef
      if $method =~ /^(port|targetPort|protocol)$/;
    return $self->SUPER::can($method);
  }
}

{
  package MockServiceSpec;
  sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
  }
  sub type  { $_[0]->{type} }
  sub ports { $_[0]->{ports} }
  sub can {
    my ($self, $method) = @_;
    return exists $self->{$method} ? $self->SUPER::can($method) : undef
      if $method =~ /^(type|ports|containers|replicas)$/;
    return $self->SUPER::can($method);
  }
}

# =================================================================
# Tests
# =================================================================

subtest 'format pod summary' => sub {
  my $pod = MockPod->new(
    metadata => MockMeta->new(
      name      => 'web-abc123',
      namespace => 'default',
      labels    => { app => 'web', env => 'prod' },
      creationTimestamp => '2026-02-23T10:00:00Z',
    ),
    kind   => 'Pod',
    status => MockPodStatus->new(phase => 'Running'),
    spec   => MockPodSpec->new(
      containers => [
        MockContainer->new(name => 'nginx'),
        MockContainer->new(name => 'sidecar'),
      ],
    ),
  );

  my $summary = $k8s->_format_resource_summary($pod);

  is($summary->{name}, 'web-abc123', 'name extracted');
  is($summary->{namespace}, 'default', 'namespace extracted');
  is($summary->{kind}, 'Pod', 'kind extracted');
  is($summary->{phase}, 'Running', 'phase extracted');
  is_deeply($summary->{labels}, { app => 'web', env => 'prod' }, 'labels extracted');
  is_deeply($summary->{containers}, ['nginx', 'sidecar'], 'containers extracted');
  is($summary->{creationTimestamp}, '2026-02-23T10:00:00Z', 'timestamp extracted');
};

subtest 'format service with ports' => sub {
  my $svc = MockPod->new(
    metadata => MockMeta->new(
      name      => 'my-service',
      namespace => 'default',
    ),
    kind => 'Service',
    spec => MockServiceSpec->new(
      type  => 'ClusterIP',
      ports => [
        MockPort->new(port => 80, targetPort => 8080, protocol => 'TCP'),
        MockPort->new(port => 443, targetPort => 8443, protocol => 'TCP'),
      ],
    ),
  );

  my $summary = $k8s->_format_resource_summary($svc);

  is($summary->{name}, 'my-service', 'service name');
  is($summary->{kind}, 'Service', 'service kind');
  is($summary->{type}, 'ClusterIP', 'service type');
  is(scalar @{$summary->{ports}}, 2, 'two ports');
  is($summary->{ports}[0]{port}, 80, 'first port');
  is($summary->{ports}[0]{targetPort}, 8080, 'first target port');
  is($summary->{ports}[1]{port}, 443, 'second port');
};

subtest 'format minimal object' => sub {
  my $obj = MockPod->new(
    metadata => MockMeta->new(name => 'minimal'),
    kind     => 'ConfigMap',
  );

  my $summary = $k8s->_format_resource_summary($obj);

  is($summary->{name}, 'minimal', 'name from minimal object');
  is($summary->{kind}, 'ConfigMap', 'kind from minimal object');
  ok(!exists $summary->{namespace}, 'no namespace on cluster-scoped');
  ok(!exists $summary->{phase}, 'no phase without status');
  ok(!exists $summary->{containers}, 'no containers without spec');
};

subtest 'format_list' => sub {
  my @items = (
    MockPod->new(
      metadata => MockMeta->new(name => 'pod-1', namespace => 'default'),
      kind     => 'Pod',
      status   => MockPodStatus->new(phase => 'Running'),
    ),
    MockPod->new(
      metadata => MockMeta->new(name => 'pod-2', namespace => 'default'),
      kind     => 'Pod',
      status   => MockPodStatus->new(phase => 'Pending'),
    ),
    MockPod->new(
      metadata => MockMeta->new(name => 'pod-3', namespace => 'default'),
      kind     => 'Pod',
      status   => MockPodStatus->new(phase => 'Succeeded'),
    ),
  );

  my $summaries = $k8s->_format_list(\@items);

  is(scalar @$summaries, 3, 'three items formatted');
  is($summaries->[0]{name}, 'pod-1', 'first pod name');
  is($summaries->[1]{phase}, 'Pending', 'second pod phase');
  is($summaries->[2]{phase}, 'Succeeded', 'third pod phase');
};

subtest 'format_list empty' => sub {
  my $summaries = $k8s->_format_list([]);
  is_deeply($summaries, [], 'empty list returns empty array');
};

subtest 'format_list undef' => sub {
  my $summaries = $k8s->_format_list(undef);
  is_deeply($summaries, [], 'undef items returns empty array');
};

subtest '_to_json roundtrip' => sub {
  my $data = { status => 'ok', count => 42, items => ['a', 'b'] };
  my $json_str = $k8s->_to_json($data);
  ok(length($json_str) > 0, 'JSON output not empty');

  my $decoded = JSON::MaybeXS->new->decode($json_str);
  is_deeply($decoded, $data, 'JSON roundtrip preserves data');
};

subtest 'event summary carries reason, message and involvedObject' => sub {
  require IO::K8s;
  my $ev = IO::K8s->new->struct_to_object('Event', {
    metadata       => { name => 'web.17a', namespace => 'default' },
    involvedObject => { kind => 'Pod', name => 'web' },
    reason         => 'BackOff',
    message        => 'Back-off restarting failed container',
    type           => 'Warning',
    count          => 7,
    lastTimestamp  => '2026-10-01T10:00:00Z',
  });
  my $s = $k8s->_format_resource_summary($ev);
  is($s->{reason}, 'BackOff', 'reason');
  is($s->{message}, 'Back-off restarting failed container', 'message');
  is($s->{type}, 'Warning', 'type');
  is($s->{count}, 7, 'count');
  is_deeply($s->{involvedObject}, { kind => 'Pod', name => 'web' }, 'involvedObject');
  ok($s->{lastTimestamp}, 'lastTimestamp');
};

done_testing;
