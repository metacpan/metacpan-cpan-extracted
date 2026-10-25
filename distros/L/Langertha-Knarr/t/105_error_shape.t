use strict;
use warnings;
use Test2::V0;

# Regression (k78): a backend failure reached Anthropic and Ollama clients
# as {"error":{"message":...}} -- the generic 500 of the native server, a
# die (Plack's text 500) under PSGI -- although only that shape is the
# OpenAI wire's: an Anthropic SDK reads error.type, an Ollama client expects
# "error" to be a string. And a stream whose backend failed before its
# first chunk had already sent its 200, then an '[error: ...]' text chunk
# without the protocol's end marker; a backend that refused at once even
# looked like an empty, complete stream (Stream->from_callback queued an
# end for a failure no read was waiting for). Now every failure Knarr
# answers itself is in the client protocol's error shape, natively and
# under PSGI, and a stream sends its 200 only with its first chunk: one
# that fails before that is answered with a status. A stream that has
# started still ends as before.

BEGIN {
  eval { require Plack::Test; 1 }
    or plan skip_all => 'Plack::Test required for this test';
}
use Plack::Test;
use HTTP::Request;
use IO::Async::Loop;
use Net::Async::HTTP;
use JSON::MaybeXS;

use Langertha::Knarr;
use Langertha::Knarr::PSGI;
use Langertha::Knarr::Stream;

my $loop = IO::Async::Loop->new;

{
  package FailingHandler;
  use Moose;
  use Future;
  with 'Langertha::Knarr::Handler';

  has loop => ( is => 'ro', required => 1 );

  sub handle_chat_f {
    my ($self, $session, $request) = @_;
    return Future->fail("backend exploded\n") if $request->model eq 'broken';
    return Future->done( Langertha::Knarr::Response->new( content => 'fine', model => $request->model ) );
  }

  # The model picks when the stream fails.
  sub handle_stream_f {
    my ($self, $session, $request) = @_;
    my $model = $request->model;
    my $loop  = $self->loop;
    return Future->fail("backend refused\n") if $model eq 'refuse';
    return Future->done( Langertha::Knarr::Stream->from_callback( sub {
      my ($emit, $done, $fail) = @_;
      if    ( $model eq 'at-once' ) { $fail->("backend broke at once\n") }
      elsif ( $model eq 'later' )   { $loop->later( sub { $fail->("backend broke later\n") } ) }
      elsif ( $model eq 'mid' )     { $emit->('a'); $loop->later( sub { $fail->("backend broke mid-stream\n") } ) }
      else                          { $loop->later( sub { $emit->('fine'); $done->() } ) }
    } ) );
  }

  sub list_models { [ { id => 'x', object => 'model' } ] }
  __PACKAGE__->meta->make_immutable;
}

my $json  = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $knarr = Langertha::Knarr->new(
  handler => FailingHandler->new( loop => $loop ),
  loop    => $loop,
  listen  => [ '127.0.0.1:0' ],
);
$knarr->start;
my $port = $knarr->_server->read_handle->sockport;
my $psgi = Plack::Test->create( Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app );
my $http = Net::Async::HTTP->new( max_connections_per_host => 0 );
$loop->add($http);

my %path = ( openai => '/v1/chat/completions', anthropic => '/v1/messages', ollama => '/api/chat' );

sub send_request {
  my ($transport, $proto, $model, $stream) = @_;
  my $body = { model => $model, messages => [ { role => 'user', content => 'hi' } ],
    stream => $stream ? JSON::MaybeXS::true() : JSON::MaybeXS::false() };
  $body->{max_tokens} = 5 if $proto eq 'anthropic';
  my @h = ( 'Content-Type' => 'application/json' );
  return $transport eq 'native'
    ? $http->do_request( request => HTTP::Request->new(
        POST => "http://127.0.0.1:$port$path{$proto}", \@h, $json->encode($body) ), timeout => 10 )->get
    : $psgi->request( HTTP::Request->new( POST => "http://localhost$path{$proto}", \@h, $json->encode($body) ) );
}

