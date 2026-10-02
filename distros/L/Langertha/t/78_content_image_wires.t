#!/usr/bin/env perl
# ABSTRACT: Content::Image on the Open-Responses, Ollama native, LM Studio native and base64-only wires
use strict;
use warnings;
use Test2::Bundle::More;
use lib 't/lib';

use JSON::MaybeXS;
use MIME::Base64 qw( encode_base64 );
use HTTP::Response;
use Test::LocalHTTPDaemon;
use Langertha::Content::Image;
use Path::Tiny ();

# karr k267: Role::Chat serialized Content::Image with the chat-completions
# shape on every non-Anthropic/Gemini engine. That is a 400 on the Open-Responses
# wire (it wants input_text / input_image with image_url as a STRING), is not
# read at all by Ollama native (string content + a base64 images array) and was
# silently dropped by LM Studio native. Ollama /v1, Cerebras, Moonshot Kimi and
# LM Studio native reject remote image URLs, so a URL image must be inlined
# (fetched, as to_gemini always did) or fail loudly before the request is sent.
# Text-only messages must stay byte-identical: the golden bodies below were
# captured from the pre-change code (d76706e).

my $json = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );
sub body_of { $json->decode( $_[0]->content ) }

my $URL  = 'https://img.test/cat.jpg';
my $B64  = 'Zm9v';
my $DATA = "data:image/png;base64,$B64";
sub url_img { Langertha::Content::Image->from_url($URL) }
sub b64_img { Langertha::Content::Image->from_base64( $B64, media_type => 'image/png' ) }

sub engine {
  my ( $name, @args ) = @_;
  my $class = "Langertha::Engine::$name";
  eval "require $class; 1" or die $@;
  return $class->new(@args);
}

my %ARGS = (
  OpenAIResponses => [ api_key => 'k', model => 'gpt-5.5-pro' ],
  Perplexity      => [ api_key => 'k', model => 'sonar' ],
  Ollama          => [ url => 'http://h:11434', model => 'llama3.3' ],
  LMStudio        => [ url => 'http://h:1234', model => 'm' ],
  OllamaOpenAI    => [ url => 'http://h:11434/v1', model => 'llama3.3' ],
  Cerebras        => [ api_key => 'k' ],
  Moonshot        => [ api_key => 'k' ],
  OpenAI          => [ api_key => 'k', model => 'gpt-5.6-terra' ],
);

# --- Value object serializers ---
{
  is_deeply url_img->to_responses, { type => 'input_image', image_url => $URL },
    'to_responses: URL as a plain string';
  is_deeply b64_img->to_responses, { type => 'input_image', image_url => $DATA },
    'to_responses: base64 as a data URL string';
  is b64_img->to_ollama, $B64, 'to_ollama: raw base64, no data: prefix';
  is_deeply b64_img->to_lmstudio, { type => 'image', data_url => $DATA },
    'to_lmstudio: data URL item';
  my $both = Langertha::Content::Image->new(
    url => $URL, base64 => $B64, media_type => 'image/png' );
  is_deeply $both->to_openai, { type => 'image_url', image_url => { url => $URL } },
    'to_openai prefers the URL';
  is_deeply $both->to_openai( inline => 1 ),
    { type => 'image_url', image_url => { url => $DATA } },
    'to_openai(inline => 1) forces the data URL';
}

