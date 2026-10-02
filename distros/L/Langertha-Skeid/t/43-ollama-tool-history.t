use strict;
use warnings;
use utf8;
use Test::More;
use Mojolicious;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Mojo::UserAgent;
use JSON::MaybeXS ();

binmode(Test::More->builder->$_, q{:encoding(UTF-8)}) for qw(output failure_output todo_output);
use Langertha::Skeid;
use Langertha::Skeid::Proxy;
use Langertha::Skeid::Protocol::Ollama;

# An Ollama client replays a tool round-trip in Ollama's own shape: the assistant's
# tool_calls[].function.arguments is an OBJECT and carries no id, and the tool reply is
# { role => 'tool', content, tool_name } with no tool_call_id. The OpenAI chat-completions
# upstream Skeid forwards to wants arguments as a JSON string and ties every tool message to a
# call by tool_call_id -- forwarded as-is, the second turn of any Ollama tool conversation is a
# 400 at the upstream (skeid #34, from the skeid #33 audit). The arguments string is nested
# inside the body, so it must be characters, or "Köln" reaches the model as mojibake (#33).

my $CITY  = 'Köln';
my $TOKYO = '東京';
my $SUSHI = "\x{1F363}";
my $TEXT  = JSON::MaybeXS->new(utf8 => 0, canonical => 1);

my $ollama_history = [
  { role => 'user', content => "Wetter in $CITY und $TOKYO?" },
  { role => 'assistant', content => '', tool_calls => [
    { function => { name => 'weather', arguments => { city => $CITY } } },
    { function => { name => 'time',    arguments => { city => "$TOKYO $SUSHI" } } },
  ] },
  # Answered out of call order: tool_name, not position, ties them to their call.
  { role => 'tool', tool_name => 'time',    content => "09:00 $SUSHI" },
  { role => 'tool', tool_name => 'weather', content => "Sonne in $CITY" },
];

