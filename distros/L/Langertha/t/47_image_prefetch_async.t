#!/usr/bin/env perl
# ABSTRACT: URL images an engine must inline are fetched through its async backend on _f paths
use strict;
use warnings;
use Test2::Bundle::More;
use lib 't/lib';

use Future;
use JSON::MaybeXS;
use MIME::Base64 qw( encode_base64 );
use HTTP::Response;
use LWP::UserAgent;
use Test::LocalHTTPDaemon;
use Test::MockMCP;
use Langertha::Content::Image;
use Langertha::Request::SyncHTTP;
use Langertha::Engine::OllamaOpenAI;
use Langertha::Engine::Gemini;
use Langertha::Engine::Ollama;

# karr k274 (ADR 0027): engines that take only inline images (Gemini, Ollama
# native, LM Studio native, and the _content_inline_images_only ones) inlined a
# URL image with a blocking LWP GET while the request was built -- also on the
# _f paths, inside the IO::Async loop that knarr/skeid serve many requests
# from. The _f paths now prefetch those images through the engine's own async
# backend (injected client > Net::Async::HTTP > sync LWP shim), all at once,
# before the build; a failed fetch fails the Future with the error the sync
# path croaks. The sync path keeps its own LWP fetch.

my $json = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );
my %BYTES = ( '/a.png' => "\x89PNG-a", '/b.png' => "\x89PNG-b" );
sub data_url { 'data:image/png;base64,' . encode_base64( $BYTES{ $_[0] }, '' ) }

# Every LWP request in this process goes through send_request; count them.
my $lwp_calls = 0;
{
  no warnings 'redefine';
  my $orig = \&LWP::UserAgent::send_request;
  *LWP::UserAgent::send_request = sub { $lwp_calls++; goto &$orig };
}

# The daemon serves the images and an OpenAI chat endpoint that answers with
# the image URLs it received, so the reply proves what went on the wire.
my $server = Test::LocalHTTPDaemon->start( sub {
  my ($req) = @_;
  my $path = $req->uri->path;
  return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'image/png' ], $BYTES{$path} )
    if exists $BYTES{$path};
  if ( $path eq '/v1/chat/completions' ) {
    my $body = $json->decode( $req->content );
    my @urls = map { $_->{image_url}{url} }
      grep { ref $_ eq 'HASH' && ( $_->{type} // '' ) eq 'image_url' }
      map { ref $_->{content} eq 'ARRAY' ? @{ $_->{content} } : () } @{ $body->{messages} };
    return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ],
      $json->encode( {
        id => 'x', object => 'chat.completion', created => 1, model => 'm',
        choices => [ { index => 0, finish_reason => 'stop',
          message => { role => 'assistant', content => join( ' ', @urls ) } } ],
      } ) );
  }
  return HTTP::Response->new( 404, 'Not Found', [ 'Content-Type' => 'text/plain' ], 'nope' );
} );
my $base = $server->url;

# --- Net::Async::HTTP backend: the fetch goes through it, never through LWP ---
SKIP: {
  skip 'Net::Async::HTTP not installed', 5 unless eval { require Net::Async::HTTP; 1 };

  my $e = Langertha::Engine::OllamaOpenAI->new( url => "$base/v1", model => 'm' );
  isa_ok $e->_async_http, 'Net::Async::HTTP';
  $lwp_calls = 0;
  my $img_a = Langertha::Content::Image->from_url("$base/a.png");
  my $img_b = Langertha::Content::Image->from_url("$base/b.png");
  my $r = $e->chat_f( messages => [ { role => 'user', content => [ 'x', $img_a, $img_b ] } ] )->get;
  is "$r", join( ' ', data_url('/a.png'), data_url('/b.png') ),
    'both URL images went on the wire as data URLs';
  is $lwp_calls, 0, '... fetched without a single LWP request';
  is $img_a->base64, encode_base64( $BYTES{'/a.png'}, '' ), '... bytes cached on the image object';

  my $bad = Langertha::Content::Image->from_url("$base/missing.png");
  my $f = $e->chat_f( messages => [ { role => 'user', content => [ 'x', $bad ] } ] );
  $f->await;
  like scalar $f->failure,
    qr/\ALangertha::Engine::OllamaOpenAI: this endpoint takes only inline images .*404.*pass the image as base64 or from a local file instead/s,
    'an unfetchable image fails the Future with the sync-path error';
}