# --- detail hint (karr k273): only the OpenAI chat and Open-Responses wires
#     have the field, so a relay (knarr k33) can pass image_url.detail through;
#     every other wire must stay free of it (an unknown key is a 400 there). ---
{
  my $low = sub { Langertha::Content::Image->from_url( $URL, detail => 'low' ) };
  my $inl = sub { Langertha::Content::Image->from_base64( $B64, media_type => 'image/png', detail => 'high' ) };

  is_deeply body_of( engine( 'OpenAI', @{ $ARGS{OpenAI} } )->chat(
    { role => 'user', content => [ $low->() ] } ) )->{messages}[0]{content},
    [ { type => 'image_url', image_url => { url => $URL, detail => 'low' } } ],
    'OpenAI chat body: image_url.detail';
  is_deeply body_of( engine( 'OpenAIResponses', @{ $ARGS{OpenAIResponses} } )->chat(
    { role => 'user', content => [ $low->() ] } ) )->{input}[0]{content},
    [ { type => 'input_image', image_url => $URL, detail => 'low' } ],
    'OpenAIResponses body: input_image.detail';
  is_deeply url_img()->to_openai, { type => 'image_url', image_url => { url => $URL } },
    'no detail set: no detail key on the OpenAI wire';

  require Langertha::Engine::Anthropic;
  my $anth = Langertha::Engine::Anthropic->new( api_key => 'k' );
  my $body = $anth->json->encode( body_of( $anth->chat(
    { role => 'user', content => [ $low->(), $inl->() ] } ) ) );
  unlike $body, qr/"detail"/, 'Anthropic body carries no detail';
  unlike $json->encode( $inl->()->to_gemini ), qr/detail/, 'to_gemini carries no detail';
  is $inl->()->to_ollama, $B64, 'to_ollama: still the raw base64 string';
  is_deeply $inl->()->to_lmstudio, { type => 'image', data_url => $DATA }, 'to_lmstudio carries no detail';

  for my $ctor (
    [ from_file   => sub { my $f = Path::Tiny->tempfile( SUFFIX => '.png' );
                          $f->spew_raw('foo');
                          Langertha::Content::Image->from_file( "$f", detail => 'auto' ) } ],
    [ from_data   => sub { Langertha::Content::Image->from_data( 'foo', media_type => 'image/png', detail => 'auto' ) } ],
    [ from_base64 => sub { Langertha::Content::Image->from_base64( $B64, media_type => 'image/png', detail => 'auto' ) } ],
    [ from_url    => sub { Langertha::Content::Image->from_url( $URL, detail => 'auto' ) } ],
  ) {
    is $ctor->[1]->()->detail, 'auto', "$ctor->[0] accepts detail";
  }
  # Normalize, don't gatekeep: a value Langertha does not know yet goes to the
  # wire unchanged and the provider judges it.
  my $new = Langertha::Content::Image->from_url( $URL, detail => 'original' );
  is_deeply $new->to_openai,
    { type => 'image_url', image_url => { url => $URL, detail => 'original' } },
    'an unknown detail value passes through to image_url.detail';
  is $new->to_responses->{detail}, 'original', '... and to input_image.detail';
  ok !eval { Langertha::Content::Image->new( url => $URL, detail => '' ); 1 },
    'an empty detail string is rejected';
}

# --- Open-Responses wire ---
for my $name (qw( OpenAIResponses Perplexity )) {
  my $e = engine( $name, @{ $ARGS{$name} } );
  is $e->content_format, 'responses', "$name content_format";
  my $input = body_of( $e->chat(
    { role => 'user', content => [ 'what is this?', url_img(), b64_img() ] },
    # Only a message holding a Content object is converted; its text parts are
    # typed by role (an assistant turn's text is output_text on this wire).
    { role => 'assistant', content => [ 'a cat', url_img() ] },
  ) )->{input};
  my @type = $name eq 'Perplexity' ? ( type => 'message' ) : ();
  is_deeply $input, [
    { @type, role => 'user', content => [
      { type => 'input_text',  text => 'what is this?' },
      { type => 'input_image', image_url => $URL },
      { type => 'input_image', image_url => $DATA },
    ] },
    { @type, role => 'assistant', content => [
      { type => 'output_text', text => 'a cat' },
      { type => 'input_image', image_url => $URL },
    ] },
  ], "$name: input_text / input_image (string image_url), output_text on the assistant turn";
}

# --- Ollama native /api/chat ---
{
  my $e = engine( 'Ollama', @{ $ARGS{Ollama} } );
  is $e->content_format, 'ollama', 'Ollama content_format';
  my $msgs = body_of( $e->chat(
    { role => 'user', content => [ 'describe', { type => 'text', text => 'briefly' }, b64_img() ] },
  ) )->{messages};
  is_deeply $msgs, [
    { role => 'user', content => "describe\nbriefly", images => [$B64] },
  ], 'Ollama: string content, raw base64 in images[]';

  ok !eval { $e->chat( { role => 'user', content => [ 'x', { type => 'image_url' }, b64_img() ] } ); 1 },
    'Ollama: an unknown content part croaks';
  like $@, qr/Ollama native \/api\/chat takes a string message content/, '... with a clear message';
}

