use strict;
use warnings;
use Test2::V0;
use Future;

use Langertha::Knarr::Session;
use Langertha::Knarr::Request;
use Langertha::Knarr::Handler::Engine;
use Langertha::Knarr::Handler::Router;

# Regression for karr #1: the streaming path must forward the same
# capability-filtered generation parameters (tools, tool_choice,
# temperature, max_tokens, messages) as the non-streaming path — i.e. it
# must call chat_stream_realtime_f with $request->chat_f_args($engine),
# NOT simple_chat_stream_realtime_f (which silently drops everything but
# the messages).

# Fake engine that records which streaming method was called and the
# named args it received, then emits a few chunks via chunk_callback.
{
  package StreamEngine;
  use Moose;
  use Future;
  has chat_model    => ( is => 'ro', default => 'stream-1' );
  has caps          => ( is => 'ro', default => sub {
    {
      tools_native                => 1,
      temperature                 => 1,
      response_size               => 1,
      response_format_json_object => 1,
      response_format_json_schema => 1,
      streaming                   => 1,
    };
  });
  has method_called => ( is => 'rw' );  # 'realtime' (correct) or 'simple' (regression)
  has captured      => ( is => 'rw' );  # named args seen by chat_stream_realtime_f
  sub supports { $_[0]->caps->{ $_[1] } ? 1 : 0 }

  sub chat_stream_realtime_f {
    my ($self, %args) = @_;
    $self->method_called('realtime');
    $self->captured(\%args);
    my $cb = $args{chunk_callback};
    $cb->($_) for ( 'Hel', 'lo', ' wo', 'rld' );
    return Future->done;
  }

  # If the fix ever regresses, the handler falls back here. Still emits so
  # the stream drains cleanly, but records the wrong method and never
  # captures the named args — both assertions below then fail.
  sub simple_chat_stream_realtime_f {
    my ($self, $chunk_callback, @messages) = @_;
    $self->method_called('simple');
    $chunk_callback->($_) for ( 'Hel', 'lo', ' wo', 'rld' );
    return Future->done;
  }
  __PACKAGE__->meta->make_immutable;
}

# Minimal router that resolves any model to a fixed engine instance, so we
# can inspect what it captured after the stream drains (cf. t/71).
{
  package MockStreamRouter;
  use Moose;
  has engine => ( is => 'ro', required => 1 );
  sub resolve { my ($self, $model) = @_; return ( $self->engine, $model // 'stream-1' ) }
  sub list_models { [ { id => 'stream-1', object => 'model' } ] }
  __PACKAGE__->meta->make_immutable;
}

sub build_request {
  Langertha::Knarr::Request->new(
    protocol    => 'openai',
    model       => 'stream-1',
    stream      => 1,
    messages    => [ { role => 'user', content => 'hi' } ],
    temperature => 0.5,
    max_tokens  => 64,
    tools       => [ { type => 'function', function => { name => 'f', parameters => {} } } ],
    tool_choice => 'auto',
  );
}

sub drain {
  my ($stream) = @_;
  my @chunks;
  while ( defined( my $c = $stream->next_chunk_f->get ) ) { push @chunks, $c }
  return @chunks;
}

sub check_captured {
  my ($engine, @chunks) = @_;
  is $engine->method_called, 'realtime',
    'chat_stream_realtime_f called (not simple_chat_stream_realtime_f)';
  my $cap = $engine->captured;
  ref $cap eq 'HASH' or return;  # method assertion already flagged the regression
  is ref $cap->{chunk_callback}, 'CODE', 'chunk_callback forwarded';
  is $cap->{messages},    [ { role => 'user', content => 'hi' } ], 'messages forwarded';
  ok $cap->{tools},       'tools forwarded';
  is $cap->{tool_choice}, 'auto', 'tool_choice forwarded';
  is $cap->{temperature}, 0.5,    'temperature forwarded';
  is $cap->{max_tokens},  64,     'max_tokens forwarded';
  is join( '', @chunks ), 'Hello world', 'chunks streamed through';
}

my $session = Langertha::Knarr::Session->new( id => 's' );

subtest 'Handler::Engine streaming forwards generation params' => sub {
  my $engine = StreamEngine->new;
  my $h = Langertha::Knarr::Handler::Engine->new( engine => $engine );
  my $stream = $h->handle_stream_f( $session, build_request() )->get;
  my @chunks = drain($stream);
  check_captured( $engine, @chunks );
};

subtest 'Handler::Router streaming forwards generation params' => sub {
  my $engine = StreamEngine->new;
  my $h = Langertha::Knarr::Handler::Router->new(
    router => MockStreamRouter->new( engine => $engine ),
  );
  my $stream = $h->handle_stream_f( $session, build_request() )->get;
  my @chunks = drain($stream);
  check_captured( $engine, @chunks );
};

done_testing;
