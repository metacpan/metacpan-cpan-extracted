use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Future;
use Kubernetes::Comb::Client::Fake;
use Kubernetes::Comb::Endpoint;
use TestComb::Configurable;
use TestComb::Fixtures qw( comb_cr comb_labels deployment service set_status );

# The upstream path of reconcile: the bridge instead of the local resources.

my $static = 'Kubernetes::Comb::Upstream::Static';
my $k8s_up = 'Kubernetes::Comb::Upstream::K8s';

# An upstream that also replicates, noting how far the deploy was then.
{
  package TestComb::Upstream::Replicating;
  use Moo;
  extends 'Kubernetes::Comb::Upstream::Static';
  has replicated => ( is => 'ro', default => sub { [] } );
  has fails      => ( is => 'ro' );
  sub replicate_into {
    my ( $self, $comb ) = @_;
    push @{ $self->replicated }, { comb => $comb, ensured => scalar $comb->k8s->calls_of('ensure') };
    return $self->fails ? Future->fail( $self->fails ) : Future->done;
  }
}

# An upstream whose answers the test writes.
{
  package TestComb::Upstream::Scripted;
  use Moo;
  with 'Kubernetes::Comb::Role::Upstream';
  has on_status    => ( is => 'ro', default => sub { sub { Future->done( { reachable => 1, phase => 'Running' } ) } } );
  has on_endpoints => ( is => 'ro', default => sub { sub { Future->done( [] ) } } );
  sub status    { $_[0]->on_status->( $_[1] ) }
  sub endpoints { $_[0]->on_endpoints->( $_[1] ) }
}

{
  package TestComb::BadBridge;
  use Moo;
  extends 'TestComb::Configurable';
  has bridge => ( is => 'ro' );
  sub bridge_manifests { $_[0]->bridge->() }
}

# nats in platform: a Deployment and a Service, offering client on 4222. The
# upstream coderef answers what the returned arrayref holds.
sub comb {
  my ( %args ) = @_;
  my $answer = [];
  my $class = delete $args{class} // 'TestComb::Configurable';
  my $k8s = delete $args{k8s} // Kubernetes::Comb::Client::Fake->new;
  my $comb = $class->new(
    name      => 'nats',
    namespace => 'platform',
    k8s       => $k8s,
    parts     => [ deployment('nats'), service('nats') ],
    offers    => [ { name => 'client', port => 4222 } ],
    upstream  => sub { @$answer },
    %args
  );
  return ( $comb, $k8s, $answer );
}

