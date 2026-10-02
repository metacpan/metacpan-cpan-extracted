#!/usr/bin/env perl
# ABSTRACT: simple_embedding_f / simple_transcription_f / simple_image_f over real LWP and Net::Async::HTTP: sync/async parity, multipart, timeout
use strict;
use warnings;
use Test2::Bundle::More;
use lib 't/lib';

BEGIN {
  plan skip_all => 'fork-based HTTP::Daemon test not supported on Windows' if $^O eq 'MSWin32';
  eval { require Net::Async::HTTP; require IO::Async::Loop; 1 }
    or plan skip_all => 'Requires Net::Async::HTTP and IO::Async (the async backend under test)';
}

use Future;
use IO::Socket::INET;
use HTTP::Response;
use JSON::MaybeXS;
use Path::Tiny ();
use LWP::UserAgent;
use Test::LocalHTTPDaemon;
use Langertha::Request::SyncHTTP;
use Langertha::Engine::OpenAI;

# karr k292 (ADR 0027): the _f variants of embedding, transcription and image
# generation must answer exactly like the sync methods on every backend --
# Net::Async::HTTP, and the sync LWP shim a clean install falls back to --
# with the same value and the same error text, and the multipart audio upload
# must survive Net::Async::HTTP byte for byte. They go through
# _async_do_request_f, so user_agent_timeout (k278) bounds them: before, an
# endpoint that never answered left an async caller's Future pending forever.

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $AUDIO = join '', map { chr } 0 .. 255;   # every byte value, NULs included
my $ERROR_BODY = $json->encode({ error => { message => 'Incorrect API key provided', type => 'invalid_request_error' } });

sub json_response { HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ], $json->encode( $_[0] ) ) }

