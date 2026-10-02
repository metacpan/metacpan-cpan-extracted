#!/usr/bin/env perl
# ABSTRACT: Test Whisper transcription request generation

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use Path::Tiny;
use HTTP::Request;

use Langertha::Engine::Whisper;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

my $whisper_testurl = 'http://test.url:12345/v1';
my $whisper = Langertha::Engine::Whisper->new(
  url => $whisper_testurl,
  transcription_model => 'model',
);
my $whisper_request = $whisper->transcription(path(__FILE__)->parent->child('data/testfile')->absolute, language => 'en');
is($whisper_request->uri, $whisper_testurl.'/audio/transcriptions', 'Whisper request uri is correct');
is($whisper_request->method, 'POST', 'Whisper request method is correct');
is($whisper_request->header('Content-Type'), 'multipart/form-data; boundary="XyXLaXyXngXyXerXyXthXyXaXyX"', 'Whisper request Content Type is correct');
my $content = "--XyXLaXyXngXyXerXyXthXyXaXyX
Content-Disposition: form-data; name=\"file\"; filename=\"testfile\"
Content-Type: application/octet-stream

testxxxx
--XyXLaXyXngXyXerXyXthXyXaXyX
Content-Disposition: form-data; name=\"language\"

en
--XyXLaXyXngXyXerXyXthXyXaXyX
Content-Disposition: form-data; name=\"model\"

model
--XyXLaXyXngXyXerXyXthXyXaXyX--
"; $content =~ s/\n/\r\n/g;
is($whisper_request->content, $content, 'Whisper request content is correct');

# karr k286: the multipart body must follow the same rules as the JSON body --
# character strings go out as UTF-8 (a prompt in German must reach the server
# as German, not Latin-1 mojibake or a "content must be bytes" croak), the
# Content-Type boundary is the one the body really uses, and OpenAI's
# multi-valued fields (timestamp_granularities[]) are repeated text parts, not
# file paths to open.
my $file = path(__FILE__)->parent->child('data/testfile')->absolute;
my $boundary = 'XyXLaXyXngXyXerXyXthXyXaXyX';
my $multipart = sub {
  my ( @parts ) = @_;
  my $body = join('', map { "--$boundary\r\n$_\r\n" } @parts)."--$boundary--\r\n";
  return $body;
};

{
  my $req = $whisper->transcription($file, prompt => "Gr\x{fc}\x{df}e \x{2603}");
  ok(!utf8::is_utf8($req->content), 'body with a wide-char prompt is bytes');
  my ($prompt) = $req->content =~ /name="prompt"\r\n\r\n(.*?)\r\n--/s;
  is($prompt, "Gr\xc3\xbc\xc3\x9fe \xe2\x98\x83", 'wide-char prompt is sent UTF-8 encoded');

  my $latin = "Gr\x{fc}\x{df}e";
  utf8::downgrade($latin);    # characters < 0x100 held without the UTF-8 flag
  ($prompt) = $whisper->transcription($file, prompt => $latin)->content =~ /name="prompt"\r\n\r\n(.*?)\r\n--/s;
  is($prompt, "Gr\xc3\xbc\xc3\x9fe", 'Latin-1 range prompt is sent UTF-8 encoded too, as in a JSON body');
}

{
  my $req = $whisper->transcription($file,
    'timestamp_granularities[]' => [qw( word segment )],
    response_format => 'verbose_json',
  );
  is($req->content, $multipart->(
    "Content-Disposition: form-data; name=\"file\"; filename=\"testfile\"\r\nContent-Type: application/octet-stream\r\n\r\ntestxxxx",
    "Content-Disposition: form-data; name=\"model\"\r\n\r\nmodel",
    "Content-Disposition: form-data; name=\"response_format\"\r\n\r\nverbose_json",
    "Content-Disposition: form-data; name=\"timestamp_granularities[]\"\r\n\r\nword",
    "Content-Disposition: form-data; name=\"timestamp_granularities[]\"\r\n\r\nsegment",
  ), 'ArrayRef under a [] key becomes repeated text fields, in order');
}

{
  my $req = $whisper->transcription($file, prompt => "x $boundary y");
  my ($used) = $req->header('Content-Type') =~ /boundary="([^"]+)"/;
  isnt($used, $boundary, 'a prompt containing the default boundary forces another one');
  like($req->content, qr/\A--\Q$used\E\r\n/, 'Content-Type boundary is the one the body starts with');
  like($req->content, qr/\r\n--\Q$used\E--\r\n\z/, 'Content-Type boundary is the one the body ends with');
}

