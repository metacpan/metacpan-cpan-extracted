#!/usr/bin/env perl
# ABSTRACT: Transcription answers in every response_format (json, verbose_json, text, srt, vtt)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use HTTP::Response;
use Path::Tiny qw( path );

use lib 't/lib';
use Test::LocalHTTPDaemon;

use Langertha::Engine::Whisper;

# karr k288. The transcription endpoints (OpenAI, Groq, faster-whisper) take
# response_format json | verbose_json | text | srt | vtt, and the POD
# advertises %extra pass-through -- but transcription_response ran every body
# through the JSON decoder, so text/srt/vtt croaked with a bare "malformed
# JSON string", and verbose_json kept only ->{text}, silently dropping the
# segments and word timestamps the caller asked for.
#
# Fixture provenance (k310): the openai_transcription_* fixtures are NOT
# captures -- they follow the response examples of OpenAI's audio API reference
# (platform.openai.com/docs/api-reference/audio); the OpenAI account had no
# credits on 2026-09-30 (HTTP 429 insufficient_quota), so they stay
# documentation-derived, including the assumed srt/vtt Content-Type. The
# groq_transcription_{json,verbose_json,text} fixtures ARE verbatim captures
# (Groq whisper-large-v3-turbo, 2026-09-30, a 6 s English ogg; the headers
# files keep only content-type).

my $data_dir = path(__FILE__)->parent->child('data');
my $json     = JSON::MaybeXS->new->canonical(1)->utf8(1);

sub fixture_http {
  my ( $name, $ext ) = @_;
  my $body    = $data_dir->child("$name.$ext")->slurp_raw;
  my $headers = $json->decode( $data_dir->child("$name.headers.json")->slurp_raw );
  my $http    = HTTP::Response->new(200, 'OK');
  $http->header( $_ => $headers->{$_} ) for sort keys %$headers;
  $http->content($body);
  return $http;
}

my $whisper = Langertha::Engine::Whisper->new( url => 'http://127.0.0.1:1/v1' );

subtest 'json' => sub {
  my $http = fixture_http('openai_transcription_json', 'json');
  like($whisper->transcription_response($http), qr/\AImagine the wildest idea/, 'text field');
  my $result = $whisper->transcription_result($http);
  is($result->{usage}{total_tokens}, 59, 'result keeps usage');
};

subtest 'verbose_json keeps segments and words' => sub {
  my $http = fixture_http('openai_transcription_verbose_json', 'json');
  is($whisper->transcription_response($http), 'The beach was a popular spot on a hot summer day.', 'text');
  my $result = $whisper->transcription_result($http);
  is($result->{language}, 'english', 'language');
  is(scalar @{ $result->{segments} }, 1, 'segments reachable');
  is($result->{segments}[0]{end}, 3.319999933242798, 'segment timing');
  is_deeply([ map { $_->{word} } @{ $result->{words} } ], [qw( The beach )], 'word timestamps reachable');
};

subtest 'text is decoded as UTF-8' => sub {
  my $http = fixture_http('openai_transcription_text', 'txt');
  is($whisper->transcription_response($http), "Gr\x{fc}\x{df}e aus Berlin.\n", 'plain body, characters');
  $http->header( 'Content-Type' => 'text/plain' );    # no charset named
  is($whisper->transcription_response($http), "Gr\x{fc}\x{df}e aus Berlin.\n", 'UTF-8 without a charset parameter');
};

subtest 'srt and vtt return the subtitle body' => sub {
  my $srt = $whisper->transcription_response( fixture_http('openai_transcription_srt', 'txt') );
  like($srt, qr/\A1\n00:00:00,000 --> 00:00:03,320\nThe beach/, 'srt');
  my $vtt = $whisper->transcription_response( fixture_http('openai_transcription_vtt', 'txt') );
  like($vtt, qr/\AWEBVTT\n\n00:00:00\.000 --> /, 'vtt');

  my $http = fixture_http('openai_transcription_srt', 'txt');
  $http->header( 'Content-Type' => 'application/x-subrip' );
  is($whisper->transcription_response($http), $srt, 'a non-text, non-JSON type is still read as text');
};

