use strict;
use warnings;
use Test::More;

use lib 't/lib';
use JSON::MaybeXS ();
use Kubernetes::Comb::Client::Fake;

sub pod {
  my ( $name, %args ) = @_;
  return {
    apiVersion => 'v1',
    kind       => 'Pod',
    metadata   => {
      name      => $name,
      namespace => $args{namespace} // 'platform',
      ( $args{labels} ? ( labels => $args{labels} ) : () )
    },
    ( $args{phase} ? ( status => { phase => $args{phase} } ) : () )
  };
}

sub comb_cr {
  my ( %status ) = @_;
  return {
    apiVersion => 'comb.internal/v1',
    kind       => 'Comb',
    metadata   => { name => 'nats', namespace => 'platform' },
    spec       => { class => 'MyApp::Comb::NATS', upstream => undef },
    ( %status ? ( status => \%status ) : () )
  };
}

sub fake { Kubernetes::Comb::Client::Fake->new(@_) }

subtest 'same surface as the real clients' => sub {
  my $k8s = fake();
  ok $k8s->DOES('Kubernetes::Comb::Role::Client'), 'consumes Kubernetes::Comb::Role::Client';
  my $f = $k8s->list('Pod');
  isa_ok $f, 'Future';
  ok $f->is_done, 'results are already done';
  ok $k8s->get( 'Pod', 'nope' )->is_failed, 'failures are already failed, not thrown';
};

subtest 'canned objects, get and list' => sub {
  my $k8s = fake( objects => [
    pod( 'nats-0', labels => { app => 'nats', tier => 'mq' }, phase => 'Running' ),
    pod( 'nats-1', labels => { app => 'nats' } ),
    pod( 'db-0',   labels => { app => 'db' } ),
    pod( 'other',  namespace => 'dev', labels => { app => 'nats' } ),
    comb_cr( phase => 'Pending' )
  ] );

  my $pod = $k8s->get( 'Pod', 'nats-0', namespace => 'platform' )->get;
  isa_ok $pod, 'IO::K8s::Api::Core::V1::Pod';
  is $pod->status->phase, 'Running', 'canned status is there';
  $pod->status->phase('Failed');
  is $k8s->object( 'Pod', 'nats-0', namespace => 'platform' )->status->phase, 'Running',
    'handed-out objects are copies';

  my $cr = $k8s->get( '+Kubernetes::Comb::CRD::Comb', 'nats', namespace => 'platform' )->get;
  isa_ok $cr, 'Kubernetes::Comb::CRD::Comb';
  ok $cr->spec->has_upstream, 'the CR keeps an explicit null upstream';
  is $k8s->get( Comb => name => 'nats', namespace => 'platform' )->get->status->phase,
    'Pending', 'the Kind and the keyed call form resolve too';

  my $missing = $k8s->get( 'Pod', 'nats-9', namespace => 'platform' );
  ok $missing->is_failed, 'missing object fails';
  like $missing->failure, qr/\AKubernetes API error \(get Pod\): 404 /, 'like the real client';
  like $missing->failure, qr/at \Q${\ __FILE__ }\E line/, 'and names the caller';

  my $names = sub { [ map { $_->metadata->name } @{ $_[0]->get->items } ] };
  is_deeply $names->( $k8s->list( 'Pod', namespace => 'platform' ) ),
    [qw( db-0 nats-0 nats-1 )], 'list in one namespace';
  is_deeply $names->( $k8s->list('Pod') ), [qw( other db-0 nats-0 nats-1 )],
    'list across namespaces';
  isa_ok $k8s->list('Pod')->get, 'IO::K8s::List';

  my %selected = (
    'app=nats'          => [qw( nats-0 nats-1 )],
    'app==nats'         => [qw( nats-0 nats-1 )],
    'app=nats,tier=mq'  => [qw( nats-0 )],
    'app!=nats'         => [qw( db-0 )],
    'tier'              => [qw( nats-0 )],
    '!tier'             => [qw( db-0 nats-1 )],
    ' app = nats , !tier ' => [qw( nats-1 )]
  );
  for my $selector ( sort keys %selected ) {
    is_deeply $names->( $k8s->list( 'Pod', namespace => 'platform', labelSelector => $selector ) ),
      $selected{$selector}, 'labelSelector '.$selector;
  }

  ok $k8s->list( 'Pod', labelSelector => 'app in (nats)' )->is_failed,
    'set-based selectors are refused, not ignored';
  ok $k8s->list( 'Pod', fieldSelector => 'status.phase=Running' )->is_failed,
    'fieldSelector is refused, not ignored';
  ok $k8s->list('Bogus')->is_failed, 'unknown Kind fails';
};