{
  my $dir = Path::Tiny->tempdir;
  my $name = "Gr\xc3\xbc\xc3\x9fe \xe2\x98\x83.wav";    # UTF-8 bytes, as readdir/ARGV give them
  $dir->child($name)->spew_raw('abc');
  my $req = $whisper->transcription($dir->child($name)->stringify);
  like($req->content, qr/; filename="\Q$name\E"\r\n/, 'undecoded (byte) path: filename sent unchanged as raw UTF-8');

  my ($body) = $whisper->generate_multipart_body($req,
    file => [ undef, "Gr\x{fc}\x{df}e \x{2603}.wav", Content => 'abc' ],
  );
  like($body, qr/; filename="\Q$name\E"\r\n/, 'decoded (character) filename is sent UTF-8 encoded');
}

# karr k287: simple_transcription($audio_bytes) is documented, so in-memory
# audio must become the file part's content -- never a path handed to open()
# (which croaked "Can't open file RIFF...").
{
  my $audio = "RIFF\0\x01\xff\xfeWAVEdata";
  my $expected = sub {
    my ( $filename ) = @_;
    return $multipart->(
      "Content-Disposition: form-data; name=\"file\"; filename=\"$filename\"\r\nContent-Type: application/octet-stream\r\n\r\n$audio",
      "Content-Disposition: form-data; name=\"model\"\r\n\r\nmodel",
    );
  };
  is($whisper->transcription(\$audio, filename => 'speech.wav')->content, $expected->('speech.wav'),
    'scalar ref: bytes are the part content, filename from the filename option (not a form field)');
  is($whisper->transcription(\$audio)->content, $expected->('audio'),
    'scalar ref without filename: filename defaults to audio');

  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  is($whisper->transcription($audio, filename => 'speech.wav')->content, $expected->('speech.wav'),
    'plain string with a NUL byte is content, as the POD documents');
  is(scalar @warnings, 0, 'and it never reaches open() (no "Invalid \\0 character in pathname")');

  open my $fh, '<', \$audio or die $!;
  is($whisper->transcription($fh, filename => 'speech.wav')->content, $expected->('speech.wav'),
    'filehandle: read to the end, sent as content');

  is($whisper->transcription($file, filename => 'renamed.wav')->content =~ /filename="([^"]+)"/ ? $1 : undef,
    'renamed.wav', 'path with filename option: upload renamed, content still read from the path');

  my $chars = "caf\x{e9} \x{2603}";
  ok(!eval { $whisper->transcription(\$chars); 1 }, 'character string as audio content croaks');
  like($@, qr/audio content must be bytes/, '... with a clear message');
}

# karr k293: $openai->whisper is sold as "the same engine, focused on
# transcription" -- it must not silently fall back to LWP's 180s timeout, the
# TranscriptionBase User-Agent or the default model when the parent says otherwise.
{
  require Langertha::Engine::OpenAI;
  my $openai = Langertha::Engine::OpenAI->new(
    api_key             => 'k',
    user_agent_timeout  => 7,
    user_agent_agent    => 'my-app/1.0',
    transcription_model => 'gpt-4o-transcribe',
  );
  my $w = $openai->whisper;
  is($w->transcription_model, 'gpt-4o-transcribe', 'whisper: parent transcription_model');
  is($w->user_agent_timeout, 7, 'whisper: parent user_agent_timeout');
  is($w->user_agent->timeout, 7, 'whisper: LWP gets that timeout');
  is($w->user_agent->agent, 'my-app/1.0', 'whisper: parent User-Agent');
  is($w->url, $openai->url, 'whisper: parent url');
  is($w->api_key, 'k', 'whisper: parent api_key');

  my $plain = Langertha::Engine::OpenAI->new( api_key => 'k' )->whisper;
  is($plain->transcription_model, 'gpt-transcribe', 'whisper: gpt-transcribe when the parent sets no model');
  ok(!$plain->has_user_agent_timeout, 'whisper: no timeout when the parent sets none');
}

