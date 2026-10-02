#!/usr/bin/env perl
# ABSTRACT: simple_embedding_f / simple_transcription_f / simple_image_f and the Embedder / ImageGen _f wrappers (mocked async)
use strict;
use warnings;
use Test2::Bundle::More;
use lib 't/lib';

use Future;
use Future::AsyncAwait;
use JSON::MaybeXS;
use Test::MockAsyncHTTP;
use Langertha::Engine::OpenAI;
use Langertha::Engine::Whisper;
use Langertha::Embedder;
use Langertha::ImageGen;

# karr k292: embedding, transcription and image generation were LWP-only, so
# an async caller (langertha-raider's raid loop, knarr/skeid proxying
# embeddings) stalled its event loop on every call -- the reactor stall of
# k165/k172. The _f variants send the same request (*_request) through the
# engine's async backend (_async_do_request_f, which also carries the k278
# timeout) and return exactly what the sync methods return. The Embedder /
# ImageGen wrappers await their plugin hooks instead of ->get-ing them: a hook
# that is still pending must suspend the call, not die or block.

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

sub mock_json { Test::MockAsyncHTTP->mock_json_response(@_) }

sub embedding_body {
  my (@vectors) = @_;
  return mock_json({ object => 'list', model => 'text-embedding-3-large',
    data => [ map { { object => 'embedding', index => $_, embedding => $vectors[$_] } } 0 .. $#vectors ],
    usage => { prompt_tokens => 3, total_tokens => 3 } });
}

sub openai {
  my ($mock, %args) = @_;
  return Langertha::Engine::OpenAI->new( api_key => 'sk-test', url => 'http://mock.invalid/v1',
    _async_http => $mock, %args );
}

subtest 'simple_embedding_f: one vector for a string, one per input for a batch' => sub {
  my $mock = Test::MockAsyncHTTP->new( responses => [
    embedding_body([ 0.1, 0.2 ]),
    embedding_body([ 1, 2 ], [ 3, 4 ]),
  ] );
  my $e = openai($mock);

  my $f = $e->simple_embedding_f('hello');
  isa_ok $f, 'Future';
  is_deeply $f->get, [ 0.1, 0.2 ], 'string input resolves to the bare vector';

  is_deeply $e->simple_embedding_f([ 'a', 'b' ])->get, [ [ 1, 2 ], [ 3, 4 ] ],
    'ArrayRef input resolves to an ArrayRef of vectors (k289)';

  is $mock->request_count, 2, 'both went through the async backend';
  my ($first, $second) = $mock->requests;
  is $first->uri->path, '/v1/embeddings', 'embeddings endpoint';
  is_deeply $json->decode( $first->content ),
    $json->decode( $e->embedding('hello')->content ),
    'the same body the sync path builds';
  is_deeply $json->decode( $second->content )->{input}, [ 'a', 'b' ], 'batch sent as one input array';
};

subtest 'simple_embedding_f fails with the sync croak text on an HTTP error' => sub {
  my $mock = Test::MockAsyncHTTP->new( responses => [
    mock_json({ error => { message => 'Invalid API key' } }, status => 401, reason => 'Unauthorized'),
  ] );
  my $f = openai($mock)->simple_embedding_f('hello');
  ok $f->is_failed, 'future fails';
  like scalar $f->failure, qr/401 Unauthorized.*Invalid API key/s, 'status and provider error in the failure';
};

subtest 'simple_transcription_f / simple_transcription_result_f send the multipart upload' => sub {
  my $mock = Test::MockAsyncHTTP->new( responses => [
    mock_json({ text => 'hello world' }),
    mock_json({ text => 'hello world', language => 'en', duration => 1.5,
      words => [ { word => 'hello', start => 0, end => 0.5 } ] }),
  ] );
  my $e = Langertha::Engine::Whisper->new( url => 'http://mock.invalid/v1', _async_http => $mock );
  my $audio = "RIFF\0\x01\x02\xff" x 16;

  is $e->simple_transcription_f( \$audio, filename => 'speech.wav', language => 'en' )->get,
    'hello world', 'resolves to the transcript text';
  my $result = $e->simple_transcription_result_f( \$audio, filename => 'speech.wav',
    response_format => 'verbose_json' )->get;
  is ref $result, 'HASH', 'result variant resolves to a HashRef';
  is $result->{words}[0]{word}, 'hello', 'verbose fields kept';

  my ($request) = $mock->requests;
  is $request->uri->path, '/v1/audio/transcriptions', 'transcriptions endpoint';
  like $request->header('Content-Type'), qr{\Amultipart/form-data; boundary=}, 'multipart body';
  my %parts = map { ( $_->header('Content-Disposition') =~ /name="([^"]+)"/ )[0] => $_ } $request->parts;
  is $parts{file}->content, $audio, 'audio bytes intact in the file part';
  like $parts{file}->header('Content-Disposition'), qr/filename="speech\.wav"/, 'filename sent';
  is $parts{language}->content, 'en', 'extra field sent';
};

subtest 'simple_image_f resolves to the image objects' => sub {
  my $mock = Test::MockAsyncHTTP->new( responses => [
    mock_json({ created => 1, data => [ { b64_json => 'aGk=' } ] }),
    mock_json({ created => 1, data => [] }),
  ] );
  my $e = openai($mock);
  is_deeply $e->simple_image_f( 'A cat', size => '1024x1024' )->get, [ { b64_json => 'aGk=' } ],
    'ArrayRef of image objects';
  my ($request) = $mock->requests;
  is $request->uri->path, '/v1/images/generations', 'images endpoint';
  is $json->decode( $request->content )->{size}, '1024x1024', '%extra reaches the body';

  my $f = $e->simple_image_f('A dog');
  ok $f->is_failed, 'an answer without image fails the future';
  like scalar $f->failure, qr/image response contained no image/, 'with the sync croak text (k290)';
};

# A hook that is still pending must suspend the _f call; the sync wrapper's
# ->get on it would die ("not yet ready") on a loop-less Future.
my @PENDING;

{
  package PendingHookPlugin;
  use Moose;
  extends 'Langertha::Plugin';
  sub _pending { my $f = Future->new; push @PENDING, $f; return $f }
  sub plugin_before_embedding  { my ( $self, $text ) = @_;   return _pending()->then( sub { Future->done("hooked: $text") } ) }
  sub plugin_after_embedding   { my ( $self, $t, $vec ) = @_; return Future->done( [ @$vec, 99 ] ) }
  sub plugin_before_image_gen  { my ( $self, $prompt ) = @_; return _pending()->then( sub { Future->done("hooked: $prompt") } ) }
  sub plugin_after_image_gen   { my ( $self, $p, $res ) = @_; return Future->done( [ @$res, { url => 'after' } ] ) }
  __PACKAGE__->meta->make_immutable;
}

for my $case (
  [ 'Embedder without model override', {} ],
  [ 'Embedder with model override',    { model => 'text-embedding-3-small' } ],
) {
  my ( $name, $args ) = @$case;
  subtest "$name: simple_embedding_f awaits the plugin hooks" => sub {
    @PENDING = ();
    my $mock = Test::MockAsyncHTTP->new( responses => [ embedding_body([ 0.5 ]) ] );
    my $embedder = Langertha::Embedder->new( engine => openai($mock),
      plugins => [ '+PendingHookPlugin' ], %$args );
    my $f = $embedder->simple_embedding_f('text');
    ok !$f->is_ready, 'suspended while the before-hook is pending';
    is $mock->request_count, 0, 'no request before the hook resolved';
    $_->done for @PENDING;
    ok $f->is_done, 'completes once the hook resolved';
    is_deeply $f->get, [ 0.5, 99 ], 'after-hook result returned';
    my $body = $json->decode( ( $mock->requests )[0]->content );
    is $body->{input}, 'hooked: text', 'before-hook output was embedded';
    is $body->{model}, $args->{model} // 'text-embedding-3-large', 'model override honored';
  };
}

subtest 'ImageGen simple_image_f awaits the plugin hooks, keeps overrides' => sub {
  @PENDING = ();
  my $mock = Test::MockAsyncHTTP->new( responses => [ mock_json({ data => [ { url => 'u' } ] }) ] );
  my $ig = Langertha::ImageGen->new( engine => openai($mock), model => 'gpt-image-2',
    size => '512x512', plugins => [ '+PendingHookPlugin' ] );
  my $f = $ig->simple_image_f('A cat');
  ok !$f->is_ready, 'suspended while the before-hook is pending';
  $_->done for @PENDING;
  is_deeply $f->get, [ { url => 'u' }, { url => 'after' } ], 'after-hook result returned';
  my $body = $json->decode( ( $mock->requests )[0]->content );
  is $body->{prompt}, 'hooked: A cat', 'before-hook output was sent';
  is $body->{model}, 'gpt-image-2', 'model override';
  is $body->{size}, '512x512', 'size override';
};

subtest 'Embedder simple_embedding_f fails on an engine without embeddings' => sub {
  my $mock = Test::MockAsyncHTTP->new;
  my $e = Langertha::Engine::Whisper->new( url => 'http://mock.invalid/v1', _async_http => $mock );
  my $f = Langertha::Embedder->new( engine => $e )->simple_embedding_f('x');
  ok $f->is_failed, 'fails';
  like scalar $f->failure, qr/does not support embeddings/, 'same text as the sync croak';
};

done_testing;
