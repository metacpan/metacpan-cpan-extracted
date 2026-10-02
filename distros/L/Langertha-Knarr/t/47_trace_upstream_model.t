use strict;
use warnings;
use Test2::V0;
use Future;
use IO::Async::Loop;
use Net::Async::HTTP;
use HTTP::Request;
use JSON::MaybeXS;

# A routed answer is labeled with the configured model for the client, and the
# Langfuse generation got that label too -- not the model the upstream
# reported answering with (gpt-4o answers as gpt-4o-2024-08-06), and a routed
# stream even got the alias the client asked for. The generation now records
# the reported model, the configured name in its metadata as
# configured_model; the client keeps seeing the configured name (sync) and the
# name it asked for (stream), as before.

use Langertha::Stream::Chunk;
use Langertha::Knarr;
use Langertha::Knarr::Session;
use Langertha::Knarr::Request;
use Langertha::Knarr::Response;
use Langertha::Knarr::Stream;
use Langertha::Knarr::Handler::Engine;
use Langertha::Knarr::Handler::Router;
use Langertha::Knarr::Handler::Tracing;
use Langertha::Knarr::Config;
use Langertha::Knarr::Tracing;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

# An engine whose upstream answers under a more concrete name than configured.
{
  package ModelEngine;
  use Moose;
  use Future;
  use Langertha::Response;
  has chat_model => ( is => 'ro', default => 'up-model' );
  has reports    => ( is => 'ro', default => 1 );
  sub supports { $_[1] eq 'streaming' ? 1 : 0 }
  sub chat_f {
    my ($self) = @_;
    return Future->done( Langertha::Response->new(
      content => 'hi', $self->reports ? ( model => 'up-model-2024' ) : () ) );
  }
  sub chat_stream_realtime_f {
    my ( $self, %args ) = @_;
    my %m = $self->reports ? ( model => 'up-model-2024' ) : ();
    $args{chunk_callback}->( Langertha::Stream::Chunk->new( content => 'hi', %m ) );
    $args{chunk_callback}->( Langertha::Stream::Chunk->new( content => '', %m, is_final => 1, finish_reason => 'stop' ) );
    return Future->done;
  }
  __PACKAGE__->meta->make_immutable;
}

# resolve() as Langertha::Knarr::Router answers it: engine, the configured
# model, and whether the config names none (alias only).
{
  package ModelRouter;
  use Moose;
  has engine     => ( is => 'ro', required => 1 );
  has alias_only => ( is => 'ro', default => 0 );
  sub resolve {
    my ($self) = @_;
    return ( $self->engine, $self->alias_only ? 'fake' : 'up-model', $self->alias_only );
  }
  sub list_models { [ { id => 'fake', object => 'model' } ] }
  __PACKAGE__->meta->make_immutable;
}

{
  package RecTracer;
  use Moose;
  has ended => ( is => 'rw' );
  sub start_trace { {} }
  sub end_trace   { my ( $self, $t, %o ) = @_; $self->ended( \%o ) }
  __PACKAGE__->meta->make_immutable;
}

my $session = Langertha::Knarr::Session->new( id => 's' );
sub req {
  my ($stream) = @_;
  return Langertha::Knarr::Request->new(
    protocol => 'openai', model => 'fake', stream => $stream ? 1 : 0,
    messages => [ { role => 'user', content => 'hi' } ],
  );
}

sub traced {
  my ( $wrapped, $stream ) = @_;
  my $tracer = RecTracer->new;
  my $h = Langertha::Knarr::Handler::Tracing->new( wrapped => $wrapped, tracing => $tracer );
  my $out;
  if ($stream) {
    $out = $h->handle_stream_f( $session, req(1) )->get;
    1 while defined $out->next_chunk_f->get;
  }
  else {
    $out = $h->handle_chat_f( $session, req(0) )->get;
  }
  return ( $tracer->ended, $out );
}

sub router { Langertha::Knarr::Handler::Router->new( router => ModelRouter->new( engine => ModelEngine->new(@_) ) ) }