# --- LM Studio native /api/v1/chat ---
{
  my $e = engine( 'LMStudio', @{ $ARGS{LMStudio} } );
  is $e->content_format, 'lmstudio', 'LMStudio content_format';
  is_deeply body_of( $e->chat(
    { role => 'user', content => [ 'look', b64_img(), 'and this' ] },
  ) )->{input}, [
    { type => 'text', content => 'look' },
    { type => 'image', data_url => $DATA },
    { type => 'text', content => 'and this' },
  ], 'LMStudio: image item with data_url, text around it kept in order';

  is_deeply body_of( $e->chat( { role => 'user', content => [ b64_img() ] } ) )->{input},
    [ { type => 'image', data_url => $DATA } ],
    'LMStudio: a lone image item is not collapsed into a string input';
}

# --- Base64-only OpenAI-compatible engines: base64 goes as a data URL ---
for my $name (qw( OllamaOpenAI Cerebras Moonshot )) {
  my $e = engine( $name, @{ $ARGS{$name} } );
  my $msg = body_of( $e->chat( { role => 'user', content => [ 'hi', b64_img() ] } ) )->{messages}[0];
  is_deeply $msg->{content}, [
    { type => 'text', text => 'hi' },
    { type => 'image_url', image_url => { url => $DATA } },
  ], "$name: base64 image as a data URL";
}

# --- URL images on inline-only wires: fetched and inlined (real LWP round trip) ---
{
  my $bytes = "\x89PNG-bytes";
  my $server = Test::LocalHTTPDaemon->start( sub {
    my ($req) = @_;
    return HTTP::Response->new( 404, 'Not Found', [ 'Content-Type' => 'text/plain' ], 'nope' )
      if $req->uri->path eq '/missing.png';
    return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'image/png' ], $bytes );
  } );
  my $b64  = encode_base64( $bytes, '' );
  my $data = "data:image/png;base64,$b64";
  my $img  = sub { Langertha::Content::Image->from_url( $server->url.'/cat' ) };

  for my $name (qw( OllamaOpenAI Cerebras Moonshot )) {
    my $e = engine( $name, @{ $ARGS{$name} } );
    is_deeply body_of( $e->chat( { role => 'user', content => [ $img->() ] } ) )->{messages}[0]{content},
      [ { type => 'image_url', image_url => { url => $data } } ],
      "$name: URL image fetched and sent as a data URL";
  }
  is_deeply body_of( engine( 'Ollama', @{ $ARGS{Ollama} } )->chat(
    { role => 'user', content => [ 'x', $img->() ] } ) )->{messages}[0]{images},
    [$b64], 'Ollama: URL image fetched into images[]';
  is_deeply body_of( engine( 'LMStudio', @{ $ARGS{LMStudio} } )->chat(
    { role => 'user', content => [ $img->() ] } ) )->{input},
    [ { type => 'image', data_url => $data } ], 'LMStudio: URL image fetched into data_url';

  # URL-capable wires keep the URL: no fetch, no inlining.
  is_deeply body_of( engine( 'OpenAI', @{ $ARGS{OpenAI} } )->chat(
    { role => 'user', content => [ url_img() ] } ) )->{messages}[0]{content},
    [ { type => 'image_url', image_url => { url => $URL } } ], 'OpenAI: URL stays a URL';
  is_deeply body_of( engine( 'OpenAIResponses', @{ $ARGS{OpenAIResponses} } )->chat(
    { role => 'user', content => [ url_img() ] } ) )->{input}[0]{content},
    [ { type => 'input_image', image_url => $URL } ], 'OpenAIResponses: URL stays a URL';

  for my $name (qw( OllamaOpenAI Cerebras Moonshot Ollama LMStudio )) {
    my $e = engine( $name, @{ $ARGS{$name} } );
    my $bad = Langertha::Content::Image->from_url( $server->url.'/missing.png' );
    ok !eval { $e->chat( { role => 'user', content => [ 'x', $bad ] } ); 1 },
      "$name: an unfetchable URL image croaks before the request";
    like $@, qr/\ALangertha::Engine::\Q$name\E: this endpoint takes only inline images .*404.*pass the image as base64 or from a local file instead/s,
      '... naming the engine, the cause and the fix';
  }
}