# A recording client for orchestration: image GETs stay pending until the test
# resolves them, the chat POST is answered from a canned body.
{
  package My::RecordingHTTP;
  sub new { bless { requests => [], pending => [], chat => $_[1] }, $_[0] }
  sub do_request {
    my ( $self, %args ) = @_;
    my $req = $args{request};
    push @{ $self->{requests} }, $req;
    if ( $req->method eq 'GET' ) {
      my $f = Future->new;
      push @{ $self->{pending} }, [ $req, $f ];
      return $f;
    }
    return Future->fail('streaming not scripted') if $args{on_header};
    return Future->done( HTTP::Response->new( 200, 'OK',
      [ 'Content-Type' => 'application/json' ], $self->{chat} ) );
  }
  sub resolve_all {
    my ($self) = @_;
    for my $p ( splice @{ $self->{pending} } ) {
      my ( $req, $f ) = @$p;
      my $bytes = $BYTES{ $req->uri->path };
      $f->done( defined $bytes
        ? HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'image/png' ], $bytes )
        : HTTP::Response->new( 404, 'Not Found', [], 'nope' ) );
    }
  }
}
my $openai_reply = $json->encode( { id => 'x', object => 'chat.completion', created => 1,
  model => 'm', choices => [ { index => 0, finish_reason => 'stop',
    message => { role => 'assistant', content => 'ok' } } ] } );

# --- Both images are requested before either arrives (needs_all, not a loop) ---
{
  my $http = My::RecordingHTTP->new($openai_reply);
  my $e = Langertha::Engine::OllamaOpenAI->new( url => 'http://h/v1', model => 'm', _async_http => $http );
  my $f = $e->chat_f( messages => [ { role => 'user', content => [
    Langertha::Content::Image->from_url('http://img/a.png'),
    Langertha::Content::Image->from_url('http://img/b.png') ] } ] );
  is scalar @{ $http->{pending} }, 2, 'both image fetches are in flight at once';
  ok !$f->is_ready, '... and chat_f waits for them';
  is scalar @{ $http->{requests} }, 2, '... no chat request before the images are in';
  $http->resolve_all;
  ok $f->is_done, 'chat_f completes once the images arrived';
  my $body = $json->decode( $http->{requests}[2]->content );
  is_deeply [ map { $_->{image_url}{url} } @{ $body->{messages}[0]{content} } ],
    [ data_url('/a.png'), data_url('/b.png') ], '... and sent them inline';
}

# --- A failed fetch fails the Future; no chat request is sent ---
{
  my $http = My::RecordingHTTP->new($openai_reply);
  my $e = Langertha::Engine::OllamaOpenAI->new( url => 'http://h/v1', model => 'm', _async_http => $http );
  my $f = $e->chat_f( messages => [ { role => 'user', content => [
    Langertha::Content::Image->from_url('http://img/missing.png') ] } ] );
  $http->resolve_all;
  ok $f->is_failed, 'a 404 image fails the chat_f Future';
  like scalar $f->failure, qr/\ALangertha::Engine::OllamaOpenAI: this endpoint takes only inline images .*404/s,
    '... with the engine-named inline error';
  is scalar @{ $http->{requests} }, 1, '... before any chat request';

  my $e2 = Langertha::Engine::OllamaOpenAI->new( url => 'http://h/v1', model => 'm',
    _async_http => bless( {}, 'My::DeadHTTP' ) );
  { package My::DeadHTTP; sub do_request { Future->fail("connection refused\n") } }
  my $f2 = $e2->chat_f( messages => [ { role => 'user', content => [
    Langertha::Content::Image->from_url('http://img/a.png') ] } ] );
  like scalar $f2->failure, qr/could not be inlined \(ensure_base64: failed to fetch http:\/\/img\/a\.png: connection refused\)/,
    'a transport failure fails the Future naming the URL and the cause';
}

