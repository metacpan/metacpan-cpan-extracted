#!/usr/bin/env perl
# ABSTRACT: Mistral Voxtral transcription: multipart request, extras, response parsing

use strict;
use warnings;

use Test2::Bundle::More;
use lib 't/lib';

use HTTP::Response;
use JSON::MaybeXS;
use Path::Tiny qw( path );
use Test::MockAsyncHTTP;

use Langertha::Engine::Mistral;

# karr k309: Mistral serves Voxtral transcription on /v1/audio/transcriptions
# (OpenAI-shape multipart), but the engine did not compose
# Role::Transcription -- a Mistral user had no way to transcribe, and the POD
# said "transcription is not available". The engine must send the upload to
# Mistral's own path with voxtral-mini-latest (the OpenAI default
# gpt-transcribe is not served there), pass diarize / context_bias /
# timestamp_granularities through, and send the list-valued ones as one part
# per element: an ArrayRef under the plain spec name would otherwise be taken
# for a file spec and its first element opened as a path (k286). Those parts
# carry the PLAIN name, no [] (k315): Mistral's SDKs (Speakeasy multipart
# "standard") and its curl docs send repeated timestamp_granularities /
# context_bias parts, and a name[] key risks being silently dropped.
#
# Fixture provenance (k310): mistral_transcription_capture.json and
# mistral_transcription_segments_capture.json are verbatim captures (Mistral
# voxtral-mini-latest, 2026-09-30, a 6 s English ogg; the second with
# timestamp_granularities=segment; headers files keep only content-type).
# mistral_transcription_doc.json (the 200 example of Mistral's API reference,
# docs.mistral.ai/api/endpoint/audio/transcriptions, also in share/mistral.yaml,
# long text shortened) and mistral_transcription_segments_doc.json (built from
# the TranscriptionSegmentChunk schema of the same spec) stay documentation-
# derived: the capture has speaker_id null and no diarized speakers.

my $boundary = 'XyXLaXyXngXyXerXyXthXyXaXyX';
my $data_dir = path(__FILE__)->parent->child('data');
my $file     = $data_dir->child('testfile')->absolute;
my $json     = JSON::MaybeXS->new->canonical(1)->utf8(1);

my $mistral = Langertha::Engine::Mistral->new( api_key => 'test-key' );

sub parts {
  my ( $content ) = @_;
  my @parts;
  while ( $content =~ /name="([^"]+)"(?:; filename="[^"]*")?\r\n(?:[^\r\n]+\r\n)*\r\n(.*?)\r\n--\Q$boundary\E/sg ) {
    push @parts, [ $1, $2 ];
  }
  return @parts;
}

subtest 'composition and defaults' => sub {
  ok( $mistral->does('Langertha::Role::Transcription'), 'Mistral does Transcription' );
  ok( $mistral->supports('transcription'), 'supports transcription' );
  is( $mistral->transcription_model, 'voxtral-mini-latest', 'default transcription_model' );
};

subtest 'request: Mistral path, multipart, voxtral model, Bearer auth' => sub {
  my $req = $mistral->transcription( $file, language => 'en' );
  is( $req->method, 'POST', 'POST' );
  is( $req->uri, 'https://api.mistral.ai/v1/audio/transcriptions', 'Mistral transcription endpoint' );
  like( $req->header('Content-Type'), qr{\Amultipart/form-data; boundary=}, 'multipart body' );
  is( $req->header('Authorization'), 'Bearer test-key', 'Bearer auth' );
  is_deeply( [ parts( $req->content ) ], [
    [ file     => 'testxxxx' ],
    [ language => 'en' ],
    [ model    => 'voxtral-mini-latest' ],
  ], 'file, language and model parts' );
};

subtest 'extras: diarize, context_bias, timestamp_granularities' => sub {
  my $req = $mistral->transcription( $file,
    diarize                 => 'true',
    context_bias            => [qw( Langertha Voxtral )],
    timestamp_granularities => [qw( segment word )],
  );
  is_deeply( [ parts( $req->content ) ], [
    [ context_bias            => 'Langertha' ],
    [ context_bias            => 'Voxtral' ],
    [ diarize                 => 'true' ],
    [ file                    => 'testxxxx' ],
    [ model                   => 'voxtral-mini-latest' ],
    [ timestamp_granularities => 'segment' ],
    [ timestamp_granularities => 'word' ],
  ], 'ArrayRef extras become one text part per element under the plain name (k315)' );
  unlike( $req->content, qr/name="[^"]*\[\]"/, 'no [] key on the Mistral wire (k315)' );

  my $bracket = $mistral->transcription( $file, 'timestamp_granularities[]' => ['segment'] );
  is_deeply( [ grep { $_->[0] =~ /timestamp/ } parts( $bracket->content ) ],
    [ [ timestamp_granularities => 'segment' ] ],
    'the [] spelling is normalized to the plain name Mistral reads (k315)' );

  my $scalar = $mistral->transcription( $file, context_bias => 'Langertha' );
  like( $scalar->content, qr/name="context_bias"\r\n\r\nLangertha\r\n/, 'a scalar extra is sent as given' );
};