subtest 'JSON sniffed only when the type says neither' => sub {
  my $http = fixture_http('openai_transcription_json', 'json');
  $http->remove_header('Content-Type');
  like($whisper->transcription_response($http), qr/\AImagine/, 'untyped JSON body decoded');
  my $text = HTTP::Response->new(200, 'OK', [ 'Content-Type' => 'text/plain' ], "{curly} start\n");
  is($whisper->transcription_response($text), "{curly} start\n", 'text/plain body starting with { stays text');
};

subtest 'errors still croak with the engine and body' => sub {
  my $http = HTTP::Response->new(400, 'Bad Request', [ 'Content-Type' => 'text/plain' ], 'Invalid file format.');
  ok(!eval { $whisper->transcription_response($http); 1 }, 'croaks');
  like($@, qr/Whisper request failed: 400 Bad Request - Invalid file format\./, 'message');
};

# karr k295: Groq answers response_format json with an extra x_groq object
# (the request id a Groq support ticket asks for). Groq composes the same
# OpenAICompatible parser; transcription_result must keep the provider's
# fields, not rebuild a { text } hash. Fixture: verbatim Groq capture of
# 2026-09-30 (whisper-large-v3-turbo), k310.
subtest 'Groq json keeps x_groq' => sub {
  require Langertha::Engine::Groq;
  my $groq = Langertha::Engine::Groq->new( api_key => 'gsk-test' );
  my $http = fixture_http('groq_transcription_json', 'json');
  is($groq->transcription_response($http), ' This is an example sound file in org-forbus format from Wikipedia, the free encyclopedia.', 'text (Groq keeps the leading space)');
  is($groq->transcription_result($http)->{x_groq}{id}, 'req_01m3rcex7sevcvf7ncrhj1scv9', 'x_groq.id kept');
};

subtest 'Groq verbose_json capture: segments, no words, x_groq' => sub {
  require Langertha::Engine::Groq;
  my $groq = Langertha::Engine::Groq->new( api_key => 'gsk-test' );
  my $http = fixture_http('groq_transcription_verbose_json', 'json');
  like($groq->transcription_response($http), qr/\A This is an example sound file/, 'text');
  my $result = $groq->transcription_result($http);
  is($result->{language}, 'English', 'language is the English name, not a code');
  is($result->{duration}, 6.104062464, 'duration');
  is(scalar @{ $result->{segments} }, 1, 'segments reachable');
  is($result->{segments}[0]{end}, 5.8399997, 'segment timing');
  ok(!exists $result->{words}, 'no words unless word granularity was asked for');
  is($result->{x_groq}{id}, 'req_01m3rcexk4exkskfr8hmq9ptdp', 'x_groq.id kept');
};

subtest 'Groq text capture: upper-case charset=UTF-8 read as text' => sub {
  require Langertha::Engine::Groq;
  my $groq = Langertha::Engine::Groq->new( api_key => 'gsk-test' );
  my $http = fixture_http('groq_transcription_text', 'txt');
  is($http->header('Content-Type'), 'text/plain; charset=UTF-8', 'fixture carries the real header');
  is($groq->transcription_response($http),
    ' This is an example sound file in org-forbus format from Wikipedia, the free encyclopedia.',
    'plain body, no trailing newline on the wire');
};

subtest 'simple_transcription_result round trip' => sub {
  my $body = $data_dir->child('openai_transcription_verbose_json.json')->slurp_raw;
  my $server = Test::LocalHTTPDaemon->start(sub {
    my ( $request ) = @_;
    my $content = $request->content;
    my $ok = $content =~ /name="response_format"\r\n\r\nverbose_json\r\n/
      && $content =~ /name="timestamp_granularities\[\]"\r\n\r\nword\r\n.*name="timestamp_granularities\[\]"\r\n\r\nsegment\r\n/s;
    return $ok
      ? HTTP::Response->new(200, 'OK', [ 'Content-Type' => 'application/json' ], $body)
      : HTTP::Response->new(400, 'Bad Request', [ 'Content-Type' => 'text/plain' ], 'unexpected form');
  });
  my $engine = Langertha::Engine::Whisper->new( url => $server->url.'/v1' );
  my $audio = "RIFF\0\0\0\0WAVE";
  my $result = eval {
    $engine->simple_transcription_result(\$audio,
      filename => 'a.wav',
      response_format => 'verbose_json',
      'timestamp_granularities[]' => [qw( word segment )],
    );
  };
  ok(defined $result, 'result returned') or diag($@);
  is($result->{words}[1]{word}, 'beach', 'words from the server answer') if $result;
};

done_testing;
