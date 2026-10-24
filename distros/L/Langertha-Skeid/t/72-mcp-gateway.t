use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Mojolicious;
use Mojo::IOLoop;
use Mojo::IOLoop::Server;
use Mojo::Server::Daemon;
use Mojo::JSON qw( decode_json );
use Scalar::Util qw( weaken );
use Time::HiRes qw( time );
use Langertha::Skeid;
use Langertha::Skeid::KeyBroker;
use Langertha::Skeid::Proxy;

# The MCP gateway (skeid k103, ADR 0022). The operator assigns MCP servers to customer key ids
# in the config's mcp: section; a customer reaches an assigned server under /mcp/<name> with its
# own Skeid key and asks /v1/mcp/servers what it was assigned. Skeid relays MCP's Streamable
# HTTP without reading it: method, body and a handful of headers up, status, headers and body or
# event stream down -- unbuffered. The client's key never goes upstream; the upstream's own
# credential comes from the key broker or the environment. Whatever is not a server of the
# presented key is one and the same 404, and without the section both routes are the unknown
# path they were before.

delete @ENV{qw( OPENBAO_ROLE_ID OPENBAO_SECRET_ID OPENBAO_ADDR SKEID_ADMIN_API_KEY
  SKEID_TRUST_KEY_ID_HEADER SKEID_T_MCP_UNSET )};

my $ALICE_KEY   = 'sk-alice-secret';
my $BOB_KEY     = 'sk-bob-secret';
my $CAROL_KEY   = 'sk-carol-secret';
my $MALLORY_KEY = 'sk-mallory-secret';
my $ALICE_ID    = Langertha::Skeid->key_id_for_key($ALICE_KEY);
my $BOB_ID      = Langertha::Skeid->key_id_for_key($BOB_KEY);
my $CAROL_ID    = Langertha::Skeid->key_id_for_key($CAROL_KEY);

# The upstream credentials. One comes from the environment, one through the key broker.
my $ENV_SECRET    = 'up-env-secret-7c1';
my $BROKER_SECRET = 'up-broker-secret-9d2';
my $BROKER_REF    = 'secret/skeid/mcp/notes';
local $ENV{SKEID_T_MCP_BOOKRAG} = $ENV_SECRET;

my $CHALLENGE = 'Bearer realm="skeid"';
my $NOT_FOUND = 'No MCP server of this name is available for this key';

{
  package Local::MCP::Broker;
  use Moo;
  extends 'Langertha::Skeid::KeyBroker';
  has secrets => (is => 'ro', default => sub { {} });
  sub resolve_key { $_[0]->secrets->{$_[1]} }
}

# --- the fake MCP upstream -------------------------------------------------------------------
# Answers by the JSON-RPC method of the body, so a test picks the answer without a header the
# relay would not pass on. Records what it received, and holds a stream open until told.

my @SEEN;
my %HOLD;

