use strict;
use warnings;
use Test::More;

use lib 't/lib';
use TestComb::AsyncClient qw( async_client_refusal );

# Skipped where the async client refuses to load: an optional dependency is
# missing or too old.
BEGIN {
  my $refusal = async_client_refusal;
  plan skip_all => $refusal if defined $refusal;
}

use Path::Tiny qw( tempdir );
use Kubernetes::Comb::Client::Async;

my $dir = tempdir;
my $kubeconfig = $dir->child('config');
$kubeconfig->spew_utf8(<<'YAML');
apiVersion: v1
kind: Config
current-context: dev
clusters:
  - name: dev
    cluster: { server: 'https://dev.example:6443' }
  - name: prod
    cluster: { server: 'https://prod.example:6443' }
users:
  - name: me
    user: { token: not-a-real-token }
contexts:
  - name: dev
    context: { cluster: dev, user: me }
  - name: prod
    context: { cluster: prod, user: me }
YAML

my $loop = IO::Async::Loop->new;

subtest 'built from kubeconfig and context' => sub {
  my $k8s = Kubernetes::Comb::Client::Async->new( loop => $loop, kubeconfig => "$kubeconfig" );
  ok $k8s->DOES('Kubernetes::Comb::Role::Client'), 'consumes Kubernetes::Comb::Role::Client';
  is $k8s->server_url, 'https://dev.example:6443', 'current context';
  isa_ok $k8s->kube, 'Net::Async::Kubernetes';
  is $k8s->kube->loop, $loop, 'added to the loop';
  is $k8s->kube->expand_class('Comb'), 'Kubernetes::Comb::CRD::Comb',
    'the Comb Kind is in its resource map';

  my $prod = $k8s->for_context('prod');
  isa_ok $prod, 'Kubernetes::Comb::Client::Async';
  is $prod->loop, $loop, 'same loop';
  is $prod->server_url, 'https://prod.example:6443', 'other context, other server';
  is $k8s->for_context('prod'), $prod, 'asking again gives the same client, no second notifier';
};

subtest 'nothing is thrown' => sub {
  my $k8s = Kubernetes::Comb::Client::Async->new( loop => $loop, kubeconfig => "$kubeconfig" );
  my $f = eval { $k8s->update('not an object') };
  ok $f, 'a croak of Net::Async::Kubernetes is not thrown';
  ok $f->is_failed, 'it fails the Future';

  $f = eval { $k8s->ensure('not an object') };
  ok $f && $f->is_failed, 'same for ensure';

  $f = eval { $k8s->get('Bogus', 'x') };
  ok $f && $f->is_failed, 'an unknown Kind fails the Future';

  my $gone = $k8s->for_context('nope');
  $f = eval { $gone->get( 'Pod', 'x', namespace => 'platform' ) };
  ok $f && $f->is_failed, 'an unknown context fails the request';
  like $f->failure, qr/Context not found: nope/, '... naming the context';
};

# Net::Async::Kubernetes whose delete records its arguments instead of
# sending anything.
{
  package Local::Kube;
  our @ISA = ('Net::Async::Kubernetes');
  our @deletes;
  sub delete { my ( $self, @args ) = @_; push @deletes, \@args; Future->done(1) }
}

subtest 'delete passes propagationPolicy on' => sub {
  my $kube = Local::Kube->new(
    server      => { endpoint => 'https://mine.example:6443' },
    credentials => { token => 'x' }
  );
  $loop->add($kube);
  my $k8s = Kubernetes::Comb::Client::Async->new( kube => $kube );
  is $k8s->delete( 'Job', 'nats-init', namespace => 'platform', propagationPolicy => 'Background' )->get, 1,
    'resolves to 1';
  is_deeply \@Local::Kube::deletes, [ [ 'Job', 'nats-init', namespace => 'platform', propagationPolicy => 'Background' ] ],
    'the arguments reach Net::Async::Kubernetes as given';
  $loop->remove($kube);

  # A real one checks the value before it sends anything.
  $k8s = Kubernetes::Comb::Client::Async->new( loop => $loop, kubeconfig => "$kubeconfig" );
  my $f = eval { $k8s->delete( 'Job', 'nats-init', namespace => 'platform', propagationPolicy => 'Backgroud' ) };
  ok $f && $f->is_failed, 'an unknown value fails the Future';
  like $f->failure, qr/Unknown propagationPolicy 'Backgroud'/, '... naming it: the option reaches Net::Async::Kubernetes';
};

subtest 'a ready Net::Async::Kubernetes' => sub {
  my $kube = Net::Async::Kubernetes->new(
    server      => { endpoint => 'https://mine.example:6443' },
    credentials => { token => 'x' }
  );
  $loop->add($kube);
  my $k8s = Kubernetes::Comb::Client::Async->new( kube => $kube );
  is $k8s->server_url, 'https://mine.example:6443', 'its server';
  is $k8s->loop, $loop, 'the loop defaults to the one it is in';
  $loop->remove($kube);
};

done_testing;
