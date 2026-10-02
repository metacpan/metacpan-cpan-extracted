#!/usr/bin/env perl
# ABSTRACT: Gemini sends array message content (hash parts, strings) as parts
use strict;
use warnings;
use Test2::Bundle::More;

use JSON::MaybeXS;
use Langertha::Engine::Gemini;

# karr k269: a Gemini message whose content is an ARRAY without a
# Langertha::Content object went out as parts => [{ text => [ ...the array... ] }]
# — Gemini rejects that (text must be a string), so a caller passing the
# OpenAI-style array every other engine accepts got an opaque 400. Array
# content is now converted part by part on both the generateContent and the
# streamGenerateContent body: strings and { type => 'text' } become { text },
# an OpenAI-style image_url becomes the same inline_data part a
# Langertha::Content::Image yields, native Gemini parts pass through untouched,
# and a typed part Gemini has no counterpart for croaks before the request.
# String-content messages must stay byte-identical: the golden body below was
# captured from the pre-change code (b1151c4).

my $json = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );
my $B64  = 'Zm9v';

sub engine {
  Langertha::Engine::Gemini->new(
    api_key => 'k', model => 'gemini-3-flash-preview', system_prompt => 'Be brief.' );
}

sub contents_of {
  my ( $method, @msgs ) = @_;
  return $json->decode( engine()->$method(@msgs)->content )->{contents};
}

# Both request builders share the conversion; check each case on both.
for my $method (qw( chat chat_stream )) {

  # --- golden: string content unchanged ---
  is $json->encode( $json->decode( engine()->$method(
      'hi', { role => 'assistant', content => 'hello' } )->content ) ),
    '{"contents":[{"parts":[{"text":"hi"}],"role":"user"},{"parts":[{"text":"hello"}],"role":"model"}],'
    . '"generationConfig":{"maxOutputTokens":2048},"systemInstruction":{"parts":[{"text":"Be brief."}]}}',
    "$method: string-content body is byte-identical to the pre-change golden";

  is_deeply contents_of( $method,
      { role => 'user', content => [ { type => 'text', text => 'x' } ] } ),
    [ { role => 'user', parts => [ { text => 'x' } ] } ],
    "$method: OpenAI-style text part becomes { text }";

  is_deeply contents_of( $method, { role => 'user', content => [ 'plain', 'two' ] } ),
    [ { role => 'user', parts => [ { text => 'plain' }, { text => 'two' } ] } ],
    "$method: plain string parts become { text }";

  is_deeply contents_of( $method, { role => 'user', content => [
      { type => 'image_url', image_url => { url => "data:image/png;base64,$B64" } } ] } ),
    [ { role => 'user', parts => [
      { inline_data => { mime_type => 'image/png', data => $B64 } } ] } ],
    "$method: data-URL image_url becomes inline_data";

  is_deeply contents_of( $method, { role => 'user', content => [
      { type => 'image_url', image_url => "data:image/jpeg;base64,$B64" } ] } ),
    [ { role => 'user', parts => [
      { inline_data => { mime_type => 'image/jpeg', data => $B64 } } ] } ],
    "$method: image_url as a plain string is read too";

  my @native = (
    { text => 'native' },
    { inline_data => { mime_type => 'image/png', data => $B64 } },
    { inlineData  => { mimeType  => 'image/png', data => $B64 } },
    { fileData    => { mimeType  => 'image/png', fileUri => 'gs://b/cat.png' } },
    { file_data   => { mime_type => 'image/png', file_uri => 'gs://b/cat.png' } },
  );
  is_deeply contents_of( $method, { role => 'user', content => [ @native ] } ),
    [ { role => 'user', parts => \@native } ],
    "$method: native Gemini parts pass through as-is";

  is_deeply contents_of( $method, { role => 'assistant', content => [
      'look:', { type => 'text', text => 'a cat' },
      { type => 'image_url', image_url => { url => "data:image/png;base64,$B64" } },
      { fileData => { mimeType => 'image/png', fileUri => 'gs://b/cat.png' } } ] } ),
    [ { role => 'model', parts => [
      { text => 'look:' }, { text => 'a cat' },
      { inline_data => { mime_type => 'image/png', data => $B64 } },
      { fileData => { mimeType => 'image/png', fileUri => 'gs://b/cat.png' } } ] } ],
    "$method: mixed array converts part by part, assistant role becomes model";

  my $err;
  eval { engine()->$method( { role => 'user', content => [
      { type => 'input_audio', input_audio => { data => $B64, format => 'wav' } } ] } ); 1 }
    or $err = $@;
  like $err, qr/Gemini.*input_audio/, "$method: an untranslatable typed part croaks before the request";
}

# A system message with array content lands in systemInstruction as text.
{
  my $body = $json->decode( Langertha::Engine::Gemini->new( api_key => 'k' )->chat(
    { role => 'system', content => [ 'Be', { type => 'text', text => 'brief.' } ] },
    'hi' )->content );
  is_deeply $body->{systemInstruction}, { parts => [ { text => "Be\nbrief." } ] },
    'system array content joins its text parts into systemInstruction';
}

done_testing;