# karr k308: OpenAI removes whisper-1 (and gpt-4o-*transcribe) on 2027-02-26;
# the OpenAI default is its successor gpt-transcribe. gpt-transcribe answers
# response_format json only, so no request may carry a defaulted
# response_format (verbose_json / srt would be a 400) -- only what the caller
# passes. Groq and self-hosted Whisper keep their own defaults.
{
  require Langertha::Engine::OpenAI;
  require Langertha::Engine::Groq;
  my $openai = Langertha::Engine::OpenAI->new( api_key => 'k' );
  is($openai->transcription_model, 'gpt-transcribe', 'OpenAI default transcription_model');
  my $req = $openai->transcription($file);
  my ($model) = $req->content =~ /name="model"\r\n\r\n(.*?)\r\n--/s;
  is($model, 'gpt-transcribe', 'OpenAI transcription request sends gpt-transcribe');
  unlike($req->content, qr/name="response_format"/, 'no defaulted response_format');
  unlike($req->content, qr/name="timestamp_granularities/, 'no defaulted timestamp_granularities');
  unlike($openai->whisper->transcription($file)->content, qr/name="response_format"/,
    'whisper handle: no defaulted response_format');
  my $explicit = $openai->transcription($file, response_format => 'text');
  like($explicit->content, qr/name="response_format"\r\n\r\ntext\r\n/,
    'a caller-set response_format is sent as given');

  is(Langertha::Engine::Groq->new( api_key => 'k' )->transcription_model,
    'whisper-large-v3', 'Groq keeps whisper-large-v3');
  is(Langertha::Engine::Whisper->new( url => $whisper_testurl )->transcription_model,
    '', 'Whisper server keeps its empty default (server picks the model)');
}

# karr k313: gpt-transcribe exists only on OpenAI. Groq, faster-whisper /
# speaches, LocalAI and other OpenAI-compatible servers do not know it, so only
# Engine::OpenAI (and its whisper handle) defaults to it; the shared
# OpenAI-compatible default -- TranscriptionBase and any third-party subclass
# of it -- is the widely accepted whisper-1 alias.
{
  require Langertha::Engine::TranscriptionBase;
  my $base = Langertha::Engine::TranscriptionBase->new( url => 'http://x/v1', api_key => 'k' );
  is($base->transcription_model, 'whisper-1',
    'TranscriptionBase defaults to whisper-1, not the OpenAI-only gpt-transcribe');
  {
    package My::ThirdPartyTranscriber;
    use Moose;
    extends 'Langertha::Engine::TranscriptionBase';
    __PACKAGE__->meta->make_immutable;
  }
  is(My::ThirdPartyTranscriber->new( url => 'http://x/v1', api_key => 'k' )->transcription_model,
    'whisper-1', 'a third-party TranscriptionBase subclass inherits whisper-1');
  is(Langertha::Engine::OpenAI->new( api_key => 'k' )->whisper->transcription_model,
    'gpt-transcribe', 'OpenAI whisper handle still gpt-transcribe');
}

# karr k313: gpt-transcribe takes `languages` (a list; multipart languages[]),
# not the singular `language`, and the two must not both be sent. A caller's
# language => 'de' must reach gpt-transcribe as languages[]; a languages
# ArrayRef must become repeated languages[] parts (not a file spec). Other
# models keep the singular field.
{
  my $fields = sub {
    my ( $req ) = @_;
    my %values;
    my $body = $req->content;
    push @{ $values{$1} }, $2 while $body =~ /name="([^"]+)"\r\n\r\n(.*?)\r\n--/sg;
    return \%values;
  };
  my $openai = Langertha::Engine::OpenAI->new( api_key => 'k' );

  my $got = $fields->( $openai->transcription($file, language => 'de') );
  is_deeply($got->{'languages[]'}, ['de'], 'gpt-transcribe: language sent as languages[]');
  ok(!exists $got->{language}, 'gpt-transcribe: no singular language field');

  $got = $fields->( $openai->transcription($file, languages => [qw( de en )]) );
  is_deeply($got->{'languages[]'}, [qw( de en )], 'gpt-transcribe: languages ArrayRef as repeated languages[]');
  unlike($openai->transcription($file, languages => [qw( de en )])->content, qr/name="languages";/,
    'gpt-transcribe: languages never sent as a file part');

  $got = $fields->( $openai->transcription($file, language => 'fr', languages => [qw( de fr )]) );
  is_deeply($got->{'languages[]'}, [qw( de fr )], 'gpt-transcribe: language merged into languages, no duplicate');
  ok(!exists $got->{language}, 'gpt-transcribe: never both fields');

  $got = $fields->( $openai->whisper->transcription($file, language => 'de') );
  is_deeply($got->{'languages[]'}, ['de'], 'whisper handle (gpt-transcribe): languages[]');

  $got = $fields->( $openai->transcription($file, model => 'gpt-transcribe-2026-07-28', language => 'de') );
  is_deeply($got->{'languages[]'}, ['de'], 'per-call gpt-transcribe snapshot: languages[]');

  $got = $fields->( $openai->transcription($file, model => 'whisper-1', language => 'de') );
  is_deeply($got->{language}, ['de'], 'per-call whisper-1: singular language unchanged');
  ok(!exists $got->{'languages[]'}, 'per-call whisper-1: no languages[]');

  my $gpt4o = Langertha::Engine::OpenAI->new( api_key => 'k', transcription_model => 'gpt-4o-transcribe' );
  $got = $fields->( $gpt4o->transcription($file, language => 'de') );
  is_deeply($got->{language}, ['de'], 'gpt-4o-transcribe: singular language unchanged');

  $got = $fields->( $whisper->transcription($file, language => 'en') );
  is_deeply($got->{language}, ['en'], 'Whisper server: singular language unchanged');
}