sub fixture_http {
  my ( $name ) = @_;
  my $headers = $json->decode( $data_dir->child("$name.headers.json")->slurp_raw );
  my $http    = HTTP::Response->new( 200, 'OK' );
  $http->header( $_ => $headers->{$_} ) for sort keys %$headers;
  $http->content( $data_dir->child("$name.json")->slurp_raw );
  return $http;
}

subtest 'response parsing (transcription_result, k288)' => sub {
  my $http = fixture_http('mistral_transcription_doc');
  like( $mistral->transcription_response($http), qr/\AThis week, I traveled to Chicago/, 'text' );
  my $result = $mistral->transcription_result($http);
  is( $result->{language}, 'en', 'language kept' );
  is( $result->{usage}{prompt_audio_seconds}, 203, 'usage kept' );

  my $diarized = $mistral->transcription_result( fixture_http('mistral_transcription_segments_doc') );
  is_deeply( [ map { [ $_->{speaker_id}, $_->{start} ] } @{ $diarized->{segments} } ],
    [ [ speaker_0 => 0 ], [ speaker_1 => 1.4 ] ], 'diarized segments with timing reachable' );
};

subtest 'response parsing: real captures (language null, finish_reason null, extra usage)' => sub {
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my $http = fixture_http('mistral_transcription_capture');
  is( $mistral->transcription_response($http),
    'This is an example sound file in Augvorbis format from Wikipedia, the free encyclopedia.', 'text' );
  my $result = $mistral->transcription_result($http);
  is( $result->{model}, 'voxtral-mini-latest', 'model kept' );
  ok( exists $result->{language} && !defined $result->{language}, 'language null stays undef' );
  is_deeply( $result->{segments}, [], 'segments empty without a granularity' );
  ok( !defined $result->{finish_reason}, 'finish_reason null' );
  is( $result->{usage}{prompt_audio_seconds}, 6, 'usage.prompt_audio_seconds' );
  is( $result->{usage}{prompt_tokens_details}{audio_tokens}, 375, 'usage.prompt_tokens_details kept' );
  is( $result->{usage}{service_tier}, 'standard', 'service_tier kept' );

  my $seg = $mistral->transcription_result( fixture_http('mistral_transcription_segments_capture') );
  is( scalar @{ $seg->{segments} }, 1, 'one segment' );
  is( $seg->{segments}[0]{type}, 'transcription_segment', 'segment type' );
  is( $seg->{segments}[0]{end}, 6, 'segment end' );
  ok( exists $seg->{segments}[0]{speaker_id} && !defined $seg->{segments}[0]{speaker_id}, 'speaker_id null without diarize' );
  is_deeply( \@warnings, [], 'no warnings on null fields' ) or diag(@warnings);
};

subtest 'simple_transcription_f / simple_transcription_result_f over the async backend' => sub {
  my $body = $data_dir->child('mistral_transcription_segments_doc.json')->slurp_raw;
  my $mock = Test::MockAsyncHTTP->new( responses => [
    Test::MockAsyncHTTP->mock_json_response( $json->decode($body) ),
    Test::MockAsyncHTTP->mock_json_response( $json->decode($body) ),
  ] );
  my $engine = Langertha::Engine::Mistral->new( api_key => 'k', _async_http => $mock );
  is( $engine->simple_transcription_f( \"RIFF\0audio", filename => 'a.wav' )->get,
    'Hello there. Hi, how are you?', 'simple_transcription_f resolves to the text' );
  my $result = $engine->simple_transcription_result_f( $file, diarize => 'true',
    timestamp_granularities => ['segment'] )->get;
  is( scalar @{ $result->{segments} }, 2, 'simple_transcription_result_f keeps segments' );
  my ( undef, $second ) = $mock->requests;
  is( $second->uri->path, '/v1/audio/transcriptions', 'async request on the Mistral path' );
  like( $second->content, qr/name="timestamp_granularities"\r\n\r\nsegment\r\n/,
    'async request carries the extras' );
};

done_testing;