subtest 'ensure' => sub {
  my $k8s = fake();
  my $created = $k8s->ensure({
    apiVersion => 'apps/v1',
    kind       => 'Deployment',
    metadata   => { name => 'nats', namespace => 'platform' },
    spec       => { replicas => 1, selector => { matchLabels => { app => 'nats' } },
                    template => { metadata => { labels => { app => 'nats' } },
                                  spec => { containers => [ { name => 'nats', image => 'nats:2' } ] } } }
  })->get;
  isa_ok $created, 'IO::K8s::Api::Apps::V1::Deployment';
  is $created->metadata->resourceVersion, '1', 'the write gets a resourceVersion';
  is $k8s->object( 'Deployment', 'nats', namespace => 'platform' )->spec->replicas, 1, 'stored';

  $created->spec->replicas(3);
  my $updated = $k8s->ensure($created)->get;
  is $updated->spec->replicas, 3, 'an existing object is updated';
  is $updated->metadata->resourceVersion, '2', 'with a new resourceVersion';

  my ( $args ) = ( $k8s->calls_of('ensure') )[1];
  $created->spec->replicas(7);
  is $args->[0]->spec->replicas, 3, 'the recorded argument is a copy from call time';

  $k8s->add( comb_cr( phase => 'Running' ) );
  my $cr = $k8s->object( 'Comb', 'nats', namespace => 'platform' );
  $cr->status->phase('Error');
  $k8s->ensure($cr)->get;
  is $k8s->object( 'Comb', 'nats', namespace => 'platform' )->status->phase, 'Running',
    'ensure does not write status (status subresource)';

  ok $k8s->ensure({ apiVersion => 'v1', metadata => { name => 'x' } })->is_failed,
    'a manifest without kind fails';
  ok $k8s->ensure({ apiVersion => 'v1', kind => 'ConfigMap', metadata => {} })->is_failed,
    'an object without a name fails';
};

subtest 'ensure leaves what the real clients leave' => sub {
  my $claim = sub { {
    apiVersion => 'v1',
    kind       => 'PersistentVolumeClaim',
    metadata   => { name => 'data', namespace => 'platform', annotations => { applied => $_[0] } },
    spec       => { accessModes => [ 'ReadWriteOnce' ], resources => { requests => { storage => $_[0] } } }
  } };
  my $job = sub { {
    apiVersion => 'batch/v1',
    kind       => 'Job',
    metadata   => { name => 'migrate', namespace => 'platform' },
    spec       => { template => { spec => {
      restartPolicy => 'Never',
      containers    => [ { name => 'migrate', image => $_[0] } ]
    } } },
    ( $_[1] ? ( status => $_[1] ) : () )
  } };
  my $image = sub { $_[0]->object( 'Job', 'migrate', namespace => 'platform' )->spec->template->spec->containers->[0]->image };

  my $k8s = fake();
  my $created = $k8s->ensure( $claim->('1Gi') )->get;
  my $again = $k8s->ensure( $claim->('2Gi') )->get;
  is $again->metadata->annotations->{applied}, '1Gi', 'an existing PersistentVolumeClaim is returned as it is';
  is $again->metadata->resourceVersion, $created->metadata->resourceVersion, 'and not written';
  is $k8s->object( 'PersistentVolumeClaim', 'data', namespace => 'platform' )->metadata->annotations->{applied},
    '1Gi', 'stored as it was';

  for my $kept ( [ 'runs' => { active => 1 } ], [ 'has succeeded' => { succeeded => 1 } ] ) {
    my ( $what, $status ) = @$kept;
    $k8s = fake( objects => [ $job->( 'img', $status ) ] );
    $k8s->ensure( $job->('img:2') )->get;
    is $image->($k8s), 'img', 'a Job that '.$what.' is left as it is';
  }

  for my $replaced ( [ 'failed' => { failed => 3 } ], [ 'has no status yet' => undef ] ) {
    my ( $what, $status ) = @$replaced;
    $k8s = fake( objects => [ $job->( 'img', $status ) ] );
    my $new = $k8s->ensure( $job->('img:2') )->get;
    is $image->($k8s), 'img:2', 'a Job that '.$what.' is replaced';
    ok !$new->status, '... and starts without a status';
  }
};

