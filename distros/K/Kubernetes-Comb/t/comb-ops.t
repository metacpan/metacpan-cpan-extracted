use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Kubernetes::Comb;
use Kubernetes::Comb::Client::Fake;
use Kubernetes::Comb::CRD::CombStatus;
use Kubernetes::Comb::Endpoint;
use TestComb::Fixtures qw( comb_cr comb_labels pod set_status );

{
  package TestComb::NATS;
  use Moo;
  extends 'Kubernetes::Comb';

  sub name { 'nats' }

  sub endpoints {
    return (
      { name => 'client',  port => 4222 },
      { name => 'monitor', port => 8222, service => 'nats-monitor', protocol => 'http' },
      Kubernetes::Comb::Endpoint->new( name => 'leaf', port => 7422, external => 'leaf.example.com:7422' )
    );
  }

  sub manifests {
    my ( $self ) = @_;
    my $workload = sub {
      my ( $kind, $name, %spec ) = @_;
      return {
        apiVersion => 'apps/v1',
        kind       => $kind,
        metadata   => { name => $name },
        spec       => {
          selector => { matchLabels => { app => $name } },
          template => {
            metadata => { labels => { app => $name } },
            spec     => { containers => [ { name => 'main', image => 'img' } ] }
          },
          %spec
        }
      };
    };
    return (
      $workload->( Deployment  => 'nats', replicas => 3 ),
      $workload->( StatefulSet => 'nats-store', serviceName => 'nats-store', replicas => 2 ),
      $workload->( DaemonSet   => 'nats-agent' ),
      {
        apiVersion => 'batch/v1',
        kind       => 'Job',
        metadata   => { name => 'nats-init' },
        spec       => { template => { spec => { restartPolicy => 'Never', containers => [ { name => 'init', image => 'img' } ] } } }
      },
      {
        apiVersion => 'batch/v1',
        kind       => 'CronJob',
        metadata   => { name => 'nats-backup' },
        spec       => {
          schedule    => '0 3 * * *',
          jobTemplate => { spec => { template => { spec => {
            restartPolicy => 'OnFailure',
            containers    => [ { name => 'backup', image => 'img' } ]
          } } } }
        }
      },
      { apiVersion => 'v1', kind => 'Service', metadata => { name => 'nats' }, spec => { ports => [ { port => 4222 } ] } }
    );
  }
}

{
  package TestComb::Broken;
  use Moo;
  extends 'Kubernetes::Comb';
  sub name      { 'broken' }
  sub endpoints { { name => 'x', port => 1, sevice => 'typo' } }
}

sub deployed {
  my $k8s = Kubernetes::Comb::Client::Fake->new;
  my $comb = TestComb::NATS->new(
    k8s => $k8s,
    crd => comb_cr( name => 'nats', class => 'TestComb::NATS', spec => { dependsOn => [ 'db' ] } )
  );
  $comb->deploy->get;
  # Somebody else's Deployment in the same namespace: never touched.
  $k8s->add( {
    apiVersion => 'apps/v1',
    kind       => 'Deployment',
    metadata   => { name => 'other', namespace => 'platform', labels => { comb_labels('other') } },
    spec       => {
      selector => { matchLabels => { app => 'other' } },
      template => { metadata => { labels => { app => 'other' } }, spec => { containers => [ { name => 'main', image => 'img' } ] } }
    }
  } );
  $k8s->clear_calls;
  return ( $comb, $k8s );
}