# --- request_to_openai: unit ---
{
  my $out = Langertha::Skeid::Protocol::Ollama->request_to_openai({
    model => 'm1', messages => $ollama_history,
  });
  my ($user, $asst, $t1, $t2) = @{ $out->{messages} };

  is $user->{content}, "Wetter in $CITY und $TOKYO?", 'a plain message passes through';
  is $asst->{role}, 'assistant', 'the assistant message keeps its role';
  is $asst->{content}, '', 'and its other fields';

  my @calls = @{ $asst->{tool_calls} };
  is scalar(@calls), 2, 'both tool calls are forwarded';
  is $_->{type}, 'function', 'each call is typed function' for @calls;
  is $calls[0]{function}{name}, 'weather', 'call names are kept';
  ok !ref($calls[0]{function}{arguments}), 'arguments become a string, as OpenAI expects';
  is_deeply $TEXT->decode($calls[0]{function}{arguments}), { city => $CITY },
    'the arguments string decodes (as characters) to the object the client sent';
  ok index($calls[1]{function}{arguments}, "$TOKYO $SUSHI") >= 0,
    'the arguments string holds CJK and emoji as characters, not UTF-8 bytes';

  ok length($calls[0]{id} // ''), 'a call without an id gets one';
  isnt $calls[0]{id}, $calls[1]{id}, 'ids are distinct within the request';
  is $calls[0]{id}, 'call_skeid_0', 'ids are synthesized deterministically';

  is $t1->{tool_call_id}, $calls[1]{id}, 'a tool message is tied to its call by tool_name';
  is $t2->{tool_call_id}, $calls[0]{id}, 'even when the replies come out of call order';
  is $t1->{content}, "09:00 $SUSHI", 'the tool content is kept';
  ok !exists $t1->{tool_name}, 'the Ollama-only tool_name does not reach the OpenAI upstream';

  my $again = Langertha::Skeid::Protocol::Ollama->request_to_openai({ model => 'm1', messages => $ollama_history });
  is_deeply $again, $out, 'the translation is stable: the same history gives the same ids';
  ok ref($ollama_history->[1]{tool_calls}[0]{function}{arguments}) eq 'HASH',
    'the client body is not modified in place';
}

# --- positional fallback, and ids the client already sent ---
{
  my $out = Langertha::Skeid::Protocol::Ollama->request_to_openai({
    model => 'm1',
    messages => [
      { role => 'assistant', content => '', tool_calls => [
        { id => 'call_client', function => { name => 'a', arguments => { n => 1 } } },
        { function => { name => 'b', arguments => '{"n":2}' } },
      ] },
      { role => 'tool', content => 'first' },
      { role => 'tool', content => 'second' },
      { role => 'assistant', content => '', tool_calls => [
        { function => { name => 'a', arguments => {} } },
      ] },
      { role => 'tool', tool_name => 'a', content => 'third' },
      { role => 'tool', tool_call_id => 'kept', content => 'explicit' },
    ],
  });
  my @m = @{ $out->{messages} };
  is $m[0]{tool_calls}[0]{id}, 'call_client', 'an id the client sent is kept';
  is $m[0]{tool_calls}[1]{function}{arguments}, '{"n":2}', 'a string arguments value passes through';
  is $m[1]{tool_call_id}, 'call_client', 'a tool message without tool_name takes the next call in order';
  is $m[2]{tool_call_id}, $m[0]{tool_calls}[1]{id}, 'and the next one the call after it';
  is $m[4]{tool_call_id}, $m[3]{tool_calls}[0]{id}, 'a later assistant turn starts a fresh set of calls';
  isnt $m[3]{tool_calls}[0]{id}, $m[0]{tool_calls}[1]{id}, 'with ids of its own';
  is $m[5]{tool_call_id}, 'kept', 'a tool_call_id the client sent is kept';
}

# --- end-to-end through the proxy and a mock upstream ---

my @upstream_bodies;
my $upstream = Mojolicious->new;
$upstream->log->level('fatal');
$upstream->routes->post('/v1/chat/completions' => sub {
  my ($c) = @_;
  push @upstream_bodies, JSON::MaybeXS::decode_json($c->req->body);   # the wire is UTF-8 bytes
  $c->render(json => {
    id => 'chatcmpl-o', object => 'chat.completion', model => 'm1',
    choices => [{ index => 0, message => { role => 'assistant', content => 'Fertig' }, finish_reason => 'stop' }],
    usage => { prompt_tokens => 3, completion_tokens => 1, total_tokens => 4 },
  });
});
my $upstream_daemon = Mojo::Server::Daemon->new(app => $upstream, listen => ['http://127.0.0.1'], silent => 1);
$upstream_daemon->start;
my $upstream_port = $upstream_daemon->ports->[0];

my $skeid = Langertha::Skeid->new(
  route_wait_poll_ms => 5,
  store_usage_event  => sub { return { ok => 1 } },
);
$skeid->add_node(id => 'n1', url => "http://127.0.0.1:$upstream_port/v1", model => 'm1', max_conns => 4);

my $proxy = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
$proxy->log->level('fatal');
my $proxy_daemon = Mojo::Server::Daemon->new(app => $proxy, listen => ['http://127.0.0.1'], silent => 1);
$proxy_daemon->start;
my $port = $proxy_daemon->ports->[0];

my $ua = Mojo::UserAgent->new;   # held: a temporary user agent is gone before it answers
{
  my $tx;
  my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->post("http://127.0.0.1:$port/api/chat" => json => {
    model => 'm1', stream => JSON::MaybeXS::false, messages => $ollama_history,
  } => sub { (undef, $tx) = @_; Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($guard);

  is $tx->res->code, 200, 'an Ollama tool history is served';
  my $up = $upstream_bodies[0] || {};
  my $calls = $up->{messages}[1]{tool_calls} || [];
  is_deeply $TEXT->decode($calls->[0]{function}{arguments} // 'null'), { city => $CITY },
    'function.arguments reaches the upstream as a string holding "Köln", not "KÃ¶ln"';
  is_deeply $TEXT->decode($calls->[1]{function}{arguments} // 'null'), { city => "$TOKYO $SUSHI" },
    'CJK and emoji arguments reach the upstream intact';
  ok length($calls->[1]{id} // ''), 'the upstream sees ids on the calls';
  is $up->{messages}[2]{tool_call_id}, $calls->[1]{id}, 'the upstream sees each tool reply tied to its call';
  is $up->{messages}[3]{tool_call_id}, $calls->[0]{id}, 'both of them';
  is $up->{messages}[3]{content}, "Sonne in $CITY", 'tool content reaches the upstream intact';
}

done_testing;
