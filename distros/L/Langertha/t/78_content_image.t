use strict;
use warnings;
use Test::More;

use Langertha::Content::Image;

# --- from_url + media_type sniffing ---
{
  my $img = Langertha::Content::Image->from_url('https://example.com/cat.jpg');
  is $img->url, 'https://example.com/cat.jpg', 'url kept';
  is $img->media_type, 'image/jpeg', 'jpg -> image/jpeg';
  ok !$img->has_base64, 'no base64 yet';
}

{
  my $img = Langertha::Content::Image->from_url('https://x.test/pic.png?v=2');
  is $img->media_type, 'image/png', 'png sniffed through query string';
}

{
  my $img = Langertha::Content::Image->from_url(
    'https://x.test/opaque',
    media_type => 'image/webp',
  );
  is $img->media_type, 'image/webp', 'explicit media_type wins';
}

# --- from_base64 + from_data ---
{
  my $img = Langertha::Content::Image->from_base64(
    'AAAA', media_type => 'image/png',
  );
  is $img->base64, 'AAAA';
  ok !$img->has_url;
}

{
  my $img = Langertha::Content::Image->from_data(
    "\x00\x01\x02\x03", media_type => 'image/jpeg',
  );
  ok $img->has_base64, 'bytes encoded to base64';
  like $img->base64, qr/^[A-Za-z0-9+\/=]+$/, 'base64 charset';
}

# --- to_openai (URL) ---
{
  my $img = Langertha::Content::Image->from_url('https://x.test/c.jpg');
  is_deeply $img->to_openai, {
    type      => 'image_url',
    image_url => { url => 'https://x.test/c.jpg' },
  }, 'openai URL form';
}

# --- to_openai (base64 -> data: URL) ---
{
  my $img = Langertha::Content::Image->from_base64(
    'Zm9v', media_type => 'image/png',
  );
  is_deeply $img->to_openai, {
    type      => 'image_url',
    image_url => { url => 'data:image/png;base64,Zm9v' },
  }, 'openai data URL';
}

# --- to_anthropic (URL) ---
{
  my $img = Langertha::Content::Image->from_url('https://x.test/c.jpg');
  is_deeply $img->to_anthropic, {
    type   => 'image',
    source => { type => 'url', url => 'https://x.test/c.jpg' },
  }, 'anthropic URL source';
}

# --- to_anthropic (base64) ---
{
  my $img = Langertha::Content::Image->from_base64(
    'Zm9v', media_type => 'image/png',
  );
  is_deeply $img->to_anthropic, {
    type   => 'image',
    source => { type => 'base64', media_type => 'image/png', data => 'Zm9v' },
  }, 'anthropic base64 source';
}

# --- to_gemini (base64 direct) ---
{
  my $img = Langertha::Content::Image->from_base64(
    'Zm9v', media_type => 'image/jpeg',
  );
  is_deeply $img->to_gemini, {
    inline_data => { mime_type => 'image/jpeg', data => 'Zm9v' },
  }, 'gemini inline_data';
}

# --- Anthropic base64 without media_type croaks ---
{
  my $img = Langertha::Content::Image->new(base64 => 'Zm9v');
  eval { $img->to_anthropic };
  like $@, qr/media_type/, 'anthropic base64 without media_type fails';
}

# --- Chat normalization dispatches on content_format ---
{
  require Langertha::Engine::OpenAI;
  my $e = Langertha::Engine::OpenAI->new(api_key => 'test', model => 'gpt-4o');
  is $e->content_format, 'openai';

  my $img = Langertha::Content::Image->from_url('https://x.test/c.jpg');
  my $messages = $e->chat_messages({
    role    => 'user',
    content => [ 'what is this?', $img ],
  });
  is_deeply $messages, [{
    role    => 'user',
    content => [
      { type => 'text', text => 'what is this?' },
      { type => 'image_url', image_url => { url => 'https://x.test/c.jpg' } },
    ],
  }], 'OpenAI normalization (string + image)';
}

{
  require Langertha::Engine::Anthropic;
  my $e = Langertha::Engine::Anthropic->new(
    api_key => 'test',
    model   => 'claude-sonnet-4-6',
  );
  is $e->content_format, 'anthropic';

  my $img = Langertha::Content::Image->from_url('https://x.test/c.jpg');
  my $messages = $e->chat_messages({
    role    => 'user',
    content => [ 'what is this?', $img ],
  });
  is_deeply $messages, [{
    role    => 'user',
    content => [
      { type => 'text', text => 'what is this?' },
      { type => 'image', source => { type => 'url', url => 'https://x.test/c.jpg' } },
    ],
  }], 'Anthropic normalization (url source)';
}

{
  require Langertha::Engine::Gemini;
  my $e = Langertha::Engine::Gemini->new(api_key => 'test', model => 'gemini-2.5-flash');
  is $e->content_format, 'gemini';

  my $img = Langertha::Content::Image->from_base64(
    'Zm9v', media_type => 'image/jpeg',
  );
  my $messages = $e->chat_messages({
    role    => 'user',
    content => [ 'describe', $img ],
  });
  is_deeply $messages, [{
    role  => 'user',
    parts => [
      { text => 'describe' },
      { inline_data => { mime_type => 'image/jpeg', data => 'Zm9v' } },
    ],
  }], 'Gemini normalization (parts)';
}

# --- Messages without Langertha::Content are passed through untouched ---
{
  require Langertha::Engine::OpenAI;
  my $e = Langertha::Engine::OpenAI->new(api_key => 'test', model => 'gpt-4o');
  my $messages = $e->chat_messages({ role => 'user', content => 'hi' });
  is_deeply $messages, [{ role => 'user', content => 'hi' }],
    'plain string content untouched';

  my $native = [{ type => 'text', text => 'hi' }];
  my $out = $e->chat_messages({ role => 'user', content => $native });
  is_deeply $out, [{ role => 'user', content => $native }],
    'native arrayref content untouched';
}

done_testing;
