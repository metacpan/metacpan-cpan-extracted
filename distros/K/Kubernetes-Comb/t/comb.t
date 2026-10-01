use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Kubernetes::Comb;
use Kubernetes::Comb::Client::Fake;
use TestComb::Fixtures qw( comb_cr );

{
  package TestComb::Plain;
  use Moo;
  extends 'Kubernetes::Comb';
}

{
  package TestComb::Named;
  use Moo;
  extends 'Kubernetes::Comb';
  sub name       { 'named' }
  sub depends_on { 'db', 'other/cache' }
}

{
  package TestComb::WithUpstream;
  use Moo;
  extends 'Kubernetes::Comb';
  sub upstream { return }
}

{
  package MyApp::CRD::Comb;
  use Moo;
  extends 'Kubernetes::Comb::CRD::Comb';
  sub api_version { 'comb.example.com/v1' }
}

{
  package TestComb::Called;
  use Moo;
  extends 'Kubernetes::Comb';
  has given => ( is => 'ro' );
  sub name { $_[0]->given }
}

{
  package TestComb::BadPort;
  use Moo;
  extends 'Kubernetes::Comb';
  sub name      { 'badport' }
  sub endpoints { { name => 'client', port => 4222 }, { name => 'Web_UI', port => 80 } }
}

my $fake = Kubernetes::Comb::Client::Fake->new;

subtest 'defaults without a custom resource' => sub {
  my $comb = TestComb::Named->new( namespace => 'platform', k8s => $fake );
  is $comb->name, 'named', 'name from the class';
  is $comb->namespace, 'platform', 'namespace from the attribute';
  is_deeply [ $comb->depends_on ], [ 'db', 'other/cache' ], 'depends_on from the class';
  is_deeply $comb->config, {}, 'config defaults to empty';
  is_deeply [ $comb->endpoints ], [], 'no endpoints';
  is_deeply [ $comb->manifests ], [], 'no manifests';
  is_deeply [ $comb->check ], [], 'nothing missing';
  is_deeply [ $comb->bridge_manifests->get ], [], 'no endpoints, no bridge';
  is $comb->crd_class, 'Kubernetes::Comb::CRD::Comb', 'default crd_class';
  ok !$comb->has_crd, 'no crd';
  ok !$comb->has_resolver, 'no resolver';
  ok !$comb->is_stub, 'not a stub';
  is $comb->recorded_status, undef, 'nothing recorded yet';
  is $comb->label_prefix, 'comb.internal/', 'default label prefix';
  is $comb->comb_label, 'comb.internal/comb', 'name label key';
  is $comb->restart_annotation, 'comb.internal/restartedAt', 'restart annotation key';
  is $comb->comb_namespace_label, 'comb.internal/comb-namespace', 'owner namespace label key';
  is_deeply $comb->comb_labels, {
    'comb.internal/comb'           => 'named',
    'comb.internal/comb-namespace' => 'platform',
    'app.kubernetes.io/managed-by' => 'kubernetes-comb'
  }, 'identifying labels';
  is $comb->label_selector, 'comb.internal/comb=named,comb.internal/comb-namespace=platform',
    'label selector: name and namespace';
  isa_ok $comb->io_k8s, 'IO::K8s';
};

subtest 'the default client' => sub {
  my $comb = TestComb::Named->new( namespace => 'platform' );
  isa_ok $comb->k8s, 'Kubernetes::Comb::Client::Sync';
  ok !eval { TestComb::Named->new( k8s => bless {}, 'Not::A::Client' ); 1 },
    'a client must do Kubernetes::Comb::Role::Client';
};

subtest 'defaults from the custom resource' => sub {
  my $cr = comb_cr(
    name  => 'nats',
    class => 'TestComb::Plain',
    spec  => { dependsOn => [ 'db' ], config => { size => 3 } }
  );
  my $comb = TestComb::Plain->new( crd => $cr, k8s => $fake );
  is $comb->name, 'nats', 'name from metadata.name';
  is $comb->namespace, 'platform', 'namespace from metadata.namespace';
  is_deeply [ $comb->depends_on ], [ 'db' ], 'depends_on from spec.dependsOn';
  is_deeply $comb->config, { size => 3 }, 'config from spec.config';
  $comb->config->{size} = 5;
  is $cr->spec->config->{size}, 3, 'config is a copy';
  is $comb->crd_class, 'Kubernetes::Comb::CRD::Comb', 'crd_class follows the crd';

  my $other = TestComb::Plain->new( crd => $cr, namespace => 'elsewhere', config => { a => 1 } );
  is $other->namespace, 'elsewhere', 'the namespace attribute wins';
  is_deeply $other->config, { a => 1 }, 'the config attribute wins';
};

subtest 'custom label prefix and managed-by' => sub {
  my $comb = TestComb::Named->new(
    namespace    => 'platform',
    label_prefix => 'example.com/',
    managed_by   => 'my-manager'
  );
  is_deeply $comb->comb_labels, {
    'example.com/comb'             => 'named',
    'example.com/comb-namespace'   => 'platform',
    'app.kubernetes.io/managed-by' => 'my-manager'
  }, 'labels follow the configuration';
  is $comb->restart_annotation, 'example.com/restartedAt', 'annotation too';
};