subtest 'update and patch keep the status' => sub {
  my $k8s = fake( objects => [ comb_cr( phase => 'Running' ) ] );
  my $cr = $k8s->object( 'Comb', 'nats', namespace => 'platform' );

  $cr->spec->dependsOn( ['db'] );
  $cr->status->phase('Error');
  my $updated = $k8s->update($cr)->get;
  is_deeply $updated->spec->dependsOn, ['db'], 'update replaces the spec';
  is $updated->status->phase, 'Running', 'but not the status';

  my $patched = $k8s->patch( 'Comb', 'nats',
    namespace => 'platform',
    patch     => { spec => { enabled => JSON::MaybeXS::false() }, status => { phase => 'Error' } },
    type      => 'merge'
  )->get;
  is $patched->spec->enabled, 0, 'patch merges into the spec';
  is_deeply $patched->spec->dependsOn, ['db'], 'and keeps the rest';
  is $patched->status->phase, 'Running', 'status in a main patch is ignored';

  my $by_object = $k8s->patch( $patched, patch => { spec => { dependsOn => undef } } )->get;
  ok !defined $by_object->spec->dependsOn, 'object form; null removes a field';

  ok $k8s->patch( $patched, patch => [ { op => 'remove', path => '/spec' } ], type => 'json' )->is_failed,
    'json patches are refused';
  ok $k8s->update( Kubernetes::Comb::CRD::Comb->new(
    metadata => { name => 'gone', namespace => 'platform' }, spec => { class => 'A' } ) )->is_failed,
    'update of a missing object fails';
};

subtest 'update_status and patch_status write only the status' => sub {
  my $k8s = fake( objects => [ comb_cr( phase => 'Pending' ) ] );
  my $cr = $k8s->object( 'Comb', 'nats', namespace => 'platform' );

  $cr->spec->class('Changed');
  $cr->status->phase('Running');
  my $updated = $k8s->update_status($cr)->get;
  is $updated->status->phase, 'Running', 'update_status replaces the status';
  is $updated->spec->class, 'MyApp::Comb::NATS', 'but not the spec';

  my $patched = $k8s->patch_status( $cr, patch => {
    status => { observedGeneration => 4, phase => undef },
    spec   => { class => 'Ignored' }
  } )->get;
  is $patched->status->observedGeneration, 4, 'patch_status merges into the status';
  ok !defined $patched->status->phase, 'null removes a status field';
  is $patched->spec->class, 'MyApp::Comb::NATS', 'the spec of a status patch is ignored';

  my $by_name = $k8s->patch_status( 'Comb', 'nats',
    namespace => 'platform', patch => { status => { phase => 'Blocked' } } )->get;
  is $by_name->status->phase, 'Blocked', 'name form';

  ok $k8s->update_status( Kubernetes::Comb::CRD::Comb->new(
    metadata => { name => 'gone', namespace => 'platform' }, spec => { class => 'A' } ) )->is_failed,
    'update_status of a missing object fails';
};

subtest 'delete' => sub {
  my $k8s = fake( objects => [ pod('a'), pod('b') ] );
  is $k8s->delete( 'Pod', 'a', namespace => 'platform' )->get, 1, 'resolves to 1';
  ok !$k8s->object( 'Pod', 'a', namespace => 'platform' ), 'gone';
  my $pod_b = $k8s->object( 'Pod', 'b', namespace => 'platform' );
  ok $k8s->delete($pod_b)->is_done, 'object form';
  my $again = $k8s->delete( 'Pod', 'a', namespace => 'platform' );
  like $again->failure, qr/\AKubernetes API error \(delete Pod\): 404 /, 'deleting a missing object fails';
};

subtest 'delete takes propagationPolicy, as the real clients do' => sub {
  my $k8s = fake( objects => [ pod('a'), pod('b'), pod('c') ] );
  ok $k8s->delete( 'Pod', 'a', namespace => 'platform', propagationPolicy => 'Background' )->is_done,
    'by name';
  ok $k8s->delete( $k8s->object( 'Pod', 'b', namespace => 'platform' ), propagationPolicy => 'Orphan' )->is_done,
    'object form';

  my $c = $k8s->object( 'Pod', 'c', namespace => 'platform' );
  like $k8s->delete( $c, propagationPolicy => 'Backgroud' )->failure,
    qr/\AUnknown propagationPolicy 'Backgroud' for delete\(\)/, 'an unknown value fails';
  like $k8s->delete( $c, propagation => 'Background' )->failure,
    qr/\AUnknown argument\(s\) to delete\(\): propagation /, 'so does an unknown option';
  like $k8s->delete( 'Pod', 'c', namespace => 'platform', dryRun => 'All' )->failure,
    qr/\AUnknown argument\(s\) to delete\(\): dryRun /, '... by name too';
  ok $k8s->object( 'Pod', 'c', namespace => 'platform' ), 'and nothing is deleted';
};