# Static => (...) offering client at the address, via dev.
sub from_dev {
  my ( $address, %args ) = @_;
  return ( Static => (
    endpoints => [ { name => 'client', port => 4222, cluster => $address // 'nats.dev.example.com:4222' } ],
    via       => [ 'dev' ],
    %args
  ) );
}

sub reconciled {
  my ( $comb ) = @_;
  my $f = $comb->reconcile;
  ok $f->is_done, 'the reconcile Future is done';
  return $f->get;
}

sub ready {
  my ( $status ) = @_;
  my ( $ready ) = grep { $_->type eq 'Ready' } @{ $status->conditions };
  return $ready;
}

sub is_step {
  my ( $status, $phase, $reason, $message, $what ) = @_;
  is $status->phase, $phase, $what.': '.$phase;
  is ready($status)->reason, $reason, $what.': '.$reason;
  like ready($status)->message, $message, $what.': the message';
}

sub managed   { [ map { $_->TO_JSON } @{ $_[0]->managedResources // [] } ] }
sub published { [ map { $_->TO_JSON } @{ $_[0]->endpoints // [] } ] }
sub ensured   { [ map { $_->[0]{kind}.'/'.$_->[0]{metadata}{name} } $_[0]->calls_of('ensure') ] }
sub deleted   { [ map { $_->[0]->kind.'/'.$_->[0]->metadata->name } $_[0]->calls_of('delete') ] }

sub stored {
  my ( $k8s, $kind, $name, $namespace ) = @_;
  my $object = $k8s->object( $kind, $name, namespace => $namespace // 'platform' );
  return $object ? $object->TO_JSON : undef;
}

my %service_nats    = ( apiVersion => 'v1',      kind => 'Service',    namespace => 'platform', name => 'nats' );
my %deployment_nats = ( apiVersion => 'apps/v1', kind => 'Deployment', namespace => 'platform', name => 'nats' );

subtest 'borrowing: the bridge, Running' => sub {
  my ( $comb, $k8s, $answer ) = comb();
  @$answer = from_dev();
  my $status = reconciled($comb);
  is_step( $status, Running => Borrowed => qr/\Aborrowed from upstream Kubernetes::Comb::Upstream::Static via dev\z/,
    'bridge in place and upstream Running' );
  is_deeply ensured($k8s), [ 'Service/nats' ], 'only the bridge is applied';
  ok !stored( $k8s, Deployment => 'nats' ), 'no local workload';
  my $service = stored( $k8s, Service => 'nats' );
  is $service->{spec}{type}, 'ExternalName', 'the Service of the local name points at the upstream';
  is $service->{spec}{externalName}, 'nats.dev.example.com', '... at its host';
  is_deeply $service->{metadata}{labels}, { comb_labels('nats') }, '... labelled as the Comb\'s';
  is_deeply managed($status), [ {%service_nats} ], 'managedResources: the bridge';

  is_deeply published($status),
    [ { name => 'client', protocol => 'tcp', port => 4222, cluster => 'nats.dev.example.com:4222' } ],
    'status.endpoints: the redirected endpoints';
  my $upstream = $status->upstream;
  is $upstream->class, $static, 'status.upstream: the class';
  ok $upstream->reachable, '... reachable';
  is $upstream->phase, 'Running', '... its phase';
  is_deeply $upstream->via, [ 'dev' ], '... via';
  like $upstream->observedAt, qr/\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ\z/, '... when';

  is $comb->endpoint('client')->get->cluster, 'nats.dev.example.com:4222', 'endpoint is redirected';
  is_deeply $comb->describe->get->{endpoints}, published($status), 'describe too';
  my $live = $comb->status->get;
  is $live->{phase}, 'Running', 'status: Running';
  ok $live->{healthy}, '... healthy';
  is_deeply $live->{pods}, [], '... no pods';
  is $live->{upstream}{class}, $static, '... the upstream';
};

subtest 'the upstream is not Running: Pending, bridged anyway' => sub {
  my ( $comb, $k8s, $answer ) = comb();
  @$answer = from_dev( undef, phase => 'Pending', message => 'starting' );
  my $status = reconciled($comb);
  is_step( $status, Pending => UpstreamNotRunning => qr/\Aupstream Kubernetes::Comb::Upstream::Static is Pending: starting\z/,
    'upstream Pending' );
  is_deeply ensured($k8s), [ 'Service/nats' ], 'the bridge is applied';
  is $status->upstream->phase, 'Pending', 'status.upstream.phase';
  ok !$comb->healthy->get, 'not healthy';
  is $comb->status->get->{reason}, 'UpstreamNotRunning', 'status says why';
};

subtest 'unreachable: Blocked, nothing touched' => sub {
  my ( $comb, $k8s, $answer ) = comb();
  reconciled($comb);
  $k8s->clear_calls;
  @$answer = from_dev( undef, reachable => 0, message => 'vendor down' );
  my $status = reconciled($comb);
  is_step( $status, Blocked => UpstreamUnreachable =>
    qr/\Aupstream Kubernetes::Comb::Upstream::Static is unreachable: vendor down\z/, 'unreachable' );
  is_deeply ensured($k8s), [], 'nothing applied';
  is_deeply deleted($k8s), [], 'nothing pruned: what runs keeps running';
  is_deeply managed($status), [ {%deployment_nats}, {%service_nats} ], 'managedResources carried forward';
  is_deeply published($status), [], 'no endpoints';
  ok !$status->upstream->reachable, 'status.upstream: not reachable';
  is $comb->status->get->{phase}, 'Blocked', 'status: Blocked';
  like $comb->endpoint('client')->failure, qr/is unreachable: vendor down/, 'endpoint fails with the reason';
};

subtest 'an endpoint the upstream has no address for: Blocked' => sub {
  my ( $comb, $k8s, $answer ) = comb();
  @$answer = ( Static => ( endpoints => [ { name => 'other', port => 1, cluster => 'x.example:1' } ],
    phase => 'Pending', message => 'booting' ) );
  my $status = reconciled($comb);
  is_step( $status, Blocked => UpstreamEndpointsMissing =>
    qr/\Aupstream Kubernetes::Comb::Upstream::Static offers no reachable address for endpoint\(s\) client \(it is Pending\); booting\z/,
    'not offered' );
  is_deeply ensured($k8s), [], 'nothing applied';
  is_deeply published($status), [], 'no endpoints';
  like $comb->endpoint('client')->failure, qr/offers no reachable address for endpoint\(s\) client/, 'endpoint fails so';

  @$answer = ( Static => ( endpoints => [ { name => 'client', port => 4222 } ] ) );
  is_step( reconciled($comb), Blocked => UpstreamEndpointsMissing => qr/endpoint\(s\) client\z/, 'offered without address' );
};

subtest 'a bridge that cannot be: Blocked, nothing deployed' => sub {
  my ( $comb, $k8s, $answer ) = comb();
  @$answer = from_dev('nats.dev.example.com:14222');
  my $status = reconciled($comb);
  is_step( $status, Blocked => BridgeImpossible =>
    qr/\Athe upstream cannot be bridged: Service nats: endpoint client is port 4222 here but 14222 at nats\.dev\.example\.com, and an ExternalName Service cannot map ports\z/,
    'ExternalName cannot map ports' );
  is_deeply ensured($k8s), [], 'no broken bridge deployed';
  is_deeply published($status),
    [ { name => 'client', protocol => 'tcp', port => 4222, cluster => 'nats.dev.example.com:14222' } ],
    'the upstream address is still published';
  is $comb->status->get->{reason}, 'BridgeImpossible', 'status says so';
};

subtest 'IP addresses: a Service and an EndpointSlice' => sub {
  my ( $comb, $k8s, $answer ) = comb();
  @$answer = from_dev('10.1.2.3:14222');
  my $status = reconciled($comb);
  is $status->phase, 'Running', 'Running';
  is_deeply ensured($k8s), [ 'Service/nats', 'EndpointSlice/nats-1' ], 'Service, then EndpointSlice';
  my $slice = stored( $k8s, EndpointSlice => 'nats-1' );
  is $slice->{addressType}, 'IPv4', 'the slice: IPv4';
  is_deeply $slice->{endpoints}, [ { addresses => [ '10.1.2.3' ] } ], '... the address';
  is_deeply $slice->{ports}, [ { name => 'client', port => 14222, protocol => 'TCP' } ], '... its port';
  is $slice->{metadata}{labels}{'kubernetes.io/service-name'}, 'nats', '... belongs to the Service';
  is $slice->{metadata}{labels}{'comb.internal/comb'}, 'nats', '... and to the Comb';
  is_deeply managed($status), [ {%service_nats},
    { apiVersion => 'discovery.k8s.io/v1', kind => 'EndpointSlice', namespace => 'platform', name => 'nats-1' } ],
    'managedResources: both';
};

subtest 'from local to upstream: workloads pruned, the Service changed in place' => sub {
  my ( $comb, $k8s, $answer ) = comb();
  reconciled($comb);
  set_status( $k8s, Deployment => 'nats', { readyReplicas => 1 } );
  # what the API server makes of it: an allocated cluster IP
  my $service = stored( $k8s, Service => 'nats' );
  $k8s->add( { %$service, spec => { %{ $service->{spec} }, clusterIP => '10.96.0.10' } } );
  is reconciled($comb)->phase, 'Running', 'running locally';

  $k8s->clear_calls;
  @$answer = from_dev();
  my $status = reconciled($comb);
  is $status->phase, 'Running', 'borrowing: Running';
  is_deeply ensured($k8s), [ 'Service/nats' ], 'the Service is applied';
  my ( $sent ) = map { $_->[0] } $k8s->calls_of('ensure');
  ok !exists $sent->{spec}{clusterIP}, '... without the cluster IP';
  ok !exists $sent->{spec}{selector}, '... and without selector';
  is_deeply deleted($k8s), [ 'Deployment/nats' ], 'the Deployment is pruned';
  ok !stored( $k8s, Deployment => 'nats' ), '... gone';
  $service = stored( $k8s, Service => 'nats' );
  is $service->{spec}{type}, 'ExternalName', 'the Service is the bridge now';
  ok !exists $service->{spec}{$_}, '... no '.$_.' left' for qw( clusterIP selector );
  is_deeply managed($status), [ {%service_nats} ], 'managedResources: the bridge';
};

subtest 'from upstream back to local' => sub {
  my ( $comb, $k8s, $answer ) = comb();
  @$answer = from_dev('10.1.2.3:4222');
  reconciled($comb);
  $k8s->clear_calls;
  @$answer = ();
  my $status = reconciled($comb);
  is $status->phase, 'Pending', 'local again: deployed, Pending';
  is_deeply ensured($k8s), [ 'Deployment/nats', 'Service/nats' ], 'the local resources are applied';
  is_deeply deleted($k8s), [ 'EndpointSlice/nats-1' ], 'the EndpointSlice is pruned';
  is_deeply stored( $k8s, Service => 'nats' )->{spec}, { selector => { app => 'nats' }, ports => [ { port => 4222 } ] },
    'the Service is the local one again';
  is_deeply managed($status), [ {%deployment_nats}, {%service_nats} ], 'managedResources: the local ones';
  ok !$status->upstream, 'no status.upstream';
  is_deeply published($status), [ { name => 'client', protocol => 'tcp', port => 4222, cluster => 'nats.platform.svc:4222' } ],
    'the local endpoints';

  # A Comb of Services only looks healthy while the bridge stands in their place.
  ( $comb, $k8s, $answer ) = comb( parts => [ service('nats') ] );
  @$answer = from_dev();
  reconciled($comb);
  @$answer = ();
  $k8s->clear_calls;
  $status = reconciled($comb);
  is_step( $status, Pending => Deployed => qr/\Aapplied 1 resource\(s\), in place of the bridge\z/,
    'deployed although healthy-looking' );
  is stored( $k8s, Service => 'nats' )->{spec}{selector}{app}, 'nats', 'the Service is the local one again';
  is reconciled($comb)->phase, 'Running', 'then Running';
};

subtest 'from upstream back to local, through steps that stop early' => sub {
  # A Comb of Services only: the bridge looks healthy in their place.
  my ( $comb, $k8s, $answer ) = comb( parts => [ service('nats') ] );
  @$answer = from_dev();
  my $borrowed = reconciled($comb);
  my @redirected = @{ published($borrowed) };

  $comb->missing( [ 'secret nats-auth' ] );
  my $status = reconciled($comb);
  is $status->phase, 'NeedsConfig', 'NeedsConfig';
  my $carried = $status->upstream;
  ok $carried, 'status.upstream carried forward: the bridge still stands';
  is $carried && $carried->class, $static, '... its class';
  is $carried && $carried->observedAt, $borrowed->upstream->observedAt, '... as it was observed';
  is_deeply published($status), \@redirected, 'status.endpoints carried forward: the redirected ones';

  @$answer = ( sub { die "registry down\n" } );
  $status = reconciled($comb);
  is ready($status)->reason, 'UpstreamFailed', 'an Error before the path';
  ok $status->upstream, '... carries status.upstream forward too';
  is_deeply published($status), \@redirected, '... and status.endpoints';

  $comb->missing( [] );
  @$answer = ();
  $k8s->fail_on( list => 'connection reset', times => 1 );
  $status = reconciled($comb);
  is ready($status)->reason, 'StatusFailed', 'local, but the live status cannot be read';
  ok $status->upstream, '... nothing replaced the bridge: status.upstream stays';
  is stored( $k8s, Service => 'nats' )->{spec}{type}, 'ExternalName', '... and so does the bridge';

  $k8s->clear_calls;
  $status = reconciled($comb);
  is_step( $status, Pending => Deployed => qr/\Aapplied 1 resource\(s\), in place of the bridge\z/,
    'local: deployed although healthy-looking' );
  is stored( $k8s, Service => 'nats' )->{spec}{selector}{app}, 'nats', 'the Service is the local one again';
  ok !$status->upstream, 'status.upstream gone';
  is_deeply published($status), [ { name => 'client', protocol => 'tcp', port => 4222, cluster => 'nats.platform.svc:4222' } ],
    'the local endpoints published';
  is reconciled($comb)->phase, 'Running', 'then Running';
};

subtest 'early stops of a local Comb carry its endpoints' => sub {
  my ( $comb, $k8s, $answer ) = comb();
  my $first = reconciled($comb);
  my @local = @{ published($first) };
  ok @local, 'local endpoints published';
  $comb->missing( [ 'secret nats-auth' ] );
  @$answer = from_dev();
  my $status = reconciled($comb);
  is $status->phase, 'NeedsConfig', 'about to borrow, but NeedsConfig';
  ok !$status->upstream, 'no status.upstream: nothing was borrowed yet';
  is_deeply published($status), \@local, 'the local endpoints still stand';
};

subtest 'a chain longer than max_upstream_depth is a loop: Blocked' => sub {
  my @client = ( endpoints => [ { name => 'client', port => 4222, cluster => 'nats.dev.example.com:4222' } ] );
  my @layers = map { 'layer'.$_ } 1 .. 17;
  my ( $comb, $k8s, $answer ) = comb();
  is $comb->max_upstream_depth, 16, 'default 16';
  @$answer = ( Static => ( @client, via => [ @layers[ 0 .. 15 ] ] ) );
  is reconciled($comb)->phase, 'Running', '16 layers are a chain';

  ( $comb, $k8s, $answer ) = comb();
  @$answer = ( Static => ( @client, via => [@layers] ) );
  my $status = reconciled($comb);
  is_step( $status, Blocked => UpstreamLoop =>
    qr/\Aupstream Kubernetes::Comb::Upstream::Static leads through more than 16 layers, a loop\? via layer1, layer2, .*, layer16\z/,
    '17 layers' );
  is_deeply $status->upstream->via, [ @layers[ 0 .. 15 ] ], 'via is cut to 16, so a loop does not grow it';
  is_deeply ensured($k8s), [], 'nothing applied';
  is_deeply published($status), [], 'no endpoints';

  ( $comb, $k8s, $answer ) = comb( max_upstream_depth => 2 );
  @$answer = ( Static => ( @client, via => [ 'dev', 'dev' ] ) );
  is reconciled($comb)->phase, 'Running', 'max_upstream_depth given: 2 layers are a chain';
  @$answer = ( Static => ( @client, via => [ 'dev', 'dev', 'prod' ] ) );
  $status = reconciled($comb);
  is ready($status)->reason, 'UpstreamLoop', '... 3 are not';
  is_deeply $status->upstream->via, [ 'dev', 'dev' ], '... cut to 2';

  ok !eval { TestComb::Configurable->new( max_upstream_depth => 0 ); 1 }, 'at least one layer';
};

subtest 'one context, three namespaces: a chain, no loop' => sub {
  # prod <- dev <- getty, all reached through the same kube context c -- the
  # one the client itself was built for
  my $k8s = Kubernetes::Comb::Client::Fake->new( context => 'c' );
  $k8s->contexts->{c} = $k8s;
  my %combs;
  for my $namespace (qw( prod dev getty )) {
    $k8s->add( comb_cr( name => 'nats', namespace => $namespace, class => 'TestComb::Configurable' ) );
    $combs{$namespace} = TestComb::Configurable->new(
      crd    => $k8s->object( Comb => 'nats', namespace => $namespace ),
      k8s    => $k8s,
      parts  => [ service('nats') ],
      offers => [ { name => 'client', port => 4222 } ],
      ( $namespace eq 'dev'   ? ( upstream => [ K8s => ( context => 'c', namespace => 'prod' ) ] ) : () ),
      ( $namespace eq 'getty' ? ( upstream => [ K8s => ( context => 'c', namespace => 'dev' ) ] ) : () )
    );
  }
  reconciled( $combs{$_} ) for qw( prod prod dev );
  my $status = reconciled( $combs{getty} );
  is_step( $status, Running => Borrowed => qr/\(context c\) via c, c\z/, 'getty borrows through dev from prod' );
  is_deeply $status->upstream->via, [ 'c', 'c' ], 'via names the context of each layer';
  is $combs{getty}->endpoint('client')->get->cluster, 'nats.prod.svc:4222', 'at prod\'s address';
};

subtest 'two layers borrowing from each other' => sub {
  my $prod_k8s = Kubernetes::Comb::Client::Fake->new( context => 'prod', server_url => 'https://prod.example:6443' );
  my $dev_k8s  = Kubernetes::Comb::Client::Fake->new( context => 'dev',  server_url => 'https://dev.example:6443',
    contexts => { prod => $prod_k8s } );
  $prod_k8s->contexts->{dev} = $dev_k8s;
  my %combs;
  for my $layer ( [ dev => $dev_k8s, 'prod' ], [ prod => $prod_k8s, 'dev' ] ) {
    my ( $name, $k8s, $other ) = @$layer;
    $k8s->add( comb_cr( name => 'nats', class => 'TestComb::Configurable',
      spec => { upstream => { class => $k8s_up, context => $other } } ) );
    $combs{$name} = TestComb::Configurable->new(
      crd                => $k8s->object( Comb => 'nats', namespace => 'platform' ),
      k8s                => $k8s,
      offers             => [ { name => 'client', port => 4222 } ],
      max_upstream_depth => 3
    );
  }
  my @vias;
  for ( 1 .. 4 ) {
    for my $name (qw( dev prod )) {
      my $status = reconciled( $combs{$name} );
      push @vias, $name.': '.ready($status)->reason.' via '.join( ',', @{ $status->upstream->via } );
    }
  }
  is_deeply \@vias, [
    'dev: UpstreamEndpointsMissing via prod',
    'prod: UpstreamEndpointsMissing via dev,prod',
    'dev: UpstreamEndpointsMissing via prod,dev,prod',
    'prod: UpstreamLoop via dev,prod,dev',
    'dev: UpstreamLoop via prod,dev,prod',
    'prod: UpstreamLoop via dev,prod,dev',
    'dev: UpstreamLoop via prod,dev,prod',
    'prod: UpstreamLoop via dev,prod,dev'
  ], 'via grows to max_upstream_depth, then both are a loop and via stays put';
  is $combs{$_}->recorded_status->phase, 'Blocked', $_.' Blocked' for qw( dev prod );
};

subtest 'replicate_into' => sub {
  my @endpoints = ( endpoints => [ { name => 'client', port => 4222, cluster => 'nats.dev.example.com:4222' } ] );
  my $upstream = TestComb::Upstream::Replicating->new(@endpoints);
  my ( $comb, $k8s ) = comb( upstream => $upstream );
  is reconciled($comb)->phase, 'Running', 'Running';
  is scalar @{ $upstream->replicated }, 1, 'called';
  is $upstream->replicated->[0]{comb}, $comb, '... with the Comb';
  is $upstream->replicated->[0]{ensured}, 0, '... before the bridge is deployed';

  $upstream = TestComb::Upstream::Replicating->new( @endpoints, fails => "snapshot failed\n" );
  ( $comb, $k8s ) = comb( upstream => $upstream );
  my $status = reconciled($comb);
  is_step( $status, Error => ReplicationFailed =>
    qr/\Areplicating from upstream TestComb::Upstream::Replicating failed: snapshot failed\z/, 'a failing replication' );
  is_deeply ensured($k8s), [], 'no bridge';
  is $status->upstream->phase, 'Running', 'status.upstream recorded';
};

subtest 'Error, never a failed Future' => sub {
  my $scripted = sub { TestComb::Upstream::Scripted->new(@_) };
  my $client = [ Kubernetes::Comb::Endpoint->new( name => 'client', port => 4222, cluster => 'nats.dev.example.com:4222' ) ];
  for my $case (
    [ 'a dying status', UpstreamFailed => qr/\Areading the status of TestComb::Upstream::Scripted failed: boom\z/,
      upstream => $scripted->( on_status => sub { die "boom\n" } ) ],
    [ 'a failing status', UpstreamFailed => qr/failed: nope\z/,
      upstream => $scripted->( on_status => sub { Future->fail('nope') } ) ],
    [ 'a status that is no hashref', UpstreamFailed => qr/->status answered a plain scalar, not a hashref/,
      upstream => $scripted->( on_status => sub { Future->done('Running') } ) ],
    [ 'a via that is no arrayref', UpstreamFailed => qr/answered a via that is no arrayref/,
      upstream => $scripted->( on_status => sub { Future->done( { reachable => 1, via => 'dev' } ) } ) ],
    [ 'failing endpoints', UpstreamFailed => qr/\Areading the endpoints of upstream TestComb::Upstream::Scripted failed: gone\z/,
      upstream => $scripted->( on_endpoints => sub { Future->fail("gone\n") } ) ],
    [ 'endpoints that are none', UpstreamFailed => qr/->endpoints answered HASH, not a Kubernetes::Comb::Endpoint/,
      upstream => $scripted->( on_endpoints => sub { Future->done( [ { name => 'client' } ] ) } ) ],
    [ 'a dying bridge_manifests', BridgeFailed => qr/\Arendering the bridge failed: no bridge today\z/,
      class => 'TestComb::BadBridge', bridge => sub { die "no bridge today\n" },
      upstream => $scripted->( on_endpoints => sub { Future->done($client) } ) ],
    [ 'a bridge manifest that is none', BridgeFailed => qr/rendering the bridge failed: .*has no kind/,
      class => 'TestComb::BadBridge', bridge => sub { return { metadata => { name => 'x' } } },
      upstream => $scripted->( on_endpoints => sub { Future->done($client) } ) ]
  ) {
    my ( $what, $reason, $message, %args ) = @$case;
    my ( $comb, $k8s ) = comb(%args);
    is_step( reconciled($comb), Error => $reason, $message, $what );
    is_deeply ensured($k8s), [], $what.': nothing applied';
  }

  my ( $comb, $k8s, $answer ) = comb();
  @$answer = from_dev();
  $k8s->fail_on( ensure => 'quota exceeded' );
  my $status = reconciled($comb);
  is_step( $status, Error => DeployFailed => qr/\Adeploy failed: ensure Service nats: quota exceeded/, 'the bridge fails to deploy' );
  is_deeply managed($status), [], 'nothing recorded as applied';
};

subtest 'status and healthy of a borrowing Comb' => sub {
  my ( $comb, $k8s, $answer ) = comb();
  @$answer = from_dev();
  my $live = $comb->status->get;
  is $live->{phase}, 'NotDeployed', 'before the bridge: NotDeployed';
  ok !$live->{healthy}, '... not healthy';
  like $live->{message}, qr/Service nats is missing/, '... saying what is missing';
  reconciled($comb);
  ok $comb->healthy->get, 'with the bridge: healthy';

  my $app = TestComb::Configurable->new(
    name     => 'app',
    namespace => 'platform',
    k8s      => $k8s,
    needs    => [ 'nats' ],
    resolver => sub { $comb }
  );
  my $status = reconciled($app);
  is( ( grep { $_->type eq 'DependenciesReady' } @{ $status->conditions } )[0]->status, 'True',
    'a Comb depending on it goes ahead' );
};

subtest 'with a custom resource: status.upstream written' => sub {
  my $k8s = Kubernetes::Comb::Client::Fake->new;
  $k8s->add( comb_cr( name => 'nats', class => 'TestComb::Configurable', spec => {
    upstream => { class => $static, endpoints => [ { name => 'client', port => 4222, cluster => 'nats.dev.example.com:4222' } ], via => [ 'dev' ] }
  } ) );
  my $comb = TestComb::Configurable->new(
    crd    => $k8s->object( Comb => 'nats', namespace => 'platform' ),
    k8s    => $k8s,
    parts  => [ deployment('nats') ],
    offers => [ { name => 'client', port => 4222 } ]
  );
  is reconciled($comb)->phase, 'Running', 'Running';
  ok scalar $k8s->calls_of('update_status'), 'written through update_status';
  my $cr = $k8s->object( Comb => 'nats', namespace => 'platform' )->status;
  is $cr->upstream->class, $static, 'status.upstream in the custom resource';
  is_deeply $cr->upstream->via, [ 'dev' ], '... with via';
  is_deeply published($cr), [ { name => 'client', protocol => 'tcp', port => 4222, cluster => 'nats.dev.example.com:4222' } ],
    'status.endpoints in the custom resource';
};

subtest 'Upstream::K8s in a reconcile' => sub {
  my ( $comb, $k8s, $answer ) = comb();
  @$answer = ( K8s => ( context => 'dev' ) );
  my $status = reconciled($comb);
  is_step( $status, Blocked => UpstreamUnreachable =>
    qr/\Aupstream Kubernetes::Comb::Upstream::K8s \(context dev\) is unreachable: reading Comb platform\/nats in context dev failed: Context not found: dev/,
    'a missing context' );
  like ready($status)->message, qr/Context not found: dev\z/, '... ending with the error, not where it was raised';
  is $status->upstream->context, 'dev', 'status.upstream.context';
  is_deeply $status->upstream->via, [ 'dev' ], 'status.upstream.via';

  my $dev = Kubernetes::Comb::Client::Fake->new( server_url => $k8s->server_url );
  $dev->add( {
    %{ comb_cr( name => 'nats', class => 'TestComb::Configurable' )->TO_JSON },
    status => { phase => 'Pending', endpoints => [ { name => 'client', port => 4222, cluster => 'nats.platform.svc:4222' } ] }
  } );
  ( $comb, $k8s, $answer ) = comb( namespace => 'getty', k8s => Kubernetes::Comb::Client::Fake->new( contexts => { dev => $dev } ) );
  @$answer = ( K8s => ( context => 'dev', namespace => 'platform' ) );
  $status = reconciled($comb);
  is_step( $status, Pending => UpstreamNotRunning => qr/\(context dev\) is Pending\z/, 'the peer is Pending' );
  is stored( $k8s, Service => 'nats', 'getty' )->{spec}{externalName}, 'nats.platform.svc.cluster.local',
    'same API server: the peer\'s cluster address, with the cluster domain';
};

subtest 'layers: getty borrows from dev, dev from prod' => sub {
  my $prod_k8s  = Kubernetes::Comb::Client::Fake->new( server_url => 'https://prod.example:6443' );
  my $dev_k8s   = Kubernetes::Comb::Client::Fake->new( server_url => 'https://dev.example:6443',
    contexts => { prod => $prod_k8s } );
  my $getty_k8s = Kubernetes::Comb::Client::Fake->new( server_url => 'https://dev.example:6443',
    contexts => { dev => $dev_k8s } );
  $prod_k8s->add( comb_cr( name => 'nats', class => 'TestComb::Configurable' ) );
  $dev_k8s->add( comb_cr( name => 'nats', class => 'TestComb::Configurable',
    spec => { upstream => { class => $k8s_up, context => 'prod' } } ) );
  $getty_k8s->add( comb_cr( name => 'nats', namespace => 'getty', class => 'TestComb::Configurable',
    spec => { upstream => { class => $k8s_up, context => 'dev', namespace => 'platform' } } ) );
  my $layer = sub {
    my ( $k8s, $namespace ) = @_;
    return TestComb::Configurable->new(
      crd    => $k8s->object( Comb => 'nats', namespace => $namespace ),
      k8s    => $k8s,
      parts  => [ deployment('nats'), service('nats') ],
      offers => [ { name => 'client', port => 4222, external => 'nats.prod.example.com:4222' } ]
    );
  };
  my %address = ( name => 'client', protocol => 'tcp', port => 4222 );

  my $prod = $layer->( $prod_k8s, 'platform' );
  reconciled($prod);
  set_status( $prod_k8s, Deployment => 'nats', { readyReplicas => 1 } );
  is reconciled($prod)->phase, 'Running', 'prod runs nats itself';

  my $dev = $layer->( $dev_k8s, 'platform' );
  my $status = reconciled($dev);
  is $status->phase, 'Running', 'dev borrows from prod: Running';
  is_deeply $status->upstream->via, [ 'prod' ], '... via prod';
  is stored( $dev_k8s, Service => 'nats' )->{spec}{externalName}, 'nats.prod.example.com',
    '... another API server: the external address';
  is_deeply published($status),
    [ { %address, cluster => 'nats.prod.example.com:4222', external => 'nats.prod.example.com:4222' } ],
    '... which it publishes';

  my $getty = $layer->( $getty_k8s, 'getty' );
  $status = reconciled($getty);
  is $status->phase, 'Running', 'getty borrows from dev: Running';
  is_deeply $status->upstream->via, [ 'dev', 'prod' ], '... via dev and prod';
  is stored( $getty_k8s, Service => 'nats', 'getty' )->{spec}{externalName}, 'nats.prod.example.com',
    '... the address dev publishes: dev knows no layer above prod';
  is $getty->endpoint('client')->get->cluster, 'nats.prod.example.com:4222', '... and its endpoint';

  set_status( $prod_k8s, Deployment => 'nats', { readyReplicas => 0 } );
  is reconciled($prod)->phase, 'Pending', 'prod goes Pending';
  is_step( reconciled($dev), Pending => UpstreamNotRunning => qr/is Pending/, 'dev follows' );
  is_step( reconciled($getty), Pending => UpstreamNotRunning => qr/is Pending/, 'getty too' );
};

subtest 'layers: dev borrows from prod, prod from a vendor' => sub {
  my $prod_k8s = Kubernetes::Comb::Client::Fake->new( server_url => 'https://prod.example:6443' );
  my $dev_k8s  = Kubernetes::Comb::Client::Fake->new( server_url => 'https://dev.example:6443',
    contexts => { prod => $prod_k8s } );
  $prod_k8s->add( comb_cr( name => 'nats', class => 'TestComb::Configurable', spec => { upstream => {
    class     => $static,
    endpoints => [ { name => 'client', port => 4222, cluster => '203.0.113.7:4222', external => '203.0.113.7:4222' } ],
    via       => [ 'vendor' ]
  } } ) );
  $dev_k8s->add( comb_cr( name => 'nats', class => 'TestComb::Configurable',
    spec => { upstream => { class => $k8s_up, context => 'prod' } } ) );
  my %layer = map {
    my ( $name, $k8s ) = @$_;
    ( $name => TestComb::Configurable->new(
      crd    => $k8s->object( Comb => 'nats', namespace => 'platform' ),
      k8s    => $k8s,
      offers => [ { name => 'client', port => 4222 } ]
    ) );
  } [ prod => $prod_k8s ], [ dev => $dev_k8s ];

  is reconciled( $layer{prod} )->phase, 'Running', 'prod borrows from the vendor';
  my $status = reconciled( $layer{dev} );
  is $status->phase, 'Running', 'dev borrows from prod';
  is_deeply $status->upstream->via, [ 'prod', 'vendor' ], '... via prod and the vendor';
  is_deeply [ map { $_->kind.'/'.$_->metadata->name } $dev_k8s->objects_of('Service'), $dev_k8s->objects_of('EndpointSlice') ],
    [ 'Service/nats', 'EndpointSlice/nats-1' ], '... bridged to the address';
  is_deeply stored( $dev_k8s, EndpointSlice => 'nats-1' )->{endpoints}, [ { addresses => [ '203.0.113.7' ] } ],
    '... the vendor\'s';
};

done_testing;
