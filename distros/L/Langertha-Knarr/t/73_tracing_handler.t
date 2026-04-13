use strict;
use warnings;
use Test2::V0;
use Future;

use Langertha::Knarr::Session;
use Langertha::Knarr::Request;
use Langertha::Knarr::Handler::Code;
use Langertha::Knarr::Handler::Tracing;

# Mock tracer that records start/end events.
{
  package MockTracer;
  use Moose;
  has events => ( is => 'ro', default => sub { [] } );
  has next_id => ( is => 'rw', default => 0 );
  sub start_trace {
    my ($self, %opts) = @_;
    $self->next_id( $self->next_id + 1 );
    my $id = 'trace-' . $self->next_id;
    push @{ $self->events }, { kind => 'start', id => $id, %opts };
    return { trace_id => $id, gen_id => "$id-gen" };
  }
  sub end_trace {
    my ($self, $info, %opts) = @_;
    push @{ $self->events }, { kind => 'end', id => $info->{trace_id}, %opts };
  }
  __PACKAGE__->meta->make_immutable;
}

my $session = Langertha::Knarr::Session->new( id => 's' );

# --- Sync chat: trace opens, closes with output ---
{
  my $tracer = MockTracer->new;
  my $wrapped  = Langertha::Knarr::Handler::Code->new( code => sub { 'echoed!' } );
  my $h = Langertha::Knarr::Handler::Tracing->new(
    wrapped   => $wrapped,
    tracing => $tracer,
  );
  my $req = Langertha::Knarr::Request->new(
    protocol => 'openai',
    model    => 'gpt-test',
    messages => [ { role => 'user', content => 'hi' } ],
  );
  my $r = $h->handle_chat_f( $session, $req )->get;
  is( $r->{content}, 'echoed!', 'wrapped result passed through' );
  is( scalar @{ $tracer->events }, 2, 'two trace events' );
  is( $tracer->events->[0]{kind}, 'start', 'first is start' );
  is( $tracer->events->[0]{model}, 'gpt-test', 'start records model' );
  is( $tracer->events->[0]{format}, 'openai', 'start records format' );
  is( $tracer->events->[1]{kind}, 'end', 'second is end' );
  is( $tracer->events->[1]{output}, 'echoed!', 'end records output' );
  is( $tracer->events->[1]{id}, 'trace-1', 'matches start id' );
}

# --- Streaming chat: trace closes after stream exhausted with accumulated text ---
{
  my $tracer = MockTracer->new;
  my $wrapped  = Langertha::Knarr::Handler::Code->new(
    code        => sub { 'sync-fallback' },
    stream_code => sub { my @p = ('al', 'ph', 'a'); sub { @p ? shift @p : undef } },
  );
  my $h = Langertha::Knarr::Handler::Tracing->new(
    wrapped   => $wrapped,
    tracing => $tracer,
  );
  my $req = Langertha::Knarr::Request->new(
    protocol => 'openai',
    model    => 'gpt-test',
    stream   => 1,
    messages => [ { role => 'user', content => 'hi' } ],
  );
  my $stream = $h->handle_stream_f( $session, $req )->get;

  my @chunks;
  while ( defined( my $c = $stream->next_chunk_f->get ) ) {
    push @chunks, $c;
  }
  is( join('', @chunks), 'alpha', 'all chunks collected' );

  # After draining, stream is closed → tracer end was called.
  is( scalar @{ $tracer->events }, 2, 'two trace events for stream' );
  is( $tracer->events->[1]{kind}, 'end', 'stream end recorded' );
  is( $tracer->events->[1]{output}, 'alpha', 'stream output accumulated' );
}

# --- Tracing skips list_models ---
{
  my $tracer = MockTracer->new;
  my $wrapped  = Langertha::Knarr::Handler::Code->new( code => sub { '' } );
  my $h = Langertha::Knarr::Handler::Tracing->new(
    wrapped => $wrapped, tracing => $tracer,
  );
  my $models = $h->list_models;
  ok( scalar @$models, 'models passed through' );
  is( scalar @{ $tracer->events }, 0, 'list_models does not start a trace' );
}

done_testing;
