use strict;
use warnings;
use Test::More;
use Mojolicious;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Mojo::UserAgent;
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# An Anthropic client may send provider built-in tools (web_search_20250305, bash_20250124,
# text_editor_*, computer_*, mcp_toolset, ...). Skeid forwards one OpenAI-shaped call to its
# nodes (ADR 0001) and has no way to run or forward a built-in, and since Langertha core k210
# Langertha::Tool->from_list croaks on one instead of silently turning it into a function tool.
# Without a guard that croak escaped the /v1/messages handler and Mojolicious answered with an
# HTML 500 -- a client mistake reported as a gateway fault, in a shape no Anthropic SDK can
# parse. The client must get a JSON 400 invalid_request_error naming the tool, before any
# routing, and the upstream must never see the request (core karr #216).

my @upstream_bodies;
my $upstream = Mojolicious->new;
$upstream->log->level('fatal');
$upstream->routes->post('/v1/chat/completions' => sub {
  my ($c) = @_;
  push @upstream_bodies, $c->req->json;
  $c->render(json => {
    id      => 'chatcmpl-1',
    object  => 'chat.completion',
    model   => 'm1',
    choices => [{
      index         => 0,
      message       => { role => 'assistant', content => 'ok' },
      finish_reason => 'stop',
    }],
    usage => { prompt_tokens => 3, completion_tokens => 1, total_tokens => 4 },
  });
});
my $upstream_daemon = Mojo::Server::Daemon->new(app => $upstream, listen => ['http://127.0.0.1'], silent => 1);
$upstream_daemon->start;
my $upstream_port = $upstream_daemon->ports->[0];

my @usage_events;
my $skeid = Langertha::Skeid->new(
  route_wait_poll_ms => 5,
  store_usage_event  => sub { push @usage_events, $_[0]; return { ok => 1 } },
);
$skeid->add_node(id => 'n1', url => "http://127.0.0.1:$upstream_port/v1", model => 'm1', max_conns => 4);

my $proxy = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
$proxy->log->level('fatal');
# Production mode: the HTML 500 this guards against is what a real deployment serves.
$proxy->mode('production');
my $proxy_daemon = Mojo::Server::Daemon->new(app => $proxy, listen => ['http://127.0.0.1'], silent => 1);
$proxy_daemon->start;
my $port = $proxy_daemon->ports->[0];

my $ua = Mojo::UserAgent->new;

sub post_json {
  my ($path, $payload) = @_;
  my $tx;
  my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->post("http://127.0.0.1:$port$path" => json => $payload => sub {
    (undef, $tx) = @_;
    Mojo::IOLoop->stop;
  });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($guard);
  return $tx->res;
}

my $function_tool = {
  name         => 'get_weather',
  description  => 'Weather for a city',
  input_schema => { type => 'object', properties => { city => { type => 'string' } } },
};

sub messages_request {
  my (%extra) = @_;
  return {
    model => 'm1', max_tokens => 64,
    messages => [{ role => 'user', content => 'hi' }],
    %extra,
  };
}

sub is_anthropic_400 {
  my ($res, $name) = @_;
  is $res->code, 400, "$name: answered 400, not 500";
  like $res->headers->content_type // '', qr{application/json}, "$name: as JSON, not an HTML error page";
  my $body = $res->json;
  is ref($body), 'HASH', "$name: the body decodes" or return {};
  is $body->{type}, 'error', "$name: typed as an Anthropic error";
  is $body->{error}{type}, 'invalid_request_error', "$name: a client error, not a gateway fault";
  return $body->{error};
}

for my $case (
  [ 'web_search_20250305', 'server',
    { type => 'web_search_20250305', name => 'web_search', max_uses => 3 } ],
  [ 'bash_20250124', 'client_builtin',
    { type => 'bash_20250124', name => 'bash' } ],
) {
  my ($type, $category, $tool) = @$case;
  @upstream_bodies = ();
  @usage_events = ();

  my $res = post_json('/v1/messages', messages_request(tools => [ $function_tool, $tool ]));
  my $err = is_anthropic_400($res, $type);
  like $err->{message}, qr/\Q$type\E/, "$type: the message names the tool type";
  like $err->{message}, qr/\Q$category\E/, "$type: the message names the category ($category)";
  like $err->{message}, qr/does not forward provider built-in tools/,
    "$type: the message says why skeid refuses it";
  unlike $err->{message}, qr/ at \S+ line \d+/, "$type: no Perl source location leaks to the client";
  is scalar(@upstream_bodies), 0, "$type: the upstream never sees the request";
  is scalar(@usage_events), 0, "$type: nothing was routed, so nothing is metered";
}

# A streamed request is translated before the stream starts, so it must fail the same way --
# as a JSON 400, not as an SSE stream that never opens.
{
  @upstream_bodies = ();
  my $res = post_json('/v1/messages', messages_request(
    stream => \1,
    tools  => [{ type => 'web_search_20250305', name => 'web_search' }],
  ));
  my $err = is_anthropic_400($res, 'streamed web_search');
  like $err->{message}, qr/web_search_20250305/, 'streamed: the message names the tool type';
  is scalar(@upstream_bodies), 0, 'streamed: the upstream never sees the request';
}

# Function tools are what skeid does forward; the guard must not catch them.
{
  @upstream_bodies = ();
  my $res = post_json('/v1/messages', messages_request(tools => [ $function_tool ]));
  is $res->code, 200, 'a request with only function tools is still answered';
  is scalar(@upstream_bodies), 1, 'and forwarded';
  is $upstream_bodies[0]{tools}[0]{function}{name}, 'get_weather',
    'with the function tool translated to the OpenAI shape';
}

# Any other failure while translating the request is also the client's malformed input, and
# must reach the client as a JSON 400 rather than escaping as an HTML 500.
{
  @upstream_bodies = ();
  my $res = post_json('/v1/messages', { model => 'm1', max_tokens => 64, messages => 'hi' });
  my $err = is_anthropic_400($res, 'untranslatable body');
  ok length($err->{message} // ''), 'untranslatable body: a message is given';
  unlike $err->{message}, qr/ at \S+ line \d+/, 'untranslatable body: no Perl source location leaks';
  is scalar(@upstream_bodies), 0, 'untranslatable body: the upstream never sees it';
}

done_testing;