subtest 'Router: the reported model on the generation, the configured one in metadata' => sub {
  my ( $end, $r ) = traced( router(), 0 );
  is $end->{model}, 'up-model-2024', 'sync: generation model is the reported one';
  is $end->{configured_model}, 'up-model', 'sync: configured model kept';
  is $r->model, 'up-model', 'sync: client still sees the configured model';
  is $r->upstream_model, 'up-model-2024', 'sync: Response carries the reported model';

  ( $end, my $s ) = traced( router(), 1 );
  is $end->{model}, 'up-model-2024', 'stream: generation model is the reported one';
  is $end->{configured_model}, 'up-model', 'stream: configured model kept';
  is [ $s->model, $s->upstream_model ], [ 'up-model', 'up-model-2024' ], 'stream: both on the stream';
};

subtest 'nothing reported: the label, no configured_model' => sub {
  my ($end) = traced( router( reports => 0 ), 0 );
  is $end->{model}, 'up-model', 'sync: the configured model';
  ok !exists $end->{configured_model}, 'sync: no configured_model';

  ($end) = traced( router( reports => 0 ), 1 );
  is $end->{model}, 'up-model', 'stream: the configured model, not the alias';
  ok !exists $end->{configured_model}, 'stream: no configured_model';
};

subtest 'alias without a configured model: the reported model, nothing else' => sub {
  my $alias = sub {
    Langertha::Knarr::Handler::Router->new(
      router => ModelRouter->new( engine => ModelEngine->new, alias_only => 1 ) );
  };
  for my $stream ( 0, 1 ) {
    my ($end) = traced( $alias->(), $stream );
    is $end->{model}, 'up-model-2024', ( $stream ? 'stream' : 'sync' ) . ': reported model';
    ok !exists $end->{configured_model}, ( $stream ? 'stream' : 'sync' ) . ': no configured_model';
  }
};

subtest 'Handler::Engine: the reported model' => sub {
  my ($end) = traced( Langertha::Knarr::Handler::Engine->new( engine => ModelEngine->new ), 1 );
  is $end->{model}, 'up-model-2024', 'stream: reported model instead of the name asked for';
  ok !exists $end->{configured_model}, 'no label to keep';
  ($end) = traced( Langertha::Knarr::Handler::Engine->new( engine => ModelEngine->new( reports => 0 ) ), 1 );
  is $end->{model}, 'fake', 'stream without a report: the name asked for';
};

{
  package CapturingTracing;
  use Moo;
  extends 'Langertha::Knarr::Tracing';
  has captured => ( is => 'ro', default => sub { [] } );
  sub flush {
    my ($self) = @_;
    push @{ $self->captured }, @{ $self->_batch };
    $self->_batch( [] );
    return;
  }
}

subtest 'Tracing records configured_model in the generation metadata' => sub {
  my $t = CapturingTracing->new(
    config => Langertha::Knarr::Config->new( data => { models => {}, langfuse => {
      url => 'http://127.0.0.1:1', public_key => 'pk-lf-test', secret_key => 'sk-lf-test' } } ),
  );
  my $info = $t->start_trace( model => 'fake', messages => [] );
  $t->end_trace( $info, output => 'hi', model => 'up-model-2024', configured_model => 'up-model' );
  my ($gen) = grep { $_->{type} eq 'generation-update' } @{ $t->captured };
  is $gen->{body}{model}, 'up-model-2024', 'generation model';
  is $gen->{body}{metadata}{configured_model}, 'up-model', 'configured_model in metadata';
};

# --- End to end: the client-visible model is unchanged ---

my $loop = IO::Async::Loop->new;
my $knarr = Langertha::Knarr->new( handler => router(), loop => $loop, port => 0 );
$knarr->start;
my $port = $knarr->_server->read_handle->sockport;
my $http = Net::Async::HTTP->new;
$loop->add($http);

sub post {
  my (%extra) = @_;
  my $r = HTTP::Request->new( POST => "http://127.0.0.1:$port/v1/chat/completions" );
  $r->header( 'Content-Type' => 'application/json' );
  $r->content( $json->encode({ model => 'fake', messages => [ { role => 'user', content => 'hi' } ], %extra }) );
  return $http->do_request( request => $r )->get->content;
}

subtest 'client sees the model it did before' => sub {
  is $json->decode( post() )->{model}, 'up-model', 'sync: configured model';
  my @models = map { $json->decode($_)->{model} }
    grep { $_ ne '[DONE]' } post( stream => JSON::MaybeXS::true() ) =~ /^data: (.+)$/mg;
  ok @models, 'stream chunks';
  is [ keys %{ { map { $_ => 1 } @models } } ], ['fake'], 'stream: the name asked for';
};

done_testing;
