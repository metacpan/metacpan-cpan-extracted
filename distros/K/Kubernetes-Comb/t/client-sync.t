use strict;
use warnings;
use Test::More;

use JSON::MaybeXS qw( decode_json encode_json );
use Path::Tiny qw( tempdir );
use IO::K8s;
use Kubernetes::REST;
use Kubernetes::REST::HTTPResponse;
use Kubernetes::Comb::Client::Sync;
use Kubernetes::Comb::CRD::Comb;

# Kubernetes::REST's pluggable io: records the requests, answers from a queue.
{
  package Local::IO;

  sub new { bless { requests => [], responses => [] }, shift }

  sub respond {
    my ( $self, @responses ) = @_;
    push @{ $self->{responses} }, @responses;
    return $self;
  }

  sub call {
    my ( $self, $req ) = @_;
    push @{ $self->{requests} }, $req;
    my $res = shift @{ $self->{responses} }
      or die 'no canned response for '.$req->method.' '.$req->url."\n";
    my ( $status, $body ) = @$res;
    return Kubernetes::REST::HTTPResponse->new(
      status  => $status,
      content => ref $body ? JSON::MaybeXS::encode_json($body) : $body // ''
    );
  }

  sub requests { @{ $_[0]{requests} } }
  sub last_request { $_[0]{requests}[-1] }
}

my $server = 'https://k8s.test:6443';

sub client {
  my $io = Local::IO->new;
  my $rest = Kubernetes::REST->new(
    server                    => { endpoint => $server },
    credentials               => { token => 'secret' },
    io                        => $io,
    resource_map_from_cluster => 0,
    with                      => ['Kubernetes::Comb::CRD']
  );
  return ( Kubernetes::Comb::Client::Sync->new( rest => $rest ), $io );
}

my %pod = (
  apiVersion => 'v1',
  kind       => 'Pod',
  metadata   => { name => 'nats-0', namespace => 'platform', labels => { app => 'nats' } },
  status     => { phase => 'Running' }
);

my %comb = (
  apiVersion => 'comb.internal/v1',
  kind       => 'Comb',
  metadata   => { name => 'nats', namespace => 'platform', resourceVersion => '7' },
  spec       => { class => 'MyApp::Comb::NATS', upstream => undef }
);

my $combs = $server.'/apis/comb.internal/v1/namespaces/platform/combs';

subtest 'surface' => sub {
  my ( $k8s ) = client();
  ok $k8s->DOES('Kubernetes::Comb::Role::Client'), 'consumes Kubernetes::Comb::Role::Client';
  is $k8s->server_url, $server, 'server_url';
};

subtest 'get' => sub {
  my ( $k8s, $io ) = client();
  $io->respond( [ 200, \%pod ] );
  my $f = $k8s->get( 'Pod', 'nats-0', namespace => 'platform' );
  isa_ok $f, 'Future';
  ok $f->is_done, 'already done';
  isa_ok $f->get, 'IO::K8s::Api::Core::V1::Pod';
  is $f->get->status->phase, 'Running', 'inflated';
  is $io->last_request->method, 'GET', 'GET';
  is $io->last_request->url, $server.'/api/v1/namespaces/platform/pods/nats-0', 'path';
};

subtest 'delete with propagationPolicy' => sub {
  my ( $k8s, $io ) = client();
  my $jobs = $server.'/apis/batch/v1/namespaces/platform/jobs';
  $io->respond( ( [ 200, { kind => 'Status', status => 'Success' } ] ) x 2 );
  is $k8s->delete( 'Job', 'nats-init', namespace => 'platform', propagationPolicy => 'Background' )->get, 1,
    'by name';
  is $io->last_request->url, $jobs.'/nats-init?propagationPolicy=Background', 'sent as query parameter';

  my $job = IO::K8s->new->new_object( Job => {
    metadata => { name => 'nats-init', namespace => 'platform' }
  } );
  is $k8s->delete( $job, propagationPolicy => 'Background' )->get, 1, 'object form';
  is $io->last_request->url, $jobs.'/nats-init?propagationPolicy=Background', '... sent too';

  my $f = eval { $k8s->delete( $job, propagationPolicy => 'Backgroud' ) };
  ok $f && $f->is_failed, 'an unknown value fails the Future, nothing is thrown';
  like $f->failure, qr/Unknown propagationPolicy 'Backgroud'/, '... naming it';
  is scalar( () = $io->requests ), 2, 'and nothing is sent';
};

subtest 'API errors and bad arguments become failed Futures' => sub {
  my ( $k8s, $io ) = client();
  $io->respond( [ 404, { kind => 'Status', code => 404, reason => 'NotFound' } ] );
  my $f = eval { $k8s->get( 'Pod', 'nope', namespace => 'platform' ) };
  ok $f, 'nothing is thrown';
  ok $f->is_failed, 'the Future is failed';
  like $f->failure, qr/\AKubernetes API error \(get Pod\): 404 /, 'with the message of Kubernetes::REST';

  ok $k8s->get('Pod')->is_failed, 'missing name';
  ok $k8s->update('not an object')->is_failed, 'not an object';
  ok $k8s->list('Bogus')->is_failed, 'unknown Kind';
};