# --- An outside Content class written against the original three-method
#     contract still composes (the new serializers are croaking defaults,
#     not `requires`), and fails loudly only when sent on a new wire. ---
{
  package My::OutsideContent;
  use Moose;
  with 'Langertha::Content';
  sub to_openai    { { type => 'text', text => 'outside' } }
  sub to_anthropic { { type => 'text', text => 'outside' } }
  sub to_gemini    { { text => 'outside' } }
  __PACKAGE__->meta->make_immutable;
}
{
  my $block = My::OutsideContent->new;
  ok $block->does('Langertha::Content'), 'three-method outside class composes';
  is_deeply body_of( engine( 'OpenAI', @{ $ARGS{OpenAI} } )->chat(
    { role => 'user', content => [$block] } ) )->{messages}[0]{content},
    [ { type => 'text', text => 'outside' } ], '... and still serializes on its wires';
  for my $case ( [ OpenAIResponses => 'responses' ], [ Ollama => 'ollama' ], [ LMStudio => 'lmstudio' ] ) {
    my ( $name, $fmt ) = @$case;
    ok !eval { engine( $name, @{ $ARGS{$name} } )->chat( { role => 'user', content => [$block] } ); 1 },
      "$name: outside class without to_$fmt croaks";
    like $@, qr/\AMy::OutsideContent cannot be sent on the \Q$fmt\E wire; implement to_\Q$fmt\E /,
      '... naming the class, the wire and the method to implement';
  }
}

# --- Text-only messages: byte-identical to the pre-change bodies (golden) ---
# LM Studio native left this table in k268 on purpose: it now sends text parts
# and only the turns after the last assistant message (t/24_lmstudio_native_input.t).
{
  my @msgs = (
    'plain user',
    { role => 'assistant', content => 'plain assistant' },
    { role => 'user', content => [ { type => 'text', text => 'native part' } ] },
  );
  my %golden = (
    Cerebras => '{"messages":[{"content":"sys","role":"system"},{"content":"plain user","role":"user"},{"content":"plain assistant","role":"assistant"},{"content":[{"text":"native part","type":"text"}],"role":"user"}],"model":"gpt-oss-120b","stream":false}',
    Moonshot => '{"max_tokens":16000,"messages":[{"content":"sys","role":"system"},{"content":"plain user","role":"user"},{"content":"plain assistant","role":"assistant"},{"content":[{"text":"native part","type":"text"}],"role":"user"}],"model":"kimi-k3","stream":false}',
    # Ollama native content is a string: the text-part array is joined (k331,
    # t/24_ollama_native_content_parts.t); sent verbatim it was a 400.
    Ollama => '{"messages":[{"content":"sys","role":"system"},{"content":"plain user","role":"user"},{"content":"plain assistant","role":"assistant"},{"content":"native part","role":"user"}],"model":"llama3.3","options":{},"stream":false}',
    OllamaOpenAI => '{"messages":[{"content":"sys","role":"system"},{"content":"plain user","role":"user"},{"content":"plain assistant","role":"assistant"},{"content":[{"text":"native part","type":"text"}],"role":"user"}],"model":"llama3.3","stream":false}',
    OpenAI => '{"messages":[{"content":"sys","role":"system"},{"content":"plain user","role":"user"},{"content":"plain assistant","role":"assistant"},{"content":[{"text":"native part","type":"text"}],"role":"user"}],"model":"gpt-5.6-terra","stream":false}',
    OpenAIResponses => '{"input":[{"content":"plain user","role":"user"},{"content":"plain assistant","role":"assistant"},{"content":[{"text":"native part","type":"text"}],"role":"user"}],"instructions":"sys","model":"gpt-5.5-pro","stream":false}',
    Perplexity => '{"input":[{"content":"plain user","role":"user","type":"message"},{"content":"plain assistant","role":"assistant","type":"message"},{"content":[{"text":"native part","type":"text"}],"role":"user","type":"message"}],"instructions":"sys","preset":"fast","stream":false}',
  );
  for my $name ( sort keys %golden ) {
    my $e = engine( $name, @{ $ARGS{$name} }, system_prompt => 'sys' );
    is $json->encode( body_of( $e->chat(@msgs) ) ), $golden{$name},
      "$name: text-only body unchanged";
  }
}

done_testing;