my $server = Test::LocalHTTPDaemon->start( sub {
  my ($request) = @_;
  my $path = $request->uri->path;
  return HTTP::Response->new( 401, 'Unauthorized', [ 'Content-Type' => 'application/json' ], $ERROR_BODY )
    if $path =~ m{^/unauth/};
  if ( $path =~ m{/embeddings\z} ) {
    my $input = $json->decode( $request->content )->{input};
    my @inputs = ref $input ? @$input : ($input);
    return json_response({ object => 'list', model => 'm',
      data => [ map { { index => $_, embedding => [ $_ + 0.5, length $inputs[$_] ] } } reverse 0 .. $#inputs ] });
  }
  if ( $path =~ m{/audio/transcriptions\z} ) {
    my %parts = map { ( $_->header('Content-Disposition') =~ /name="([^"]+)"/ )[0] => $_ } $request->parts;
    my $file = $parts{file};
    my ($filename) = $file->header('Content-Disposition') =~ /filename="([^"]*)"/;
    my $intact = $file->content eq $AUDIO ? 'intact' : 'CORRUPT';
    # gpt-transcribe gets the caller's language as languages[] (k313).
    my $language = $parts{'languages[]'} // $parts{language};
    return json_response({ text => "$filename $intact " . $parts{model}->content . ' ' . $language->content });
  }
  if ( $path =~ m{/images/generations\z} ) {
    my $body = $json->decode( $request->content );
    return json_response({ created => 1, data => [ { url => "img:$body->{prompt}:$body->{size}" } ] });
  }
  return HTTP::Response->new( 404, 'Not Found' );
} );
my $base = $server->url;

my $loop = IO::Async::Loop->new;

sub engine {
  my ( $url, $backend, %args ) = @_;
  my $e = Langertha::Engine::OpenAI->new( api_key => 'sk-test', url => $url, %args,
    $backend eq 'shim' ? ( _async_http => Langertha::Request::SyncHTTP->new( user_agent => LWP::UserAgent->new ) ) : () );
  ok $e->_async_http->isa('Net::Async::HTTP'), 'engine runs on Net::Async::HTTP' if $backend eq 'nahttp';
  return $e;
}

# Runs one call on all three paths; returns { sync|nahttp|shim => { value, error } }.
sub run_all {
  my ( $url, $method, @args ) = @_;
  my %out;
  my $sync = engine( $url, 'sync' );
  $out{sync} = eval { { value => $sync->$method(@args), error => '' } } // { error => $@ };
  for my $backend (qw( nahttp shim )) {
    my $e = engine( $url, $backend );
    my $method_f = "${method}_f";
    my $f = $e->$method_f(@args);
    $loop->await($f) unless $f->is_ready;
    $out{$backend} = $f->is_done ? { value => $f->get, error => '' } : { error => scalar $f->failure };
  }
  # croak names the caller's line: the same message, reported from two places.
  s/ at \S+ line \d+\.?\n?\z// for map { $_->{error} } values %out;
  return \%out;
}

sub parity {
  my ( $out, $want, $label ) = @_;
  for my $backend (qw( sync nahttp shim )) {
    is $out->{$backend}{error}, '', "$label: no error ($backend)";
    is_deeply $out->{$backend}{value}, $want, "$label: value ($backend)";
  }
}

subtest 'simple_embedding_f: same vectors on every backend' => sub {
  parity( run_all( "$base/ok/v1", 'simple_embedding', 'hello' ), [ 0.5, 5 ], 'string' );
  parity( run_all( "$base/ok/v1", 'simple_embedding', [ 'a', 'bcd' ] ), [ [ 0.5, 1 ], [ 1.5, 3 ] ],
    'batch, reordered by index' );
};

subtest 'simple_transcription_f: multipart audio arrives intact on every backend' => sub {
  parity( run_all( "$base/ok/v1", 'simple_transcription', \$AUDIO, filename => 'speech.wav', language => 'de' ),
    'speech.wav intact gpt-transcribe de', 'bytes' );
  my $path = Path::Tiny->tempfile( SUFFIX => '.mp3' );
  $path->spew_raw($AUDIO);
  parity( run_all( "$base/ok/v1", 'simple_transcription', "$path", language => 'en' ),
    $path->basename . ' intact gpt-transcribe en', 'file path' );
  parity( run_all( "$base/ok/v1", 'simple_transcription_result', \$AUDIO, filename => 'a.wav', language => 'en' ),
    { text => 'a.wav intact gpt-transcribe en' }, 'result HashRef' );
};

subtest 'simple_image_f: same image objects on every backend' => sub {
  parity( run_all( "$base/ok/v1", 'simple_image', 'cat', size => '256x256' ), [ { url => 'img:cat:256x256' } ], 'image' );
};

subtest 'an HTTP error fails every _f call with the sync croak text' => sub {
  for my $call (
    [ 'simple_embedding', 'hello' ],
    [ 'simple_transcription', \$AUDIO, filename => 'a.wav' ],
    [ 'simple_transcription_result', \$AUDIO, filename => 'a.wav' ],
    [ 'simple_image', 'cat' ],
  ) {
    my ( $method, @args ) = @$call;
    my $out = run_all( "$base/unauth/v1", $method, @args );
    like $out->{sync}{error}, qr/401 Unauthorized.*Incorrect API key provided/s, "$method: sync croaks";
    is $out->{$_}{error}, $out->{sync}{error}, "$method: $_ fails with the same text" for qw( nahttp shim );
  }
};

subtest 'user_agent_timeout bounds the _f calls on Net::Async::HTTP (k278)' => sub {
  # Accepts connections (the kernel completes the handshake) and never answers.
  my $hang = IO::Socket::INET->new( Listen => 5, LocalAddr => '127.0.0.1', LocalPort => 0,
    Proto => 'tcp', ReuseAddr => 1 ) or die "listen: $!";
  my $hang_url = 'http://127.0.0.1:' . $hang->sockport . '/v1';
  for my $call (
    [ 'simple_embedding_f', 'hello' ],
    [ 'simple_transcription_f', \$AUDIO, filename => 'a.wav' ],
    [ 'simple_transcription_result_f', \$AUDIO, filename => 'a.wav' ],
    [ 'simple_image_f', 'cat' ],
  ) {
    my ( $method, @args ) = @$call;
    my $e = engine( $hang_url, 'nahttp', user_agent_timeout => 1 );
    my $f = $e->$method(@args);
    my $cap = $loop->delay_future( after => 10 );
    $loop->await( Future->wait_any( $f->without_cancel, $cap ) );
    $cap->cancel unless $cap->is_ready;
    ok $f->is_failed, "$method fails instead of hanging";
    my ( $message, $category ) = $f->is_failed ? $f->failure : ( '', '' );
    like $message, qr/\ALangertha::Engine::OpenAI: request to http:\/\/127\.0\.0\.1:\d+\/v1\/\S+ timed out after 1s\n\z/,
      "$method: engine-named timeout";
    is $category, 'timeout', "$method: timeout category";
  }
};

done_testing;