# --- Gemini: Content objects and image_url hash parts both prefetched ---
{
  my $gemini_reply = $json->encode( { candidates => [ { content => { role => 'model',
    parts => [ { text => 'ok' } ] }, finishReason => 'STOP' } ] } );
  my $http = My::RecordingHTTP->new($gemini_reply);
  my $e = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-2.5-flash', _async_http => $http );
  my $hash_part = { type => 'image_url', image_url => { url => 'http://img/b.png' } };
  my $msg = { role => 'user', content => [ 'x', Langertha::Content::Image->from_url('http://img/a.png'), $hash_part ] };
  my $f = $e->chat_f( messages => [$msg] );
  is scalar @{ $http->{pending} }, 2, 'Gemini: the Content image and the image_url part are both fetched async';
  $http->resolve_all;
  ok $f->is_done, '... chat_f completes';
  my $body = $json->decode( $http->{requests}[2]->content );
  is_deeply [ map { $_->{inline_data}{data} } grep { $_->{inline_data} } @{ $body->{contents}[0]{parts} } ],
    [ map { encode_base64( $BYTES{$_}, '' ) } '/a.png', '/b.png' ], '... both sent as inline_data';
  is ref $msg->{content}[2], 'HASH', "... the caller's message is not modified";
}

# --- Streaming and the MCP tool loop prefetch too ---
{
  my $http = My::RecordingHTTP->new($openai_reply);
  my $e = Langertha::Engine::Ollama->new( url => 'http://h:11434', model => 'm', _async_http => $http );
  my $f = $e->chat_stream_realtime_f( messages => [ { role => 'user', content => [
    'x', Langertha::Content::Image->from_url('http://img/a.png') ] } ] );
  is scalar @{ $http->{pending} }, 1, 'chat_stream_realtime_f: the image is fetched async first';
  $http->resolve_all;
  my $body = $json->decode( $http->{requests}[1]->content );
  is_deeply $body->{messages}[0]{images}, [ encode_base64( $BYTES{'/a.png'}, '' ) ],
    '... and inlined into the stream request';
  $f->await;

  my $http2 = My::RecordingHTTP->new($openai_reply);
  my $mcp = Test::MockMCP->new( tools => [ { name => 't', description => 'd',
    input_schema => { type => 'object' }, code => sub { $_[0]->text_result('r') } } ] );
  my $e2 = Langertha::Engine::OllamaOpenAI->new( url => 'http://h/v1', model => 'm',
    _async_http => $http2, mcp_servers => [$mcp] );
  my $f2 = $e2->chat_with_tools_f( { role => 'user', content => [
    'x', Langertha::Content::Image->from_url('http://img/a.png') ] } );
  is scalar @{ $http2->{pending} }, 1, 'chat_with_tools_f: the image is fetched async first';
  $http2->resolve_all;
  ok $f2->is_done, '... and the loop completes';
}

# --- Sync LWP fallback: the fetch rides the engine's own user_agent ---
# (the image GET goes through a copy of it restricted to http/https, karr
# k325, so it is recognised by its settings rather than by identity)
{
  my $ua = LWP::UserAgent->new( agent => 'k274-engine-ua' );
  my $e = Langertha::Engine::OllamaOpenAI->new( url => "$base/v1", model => 'm', user_agent => $ua,
    _async_http => Langertha::Request::SyncHTTP->new( user_agent => $ua ) );
  my @via;
  { no warnings 'redefine'; my $orig = \&LWP::UserAgent::request;
    local *LWP::UserAgent::request = sub { push @via, [ $_[0]->agent, $_[1]->uri->path ]; goto &$orig };
    my $r = $e->chat_f( messages => [ { role => 'user', content => [
      Langertha::Content::Image->from_url("$base/a.png") ] } ] )->get;
    is "$r", data_url('/a.png'), 'sync fallback: image inlined';
  }
  is_deeply \@via, [ [ 'k274-engine-ua', '/a.png' ], [ 'k274-engine-ua', '/v1/chat/completions' ] ],
    '... fetched through the backend (engine user_agent), before the chat request';
}

# --- Sync path unchanged: builds without touching the async backend ---
{
  my $e = Langertha::Engine::OllamaOpenAI->new( url => 'http://h/v1', model => 'm',
    _async_http => bless( {}, 'My::ForbiddenHTTP' ) );
  { package My::ForbiddenHTTP; sub do_request { die "async backend used on the sync path\n" } }
  my $req = $e->chat( { role => 'user', content => [ Langertha::Content::Image->from_url("$base/a.png") ] } );
  is $json->decode( $req->content )->{messages}[0]{content}[0]{image_url}{url}, data_url('/a.png'),
    'sync chat still fetches and inlines on its own';
}

done_testing;