sub decoded { my ($resp) = @_; my $d = eval { $json->decode( $resp->content ) }; return $d // $resp->content }

# The protocol's error shape of a 500 carrying $re.
my %error_shape = (
  openai    => sub { my ($re) = @_; hash { field error => hash { field message => match $re; end }; end } },
  anthropic => sub { my ($re) = @_; hash { field type => 'error';
    field error => hash { field type => 'api_error'; field message => match $re; end }; end } },
  ollama    => sub { my ($re) = @_; hash { field error => match $re; end } },
);

for my $transport (qw( native psgi )) {
  for my $proto (qw( openai anthropic ollama )) {
    my $label = "$transport $proto";

    my $resp = send_request( $transport, $proto, 'broken', 0 );
    is( $resp->code, 500, "$label sync failure: 500" );
    is( $resp->header('Content-Type'), 'application/json', "$label sync failure: JSON" );
    is( decoded($resp), $error_shape{$proto}->(qr/\Abackend exploded\z/), "$label sync failure: protocol's error shape" );

    for my $case (
      [ refuse    => qr/\Abackend refused\z/,       'handler fails' ],
      [ 'at-once' => qr/\Abackend broke at once\z/, 'stream fails before the first read' ],
      [ later     => qr/\Abackend broke later\z/,   'stream fails before its first chunk' ],
    ) {
      my ($model, $re, $what) = @$case;
      $resp = send_request( $transport, $proto, $model, 1 );
      is( $resp->code, 500, "$label stream, $what: 500, the stream never started" );
      is( decoded($resp), $error_shape{$proto}->($re), "$label stream, $what: protocol's error shape" );
    }

    $resp = send_request( $transport, $proto, 'fine', 1 );
    is( $resp->code, 200, "$label stream that works: 200" );
    like( $resp->content, qr/fine/, "$label stream that works: its chunk" );
  }
}

# A stream that has started keeps its 200; what it ends with is not this
# card's (the status is out). Under PSGI nothing is out yet: 500.
for my $proto (qw( openai anthropic ollama )) {
  my $resp = send_request( 'native', $proto, 'mid', 1 );
  is( $resp->code, 200, "native $proto stream failing after its first chunk: 200, the stream had started" );
  like( $resp->content, qr/broke mid-stream/, "native $proto stream failing after its first chunk: the failure is in it" );

  $resp = send_request( 'psgi', $proto, 'mid', 1 );
  is( $resp->code, 500, "psgi $proto stream failing after its first chunk: 500, buffered" );
  is( decoded($resp), $error_shape{$proto}->(qr/\Abackend broke mid-stream\z/), "psgi $proto mid-stream failure: protocol's error shape" );
}

subtest 'Stream->from_callback: a failure no read waits for is not an end' => sub {
  my $s = Langertha::Knarr::Stream->from_callback( sub { $_[2]->('gone') } );
  my $f = $s->next_chunk_f;
  ok( $f->is_failed, 'failed before the first read: the first read fails' );
  is( ( $f->failure )[0], 'gone', '... with the failure' );

  my $later;
  $s = Langertha::Knarr::Stream->from_callback( sub {
    my ($emit, $done, $fail) = @_;
    $emit->('a'); $emit->('b'); $fail->( 'cut', 'stall_timeout' );
  } );
  is( $s->next_chunk_f->get, 'a', 'chunks queued before the failure come first' );
  is( $s->next_chunk_f->get, 'b', '... all of them' );
  $f = $s->next_chunk_f;
  ok( $f->is_failed, 'then the failure' );
  is( [ $f->failure ], [ 'cut', 'stall_timeout' ], '... category included' );

  $s = Langertha::Knarr::Stream->from_callback( sub { $later = $_[2] } );
  $f = $s->next_chunk_f;
  ok( !$f->is_ready, 'a read waits' );
  $later->('late');
  ok( $f->is_failed, 'a waiting read gets the failure' );

  $s = Langertha::Knarr::Stream->from_callback( sub { $_[0]->('x'); $_[1]->() } );
  is( $s->next_chunk_f->get, 'x', 'a stream that ends' );
  is( $s->next_chunk_f->get, undef, '... ends with undef' );
};

done_testing;
