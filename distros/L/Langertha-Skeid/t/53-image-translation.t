use strict;
use warnings;
use utf8;
use Test::More;
use Mojolicious;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Mojo::UserAgent;
use JSON::MaybeXS ();
use MIME::Base64 qw(encode_base64);
use Langertha::Skeid;
use Langertha::Skeid::Proxy;
use Langertha::Skeid::Protocol;
use Langertha::Skeid::Protocol::Anthropic;
use Langertha::Skeid::Protocol::Ollama;

binmode(Test::More->builder->$_, q{:encoding(UTF-8)}) for qw(output failure_output todo_output);

# Images through the translated faces (skeid #42). Skeid makes one OpenAI-shaped upstream call
# (ADR 0001), so an image a client sends on /v1/messages or /api/chat reaches the model only if
# its translator turns it into an OpenAI image_url part. Before this, the Anthropic translator
# folded a content array to its text and dropped every image block, and the Ollama translator
# relayed message.images, a field no OpenAI-chat server reads -- the model answered about a
# picture it never saw. The manifest may claim image_input on a face only because of this, so
# the assertions are on the exact body the upstream receives.

my $PNG  = encode_base64("\x89PNG\r\n\x1a\n\0\0\0\rIHDR", '');
my $JPEG = encode_base64("\xFF\xD8\xFF\xE0\0\x10JFIF\0\x01", '');
my $GIF  = encode_base64("GIF89a\x01\0\x01\0\x80\0\0", '');
my $WEBP = encode_base64("RIFF\x24\0\0\0WEBPVP8 \x18\0", '');
my $ODD  = encode_base64("not an image at all", '');

# --- the media type is read from the magic bytes ---
{
  my %want = ($PNG => 'image/png', $JPEG => 'image/jpeg', $GIF => 'image/gif',
    $WEBP => 'image/webp', $ODD => 'image/png');
  is(Langertha::Skeid::Protocol::image_media_type($_), $want{$_}, "sniffed as $want{$_}")
    for ($PNG, $JPEG, $GIF, $WEBP, $ODD);
}

# --- mock upstream and proxy, one event loop ---

my @upstream_bodies;
my $upstream = Mojolicious->new;
$upstream->log->level('fatal');
$upstream->routes->post('/v1/chat/completions' => sub {
  my ($c) = @_;
  push @upstream_bodies, JSON::MaybeXS::decode_json($c->req->body);
  $c->render(json => {
    id => 'chatcmpl-img', object => 'chat.completion', model => 'm1',
    choices => [{ index => 0, message => { role => 'assistant', content => 'a cat' }, finish_reason => 'stop' }],
    usage => { prompt_tokens => 5, completion_tokens => 2, total_tokens => 7 },
  });
});
my $upstream_daemon = Mojo::Server::Daemon->new(app => $upstream, listen => ['http://127.0.0.1'], silent => 1);
$upstream_daemon->start;
my $upstream_port = $upstream_daemon->ports->[0];

my $skeid = Langertha::Skeid->new(route_wait_poll_ms => 5, store_usage_event => sub { return { ok => 1 } });
$skeid->add_node(id => 'n1', url => "http://127.0.0.1:$upstream_port/v1", model => 'm1', max_conns => 4);
my $proxy = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
$proxy->log->level('fatal');
my $proxy_daemon = Mojo::Server::Daemon->new(app => $proxy, listen => ['http://127.0.0.1'], silent => 1);
$proxy_daemon->start;
my $port = $proxy_daemon->ports->[0];
my $ua = Mojo::UserAgent->new;