my $up = Mojolicious->new;
$up->log->level('fatal');
my $upstream = sub {
  my ($c) = @_;
  my $req = $c->req;
  push @SEEN, {
    method  => $req->method,
    path    => $req->url->path->to_string,
    query   => $req->url->query->to_string,
    headers => { map { lc($_) => $req->headers->header($_) } @{$req->headers->names} },
    body    => $req->body,
  };
  my $rpc = (eval { decode_json($req->body) } || {})->{method} // '';

  if ($req->method eq 'GET') {
    # The standing stream: headers at once, events whenever the server has one.
    $c->inactivity_timeout(60);
    $c->res->headers->content_type('text/event-stream');
    $c->res->headers->cache_control('no-cache');
    $c->write_chunk;
    $HOLD{get} = $c;
    $c->tx->on(finish => sub { $HOLD{get_closed}++ });
    return;
  }
  if ($req->method eq 'DELETE') {
    $c->res->headers->header('Mcp-Session-Ended' => $req->headers->header('Mcp-Session-Id') // '');
    return $c->rendered(204);
  }
  if ($rpc eq 'stream') {
    $c->inactivity_timeout(60);
    $c->res->headers->content_type('text/event-stream');
    $c->res->headers->header('Mcp-Session-Id' => 'sess-stream');
    $c->write_chunk;
    $HOLD{stream} = $c;
    $c->tx->on(finish => sub { $HOLD{stream_closed}++ });
    return;
  }
  return $c->rendered(202) if $rpc eq 'notifications/initialized';
  if ($rpc eq 'headers') {
    my $h = $c->res->headers;
    $h->header('Set-Cookie' => 'upstream=session; Path=/');
    $h->header('Server' => 'internal-mcp/1.0');
    $h->header('Access-Control-Allow-Origin' => '*');
    $h->header('Strict-Transport-Security' => 'max-age=1');
    $h->header('Retry-After' => '7');
    $h->header('Cache-Control' => 'no-store');
    $h->header('Mcp-Session-Id' => 'sess-h');
    $h->header('Mcp-Future-Reply' => 'kept');
    return $c->render(json => { jsonrpc => '2.0', id => 1, result => {} });
  }
  if ($rpc eq 'big') {
    # 40 chunks of 64 KiB, an event stream that is longer than any limit a test sets.
    $c->res->headers->content_type('text/event-stream');
    $c->write_chunk;
    my $left = 40;
    my $send; $send = sub {
      return $c->finish unless $left--;
      $c->write_chunk('data: ' . ('x' x 65530) . "\n\n" => sub { Mojo::IOLoop->next_tick($send) });
    };
    $send->();
    return;
  }
  if ($rpc eq 'unauthorized') {
    $c->res->headers->www_authenticate('Bearer resource_metadata="http://internal.example/.well-known/x"');
    return $c->render(status => 401, json => { error => 'bad upstream token' });
  }
  return $c->render(status => 404, json => { jsonrpc => '2.0', error => { code => -32001, message => 'Session not found' } })
    if $rpc eq 'expired';
  return $c->render(status => 500, text => 'upstream exploded') if $rpc eq 'boom';
  if ($rpc eq 'redirect') {
    $c->res->headers->location('http://internal.example:8080/mcp/');
    return $c->rendered(307);
  }

  $c->res->headers->header('Mcp-Session-Id' => 'sess-1');
  $c->res->headers->header('X-Upstream' => 'bookrag');
  $c->render(json => { jsonrpc => '2.0', id => 1, result => { path => $req->url->path->to_string } });
};
$up->routes->any('/mcp'       => $upstream);
$up->routes->any('/mcp/*rest' => $upstream);
$up->routes->any('/other'     => $upstream);
$up->routes->get('/ping'      => sub { $_[0]->render(text => 'pong') });
my $up_daemon = Mojo::Server::Daemon->new(app => $up, listen => ['http://127.0.0.1'], silent => 1)->start;
my $UP = 'http://127.0.0.1:' . $up_daemon->ports->[0];
my $DEAD = 'http://127.0.0.1:' . Mojo::IOLoop::Server->generate_port;

# --- the proxy ---------------------------------------------------------------------------------

my (@USAGE, @LOG, @CONTROLLERS);
my $CFG;

sub mcp_config {
  my (%over) = @_;
  return {
    names => { alice => $ALICE_ID, bob => $BOB_ID },
    mcp   => {
      public_url => 'https://llm.example.test',
      servers    => {
        bookrag => {
          url         => "$UP/mcp",
          description => 'Book search',
          api_key_env => 'SKEID_T_MCP_BOOKRAG',
          headers     => { 'X-Tenant' => 'citilan' },
          keys        => [ 'alice', $CAROL_ID ],
        },
        notes => {
          url         => "$UP/mcp",
          api_key_ref => $BROKER_REF,
          keys        => ['bob'],
        },
        open => { url => "$UP/mcp", keys => ['bob'] },
        files => {
          transport   => 'stdio',
          command     => 'mcp-files',
          args        => [ '--root', '/srv/data' ],
          env         => { MCP_FILES_MODE => 'ro' },
          description => 'Files on your machine',
          keys        => ['alice'],
        },
        nokey   => { url => "$UP/mcp", api_key_env => 'SKEID_T_MCP_UNSET', keys => ['alice'] },
        dead    => { url => "$DEAD/mcp", keys => ['alice'] },
        %{ $over{servers} || {} },
      },
    },
    %{ $over{top} || {} },
  };
}

sub proxy {
  my (%opts) = @_;
  my $skeid = Langertha::Skeid->new(
    config_reload_interval => 0,
    store_usage_event      => sub { push @USAGE, $_[1]; return { ok => 1 } },
    key_broker             => Local::MCP::Broker->new(secrets => { $BROKER_REF => $BROKER_SECRET }),
    config_loader          => sub { $CFG },
    %opts,
  );
  my $app = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
  # The development page for an unknown path repeats the request; production's is one page.
  $app->mode('production');
  $app->log->level('trace');
  $app->log->unsubscribe('message')->on(message => sub {
    my ($log, $level, @lines) = @_;
    push @LOG, [ $level, join(' ', @lines) ];
  });
  # Every relayed request's controller, held weakly: a finished request must let go of it.
  $app->hook(before_dispatch => sub {
    my ($c) = @_;
    return unless $c->req->url->path->to_string =~ m{\A/mcp/};
    push @CONTROLLERS, $c;
    weaken($CONTROLLERS[-1]);
  });
  return (Test::Mojo->new($app), $skeid);
}

# No finished request may keep its controller: the relay's listeners close over it and over the
# upstream transaction, and one that is not taken off again holds both for good. The client's
# user agent and the proxy's each keep the last transaction of a keep-alive connection, so every
# such connection is used once more for a request that captures no relay controller; what is
# still alive after that is Skeid's.
sub released_ok {
  my ($t, $label) = @_;
  my $seen = @CONTROLLERS;
  my $flushed = 0;
  $t->ua->get('/health' => sub { $flushed++ });
  $t->app->ua->get("$UP/ping" => sub { $flushed++ });
  wait_for(sub { $flushed == 2 }, "$label: the keep-alive connections were used again");
  $t->get_ok('/health')->status_is(200);
  wait_for(sub { !grep { defined } @CONTROLLERS }, "$label: every one of $seen requests released its controller");
  @CONTROLLERS = ();
  return;
}

sub bearer { return (Authorization => "Bearer $_[0]") }

# Runs the loop until $cond holds, at most five seconds.
sub wait_for {
  my ($cond, $what) = @_;
  my $ok = $cond->() ? 1 : 0;
  unless ($ok) {
    my $deadline = time + 5;
    my $id = Mojo::IOLoop->recurring(0.01 => sub {
      $ok = 1 if $cond->();
      Mojo::IOLoop->stop if $ok || time > $deadline;
    });
    Mojo::IOLoop->start;
    Mojo::IOLoop->remove($id);
  }
  ok $ok, $what;
  return $ok;
}

sub is_not_found {
  my ($t, $label) = @_;
  $t->status_is(404, "$label: 404")
    ->json_is('/error/type' => 'not_found', "$label: not_found")
    ->json_is('/error/message' => $NOT_FOUND, "$label: one message for every such case");
  return;
}

my $RPC = qq({ "jsonrpc" : "2.0",\n  "id":1, "method": "tools/list" , "params":{"n":"\xc3\xa4"} });

# --- without an mcp: section both routes are the unknown path they were ------------------------
{
  $CFG = { names => { alice => $ALICE_ID } };
  my ($t, $skeid) = proxy();
  ok !$skeid->mcp_enabled, 'no mcp section: the gateway is off';
  # The page of an unknown path, but for the one line that differs from request to request.
  my $page = sub { (my $body = $t->tx->res->body) =~ s/<!-- Request ID: [^>]* -->//; $body };
  $t->get_ok('/nope');
  my ($status, $body, $type) = ($t->tx->res->code, $page->(), $t->tx->res->headers->content_type);
  like $body, qr/Page Not Found/, 'with the page of an unknown path';
  is $status, 404, 'an unknown path is 404';
  for my $call ([ GET => '/v1/mcp/servers' ], [ GET => '/mcp/bookrag' ], [ POST => '/mcp/bookrag' ],
    [ DELETE => '/mcp/bookrag' ], [ POST => '/mcp/bookrag/sub' ]) {
    my ($method, $path) = @$call;
    for my $headers ({}, { bearer($ALICE_KEY) }) {
      my $tx = $t->ua->build_tx($method => $path => $headers);
      $t->request_ok($tx)->status_is(404, "$method $path without the section: 404");
      is $page->(), $body, "$method $path: the very answer of an unknown path";
      is $t->tx->res->headers->content_type, $type, "$method $path: and its content type";
    }
  }

  $CFG = { names => { alice => $ALICE_ID }, client_auth => { keys => ['alice'] } };
  $t->get_ok('/v1/models')->status_is(401, 'client_auth is on now');
  for my $path ('/v1/mcp/servers', '/mcp/bookrag') {
    $t->get_ok($path)->status_is(404, "$path, client_auth on, no key, no mcp section: still 404, not 401");
    ok !defined($t->tx->res->headers->www_authenticate), "$path: no challenge";
  }
  is scalar(@SEEN), 0, 'nothing reached an upstream';
  is scalar(@USAGE), 0, 'and nothing was metered';
}

# --- the section, resolved at config load ------------------------------------------------------
{
  $CFG = mcp_config();
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my ($t, $skeid) = proxy();
  ok $skeid->mcp_enabled, 'an mcp section turns the gateway on';
  is $skeid->mcp_public_url, 'https://llm.example.test', 'public_url is kept';
  is_deeply [ sort keys %{$skeid->mcp_servers} ], [qw( bookrag dead files nokey notes open )], 'every server is loaded';
  is_deeply $skeid->mcp_servers->{bookrag}{keys}, { $ALICE_ID => 1, $CAROL_ID => 1 },
    'keys: a names: entry resolves to its id, a key id stands as it is';
  is $skeid->mcp_servers->{bookrag}{transport}, 'streamable-http', 'a server with a url is streamable-http';
  is $skeid->mcp_servers->{files}{transport}, 'stdio', 'a stdio entry keeps its transport';

  is $skeid->mcp_server_for_key('bookrag', $ALICE_ID)->{name}, 'bookrag', 'an assigned key finds its server';
  ok !defined($skeid->mcp_server_for_key('bookrag', $BOB_ID)), 'a key it is not assigned to does not';
  ok !defined($skeid->mcp_server_for_key('nope', $ALICE_ID)), 'an unknown name finds nothing';
  ok !defined($skeid->mcp_server_for_key('bookrag', 'anonymous')), 'anonymous is assigned nothing';
  ok !defined($skeid->mcp_server_for_key('bookrag', undef)), 'nor is no id at all';
  is_deeply [ map { $_->{name} } @{$skeid->mcp_servers_for_key($ALICE_ID)} ], [qw( bookrag dead files nokey )],
    'the servers of a key, sorted by name';
  is_deeply $skeid->mcp_servers_for_key(Langertha::Skeid->key_id_for_key($MALLORY_KEY)), [],
    'a key with no assignment has none';
  ok !grep({ /mcp/ } @warnings), 'a complete section loads without a notice' or diag explain \@warnings;
}

# --- a short (pre-ADR 0016) id in keys: matches the full id it is the prefix of ------------------
{
  my $short = substr($ALICE_ID, 0, 14);
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  $CFG = { mcp => { servers => { bookrag => { url => "$UP/mcp", keys => $short } } } };
  my ($t, $skeid) = proxy();
  ok grep({ /short key id/ } @warnings), 'a short id loads with the deprecation warning';
  is_deeply $skeid->mcp_servers->{bookrag}{keys}, { $short => 1 }, 'a single id stands without a list';
  ok $skeid->mcp_server_for_key('bookrag', $ALICE_ID), 'and the full id it is the prefix of is assigned';
  ok !$skeid->mcp_server_for_key('bookrag', $BOB_ID), 'another key is not';
}

# --- a section that does not load ---------------------------------------------------------------
{
  my $PASTED = 'sk-pasted-client-key-000';
  my @bad = (
    [ 'not a hash',            'mcp-string',                              qr/mcp must be a hash/ ],
    [ 'unknown key',           { server => {} },                          qr/mcp: unknown key 'server'/ ],
    [ 'servers not a hash',    { servers => [] },                         qr/mcp\.servers must be a hash/ ],
    [ 'public_url not http',   { public_url => 'llm.example.test', servers => {} }, qr/mcp\.public_url must be an absolute http/ ],
    [ 'bad server name',       { servers => { 'a/b' => { url => "$UP/mcp" } } }, qr/mcp\.servers: a server name must/ ],
    [ 'server not a hash',     { servers => { x => 'http://x' } },        qr/mcp\.servers\.x must be a hash/ ],
    [ 'unknown server key',    { servers => { x => { url => "$UP/mcp", uri => 1 } } }, qr/mcp\.servers\.x: unknown key 'uri'/ ],
    [ 'unknown transport',     { servers => { x => { transport => 'sse', url => "$UP/mcp" } } }, qr/mcp\.servers\.x: unknown transport/ ],
    [ 'no url',                { servers => { x => { keys => [] } } },    qr/mcp\.servers\.x needs a url/ ],
    [ 'relative url',          { servers => { x => { url => '/mcp' } } }, qr/mcp\.servers\.x\.url must be an absolute http/ ],
    [ 'url with credentials',  { servers => { x => { url => "http://u:$PASTED\@h/mcp" } } }, qr/mcp\.servers\.x\.url must not carry credentials/ ],
    [ 'stdio with a url',      { servers => { x => { transport => 'stdio', command => 'c', url => "$UP/mcp" } } }, qr/mcp\.servers\.x: 'url' does not belong to a stdio server/ ],
    [ 'stdio without command', { servers => { x => { transport => 'stdio' } } }, qr/mcp\.servers\.x needs a command/ ],
    [ 'stdio args not a list', { servers => { x => { transport => 'stdio', command => 'c', args => 'a' } } }, qr/mcp\.servers\.x\.args must be a list of strings/ ],
    [ 'stdio env not a map',   { servers => { x => { transport => 'stdio', command => 'c', env => ['a'] } } }, qr/mcp\.servers\.x\.env must be a map of strings/ ],
    [ 'http with a command',   { servers => { x => { url => "$UP/mcp", command => 'c' } } }, qr/mcp\.servers\.x: 'command' belongs to a stdio server/ ],
    [ 'credential in headers', { servers => { x => { url => "$UP/mcp", headers => { authorization => "Bearer $PASTED" } } } },
      qr/mcp\.servers\.x\.headers: 'authorization' may not be set here/ ],
    [ 'relayed header in headers', { servers => { x => { url => "$UP/mcp", headers => { 'Mcp-Session-Id' => 'x' } } } },
      qr/mcp\.servers\.x\.headers: 'Mcp-Session-Id' may not be set here/ ],
    [ 'header value not a string', { servers => { x => { url => "$UP/mcp", headers => { 'X-A' => [$PASTED] } } } },
      qr/mcp\.servers\.x\.headers: the value of 'X-A' must be a string/ ],
    [ 'a key where an id belongs', { servers => { x => { url => "$UP/mcp", keys => [ $ALICE_ID, $PASTED ] } } },
      qr/mcp\.servers\.x\.keys entry 2 is neither a names: entry nor a key id/ ],
    [ 'limit zero',            { max_request_bytes => 0, servers => {} },    qr/mcp\.max_request_bytes must be an integer of at least 1/ ],
    [ 'limit negative',        { max_request_bytes => -1, servers => {} },   qr/mcp\.max_request_bytes must be an integer/ ],
    [ 'limit a word',          { max_request_bytes => 'big', servers => {} }, qr/mcp\.max_request_bytes must be an integer/ ],
    [ 'limit fractional',      { max_request_bytes => '1.5', servers => {} }, qr/mcp\.max_request_bytes must be an integer/ ],
    [ 'limit a list',          { max_request_bytes => [1], servers => {} },  qr/mcp\.max_request_bytes must be an integer/ ],
    [ 'limit null',            { max_request_bytes => undef, servers => {} }, qr/mcp\.max_request_bytes must be an integer/ ],
    [ 'description not a string', { servers => { x => { url => "$UP/mcp", description => {} } } }, qr/mcp\.servers\.x\.description must be a string/ ],
  );
  for my $case (@bad) {
    my ($label, $section, $want) = @$case;
    my $err = '';
    eval { Langertha::Skeid->new(config_loader => sub { { mcp => $section } }); 1 } or $err = "$@";
    like $err, $want, "$label: the load fails and says why";
    unlike $err, qr/\Q$PASTED\E/, "$label: the error repeats no value that could be a secret";
  }

  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my $skeid = Langertha::Skeid->new(config_loader => sub { { mcp => { servers => { lonely => { url => "$UP/mcp" } } } } });
  ok grep({ /mcp\.servers\.lonely is assigned to no key/ } @warnings), 'a server without keys loads and says so once';
  is_deeply $skeid->mcp_servers->{lonely}{keys}, {}, 'and is assigned to nobody';
}

# --- the section from a YAML file, as `skeid serve --config` reads it ----------------------------
{
  require File::Temp;
  require Mojo::JSON;
  my ($fh, $file) = File::Temp::tempfile(SUFFIX => '.yaml', UNLINK => 1);
  print {$fh} <<"YAML";
names:
  alice: $ALICE_ID
mcp:
  public_url: https://llm.example.test/
  servers:
    bookrag:
      url: $UP/mcp
      api_key_env: SKEID_T_MCP_BOOKRAG
      headers: { X-Tenant: citilan, X-Shard: 7 }
      keys: [alice]
    files:
      transport: stdio
      command: mcp-files
      args: ["--port", 8080, --verbose]
      env: { MCP_FILES_DEPTH: 3 }
      keys: alice
YAML
  close $fh;
  my $skeid = Langertha::Skeid->new(config_file => $file);
  ok $skeid->mcp_enabled, 'a YAML config turns the gateway on';
  is $skeid->mcp_public_url, 'https://llm.example.test', 'public_url loses its trailing slash';
  is_deeply $skeid->mcp_servers->{bookrag}{headers}, { 'X-Tenant' => 'citilan', 'X-Shard' => '7' }, 'static headers';
  my $entry = Langertha::Skeid::Protocol::MCP->listing_entry($skeid->mcp_servers->{files}, 'https://x');
  like Mojo::JSON::encode_json($entry), qr/"args":\["--port","8080","--verbose"\]/,
    'a number among the args is listed as the string a command line takes';
  like Mojo::JSON::encode_json($entry), qr/"MCP_FILES_DEPTH":"3"/, 'and so is an env value';
  is_deeply [ map { $_->{name} } @{$skeid->mcp_servers_for_key($ALICE_ID)} ], [qw( bookrag files )],
    'keys: a single name without the list';
}

# --- the listing: what a key was assigned, and nothing of the upstream -------------------------
{
  $CFG = mcp_config();
  my ($t, $skeid) = proxy();
  @SEEN = @USAGE = ();

  $t->get_ok('/v1/mcp/servers' => { bearer($ALICE_KEY) })->status_is(200)
    ->header_is('Cache-Control' => 'private, no-store', 'the listing is per key and never cached')
    ->header_like(Vary => qr/Authorization/, 'and varies on the identity')
    ->json_is('' => {
      object => 'list',
      data   => [
        { name => 'bookrag', transport => 'streamable-http', url => 'https://llm.example.test/mcp/bookrag',
          description => 'Book search' },
        { name => 'dead', transport => 'streamable-http', url => 'https://llm.example.test/mcp/dead', description => '' },
        { name => 'files', transport => 'stdio', command => 'mcp-files', args => [ '--root', '/srv/data' ],
          env => { MCP_FILES_MODE => 'ro' }, description => 'Files on your machine' },
        { name => 'nokey', transport => 'streamable-http', url => 'https://llm.example.test/mcp/nokey', description => '' },
      ],
    }, 'alice sees her servers, sorted, with public URLs and the stdio hint');
  my $alice = $t->tx->res->body;

  $t->get_ok('/v1/mcp/servers' => { 'x-api-key' => $BOB_KEY })->status_is(200)
    ->json_is('/data/0/name' => 'notes')->json_is('/data/1/name' => 'open')
    ->json_hasnt('/data/2', 'bob sees his two and not alice\'s');
  my $bob = $t->tx->res->body;
  $t->get_ok('/v1/mcp/servers' => { bearer($MALLORY_KEY) })->status_is(200)
    ->json_is('' => { object => 'list', data => [] }, 'a key with no assignment gets an empty list');

  for my $body ($alice, $bob) {
    unlike $body, qr/\Q$UP\E|127\.0\.0\.1/, 'no upstream URL in the listing';
    unlike $body, qr/SKEID_T_MCP|\Q$BROKER_REF\E|api_key/, 'no key reference or variable name';
    unlike $body, qr/X-Tenant|citilan|headers/, 'no upstream header';
    unlike $body, qr/\Q$ENV_SECRET\E|\Q$BROKER_SECRET\E/, 'and no secret';
  }

  $t->get_ok('/v1/mcp/servers')->status_is(401, 'no key: 401, also without client_auth')
    ->header_is('WWW-Authenticate' => $CHALLENGE)
    ->json_is('/error/message' => 'Missing API key')
    ->json_is('/error/code' => 'invalid_api_key');
  is scalar(@SEEN), 0, 'the listing calls no upstream';
  is scalar(@USAGE), 0, 'and writes no usage event';

  # Without public_url the URLs are built from the request.
  delete $CFG->{mcp}{public_url};
  $CFG = { %$CFG };
  my $port = $t->ua->server->url->port;
  $t->get_ok('/v1/mcp/servers' => { bearer($ALICE_KEY) })->status_is(200)
    ->json_is('/data/0/url' => "http://127.0.0.1:$port/mcp/bookrag", 'no public_url: the URL of the request');
  $CFG = mcp_config(top => { mcp => { %{ mcp_config()->{mcp} }, public_url => 'https://llm.example.test/skeid/' } });
  $t->get_ok('/v1/mcp/servers' => { bearer($ALICE_KEY) })->status_is(200)
    ->json_is('/data/0/url' => 'https://llm.example.test/skeid/mcp/bookrag', 'a public_url with a path and a trailing slash');
}

# --- the relay: a JSON answer --------------------------------------------------------------------
{
  $CFG = mcp_config();
  my ($t, $skeid) = proxy();
  @SEEN = @USAGE = @LOG = @CONTROLLERS = ();

  $t->post_ok('/mcp/bookrag' => {
    bearer($ALICE_KEY),
    'Content-Type'         => 'application/json',
    Accept                 => 'application/json, text/event-stream',
    'Mcp-Session-Id'       => 'sess-client',
    'MCP-Protocol-Version' => '2025-06-18',
    'Last-Event-ID'        => 'ev-41',
    'Mcp-Future-Header'    => 'kept',
    'X-Api-Key'            => $ALICE_KEY,
    Cookie                 => 'session=abc',
    'X-Custom'             => 'dropped',
    'X-Forwarded-For'      => '203.0.113.9',
    'X-Request-Id'         => 'req-client-1',
  } => $RPC)->status_is(200, 'an assigned server answers')
    ->header_is('Mcp-Session-Id' => 'sess-1', 'the upstream\'s session id comes back')
    ->header_is('x-upstream' => undef, 'but not its other headers: the relay lets a list through')
    ->header_is('x-request-id' => 'req-client-1', 'and the request id of this request')
    ->header_like('Content-Type' => qr{\Aapplication/json})
    ->json_is('/result/path' => '/mcp', 'the upstream\'s body');
  ok !defined($t->tx->res->headers->header('x-skeid-node')), 'no node served this';

  is scalar(@SEEN), 1, 'one upstream call';
  my $seen = $SEEN[0];
  is $seen->{method}, 'POST', 'the method';
  is $seen->{path}, '/mcp', 'the configured path';
  is $seen->{body}, $RPC, 'the body, byte for byte';
  is $seen->{headers}{'content-type'}, 'application/json', 'Content-Type';
  is $seen->{headers}{accept}, 'application/json, text/event-stream', 'Accept';
  is $seen->{headers}{'mcp-session-id'}, 'sess-client', 'Mcp-Session-Id';
  is $seen->{headers}{'mcp-protocol-version'}, '2025-06-18', 'Mcp-Protocol-Version, however it is spelled';
  is $seen->{headers}{'last-event-id'}, 'ev-41', 'Last-Event-ID';
  is $seen->{headers}{'mcp-future-header'}, 'kept', 'any other Mcp-* header';
  is $seen->{headers}{authorization}, "Bearer $ENV_SECRET", 'the upstream gets its own credential';
  is $seen->{headers}{'x-tenant'}, 'citilan', 'and the configured static header';
  for my $name (qw( x-api-key cookie x-custom x-forwarded-for x-request-id x-skeid-key-id )) {
    ok !exists $seen->{headers}{$name}, "$name does not go upstream";
  }
  unlike join("\n", %{$seen->{headers}}, $seen->{body}), qr/\Q$ALICE_KEY\E/, 'the client key reaches the upstream nowhere';

  is scalar(@USAGE), 1, 'one usage event';
  my $event = $USAGE[0];
  is $event->{api_format}, 'mcp', 'api_format mcp';
  is $event->{endpoint}, '/mcp/bookrag', 'the endpoint names the server';
  is $event->{api_key_id}, $ALICE_ID, 'under the customer key id';
  is $event->{status_code}, 200, 'the status';
  is $event->{ok}, 1, 'ok';
  ok $event->{duration_ms} >= 0, 'a duration';
  is $event->{request_id}, 'req-client-1', 'the request id';
  is $event->{route_url}, "$UP/mcp", 'the server\'s url as route_url';
  is $event->{model}, '', 'no model';
  is $event->{node_id}, '', 'no node';
  is $event->{total_tokens}, 0, 'no tokens';

  # Another customer's key on the same server: carol is assigned by raw id.
  $t->post_ok('/mcp/bookrag' => { 'x-api-key' => $CAROL_KEY } => $RPC)->status_is(200, 'x-api-key identifies as well');
  is $USAGE[-1]{api_key_id}, $CAROL_ID, 'metered under that key';

  # The key through the broker, and a server with no key source at all.
  $t->post_ok('/mcp/notes' => { bearer($BOB_KEY) } => $RPC)->status_is(200);
  is $SEEN[-1]{headers}{authorization}, "Bearer $BROKER_SECRET", 'api_key_ref: the key the broker resolved';
  $t->post_ok('/mcp/open' => { bearer($BOB_KEY) } => $RPC)->status_is(200);
  ok !exists $SEEN[-1]{headers}{authorization}, 'no key source: no Authorization at all, never the client\'s';

  for my $line (@LOG) {
    unlike $line->[1], qr/\Q$ENV_SECRET\E|\Q$BROKER_SECRET\E|\Q$ALICE_KEY\E|\Q$BOB_KEY\E/, 'no log line holds a key';
  }
  released_ok($t, 'JSON answers');
}

# --- the relay: statuses and bodies as the upstream gave them -----------------------------------
{
  $CFG = mcp_config();
  my ($t, $skeid) = proxy();
  @SEEN = @USAGE = @LOG = @CONTROLLERS = ();
  my %h = (bearer($ALICE_KEY), 'Content-Type' => 'application/json');

  $t->post_ok('/mcp/bookrag' => {%h} => '{"jsonrpc":"2.0","method":"notifications/initialized"}')
    ->status_is(202, 'a 202 without a body')->content_is('');
  is $USAGE[-1]{status_code}, 202, 'metered with its status';

  $t->post_ok('/mcp/bookrag' => {%h} => '{"jsonrpc":"2.0","id":2,"method":"expired"}')
    ->status_is(404, 'the upstream\'s own 404 (session gone) is relayed, the client must see it')
    ->json_is('/error/message' => 'Session not found', 'with the upstream\'s body');
  is $USAGE[-1]{status_code}, 404, 'metered as 404';
  is $USAGE[-1]{ok}, 1, 'a 4xx the upstream answered is a served request';

  $t->post_ok('/mcp/bookrag' => {%h} => '{"jsonrpc":"2.0","id":3,"method":"boom"}')
    ->status_is(500, 'a 500 is relayed')->content_is('upstream exploded');
  is $USAGE[-1]{ok}, 0, 'and metered as failed';

  $t->delete_ok('/mcp/bookrag' => { bearer($ALICE_KEY), 'Mcp-Session-Id' => 'sess-1' })
    ->status_is(204, 'DELETE is relayed')
    ->header_is('Mcp-Session-Ended' => 'sess-1', 'with the session id');
  is $SEEN[-1]{method}, 'DELETE', 'as a DELETE';
  is $SEEN[-1]{body}, '', 'without a body';

  # An upstream 401 is about Skeid's credential, not the client's key.
  @LOG = ();
  $t->post_ok('/mcp/bookrag' => {%h} => '{"jsonrpc":"2.0","id":4,"method":"unauthorized"}')
    ->status_is(502, 'an upstream 401 is a 502 to the client')
    ->json_is('/error/type' => 'upstream_error')
    ->content_unlike(qr/bad upstream token|internal\.example/, 'the upstream\'s 401 body stays here');
  ok !defined($t->tx->res->headers->www_authenticate), 'and so does its challenge';
  is $USAGE[-1]{status_code}, 502, 'metered as 502';
  is $USAGE[-1]{ok}, 0, 'failed';
  is $USAGE[-1]{error_type}, 'upstream_unauthorized', 'and why';
  ok grep({ $_->[0] eq 'error' && $_->[1] =~ /bookrag/ && $_->[1] =~ /401/ } @LOG), 'the operator is told, by server name';

  # A redirect names an upstream URL and is not followed.
  @LOG = ();
  $t->post_ok('/mcp/bookrag' => {%h} => '{"jsonrpc":"2.0","id":5,"method":"redirect"}')
    ->status_is(502, 'an upstream redirect is a 502 to the client')
    ->json_is('/error/type' => 'upstream_error')
    ->content_unlike(qr/internal\.example/, 'without its target');
  ok !defined($t->tx->res->headers->location), 'and without its Location';
  is $USAGE[-1]{status_code}, 502, 'metered as 502';
  is $USAGE[-1]{error_type}, 'upstream_redirect', 'and why';
  ok grep({ $_->[0] eq 'error' && $_->[1] =~ /bookrag/ && $_->[1] =~ m{internal\.example:8080/mcp/} } @LOG),
    'the operator is told where it leads';

  # HEAD rides the GET route; it is relayed like any method and must not hang.
  $t->head_ok('/mcp/bookrag' => { bearer($ALICE_KEY) })->status_is(200, 'a HEAD is answered')->content_is('');
  is $SEEN[-1]{method}, 'HEAD', 'relayed as a HEAD';

  # A named key source that yields no key: the server is not called.
  my $calls = @SEEN;
  @LOG = ();
  $t->post_ok('/mcp/nokey' => {%h} => $RPC)
    ->status_is(503, 'no upstream key: 503')
    ->json_is('/error/type' => 'upstream_key_unavailable')
    ->content_unlike(qr/SKEID_T_MCP_UNSET/, 'the client is not told which variable');
  is scalar(@SEEN), $calls, 'and the upstream is not called';
  is $USAGE[-1]{status_code}, 503, 'metered as 503';
  is $USAGE[-1]{error_type}, 'upstream_key_unavailable', 'with the reason';
  ok grep({ $_->[0] eq 'error' && $_->[1] =~ /SKEID_T_MCP_UNSET/ } @LOG), 'the log names the variable';

  $t->post_ok('/mcp/dead' => {%h} => $RPC)
    ->status_is(502, 'an upstream that is not there: 502')
    ->json_is('/error/type' => 'upstream_error')
    ->content_unlike(qr/127\.0\.0\.1/, 'without its address');
  is $USAGE[-1]{status_code}, 502, 'metered as 502';
  is $USAGE[-1]{ok}, 0, 'failed';
  released_ok($t, 'answers of every kind');
}

# --- a body over the request limit is refused, not relayed cut off -------------------------------
{
  $CFG = mcp_config(top => { mcp => { max_request_bytes => 4096, servers => mcp_config()->{mcp}{servers} } });
  my ($t, $skeid) = proxy();
  @SEEN = @USAGE = ();
  $t->post_ok('/mcp/bookrag' => { bearer($ALICE_KEY), 'Content-Type' => 'application/json' }
      => '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"pad":"' . ('x' x 8192) . '"}}')
    ->status_is(413, 'a body over the request limit: 413')
    ->json_is('/error/type' => 'invalid_request_error');
  is scalar(@SEEN), 0, 'and nothing of it goes upstream';
  is scalar(@USAGE), 0, 'nor is it metered';
}

# --- sub-paths and the query ----------------------------------------------------------------------
{
  $CFG = mcp_config();
  my ($t, $skeid) = proxy();
  @SEEN = @USAGE = ();
  my %h = (bearer($ALICE_KEY));

  $t->post_ok('/mcp/bookrag/messages/a%20b?sessionId=s%2F1&x=2' => {%h} => $RPC)->status_is(200)
    ->json_is('/result/path' => '/mcp/messages/a%20b', 'a sub-path is appended to the configured path');
  is $SEEN[-1]{query}, 'sessionId=s%2F1&x=2', 'and the query goes along';
  is $USAGE[-1]{endpoint}, '/mcp/bookrag', 'the event names the server, not the sub-path';

  $t->post_ok('/mcp/bookrag/' => {%h} => $RPC)->status_is(200)
    ->json_is('/result/path' => '/mcp', 'a trailing slash is the server itself');

  my $calls = @SEEN;
  my $events = @USAGE;
  for my $path ('/mcp/bookrag/../other', '/mcp/bookrag/%2e%2e/other', '/mcp/bookrag/a/./b', '/mcp/bookrag/a/%2E%2E',
    '/mcp/bookrag/..%2fother', '/mcp/bookrag/a%5c..%5cother') {
    my $tx = $t->ua->build_tx(POST => $path => {%h} => $RPC);
    $t->request_ok($tx);
    is_not_found($t, "POST $path");
  }
  is scalar(@SEEN), $calls, 'a path that climbs is never sent upstream';
  is scalar(@USAGE), $events, 'nor metered';
}

# --- what is not a server of this key is one 404 ------------------------------------------------
{
  $CFG = mcp_config();
  my ($t, $skeid) = proxy();
  @SEEN = @USAGE = @LOG = ();

  my @bodies;
  for my $case (
    [ 'a server of another key', '/mcp/notes',   $ALICE_KEY ],
    [ 'an unknown name',         '/mcp/nothing', $ALICE_KEY ],
    [ 'a stdio entry',           '/mcp/files',   $ALICE_KEY ],
    [ 'a key with no assignment', '/mcp/bookrag', $MALLORY_KEY ],
    [ 'the other way round',     '/mcp/bookrag', $BOB_KEY ],
  ) {
    my ($label, $path, $key) = @$case;
    for my $method (qw( POST GET DELETE )) {
      my $tx = $t->ua->build_tx($method => $path => { bearer($key) } => ($method eq 'POST' ? $RPC : ()));
      $t->request_ok($tx);
      is_not_found($t, "$method $path, $label");
      push @bodies, $t->tx->res->body;
      ok !defined($t->tx->res->headers->www_authenticate), "$method $path: no challenge";
    }
  }
  is scalar(keys %{{ map { $_ => 1 } @bodies }}), 1, 'every such answer is the same body: existence is not revealed';
  is scalar(@SEEN), 0, 'none of them reached an upstream';
  is scalar(@USAGE), 0, 'none was metered';

  for my $method (qw( POST GET DELETE )) {
    my $tx = $t->ua->build_tx($method => '/mcp/bookrag');
    $t->request_ok($tx)->status_is(401, "$method without a key: 401")
      ->header_is('WWW-Authenticate' => $CHALLENGE)
      ->json_is('/error/message' => 'Missing API key')
      ->json_is('/error/type' => 'invalid_request_error')
      ->json_is('/error/code' => 'invalid_api_key');
  }
  $t->post_ok('/mcp/nothing')->status_is(401, 'no key on an unknown name: 401 as well, not 404');
  is scalar(@SEEN), 0, 'still nothing upstream';

  $t->put_ok('/mcp/bookrag' => { bearer($ALICE_KEY) } => $RPC)->status_is(404, 'PUT is not a route');
  is scalar(@SEEN), 0, 'and is not relayed';
}

# --- with client_auth: the same gate as every client route --------------------------------------
{
  $CFG = mcp_config(top => { client_auth => { keys => [ 'alice', 'bob' ] } });
  my ($t, $skeid) = proxy();
  @SEEN = @USAGE = @LOG = ();

  for my $path ('/mcp/bookrag', '/v1/mcp/servers') {
    $t->get_ok($path)->status_is(401, "$path, no key: 401")
      ->header_is('WWW-Authenticate' => $CHALLENGE)->json_is('/error/message' => 'Missing API key');
    $t->get_ok($path => { bearer($MALLORY_KEY) })->status_is(401, "$path, a key not on the list: 401")
      ->header_is('WWW-Authenticate' => $CHALLENGE)->json_is('/error/message' => 'Invalid API key');
    # carol is assigned bookrag but is not on the client_auth list: the gate comes first.
    $t->get_ok($path => { bearer($CAROL_KEY) })->status_is(401, "$path, assigned but not let in: 401");
  }
  is scalar(@SEEN), 0, 'a refused request reaches no upstream';
  is scalar(@USAGE), 0, 'and writes no usage event';
  ok !grep({ $_->[0] =~ /\A(?:info|warn|error|fatal)\z/ } @LOG), 'and is not logged';

  $t->post_ok('/mcp/bookrag' => { bearer($ALICE_KEY) } => $RPC)->status_is(200, 'a listed and assigned key is relayed');
  $t->post_ok('/mcp/bookrag' => { bearer($BOB_KEY) } => $RPC);
  is_not_found($t, 'a listed key that is not assigned');
}

# --- an event stream is relayed as it arrives ---------------------------------------------------
{
  $CFG = mcp_config();
  my ($t, $skeid) = proxy();
  @SEEN = @USAGE = @CONTROLLERS = ();
  %HOLD = ();

  my ($body, $headers_seen, $done) = ('', 0, 0);
  my $tx = $t->ua->build_tx(POST => '/mcp/bookrag' => {
    bearer($ALICE_KEY), 'Content-Type' => 'application/json', Accept => 'application/json, text/event-stream',
  } => '{"jsonrpc":"2.0","id":7,"method":"stream"}');
  $tx->res->content->unsubscribe('read')->on(read => sub { $headers_seen = 1; $body .= $_[1] });
  $t->ua->start($tx => sub { $done = 1 });

  wait_for(sub { $headers_seen }, 'the response opens as soon as the upstream\'s headers are there');
  is $body, '', 'before any event was sent';
  is $tx->res->code, 200, 'with the status';
  is $tx->res->headers->content_type, 'text/event-stream', 'the content type';
  is $tx->res->headers->header('Mcp-Session-Id'), 'sess-stream', 'and the session id';
  ok $HOLD{stream}, 'the upstream holds the stream';

  my $first = qq(event: message\nid: 1\ndata: {"jsonrpc":"2.0","method":"notifications/progress"}\n\n);
  $HOLD{stream}->write_chunk($first);
  wait_for(sub { $body eq $first }, 'the first event reaches the client');
  ok !$done, 'while the stream is still open: nothing waited for its end';
  ok !$HOLD{stream_closed}, 'on the upstream side too';
  is scalar(@USAGE), 0, 'and it is not metered before it ends';

  # An event split over two writes arrives as it was written.
  my $second = qq(event: message\nid: 2\ndata: {"jsonrpc":"2.0","id":7,"result":{"ok":true}}\n\n);
  $HOLD{stream}->write_chunk(substr($second, 0, 20));
  wait_for(sub { $body eq $first . substr($second, 0, 20) }, 'half an event is passed on as half an event');
  $HOLD{stream}->write_chunk(substr($second, 20) => sub { $HOLD{stream}->finish });
  wait_for(sub { $done }, 'the stream ends when the upstream ends it');
  is $body, $first . $second, 'byte for byte';

  wait_for(sub { @USAGE == 1 }, 'one usage event, at the end');
  is $USAGE[0]{status_code}, 200, 'with the stream\'s status';
  is $USAGE[0]{ok}, 1, 'ok';
  is $USAGE[0]{endpoint}, '/mcp/bookrag', 'for the server';
  undef $tx;
  released_ok($t, 'a finished stream');
}

# --- the standing GET stream, and a client that leaves ------------------------------------------
{
  $CFG = mcp_config();
  my ($t, $skeid) = proxy();
  @SEEN = @USAGE = @CONTROLLERS = ();
  %HOLD = ();

  my ($body, $headers_seen, $done) = ('', 0, 0);
  my $tx = $t->ua->build_tx(GET => '/mcp/bookrag' => {
    bearer($ALICE_KEY), Accept => 'text/event-stream', 'Mcp-Session-Id' => 'sess-1', 'Last-Event-ID' => 'ev-9',
  });
  $tx->res->content->unsubscribe('read')->on(read => sub { $headers_seen = 1; $body .= $_[1] });
  $t->ua->start($tx => sub { $done = 1 });

  wait_for(sub { $headers_seen }, 'a GET stream is open for the client before its first event');
  is $tx->res->code, 200, 'status 200';
  is $tx->res->headers->content_type, 'text/event-stream', 'an event stream';
  is $SEEN[-1]{method}, 'GET', 'relayed as a GET';
  is $SEEN[-1]{headers}{'last-event-id'}, 'ev-9', 'with Last-Event-ID';
  is $SEEN[-1]{headers}{'mcp-session-id'}, 'sess-1', 'and the session id';
  is $SEEN[-1]{headers}{authorization}, "Bearer $ENV_SECRET", 'under the upstream\'s credential';

  my $event = qq(data: {"jsonrpc":"2.0","method":"notifications/tools/list_changed"}\n\n);
  $HOLD{get}->write_chunk($event);
  wait_for(sub { $body eq $event }, 'a server event arrives');

  # The client hangs up: the upstream connection is closed with it.
  Mojo::IOLoop->stream($tx->connection)->close;
  wait_for(sub { $HOLD{get_closed} }, 'a client that leaves closes the upstream stream');
  wait_for(sub { @USAGE == 1 }, 'and the stream is metered once');
  is $USAGE[0]{status_code}, 200, 'an event stream the client ended keeps its status';
  is $USAGE[0]{ok}, 1, 'and is not a failed request';
  is $USAGE[0]{error_type}, '', 'nor an abort';
  undef $tx;
  released_ok($t, 'a stream the client left');
}

# --- a client that leaves before the upstream answered ------------------------------------------
{
  # An upstream that accepts and never answers.
  my $silent_closed = 0;
  my $silent = Mojo::IOLoop->server({ address => '127.0.0.1' } => sub {
    my (undef, $stream) = @_;
    $stream->timeout(30);
    $stream->on(read => sub { });
    $stream->on(close => sub { $silent_closed++ });
  });
  my $silent_port = Mojo::IOLoop->acceptor($silent)->port;
  $CFG = mcp_config(servers => { silent => { url => "http://127.0.0.1:$silent_port/mcp", keys => ['alice'] } });
  my ($t, $skeid) = proxy();
  @USAGE = @CONTROLLERS = ();

  my $done = 0;
  my $tx = $t->ua->build_tx(POST => '/mcp/silent' => { bearer($ALICE_KEY) } => $RPC);
  $t->ua->start($tx => sub { $done = 1 });
  wait_for(sub { defined $tx->connection }, 'the request is on its way');
  Mojo::IOLoop->timer(0.2 => sub { Mojo::IOLoop->stream($tx->connection)->close });
  wait_for(sub { $silent_closed }, 'the client left: the upstream call is cancelled');
  wait_for(sub { @USAGE == 1 }, 'one usage event');
  is $USAGE[0]{status_code}, 499, 'recorded as a client abort';
  is $USAGE[0]{ok}, 0, 'failed';
  is $USAGE[0]{error_type}, 'client_abort', 'by its type';
  Mojo::IOLoop->remove($silent);
  undef $tx;
  released_ok($t, 'a request the client abandoned');
}

# --- the section is hot: on, changed and off from the next request -------------------------------
{
  # A failing loader is retried with a back-off (skeid #54), hence the clock.
  my $now = time;
  no warnings 'redefine';
  local *Langertha::Skeid::_now = sub { $now };

  $CFG = { names => { alice => $ALICE_ID, bob => $BOB_ID } };
  my ($t, $skeid) = proxy();
  @SEEN = @USAGE = ();
  $t->post_ok('/mcp/bookrag' => { bearer($ALICE_KEY) } => $RPC)->status_is(404, 'off');
  unlike $t->tx->res->body, qr/\Q$NOT_FOUND\E/, 'as an unknown path';

  $CFG = mcp_config();
  $t->post_ok('/mcp/bookrag' => { bearer($ALICE_KEY) } => $RPC)->status_is(200, 'the section added: on from the next request');
  $t->get_ok('/v1/mcp/servers' => { bearer($ALICE_KEY) })->status_is(200, 'on a GET as well');

  # Reassigned: alice loses bookrag, bob gets it.
  $CFG = mcp_config(servers => { bookrag => { %{ mcp_config()->{mcp}{servers}{bookrag} }, keys => ['bob'] } });
  $t->post_ok('/mcp/bookrag' => { bearer($ALICE_KEY) } => $RPC);
  is_not_found($t, 'an assignment taken away');
  $t->post_ok('/mcp/bookrag' => { bearer($BOB_KEY) } => $RPC)->status_is(200, 'and given to another key');

  # A reload that fails keeps the section that was in force.
  {
    local $SIG{__WARN__} = sub { };
    $CFG = mcp_config(servers => { broken => { url => 'not-a-url' } });
    $t->post_ok('/mcp/bookrag' => { bearer($BOB_KEY) } => $RPC)->status_is(200, 'a failed reload keeps the previous assignments');
    ok !exists $skeid->mcp_servers->{broken}, 'and none of the broken section';
    ok !$skeid->reload_status->{ok}, 'the reload is reported as failed';
    like $skeid->reload_status->{error}, qr/mcp\.servers\.broken\.url/, 'by the entry that broke it';
  }

  $now += 120;
  $CFG = { names => { alice => $ALICE_ID, bob => $BOB_ID } };
  $t->post_ok('/mcp/bookrag' => { bearer($BOB_KEY) } => $RPC)->status_is(404, 'the section removed: off again');
  unlike $t->tx->res->body, qr/\Q$NOT_FOUND\E/, 'as an unknown path';
  ok !$skeid->mcp_enabled, 'the gateway is off';
}

# --- routing.trust_key_id_header: the identity is the one every route uses ----------------------
{
  $CFG = mcp_config(top => { routing => { trust_key_id_header => 1 } });
  my ($t, $skeid) = proxy();
  @USAGE = ();
  $t->post_ok('/mcp/bookrag' => { bearer('sk-gateway-own'), 'x-skeid-key-id' => $ALICE_ID } => $RPC)
    ->status_is(200, 'with the trusted header, its key id is what the server is assigned to');
  is $USAGE[-1]{api_key_id}, $ALICE_ID, 'and what the request is metered under';
  ok !exists $SEEN[-1]{headers}{'x-skeid-key-id'}, 'the header itself stays here';
}

# --- response headers: a list passes, nothing else (review of k103) -----------------------------
{
  $CFG = mcp_config();
  my ($t, $skeid) = proxy();
  $t->post_ok('/mcp/bookrag' => { bearer($ALICE_KEY) } => '{"jsonrpc":"2.0","id":1,"method":"headers"}')
    ->status_is(200);
  my $h = $t->tx->res->headers;
  is $h->header('Mcp-Session-Id'), 'sess-h', 'Mcp-Session-Id passes';
  is $h->header('Mcp-Future-Reply'), 'kept', 'so does any Mcp-* header';
  is $h->header('Cache-Control'), 'no-store', 'Cache-Control passes';
  is $h->header('Retry-After'), '7', 'Retry-After passes';
  like $h->content_type, qr{\Aapplication/json}, 'Content-Type passes';
  for my $name (qw( Set-Cookie Access-Control-Allow-Origin Strict-Transport-Security )) {
    ok !defined($h->header($name)), "$name of the upstream does not reach the client";
  }
  isnt $h->header('Server') // '', 'internal-mcp/1.0', 'nor does its Server header';
}

# --- a long event stream is not cut by the user agent's response limit --------------------------
{
  $CFG = mcp_config();
  my ($t, $skeid) = proxy();
  # The default of every message object, 16 MiB, made small. The test client reads without limit.
  local $ENV{MOJO_MAX_MESSAGE_SIZE} = 1_000_000;
  $t->ua->max_response_size(0);
  @USAGE = ();
  $t->post_ok('/mcp/bookrag' => { bearer($ALICE_KEY) } => '{"jsonrpc":"2.0","id":1,"method":"big"}')
    ->status_is(200);
  cmp_ok length($t->tx->res->body), '>', 2_500_000, 'all of an event stream longer than max_response_size arrives';
  is $USAGE[-1]{ok}, 1, 'and is metered as ok';
}

# --- the request limit of the mcp section -------------------------------------------------------
{
  my $small = '{"jsonrpc":"2.0","id":1,"method":"tools/list","pad":"' . ('a' x 3000) . '"}';
  $CFG = mcp_config(top => { mcp => { max_request_bytes => 2048, servers => mcp_config()->{mcp}{servers} } });
  my ($t, $skeid) = proxy();
  is $skeid->mcp_max_request_bytes, 2048, 'the limit is loaded';
  @SEEN = @USAGE = ();
  $t->post_ok('/mcp/bookrag' => { bearer($ALICE_KEY) } => $small)
    ->status_is(413, 'a body over the limit is 413')
    ->json_is('/error/type' => 'invalid_request_error');
  is scalar(@SEEN), 0, 'it never reached the upstream';
  $t->post_ok('/mcp/bookrag' => { bearer($ALICE_KEY) } => '{"jsonrpc":"2.0","id":1,"method":"tools/list"}')
    ->status_is(200, 'one under it is relayed');

  # Larger than the server's own limit, when the operator asks for it.
  $CFG = mcp_config(top => { mcp => { max_request_bytes => 40_000_000, servers => mcp_config()->{mcp}{servers} } });
  my $big = '{"jsonrpc":"2.0","id":1,"method":"tools/list","pad":"' . ('a' x 17_000_000) . '"}';
  $t->post_ok('/mcp/bookrag' => { bearer($ALICE_KEY) } => $big)->status_is(200, 'a raised limit holds above the server\'s 16 MiB');
  @SEEN = ();

  $CFG = mcp_config();
  $t->post_ok('/mcp/bookrag' => { bearer($ALICE_KEY) } => $RPC)->status_is(200);
  is $skeid->mcp_max_request_bytes, 10485760, 'the default is 10 MiB';

}

# --- an event stream cut by the request timeout is not a clean one ------------------------------
{
  $CFG = mcp_config();
  my ($t, $skeid) = proxy();
  $t->app->ua->request_timeout(0.3);
  @USAGE = ();
  $t->get_ok('/mcp/bookrag' => { bearer($ALICE_KEY) })->status_is(200, 'the stream opened');
  wait_for(sub { scalar @USAGE }, 'an event was written when the time limit cut it');
  is $USAGE[-1]{ok}, 0, 'a stream the time limit cut is not ok';
  is $USAGE[-1]{error_type}, 'upstream_timeout', 'it says why';
  is $USAGE[-1]{status_code}, 200, 'under the status it was opened with';
}

done_testing;
