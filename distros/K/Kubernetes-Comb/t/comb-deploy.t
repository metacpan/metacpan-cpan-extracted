use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Future;
use IO::K8s;
use Kubernetes::Comb;
use Kubernetes::Comb::Client::Fake;
use Scalar::Util qw( blessed );
use TestComb::Fixtures qw( comb_labels );

my $io = IO::K8s->new;

# The manifests a test wants, handed out by the class.
our @MANIFESTS;

{
  package TestComb::Parts;
  use Moo;
  extends 'Kubernetes::Comb';
  sub name      { 'parts' }
  sub manifests { @main::MANIFESTS }
}

sub deployment {
  my ( $name, %extra ) = @_;
  return {
    apiVersion => 'apps/v1',
    kind       => 'Deployment',
    metadata   => { name => $name, labels => { app => $name }, %{ $extra{metadata} // {} } },
    spec       => {
      selector => { matchLabels => { app => $name } },
      template => {
        metadata => { labels => { app => $name } },
        spec     => { containers => [ { name => 'main', image => 'img' } ] }
      }
    }
  };
}

sub comb {
  my ( %args ) = @_;
  my $k8s = Kubernetes::Comb::Client::Fake->new;
  return ( TestComb::Parts->new( k8s => $k8s, namespace => 'platform', %args ), $k8s );
}

my %labels = comb_labels('parts');

subtest 'labels on hashrefs, pod templates included' => sub {
  my $manifest = deployment('web');
  local @MANIFESTS = ( $manifest );
  my ( $comb, $k8s ) = comb();
  my @stored = $comb->deploy->get;
  is scalar @stored, 1, 'one object stored';
  isa_ok $stored[0], 'IO::K8s::Api::Apps::V1::Deployment';

  my ( $sent ) = map { $_->[0] } $k8s->calls_of('ensure');
  is ref $sent, 'HASH', 'a hashref goes to the client as a hashref';
  is_deeply $sent->{metadata}{labels}, { app => 'web', %labels }, 'the object carries the Comb labels';
  is_deeply $sent->{spec}{template}{metadata}{labels}, { app => 'web', %labels },
    'so does its pod template';
  is_deeply $sent->{spec}{selector}{matchLabels}, { app => 'web' }, 'the selector is untouched';
  is $sent->{metadata}{namespace}, 'platform', 'namespace defaulted';

  is_deeply $manifest, deployment('web'), 'the manifest of the class is not changed';
};

subtest 'labels on IO::K8s objects' => sub {
  my $object = $io->new_object( Deployment => deployment('api') );
  my $before = $object->TO_JSON;
  local @MANIFESTS = ( $object );
  my ( $comb, $k8s ) = comb();
  $comb->deploy->get;

  my ( $sent ) = map { $_->[0] } $k8s->calls_of('ensure');
  isa_ok $sent, 'IO::K8s::Api::Apps::V1::Deployment', 'an object goes as an object';
  is_deeply $sent->metadata->labels, { app => 'api', %labels }, 'labelled';
  is_deeply $sent->spec->template->metadata->labels, { app => 'api', %labels }, 'pod template labelled';
  is $sent->metadata->namespace, 'platform', 'namespace defaulted';
  is_deeply $object->TO_JSON, $before, 'the object of the class is not changed';
};

subtest 'a CronJob labels its jobs and their pods' => sub {
  local @MANIFESTS = ( {
    apiVersion => 'batch/v1',
    kind       => 'CronJob',
    metadata   => { name => 'backup' },
    spec       => {
      schedule    => '0 3 * * *',
      jobTemplate => {
        spec => { template => { spec => {
          restartPolicy => 'OnFailure',
          containers    => [ { name => 'backup', image => 'img' } ]
        } } }
      }
    }
  } );
  my ( $comb, $k8s ) = comb();
  $comb->deploy->get;
  my ( $sent ) = map { $_->[0] } $k8s->calls_of('ensure');
  is_deeply $sent->{metadata}{labels}, \%labels, 'the CronJob';
  is_deeply $sent->{spec}{jobTemplate}{metadata}{labels}, \%labels, 'its Jobs';
  is_deeply $sent->{spec}{jobTemplate}{spec}{template}{metadata}{labels}, \%labels, 'their Pods';
};

subtest 'our labels win over the manifest' => sub {
  local @MANIFESTS = ( deployment( 'web', metadata => { labels => {
    'comb.internal/comb'           => 'someone-else',
    'app.kubernetes.io/managed-by' => 'helm'
  } } ) );
  my ( $comb, $k8s ) = comb();
  $comb->deploy->get;
  my ( $sent ) = map { $_->[0] } $k8s->calls_of('ensure');
  is_deeply $sent->{metadata}{labels}, \%labels, 'identity labels are the Comb\'s';
};

subtest 'namespace defaulting' => sub {
  local @MANIFESTS = (
    { apiVersion => 'v1', kind => 'ConfigMap', metadata => { name => 'mine' } },
    { apiVersion => 'v1', kind => 'ConfigMap', metadata => { name => 'theirs', namespace => 'shared' } },
    { apiVersion => 'v1', kind => 'Namespace', metadata => { name => 'extra' } },
    { apiVersion => 'rbac.authorization.k8s.io/v1', kind => 'ClusterRole', metadata => { name => 'reader' } },
    $io->new_object( ClusterRoleBinding => { metadata => { name => 'reader' }, roleRef => {
      apiGroup => 'rbac.authorization.k8s.io', kind => 'ClusterRole', name => 'reader'
    } } ),
    { apiVersion => 'example.com/v1', kind => 'Widget', metadata => { name => 'w' } },
    { kind => 'Service', metadata => { name => 'svc' } }
  );
  my ( $comb, $k8s ) = comb();
  my @items = $comb->_items(@MANIFESTS);
  my %ns = map { ( $_->{kind}.'/'.$_->{name} => $_->{namespace} ) } @items;
  is $ns{'ConfigMap/mine'}, 'platform', 'a namespaced resource gets the Comb namespace';
  is $ns{'ConfigMap/theirs'}, 'shared', 'an explicit namespace stays';
  ok !defined $ns{'Namespace/extra'}, 'a Namespace is cluster-scoped: untouched';
  ok !defined $ns{'ClusterRole/reader'}, 'a ClusterRole hashref: untouched';
  ok !defined $ns{'ClusterRoleBinding/reader'}, 'a cluster-scoped object: untouched';
  ok !exists $items[4]{manifest}->TO_JSON->{metadata}{namespace}, 'and it has no namespace set';
  is $ns{'Widget/w'}, 'platform', 'a Kind IO::K8s does not know counts as namespaced';
  is $ns{'Service/svc'}, 'platform', 'a hashref without apiVersion is resolved';
  is $items[6]{apiVersion}, 'v1', 'and gets its apiVersion';
  is_deeply $items[2]{manifest}{metadata}{labels}, \%labels, 'cluster-scoped resources are labelled too';
};

subtest 'the item record' => sub {
  local @MANIFESTS = ( deployment('web'), $io->new_object( Service => { metadata => { name => 'web' } } ) );
  my ( $comb ) = comb();
  my ( $deployment, $service ) = $comb->_items(@MANIFESTS);
  is $deployment->{resource}, 'apps/v1/Deployment', 'hashref: resource by apiVersion/Kind';
  is $deployment->{group}, 'apps', 'group';
  ok $deployment->{workload}, 'a Deployment is a workload';
  is $service->{resource}, '+IO::K8s::Api::Core::V1::Service', 'object: resource by its class';
  is $service->{group}, '', 'core group';
  ok !$service->{workload}, 'a Service is not';
};

subtest 'deploys in order, one after the other' => sub {
  local @MANIFESTS = (
    { apiVersion => 'v1', kind => 'Namespace', metadata => { name => 'platform' } },
    { apiVersion => 'v1', kind => 'ConfigMap', metadata => { name => 'conf' } },
    deployment('web')
  );
  my ( $comb, $k8s ) = comb();
  my @stored = $comb->deploy->get;
  is_deeply [ map { $_->[0]{kind} } $k8s->calls_of('ensure') ], [qw( Namespace ConfigMap Deployment )],
    'manifest order';
  is_deeply [ map { ref } @stored ], [ map { 'IO::K8s::Api::'.$_ } qw( Core::V1::Namespace Core::V1::ConfigMap Apps::V1::Deployment ) ],
    'Future of the stored objects';
  ok $k8s->object( 'ConfigMap', 'conf', namespace => 'platform' ), 'stored in the fake';
};

subtest 'a failure stops the deploy and says what was applied' => sub {
  local @MANIFESTS = (
    { apiVersion => 'v1', kind => 'ConfigMap', metadata => { name => 'one' } },
    { apiVersion => 'v1', kind => 'ConfigMap', metadata => { name => 'two' } },
    { apiVersion => 'v1', kind => 'ConfigMap', metadata => { name => 'three' } }
  );
  my ( $comb, $k8s ) = comb();
  $k8s->fail_on( ensure => 'Kubernetes API error (create ConfigMap): 403 forbidden',
    when => sub { $_[0]{metadata}{name} eq 'two' } );
  my $f = $comb->deploy;
  ok $f->is_failed, 'failed Future, nothing thrown';
  my ( $message, $category, $details ) = $f->failure;
  like $message, qr/\Aensure ConfigMap two: Kubernetes API error \(create ConfigMap\): 403 forbidden/,
    'names the resource and passes the error on';
  is $category, 'deploy', 'category';
  is_deeply [ map { $_->metadata->name } @{ $details->{applied} } ], ['one'], 'what was applied';
  is $details->{failed}{metadata}{name}, 'two', 'what failed';
  is scalar $k8s->calls_of('ensure'), 2, 'three was never tried';
};

subtest 'errors in the class become failed Futures' => sub {
  {
    no warnings 'once';
    local *TestComb::Parts::manifests = sub { die "no manifests today\n" };
    my ( $comb ) = comb();
    my $f = $comb->deploy;
    ok $f->is_failed, 'manifests dies';
    is $f->failure, "no manifests today\n", 'the error is the failure';
  }
  for my $bad (
    [ 'a plain string'  => 'Deployment',                       qr/is an IO::K8s object or a hashref, got a plain scalar/ ],
    [ 'no kind'         => { metadata => { name => 'x' } },    qr/a manifest has no kind/ ],
    [ 'no name'         => { apiVersion => 'v1', kind => 'ConfigMap' }, qr/manifest ConfigMap has no metadata.name/ ],
    [ 'unknown, no apiVersion' => { kind => 'Widget', metadata => { name => 'w' } }, qr/manifest Widget has no apiVersion/ ]
  ) {
    my ( $what, $manifest, $error ) = @$bad;
    local @MANIFESTS = ( $manifest );
    my ( $comb ) = comb();
    my $f = $comb->deploy;
    ok $f->is_failed, $what.' fails';
    like scalar $f->failure, $error, $what.': says why';
  }
};

subtest 'a restart stays: the live restart annotation is kept' => sub {
  my $store = $io->new_object( StatefulSet => {
    metadata => { name => 'store' },
    spec     => { serviceName => 'store', %{ deployment('store')->{spec} } }
  } );
  local @MANIFESTS = ( deployment('web'), $store, { %{ deployment('agent') }, kind => 'DaemonSet' } );
  my ( $comb, $k8s ) = comb();
  $comb->deploy->get;
  my @restarted = $comb->restart->get;
  is scalar @restarted, 3, 'restarted';
  my %at = map {
    my $template = $_->TO_JSON->{spec}{template};
    ( $_->kind.'/'.$_->metadata->name => $template->{metadata}{annotations}{'comb.internal/restartedAt'} );
  } map { $k8s->objects_of( $_, namespace => 'platform' ) } qw( Deployment StatefulSet DaemonSet );
  ok defined $at{$_}, $_.' carries the annotation' for sort keys %at;

  push @MANIFESTS, deployment('fresh');   # new since the restart
  $k8s->clear_calls;
  $comb->deploy->get;
  my %sent = map {
    my $sent = blessed $_->[0] ? $_->[0]->TO_JSON : $_->[0];
    ( $sent->{kind}.'/'.$sent->{metadata}{name} => $sent );
  } $k8s->calls_of('ensure');
  for my $what ( sort keys %at ) {
    my $template = $sent{$what}{spec}{template}{metadata};
    is $template->{annotations}{'comb.internal/restartedAt'}, $at{$what}, $what.': the applied manifest keeps it';
    is_deeply $template->{labels}, { app => ( split m{/}, $what )[1], %labels }, $what.': labelled as ever';
  }
  ok !exists $sent{'Deployment/fresh'}{spec}{template}{metadata}{annotations}, 'none where there is no live one';
  ok blessed( ( grep { blessed $_->[0] } $k8s->calls_of('ensure') )[0][0] ), 'an IO::K8s manifest stays an object';
  is $k8s->object( Deployment => 'web', namespace => 'platform' )->TO_JSON->{spec}{template}{metadata}{annotations}
    {'comb.internal/restartedAt'}, $at{'Deployment/web'}, 'the restart stands';
  is_deeply [ sort map { $_->[0] } $k8s->calls_of('list') ],
    [ '+IO::K8s::Api::Apps::V1::StatefulSet', 'apps/v1/DaemonSet', 'apps/v1/Deployment' ], 'one list per kind';
  is_deeply [ map { $_->[4] } $k8s->calls_of('list') ], [ ('comb.internal/comb=parts') x 3 ], '... by the Comb label';
  ok !exists $MANIFESTS[0]{spec}{template}{metadata}{annotations}, 'what the class returned is left as it was';
};

subtest 'a restart annotation that cannot be read: deploy fails, nothing applied' => sub {
  local @MANIFESTS = ( deployment('web') );
  my ( $comb, $k8s ) = comb();
  $k8s->fail_on( list => 'connection refused' );
  my $f = $comb->deploy;
  ok $f->is_failed, 'failed Future';
  my ( $message, $category, $details ) = $f->failure;
  like $message, qr/\Areading the live workloads failed: connection refused/, 'says so';
  is $category, 'deploy', 'category deploy';
  is_deeply $details->{applied}, [], 'nothing applied';
  ok !$k8s->calls_of('ensure'), 'nothing tried';
};

subtest 'manifests may return a Future' => sub {
  no warnings 'once';
  local *TestComb::Parts::manifests = sub {
    Future->done( { apiVersion => 'v1', kind => 'ConfigMap', metadata => { name => 'later' } } );
  };
  my ( $comb, $k8s ) = comb();
  my @stored = $comb->deploy->get;
  is $stored[0]->metadata->name, 'later', 'the list inside the Future is deployed';
};

done_testing;