sub post_json {
  my ($path, $payload) = @_;
  my $tx;
  my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->post("http://127.0.0.1:$port$path" => json => $payload => sub { (undef, $tx) = @_; Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($guard);
  return $tx->res;
}

sub upstream_messages_for {
  my ($path, $payload) = @_;
  @upstream_bodies = ();
  my $res = post_json($path, $payload);
  is($res->code, 200, "$path answered") or diag $res->body;
  is(scalar @upstream_bodies, 1, 'one upstream call');
  return $upstream_bodies[0]{messages};
}

# --- Anthropic face: base64 and url sources, text and images in the client's order ---
{
  my $messages = upstream_messages_for('/v1/messages', {
    model => 'm1', max_tokens => 64, system => 'Describe.',
    messages => [{ role => 'user', content => [
      { type => 'text', text => 'Erst das Bild aus Köln:' },
      { type => 'image', source => { type => 'base64', media_type => 'image/jpeg', data => $JPEG } },
      { type => 'text', text => 'dann dieses:' },
      { type => 'image', source => { type => 'url', url => 'https://img.example.com/cat.webp' } },
    ] }],
  });
  is_deeply($messages, [
    { role => 'system', content => 'Describe.' },
    { role => 'user', content => [
      { type => 'text', text => 'Erst das Bild aus Köln:' },
      { type => 'image_url', image_url => { url => "data:image/jpeg;base64,$JPEG" } },
      { type => 'text', text => 'dann dieses:' },
      { type => 'image_url', image_url => { url => 'https://img.example.com/cat.webp' } },
    ] },
  ], 'image blocks become image_url parts, base64 as a data URL with its media_type, in order, '
   . 'text as characters');

  # An image-only message is still a message; the stream path takes the same translator.
  $messages = upstream_messages_for('/v1/messages', {
    model => 'm1', max_tokens => 64, stream => JSON::MaybeXS::false,
    messages => [{ role => 'user', content => [
      { type => 'image', source => { type => 'base64', media_type => 'image/png', data => $PNG } },
    ] }],
  });
  is_deeply($messages, [
    { role => 'user', content => [ { type => 'image_url', image_url => { url => "data:image/png;base64,$PNG" } } ] },
  ], 'an image without text is forwarded, not dropped as an empty message');

  # Text-only content arrays keep folding to one string (non-regression).
  $messages = upstream_messages_for('/v1/messages', {
    model => 'm1', max_tokens => 64,
    messages => [{ role => 'user', content => [ { type => 'text', text => 'a' }, { type => 'text', text => 'b' } ] }],
  });
  is_deeply($messages, [ { role => 'user', content => 'ab' } ], 'text-only blocks still fold to a string');

  @upstream_bodies = ();
  my $res = post_json('/v1/messages', {
    model => 'm1', max_tokens => 64,
    messages => [{ role => 'user', content => [
      { type => 'image', source => { type => 'file', file_id => 'file_123' } },
    ] }],
  });
  is($res->code, 400, 'a Files API image source cannot be forwarded: 400');
  like($res->json->{error}{message}, qr/image source type 'file'/, 'naming the source type');
  is(scalar @upstream_bodies, 0, 'and nothing reaches the upstream');
}

# --- Anthropic tool_result images (skeid #43) ---
# A computer-use or screenshot tool answers with image blocks inside its tool_result. An OpenAI
# tool message takes no image parts, so they were JSON-stringified into its text: the model got
# a base64 blob as characters instead of a picture. They move to one user message placed after
# the whole run of tool messages -- OpenAI wants the tool answers directly after the assistant's
# tool calls -- each result's images labelled with its tool_use_id.
{
  my $messages = upstream_messages_for('/v1/messages', {
    model => 'm1', max_tokens => 64,
    messages => [
      { role => 'user', content => 'Take two screenshots.' },
      { role => 'assistant', content => [
        { type => 'tool_use', id => 'toolu_1', name => 'screenshot', input => { screen => 1 } },
        { type => 'tool_use', id => 'toolu_2', name => 'screenshot', input => { screen => 2 } },
      ] },
      { role => 'user', content => [
        { type => 'tool_result', tool_use_id => 'toolu_1', content => [
          { type => 'text', text => 'Bildschirm eins' },
          { type => 'image', source => { type => 'base64', media_type => 'image/png', data => $PNG } },
        ] },
        { type => 'tool_result', tool_use_id => 'toolu_2', content => [
          { type => 'image', source => { type => 'url', url => 'https://img.example.com/two.jpg' } },
        ] },
        { type => 'tool_result', tool_use_id => 'toolu_3', content => 'plain text result' },
        { type => 'text', text => 'Compare them.' },
      ] },
    ],
  });
  is_deeply([ map { $_->{role} } @$messages ], [qw(user assistant tool tool tool user user)],
    'tool messages first, then the one images message, then the client text');
  is_deeply($messages->[2], { role => 'tool', tool_call_id => 'toolu_1',
    content => '[{"text":"Bildschirm eins","type":"text"}]' },
    'the tool message keeps its other blocks as JSON text, without the image');
  is_deeply($messages->[3], { role => 'tool', tool_call_id => 'toolu_2',
    content => 'The tool result is the images in the next message.' },
    'an image-only result says where its content went instead of sending an empty []');
  is_deeply($messages->[4], { role => 'tool', tool_call_id => 'toolu_3', content => 'plain text result' },
    'a string result is unchanged');
  is_deeply($messages->[5], { role => 'user', content => [
    { type => 'text', text => 'Images from tool result toolu_1:' },
    { type => 'image_url', image_url => { url => "data:image/png;base64,$PNG" } },
    { type => 'text', text => 'Images from tool result toolu_2:' },
    { type => 'image_url', image_url => { url => 'https://img.example.com/two.jpg' } },
  ] }, 'one user message carries every result\'s images, each labelled with its tool_use_id');
  is_deeply($messages->[6], { role => 'user', content => 'Compare them.' }, 'the client text follows');

  # Without images a structured result is the JSON text it always was (non-regression).
  $messages = upstream_messages_for('/v1/messages', {
    model => 'm1', max_tokens => 64,
    messages => [
      { role => 'assistant', content => [ { type => 'tool_use', id => 'toolu_9', name => 't', input => {} } ] },
      { role => 'user', content => [
        { type => 'tool_result', tool_use_id => 'toolu_9', content => [ { type => 'text', text => 'ok' } ] },
      ] },
    ],
  });
  is_deeply($messages->[1], { role => 'tool', tool_call_id => 'toolu_9', content => '[{"text":"ok","type":"text"}]' },
    'a text-only structured result is unchanged');
  is(scalar @$messages, 2, 'and no images message is added');

  @upstream_bodies = ();
  my $res = post_json('/v1/messages', {
    model => 'm1', max_tokens => 64,
    messages => [
      { role => 'assistant', content => [ { type => 'tool_use', id => 'toolu_f', name => 't', input => {} } ] },
      { role => 'user', content => [ { type => 'tool_result', tool_use_id => 'toolu_f', content => [
        { type => 'image', source => { type => 'file', file_id => 'file_123' } },
      ] } ] },
    ],
  });
  is($res->code, 400, 'a Files API image inside a tool_result is refused like one outside it');
  is(scalar @upstream_bodies, 0, 'and nothing reaches the upstream');
}

# --- Ollama face: message.images become image_url data URLs with sniffed types ---
{
  my $messages = upstream_messages_for('/api/chat', {
    model => 'm1', stream => JSON::MaybeXS::false,
    messages => [
      { role => 'system', content => 'Describe.' },
      { role => 'user', content => 'Was zeigt das Bild aus Köln?', images => [ $JPEG, $GIF, $WEBP, $ODD ] },
    ],
  });
  is_deeply($messages, [
    { role => 'system', content => 'Describe.' },
    { role => 'user', content => [
      { type => 'text', text => 'Was zeigt das Bild aus Köln?' },
      { type => 'image_url', image_url => { url => "data:image/jpeg;base64,$JPEG" } },
      { type => 'image_url', image_url => { url => "data:image/gif;base64,$GIF" } },
      { type => 'image_url', image_url => { url => "data:image/webp;base64,$WEBP" } },
      { type => 'image_url', image_url => { url => "data:image/png;base64,$ODD" } },
    ] },
  ], 'text then one image_url per image, media type sniffed, image/png when unknown; no images field left');

  $messages = upstream_messages_for('/api/chat', {
    model => 'm1', stream => JSON::MaybeXS::false,
    messages => [ { role => 'user', content => '', images => [ $PNG ] } ],
  });
  is_deeply($messages, [
    { role => 'user', content => [ { type => 'image_url', image_url => { url => "data:image/png;base64,$PNG" } } ] },
  ], 'empty text is not sent as an empty text part');

  $messages = upstream_messages_for('/api/chat', {
    model => 'm1', stream => JSON::MaybeXS::false,
    messages => [ { role => 'user', content => 'hi' } ],
  });
  is_deeply($messages, [ { role => 'user', content => 'hi' } ], 'a message without images keeps string content');
}

# --- OpenAI face: relayed as sent ---
{
  my $sent = [ { role => 'user', content => [
    { type => 'text', text => 'what?' },
    { type => 'image_url', image_url => { url => "data:image/png;base64,$PNG" } },
  ] } ];
  my $messages = upstream_messages_for('/v1/chat/completions', { model => 'm1', messages => $sent });
  is_deeply($messages, $sent, 'image_url parts reach the upstream untouched');
}

# --- each face that carries images says so in its manifest spec ---
for my $spec (
  [ openai    => Langertha::Skeid::Protocol->openai_manifest_endpoint ],
  [ anthropic => Langertha::Skeid::Protocol::Anthropic->manifest_endpoint ],
  [ ollama    => Langertha::Skeid::Protocol::Ollama->manifest_endpoint ],
) {
  ok((grep { $_ eq 'image_input' } @{$spec->[1]{capabilities}}), "$spec->[0] face lists image_input");
}

done_testing;