subtest 'list' => sub {
  my ( $k8s, $io ) = client();
  $io->respond( [ 200, { kind => 'PodList', apiVersion => 'v1', items => [ \%pod ] } ] );
  my $list = $k8s->list( 'Pod', namespace => 'platform', labelSelector => 'app=nats' )->get;
  isa_ok $list, 'IO::K8s::List';
  is $list->items->[0]->metadata->name, 'nats-0', 'items';
  like $io->last_request->url, qr{/api/v1/namespaces/platform/pods\?labelSelector=app}, 'selector sent';
};

subtest 'ensure and delete' => sub {
  my ( $k8s, $io ) = client();
  $io->respond( [ 404, { kind => 'Status', code => 404 } ], [ 201, \%pod ] );
  my $created = $k8s->ensure({ %pod })->get;
  isa_ok $created, 'IO::K8s::Api::Core::V1::Pod';
  is_deeply [ map { $_->method } $io->requests ], [qw( GET POST )], 'missing object is created';

  $io->respond( [ 200, { kind => 'Status', status => 'Success' } ] );
  is $k8s->delete( 'Pod', 'nats-0', namespace => 'platform' )->get, 1, 'delete resolves to 1';
  is $io->last_request->method, 'DELETE', 'DELETE';
  is $io->last_request->url, $server.'/api/v1/namespaces/platform/pods/nats-0', 'path';
};

subtest 'the Comb CR through the client' => sub {
  my ( $k8s, $io ) = client();
  $io->respond( [ 200, \%comb ], [ 200, \%comb ] );
  my $cr = $k8s->get( 'Comb', 'nats', namespace => 'platform' )->get;
  isa_ok $cr, 'Kubernetes::Comb::CRD::Comb';
  is $io->last_request->url, $combs.'/nats', 'the Kind resolves through the provider';
  ok $cr->spec->has_upstream && !defined $cr->spec->upstream, 'explicit null upstream survives';
  $k8s->get( '+Kubernetes::Comb::CRD::Comb', 'nats', namespace => 'platform' )->get;
  is $io->last_request->url, $combs.'/nats', 'and so does the class name';

  $cr->status({ phase => 'Running', observedGeneration => 3 });
  $io->respond( [ 200, { %comb, status => { phase => 'Running' } } ] );
  my $updated = $k8s->update_status($cr)->get;
  is $updated->status->phase, 'Running', 'update_status';
  is $io->last_request->method, 'PUT', 'PUT';
  is $io->last_request->url, $combs.'/nats/status', 'to the status subresource';
  is decode_json( $io->last_request->content )->{status}{phase}, 'Running', 'with the status';

  $io->respond( [ 200, { %comb, status => { phase => 'Blocked' } } ] );
  $k8s->patch_status( $cr, patch => { status => { phase => 'Blocked' } } )->get;
  is $io->last_request->method, 'PATCH', 'PATCH';
  is $io->last_request->url, $combs.'/nats/status', 'patch_status to the status subresource';
  is $io->last_request->headers->{'Content-Type'}, 'application/merge-patch+json', 'as a merge patch';

  $io->respond( [ 200, \%comb ] );
  $k8s->patch( 'Comb', 'nats', namespace => 'platform', patch => { spec => { enabled => \0 } }, type => 'merge' )->get;
  is $io->last_request->url, $combs.'/nats', 'patch goes to the main resource';

  $io->respond( [ 200, \%comb ] );
  $k8s->update($cr)->get;
  is $io->last_request->method, 'PUT', 'update';
};

subtest 'log' => sub {
  my ( $k8s, $io ) = client();
  $io->respond( [ 200, "crashed\n" ] );
  my $text = $k8s->log( 'Pod', 'nats-0',
    namespace => 'platform', container => 'nats', previous => 1, tailLines => 10 )->get;
  is $text, "crashed\n", 'log text';
  like $io->last_request->url, qr{/pods/nats-0/log\?}, 'log subresource';
  like $io->last_request->url, qr/previous=true/, 'previous';
  like $io->last_request->url, qr/tailLines=10/, 'tailLines';
  like $io->last_request->url, qr/container=nats/, 'container';
};

subtest 'kubeconfig contexts' => sub {
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

  my $k8s = Kubernetes::Comb::Client::Sync->new( kubeconfig => "$kubeconfig" );
  is $k8s->server_url, 'https://dev.example:6443', 'current context';
  is $k8s->rest->expand_class('+Kubernetes::Comb::CRD::Comb'), 'Kubernetes::Comb::CRD::Comb',
    'built client resolves the CR class';
  ok grep( { ref $_ && $_->isa('Kubernetes::Comb::CRD') } @{ $k8s->rest->with } ),
    'built client has the Comb resource map provider';

  my $prod = $k8s->for_context('prod');
  isa_ok $prod, 'Kubernetes::Comb::Client::Sync';
  is $prod->kubeconfig, "$kubeconfig", 'same kubeconfig';
  is $prod->context, 'prod', 'other context';
  is $prod->server_url, 'https://prod.example:6443', 'other server';
  is $k8s->for_context('prod'), $prod, 'asking again gives the same client';

  my $gone = $k8s->for_context('nope');
  my $f = eval { $gone->get( 'Pod', 'x', namespace => 'platform' ) };
  ok $f && $f->is_failed, 'an unknown context fails the request, nothing thrown';
  like $f->failure, qr/Context not found: nope/, '... naming the context';
  ok !eval { $gone->server_url; 1 }, 'server_url croaks for it';
};

done_testing;
