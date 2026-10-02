#!/usr/bin/env perl
# ABSTRACT: Ollama native /api/chat: an array of content parts becomes a string content (+ images)
use strict;
use warnings;
use Test2::Bundle::More;

use JSON::MaybeXS;
use Langertha::Content::Image;
use Langertha::Engine::Ollama;

# karr k331: native /api/chat Message.content is a Go string (api/types.go),
# so an OpenAI-style array of text parts sent verbatim is a 400 ("cannot
# unmarshal array into ... string"). Gateways forward exactly that shape. The
# ollama branch of _normalize_content_blocks joins text with "\n" and lifts
# images into the sibling images[] array; it must run for every array
# content, not only one that happens to hold a Langertha::Content object.

my $json = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );
sub engine { Langertha::Engine::Ollama->new( url => 'http://h:11434', model => 'm' ) }
sub user_msg {
  my ( $req ) = @_;
  my ($msg) = grep { $_->{role} eq 'user' } @{ $json->decode( $req->content )->{messages} };
  return $msg;
}

my $PNG = 'iVBORw0KGgo=';

{
  my $msg = user_msg( engine()->chat( { role => 'user', content => [ { type => 'text', text => 'hi' } ] } ) );
  is_deeply $msg, { role => 'user', content => 'hi' },
    'a single text part becomes a plain string content';
}

{
  my $msg = user_msg( engine()->chat( { role => 'user',
    content => [ { type => 'text', text => 'one' }, 'two', { type => 'text', text => 'three' } ] } ) );
  is $msg->{content}, "one\ntwo\nthree", 'text parts and bare strings join with a newline';
  ok !ref $msg->{content}, 'content is a string, not an array';
}

# Image parts keep today's behavior: text into content, images into images[].
{
  my $msg = user_msg( engine()->chat( { role => 'user', content => [
    'what is this?', Langertha::Content::Image->from_base64( $PNG, media_type => 'image/png' ) ] } ) );
  is_deeply $msg, { role => 'user', content => 'what is this?', images => [$PNG] },
    'a Content::Image part still goes to images[]';
}

# An OpenAI-style image_url part with a data URL is the gateway spelling of
# the same image: it goes to images[] like a Content::Image.
{
  my $msg = user_msg( engine()->chat( { role => 'user', content => [
    { type => 'text', text => 'what is this?' },
    { type => 'image_url', image_url => { url => "data:image/png;base64,$PNG" } } ] } ) );
  is_deeply $msg, { role => 'user', content => 'what is this?', images => [$PNG] },
    'an image_url data-URL part goes to images[]';
}

# A part the native wire has no place for fails before the request, naming
# the engine, instead of a 400 from the server.
{
  my $err;
  eval { engine()->chat( { role => 'user', content => [ { type => 'input_audio', input_audio => {} } ] } ); 1 }
    or $err = $@;
  like $err, qr/\ALangertha::Engine::Ollama: Ollama native \/api\/chat takes a string message content/,
    'an unknown part croaks with the engine name';
}

# A plain string content is untouched.
{
  my $msg = user_msg( engine()->chat('plain') );
  is_deeply $msg, { role => 'user', content => 'plain' }, 'a string content passes through';
}

done_testing;