# karr k295: the Whisper server test above is the only one that looked at the
# whole request; the hosted engines (OpenAI, Groq, and the $openai->whisper
# handle) never had their endpoint, Bearer auth or multipart parts checked,
# so a wrong base URL or a lost Authorization header would only surface as a
# 401/404 against the paying provider. Expected values follow the providers'
# API references (platform.openai.com/docs/api-reference/audio,
# console.groq.com/docs/api-reference#audio-transcription); no live call.
{
  require Langertha::Engine::OpenAI;
  require Langertha::Engine::Groq;
  my $parts_of = sub {
    my ( $req ) = @_;
    return [ map {
      my ($name) = $_->header('Content-Disposition') =~ /name="([^"]+)"/;
      my ($filename) = $_->header('Content-Disposition') =~ /filename="([^"]+)"/;
      [ $name, $filename, $_->content ];
    } $req->parts ];
  };

  for my $case (
    [ 'OpenAI', Langertha::Engine::OpenAI->new( api_key => 'sk-openai' ),
      'https://api.openai.com/v1/audio/transcriptions', 'Bearer sk-openai', 'gpt-transcribe', 'languages[]' ],
    [ 'OpenAI->whisper', Langertha::Engine::OpenAI->new( api_key => 'sk-openai' )->whisper,
      'https://api.openai.com/v1/audio/transcriptions', 'Bearer sk-openai', 'gpt-transcribe', 'languages[]' ],
    [ 'Groq', Langertha::Engine::Groq->new( api_key => 'gsk-groq' ),
      'https://api.groq.com/openai/v1/audio/transcriptions', 'Bearer gsk-groq', 'whisper-large-v3', 'language' ],
  ) {
    my ( $label, $engine, $uri, $auth, $model, $lang_field ) = @$case;
    my $req = $engine->transcription($file, language => 'de');
    is($req->method, 'POST', "$label: POST");
    is($req->uri, $uri, "$label: transcriptions endpoint of the provider");
    is($req->header('Authorization'), $auth, "$label: Bearer auth with the engine api_key");
    like($req->header('Content-Type'), qr{\Amultipart/form-data; boundary="[^"]+"\z}, "$label: multipart Content-Type");
    is_deeply($parts_of->($req), [
      [ 'file',     'testfile', 'testxxxx' ],
      [ $lang_field, undef,    'de' ],
      [ 'model',    undef,      $model ],
    ], "$label: file, language (languages[] for gpt-transcribe, k313) and model parts, nothing else");
  }
}

# karr k315: some providers read a list field as repeated parts under the
# PLAIN name (Mistral: timestamp_granularities, context_bias -- no []), while
# OpenAI and Groq read name[]. generate_multipart_body must take an explicit
# { repeated => [...] } marker for the plain-name form instead of guessing
# from the key -- an ArrayRef under a plain key is a file spec -- and the
# k286 [] convention must stay as it is for OpenAI / Groq.
{
  my ($body) = $whisper->generate_multipart_body(HTTP::Request->new(POST => 'http://x/'),
    timestamp_granularities => { repeated => [qw( segment word )] },
  );
  is($body, $multipart->(
    "Content-Disposition: form-data; name=\"timestamp_granularities\"\r\n\r\nsegment",
    "Content-Disposition: form-data; name=\"timestamp_granularities\"\r\n\r\nword",
  ), '{ repeated => [...] } becomes repeated text parts under the plain name');

  require Langertha::Engine::OpenAI;
  require Langertha::Engine::Groq;
  for my $case (
    [ OpenAI => Langertha::Engine::OpenAI->new( api_key => 'k' ) ],
    [ Groq   => Langertha::Engine::Groq->new( api_key => 'k' ) ],
  ) {
    my ( $label, $engine ) = @$case;
    my $req = $engine->transcription($file, 'timestamp_granularities[]' => [qw( word segment )]);
    my @names = map { /name="([^"]+)"/ ? $1 : () } map { $_->header('Content-Disposition') } $req->parts;
    is_deeply([ grep { /timestamp/ } @names ], [ ('timestamp_granularities[]') x 2 ],
      "$label: list field still goes out as repeated name[] parts (k286)");
  }
}

done_testing;
