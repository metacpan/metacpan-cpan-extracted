#!/usr/bin/env perl
# ABSTRACT: Tests for the langertha_whisper CLI against a Whisper server

use strict;
use warnings;

use Test2::Bundle::More;

# karr k370: speaches (the successor of faster-whisper-server) requires a
# model field and answers 422 without one. bin/langertha_whisper offers
# LANGERTHA_WHISPER_WHISPER_MODEL for that, but handed it to Whisper's `model`,
# which transcription never reads (transcription_model defaults to '') -- so
# the documented variable had no effect and the CLI could not talk to speaches
# at all. The daemon below answers like speaches did live (422 detail without
# a model, the captured text body with one).

use lib 't/lib';
use Test::LocalHTTPDaemon;

use HTTP::Response;
use IPC::Open3 qw( open3 );
use Path::Tiny qw( path );
use Symbol qw( gensym );

my $root   = path(__FILE__)->absolute->parent->parent;
my $script = $root->child('bin/langertha_whisper');
my $data   = $root->child('t/data');

sub run_cli {
  my ( %request ) = @_;
  my @include = map { ( '-I', "$_" ) } grep { !ref } @INC;
  local %ENV = (
    PATH             => $ENV{PATH} // '',
    LANG             => 'C.UTF-8',
    LC_ALL           => 'C.UTF-8',
    LANGERTHA_NO_TIME => 1,
    %{ $request{environment} },
  );
  my $stderr = gensym;
  my $pid = open3( my $stdin, my $stdout, $stderr, $^X, @include, "$script", @{ $request{arguments} } );
  close $stdin;
  my $stdout_text = do { local $/; <$stdout> // '' };
  my $stderr_text = do { local $/; <$stderr> // '' };
  waitpid $pid, 0;
  return { stdout => $stdout_text, stderr => $stderr_text, exit => $? >> 8 };
}

my $transcript = $data->child('speaches_transcription_text.txt')->slurp_raw;
my $server = Test::LocalHTTPDaemon->start( sub {
  my ( $request ) = @_;
  # Like speaches started with API_KEY: any other bearer key is refused with
  # 403. The engine's placeholder key 'whisper' stands in for a server that
  # checks none.
  my $auth = $request->header('Authorization') // '';
  return HTTP::Response->new( 403, 'Forbidden', [ 'Content-Type' => 'application/json' ],
    '{"detail":"Invalid API key"}' )
    unless $auth eq 'Bearer whisper' || $auth eq 'Bearer secret-key';
  my ( $model ) = $request->content =~ /name="model"\r\n\r\n([^\r]*)\r\n/;
  return HTTP::Response->new( 422, 'Unprocessable Entity', [ 'Content-Type' => 'application/json' ],
    $data->child('speaches_transcription_error_no_model.json')->slurp_raw )
    unless defined $model && length $model;
  return HTTP::Response->new( 404, 'Not Found', [ 'Content-Type' => 'application/json' ],
    '{"detail":"Model \'' . $model . '\' is not installed locally."}' )
    unless $model eq 'Systran/faster-whisper-tiny.en';
  return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ],
    '{"text":"' . $transcript . '","logprobs":null,"usage":null}' );
});

my $tempdir = Path::Tiny->tempdir;
my $audio   = $tempdir->child('sample.ogg');
$audio->spew_raw("OggS\0\0\0\0");

my $run = run_cli(
  environment => {
    LANGERTHA_WHISPER_WHISPER_URL   => $server->url . '/v1',
    LANGERTHA_WHISPER_WHISPER_MODEL => 'Systran/faster-whisper-tiny.en',
  },
  arguments => [ "$audio" ],
);
is( $run->{exit}, 0, 'LANGERTHA_WHISPER_WHISPER_MODEL: exits 0' ) or diag( $run->{stderr} );
is( $run->{stdout}, $transcript, 'LANGERTHA_WHISPER_WHISPER_MODEL reaches the model field' );

$run = run_cli(
  environment => { LANGERTHA_WHISPER_WHISPER_URL => $server->url . '/v1' },
  arguments   => [ "$audio" ],
);
isnt( $run->{exit}, 0, 'without a model the server error fails the CLI' );
like( $run->{stderr}, qr/422 Unprocessable Entity.*"msg":"Field required"/, 'and shows the server detail' );

# LANGERTHA_WHISPER_WHISPER_API_KEY reaches the Authorization header: the
# right key passes, a wrong one is refused by the server.
$run = run_cli(
  environment => {
    LANGERTHA_WHISPER_WHISPER_URL     => $server->url . '/v1',
    LANGERTHA_WHISPER_WHISPER_MODEL   => 'Systran/faster-whisper-tiny.en',
    LANGERTHA_WHISPER_WHISPER_API_KEY => 'secret-key',
  },
  arguments => [ "$audio" ],
);
is( $run->{exit}, 0, 'LANGERTHA_WHISPER_WHISPER_API_KEY: the right key passes' ) or diag( $run->{stderr} );

$run = run_cli(
  environment => {
    LANGERTHA_WHISPER_WHISPER_URL     => $server->url . '/v1',
    LANGERTHA_WHISPER_WHISPER_MODEL   => 'Systran/faster-whisper-tiny.en',
    LANGERTHA_WHISPER_WHISPER_API_KEY => 'wrong-key',
  },
  arguments => [ "$audio" ],
);
isnt( $run->{exit}, 0, 'a wrong LANGERTHA_WHISPER_WHISPER_API_KEY is sent and refused' );
like( $run->{stderr}, qr/403/, 'with the server status' );

done_testing;