subtest 'log' => sub {
  my $k8s = fake();
  $k8s->set_log( name => 'nats-0', namespace => 'platform', text => "one\ntwo\nthree\n" );
  $k8s->set_log( name => 'nats-0', namespace => 'platform', previous => 1, text => "crashed\n" );
  $k8s->set_log( name => 'nats-0', namespace => 'platform', container => 'sidecar', text => "side\n" );

  is $k8s->log( 'Pod', 'nats-0', namespace => 'platform' )->get, "one\ntwo\nthree\n", 'current';
  is $k8s->log( 'Pod', 'nats-0', namespace => 'platform', previous => 1 )->get, "crashed\n",
    'previous container';
  is $k8s->log( 'Pod', 'nats-0', namespace => 'platform', container => 'sidecar' )->get, "side\n",
    'by container';
  is $k8s->log( 'Pod', 'nats-0', namespace => 'platform', tailLines => 2 )->get, "two\nthree\n",
    'tailLines';
  ok $k8s->log( 'Pod', 'nats-1', namespace => 'platform' )->is_failed, 'no canned log fails';
};

subtest 'fail_on' => sub {
  my $k8s = fake( objects => [ pod('a') ] );

  $k8s->fail_on( ensure => 'quota exceeded', times => 1 );
  my $failed = $k8s->ensure( pod('b') );
  is $failed->failure, 'quota exceeded', 'fails with the given message';
  ok !$k8s->object( 'Pod', 'b', namespace => 'platform' ), 'and does nothing';
  ok $k8s->ensure( pod('b') )->is_done, 'times => 1 fails once';

  $k8s->fail_on( get => 'forbidden', when => sub { $_[1] eq 'b' } );
  ok $k8s->get( 'Pod', 'b', namespace => 'platform' )->is_failed, 'when matches';
  ok $k8s->get( 'Pod', 'a', namespace => 'platform' )->is_done, 'when does not match';

  $k8s->fail_on( '*' => 'connection refused' );
  is $k8s->list('Pod')->failure, 'connection refused', 'wildcard';
  $k8s->clear_failures;
  ok $k8s->get( 'Pod', 'b', namespace => 'platform' )->is_done, 'clear_failures';

  ok !eval { $k8s->fail_on('get'); 1 }, 'fail_on needs a message';
};

subtest 'recorded calls' => sub {
  my $k8s = fake();
  $k8s->fail_on( delete => 'nope' );
  $k8s->list( 'Pod', namespace => 'platform' );
  $k8s->delete( 'Pod', 'x', namespace => 'platform', propagationPolicy => 'Background' );
  $k8s->get( 'Pod', 'x' );
  is_deeply [ map { $_->{method} } @{ $k8s->calls } ], [qw( list delete get )],
    'every call in order, failed ones included';
  is_deeply [ $k8s->calls_of('delete') ],
    [ [ 'Pod', 'x', namespace => 'platform', propagationPolicy => 'Background' ] ],
    'arguments as given';
  $k8s->clear_calls;
  is_deeply $k8s->calls, [], 'clear_calls';
};

subtest 'server_url and for_context' => sub {
  my $dev = fake( server_url => 'https://dev.example:6443' );
  my $k8s = fake( contexts => { dev => $dev } );
  is $k8s->server_url, 'https://fake.invalid:6443', 'default server_url';
  is $k8s->for_context('dev'), $dev, 'known context';
  is $k8s->for_context('dev')->server_url, 'https://dev.example:6443', 'with its own server';

  my $gone = $k8s->for_context('prod');
  isa_ok $gone, 'Kubernetes::Comb::Client::Fake';
  is $gone->get( 'Pod', 'x' )->failure, 'Context not found: prod', 'unknown context fails requests';
  ok !eval { $gone->server_url; 1 }, 'and server_url croaks';
  like $@, qr/Context not found: prod/, '... with the same reason';
};

done_testing;