subtest 'crd_class for another API group' => sub {
  my $cr = MyApp::CRD::Comb->new(
    metadata => { name => 'nats', namespace => 'platform' },
    spec     => { class => 'TestComb::Plain' }
  );
  is( TestComb::Plain->new( crd => $cr )->crd_class, 'MyApp::CRD::Comb', 'taken from the crd' );
  ok eval { TestComb::Plain->new( crd => $cr, crd_class => 'MyApp::CRD::Comb' ); 1 }, 'a matching crd_class';
  my $plain = comb_cr( name => 'nats', class => 'TestComb::Plain' );
  ok !eval { TestComb::Plain->new( crd => $plain, crd_class => 'MyApp::CRD::Comb' ); 1 },
    'a crd of another class dies';
  like $@, qr/crd is a Kubernetes::Comb::CRD::Comb, not a MyApp::CRD::Comb/, 'naming both';
};

subtest 'missing name and namespace fail the operations, not construction' => sub {
  my $comb = TestComb::Plain->new( k8s => $fake );
  ok !eval { $comb->name; 1 }, 'name dies';
  like $@, qr/TestComb::Plain has no name/, 'saying so';
  my $f = $comb->endpoint('x');
  ok $f->is_failed, 'a lifecycle method fails its Future instead of throwing';
  like $f->failure, qr/has no name|has no namespace/, 'with the reason';

  my $named = TestComb::Named->new( k8s => $fake );
  my $d = $named->deploy;
  isa_ok $d, 'Future';
  ok $d->is_done, 'nothing to deploy needs no namespace';
  like( TestComb::Named->new( k8s => $fake )->describe->failure, qr/TestComb::Named has no namespace/,
    'describe names the missing namespace' );
};

subtest 'the name must be a label value' => sub {
  for my $name ( 'nats', 'a', 'Nats_2.b-c', 'x' x 63 ) {
    ok eval { TestComb::Called->new( given => $name ); 1 }, $name.' is fine' or diag $@;
  }
  for my $name ( 'x' x 64, 'nats!', '-nats', 'nats.', 'na ts' ) {
    ok !eval { TestComb::Called->new( given => $name ); 1 }, $name.' dies at construction';
    like $@, qr/\ATestComb::Called: the name '\Q$name\E' cannot be a label value/, '... naming it';
  }
  my $cr = comb_cr( name => 'n' x 64, class => 'TestComb::Plain' );
  ok !eval { Kubernetes::Comb->from_crd($cr); 1 }, 'a custom resource with a longer name';
  like $@, qr/the name 'n{64}' cannot be a label value/, '... is refused';
  ok eval { TestComb::Called->new; 1 }, 'no name yet: the operations fail, not construction';
};

subtest 'endpoint names are DNS-1123 labels' => sub {
  my $comb = TestComb::BadPort->new( namespace => 'platform', k8s => Kubernetes::Comb::Client::Fake->new );
  my $f = $comb->endpoint('client');
  ok $f->is_failed, 'a declaration with an invalid name fails the endpoints';
  like $f->failure, qr/TestComb::BadPort->endpoints: the name 'Web_UI' is not a DNS-1123 label/, '... naming it';
  my $status = $comb->reconcile->get;
  is $status->phase, 'Error', 'reconcile: Error';
  my ( $ready ) = grep { $_->type eq 'Ready' } @{ $status->conditions };
  like $ready->message, qr/'Web_UI' is not a DNS-1123 label/, '... saying why';
};

subtest 'the upstream argument' => sub {
  ok !Kubernetes::Comb->can('upstream'), 'the base class has no upstream method';
  ok( TestComb::WithUpstream->can('upstream'), 'a class may define one' );

  my $none = TestComb::Named->new;
  ok !$none->_has_upstream, 'not given';
  for my $given (
    [ coderef => sub { return } ],
    [ object  => bless( {}, 'Some::Upstream' ) ],
    [ hashref => { class => 'Kubernetes::Comb::Upstream::K8s', context => 'dev' } ],
    [ arrayref => [ K8s => ( context => 'dev' ) ] ],
    [ undef   => undef ]
  ) {
    my ( $what, $value ) = @$given;
    my $comb = TestComb::Named->new( upstream => $value );
    ok $comb->_has_upstream, $what.' is taken';
    is $comb->_upstream, $value, $what.' is kept as given';
  }
  ok !eval { TestComb::Named->new( upstream => 'K8s' ); 1 }, 'a plain string is refused';

  my $with = TestComb::WithUpstream->new( upstream => sub { return } );
  is ref( $with->can('upstream') ), 'CODE', 'the class method stays reachable next to the argument';
};

subtest 'resolver' => sub {
  my $resolver = sub { undef };
  my $comb = TestComb::Named->new( resolver => $resolver );
  ok $comb->has_resolver, 'given';
  is $comb->resolver, $resolver, 'kept';
  ok !eval { TestComb::Named->new( resolver => 'nope' ); 1 }, 'must be a coderef';
};

done_testing;