subtest 'restart' => sub {
  my ( $comb, $k8s ) = deployed();
  my @touched = $comb->restart->get;
  is_deeply \@touched,
    [ 'Deployment/nats', 'StatefulSet/nats-store', 'DaemonSet/nats-agent', 'Job/nats-init' ],
    'Future of what it touched';

  for my $kind (qw( Deployment StatefulSet DaemonSet )) {
    my ( $object ) = grep { $_->metadata->name ne 'other' } $k8s->objects_of( $kind, namespace => 'platform' );
    my $at = ( $object->spec->template->metadata->annotations // {} )->{'comb.internal/restartedAt'};
    like $at, qr/\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ\z/, $kind.': restartedAt as RFC 3339';
  }
  ok !$k8s->object( 'Job', 'nats-init', namespace => 'platform' ), 'the Job is deleted';
  ok $k8s->object( 'CronJob', 'nats-backup', namespace => 'platform' ), 'the CronJob stays';
  ok !$k8s->object( 'Deployment', 'other', namespace => 'platform' )->spec->template->metadata->annotations,
    'another Comb\'s Deployment is untouched';
  is_deeply [ map { +{ @{$_}[ 1 .. $#$_ ] }->{type} } $k8s->calls_of('patch') ], [ ('merge') x 3 ], 'merge patches';
  is_deeply [ map { [ $_->[0]->metadata->name, @{$_}[ 1 .. $#$_ ] ] } $k8s->calls_of('delete') ],
    [ [ 'nats-init', propagationPolicy => 'Background' ] ],
    'the Job is deleted with its Pods: propagationPolicy Background';
  ok $k8s->object( 'Deployment', 'nats', namespace => 'platform' )->spec->template->spec->containers,
    'the rest of the pod template is kept';
};

subtest 'stop' => sub {
  my ( $comb, $k8s ) = deployed();
  my @touched = $comb->stop->get;
  is_deeply \@touched,
    [ 'Deployment/nats', 'StatefulSet/nats-store', 'CronJob/nats-backup', 'Job/nats-init' ],
    'Future of what it touched';
  is $k8s->object( 'Deployment', 'nats', namespace => 'platform' )->spec->replicas, 0, 'Deployment at 0';
  is $k8s->object( 'StatefulSet', 'nats-store', namespace => 'platform' )->spec->replicas, 0, 'StatefulSet at 0';
  ok $k8s->object( 'CronJob', 'nats-backup', namespace => 'platform' )->spec->suspend, 'CronJob suspended';
  ok !$k8s->object( 'Job', 'nats-init', namespace => 'platform' ), 'Job deleted';
  is_deeply [ map { [ $_->[0]->metadata->name, @{$_}[ 1 .. $#$_ ] ] } $k8s->calls_of('delete') ],
    [ [ 'nats-init', propagationPolicy => 'Background' ] ],
    '... with its Pods: propagationPolicy Background';
  ok !$k8s->object( 'DaemonSet', 'nats-agent', namespace => 'platform' )->spec->template->metadata->annotations,
    'the DaemonSet is left alone';
  is $k8s->object( 'Deployment', 'other', namespace => 'platform' )->spec->replicas, undef,
    'another Comb\'s Deployment is untouched';
};

subtest 'restart and stop fail their Future, never throw' => sub {
  my ( $comb, $k8s ) = deployed();
  $k8s->fail_on( delete => 'Kubernetes API error (delete Job): 403 forbidden' );
  my $f = $comb->stop;
  ok $f->is_failed, 'failed delete';
  like $f->failure, qr/403 forbidden/, 'error passed on';
  $k8s->clear_failures->fail_on( list => 'connection refused' );
  ok $comb->restart->is_failed, 'failed list';
};

subtest 'logs' => sub {
  my $k8s = Kubernetes::Comb::Client::Fake->new;
  my $comb = TestComb::NATS->new( k8s => $k8s, namespace => 'platform', crd => comb_cr( name => 'nats', class => 'TestComb::NATS' ) );
  is $comb->logs->get, '', 'no pods, no logs';

  $k8s->add( pod( 'nats-a', containers => [ { name => 'nats', ready => 1, state => { running => {} } } ] ) );
  $k8s->set_log( name => 'nats-a', namespace => 'platform', container => 'nats', text => join '', map { "line $_\n" } 1 .. 5 );
  is $comb->logs( lines => 2 )->get, "line 4\nline 5\n", 'one container: the text alone, tailed';
  my ( $call ) = $k8s->calls_of('log');
  is_deeply $call, [ 'v1/Pod', 'nats-a', namespace => 'platform', container => 'nats', tailLines => 2 ], 'the request';
  $k8s->clear_calls;
  $comb->logs->get;
  my %args = @{ ( $k8s->calls_of('log') )[0] }[ 2 .. 7 ];
  is $args{tailLines}, 100, 'default 100 lines';

  $k8s->add( pod( 'nats-b', containers => [
    { name => 'nats',    ready => 0, restartCount => 4, state => { waiting => { reason => 'CrashLoopBackOff' } } },
    { name => 'sidecar', ready => 1, state => { running => {} } }
  ] ) );
  $k8s->set_log( name => 'nats-b', namespace => 'platform', container => 'nats', previous => 1, text => "panic: boom" );
  $k8s->set_log( name => 'nats-b', namespace => 'platform', container => 'sidecar', text => "ok\n" );
  is $comb->logs->get, join( '',
    "==> nats-a <==\n", "line 1\nline 2\nline 3\nline 4\nline 5\n",
    "\n",
    "==> nats-b/nats (previous) <==\n", "panic: boom\n",
    "\n",
    "==> nats-b/sidecar <==\n", "ok\n"
  ), 'several: headers, the crash-looping container from its previous instance';

  $k8s->clear_calls->fail_on( log => 'Kubernetes API error (log Pod): 400 container is starting', when => sub { $_[1] eq 'nats-a' } );
  my $text = $comb->logs->get;
  like $text, qr/==> nats-a <==\n\(no log: Kubernetes API error \(log Pod\): 400 container is starting\)\n/,
    'an unreadable log is shown, not fatal';
  like $text, qr/==> nats-b\/sidecar <==\nok\n/, 'the others still come';

  $k8s->clear_failures->fail_on( list => 'connection refused' );
  ok $comb->logs->is_failed, 'no pods to ask: failed Future';
};

subtest 'endpoint' => sub {
  my ( $comb ) = deployed();
  my $client = $comb->endpoint('client')->get;
  isa_ok $client, 'Kubernetes::Comb::Endpoint';
  is $client->cluster, 'nats.platform.svc:4222', 'cluster address: comb name, namespace, port';
  is $client->protocol, 'tcp', 'protocol default';
  ok !$client->has_external, 'no external address declared';

  my $monitor = $comb->endpoint('monitor')->get;
  is $monitor->cluster, 'nats-monitor.platform.svc:8222', 'service overridden per endpoint';
  is $monitor->protocol, 'http', 'protocol declared';

  my $leaf = $comb->endpoint('leaf')->get;
  is $leaf->cluster, 'nats.platform.svc:7422', 'an Endpoint object gets its cluster address';
  is $leaf->external, 'leaf.example.com:7422', 'and keeps its external one';

  my $missing = $comb->endpoint('nope');
  ok $missing->is_failed, 'unknown name: failed Future';
  like $missing->failure, qr/nats has no endpoint nope \(it has: client, monitor, leaf\)/, 'naming what there is';
  ok $comb->endpoint->is_failed, 'no name: failed Future';

  my $broken = TestComb::Broken->new( namespace => 'platform' )->endpoint('x');
  like $broken->failure, qr/unknown key\(s\) sevice/, 'a typo in a declaration fails';
};

subtest 'describe' => sub {
  my ( $comb, $k8s ) = deployed();
  my $describe = $comb->describe->get;
  is $describe->{name}, 'nats', 'name';
  is $describe->{class}, 'TestComb::NATS', 'class';
  is $describe->{namespace}, 'platform', 'namespace';
  is_deeply $describe->{depends_on}, [ 'db' ], 'depends_on';
  is_deeply $describe->{endpoints}[0],
    { name => 'client', protocol => 'tcp', port => 4222, cluster => 'nats.platform.svc:4222' }, 'endpoints as data';
  is scalar @{ $describe->{endpoints} }, 3, 'all of them';
  is $describe->{status}{phase}, 'Pending', 'the live status';
  ok !exists $describe->{recorded}, 'nothing recorded';
  ok !exists $describe->{stub_of}, 'no stub';

  $comb->_memory_status( Kubernetes::Comb::CRD::CombStatus->new( phase => 'Pending' ) );
  ok !exists $comb->describe->get->{recorded}, 'with a CR the CR status is the recorded one';
  my $plain = TestComb::NATS->new( k8s => $k8s, namespace => 'platform' );
  $plain->_memory_status( Kubernetes::Comb::CRD::CombStatus->new( phase => 'Running' ) );
  is $plain->recorded_status->phase, 'Running', 'without a CR the memory status is';
  is $plain->describe->get->{recorded}{phase}, 'Running', 'and describe shows it';

  $k8s->fail_on( list => 'connection refused' );
  ok $comb->describe->is_failed, 'a failed status fails describe';
};

subtest 'recorded status from the custom resource' => sub {
  my $cr = comb_cr( name => 'nats', class => 'TestComb::NATS' );
  $cr->status( { phase => 'Running', managedResources => [ { apiVersion => 'v1', kind => 'Service', name => 'nats', namespace => 'platform' } ] } );
  my $comb = TestComb::NATS->new( crd => $cr );
  isa_ok $comb->recorded_status, 'Kubernetes::Comb::CRD::CombStatus';
  is $comb->recorded_status->phase, 'Running', 'crd->status';
  is $comb->recorded_status->managedResources->[0]->name, 'nats', 'managedResources reachable';
};

done_testing;
