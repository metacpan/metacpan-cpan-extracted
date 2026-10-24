use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Mojo::IOLoop;
use File::Temp qw( tempfile );
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# Client authentication (skeid k90). With a client_auth section, the client routes let in only
# the key ids it lists and answer every other caller 401 -- in the dialect of the route, with a
# Bearer challenge, and before anything is routed, forwarded or metered. Without the section
# nothing is checked at all: a Skeid behind a gateway that authenticates keeps working exactly
# as it did. The list is hot: switching it on, rotating an id and switching it off hold from the
# next request on every client route, a GET included.

delete @ENV{qw( OPENBAO_ROLE_ID OPENBAO_SECRET_ID OPENBAO_ADDR SKEID_ADMIN_API_KEY
  SKEID_TRUST_KEY_ID_HEADER )};

my $ALICE_KEY   = 'sk-alice-secret';
my $BOB_KEY     = 'sk-bob-secret';
my $MALLORY_KEY = 'sk-mallory-secret';
my $ALICE_ID    = Langertha::Skeid->key_id_for_key($ALICE_KEY);
my $BOB_ID      = Langertha::Skeid->key_id_for_key($BOB_KEY);
my $MALLORY_ID  = Langertha::Skeid->key_id_for_key($MALLORY_KEY);

my $CHALLENGE = 'Bearer realm="skeid"';
my $MESSAGES  = [{ role => 'user', content => 'hi' }];

# Every client route, with the dialect its errors come in and what it answers once let in:
# the manifest is not enabled in these configs, so the route behind the gate is its 404.
my @ROUTES = (
  { method => 'GET',  path => '/v1/models',                 face => 'openai',    pass => 200 },
  { method => 'POST', path => '/v1/chat/completions',       face => 'openai',    pass => 200,
    body => { model => 'm', messages => $MESSAGES } },
  { method => 'POST', path => '/v1/embeddings',             face => 'openai',    pass => 200,
    body => { model => 'm', input => 'hi' } },
  { method => 'POST', path => '/v1/messages',               face => 'anthropic', pass => 200,
    body => { model => 'm', max_tokens => 10, messages => $MESSAGES } },
  { method => 'POST', path => '/api/chat',                  face => 'ollama',    pass => 200,
    body => { model => 'm', stream => \0, messages => $MESSAGES } },
  { method => 'POST', path => '/api/generate',              face => 'ollama',    pass => 200,
    body => { model => 'm', stream => \0, prompt => 'hi' } },
  { method => 'GET',  path => '/api/tags',                  face => 'ollama',    pass => 200 },
  { method => 'GET',  path => '/api/ps',                    face => 'ollama',    pass => 200 },
  { method => 'GET',  path => '/.well-known/langertha.json', face => 'manifest', pass => 404 },
);

my $UPSTREAM_CALLS = 0;
my @USAGE;
my @LOG;

sub settle {
  Mojo::IOLoop->timer(0.05 => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
}

# A proxy over a Skeid built from %opts, with one node whose upstream is mounted on the same app
# (outside the client routes, so the gate never sees it) and counts every call it gets.
sub proxy {
  my (%opts) = @_;
  my $skeid = Langertha::Skeid->new(
    route_wait_timeout_ms  => 50,
    route_wait_poll_ms     => 5,
    config_reload_interval => 0,
    store_usage_event      => sub { push @USAGE, $_[1]; return { ok => 1 } },
    %opts,
  );
  my $app = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
  $app->log->level('trace');
  $app->log->unsubscribe('message')->on(message => sub {
    my ($log, $level, @lines) = @_;
    push @LOG, [ $level, join(' ', @lines) ];
  });
  $app->routes->post('/__up/v1/chat/completions' => sub {
    my ($c) = @_;
    $UPSTREAM_CALLS++;
    $c->render(json => {
      id => 'c1', object => 'chat.completion', model => 'm',
      choices => [{ index => 0, message => { role => 'assistant', content => 'ok' }, finish_reason => 'stop' }],
      usage => { prompt_tokens => 4, completion_tokens => 2, total_tokens => 6 },
    });
  });
  $app->routes->post('/__up/v1/embeddings' => sub {
    my ($c) = @_;
    $UPSTREAM_CALLS++;
    $c->render(json => {
      object => 'list', model => 'm',
      data   => [{ object => 'embedding', index => 0, embedding => [0.1, 0.2] }],
      usage  => { prompt_tokens => 1, total_tokens => 1 },
    });
  });
  my $t = Test::Mojo->new($app);
  my $up = $t->ua->server->nb_url->clone->path('/__up/v1');
  $skeid->add_node(id => 'n1', url => "$up", model => 'm', engine => 'openai', max_conns => 2);
  return ($t, $skeid);
}

sub call {
  my ($t, $route, $headers) = @_;
  $headers ||= {};
  return $route->{method} eq 'GET'
    ? $t->get_ok($route->{path} => $headers)
    : $t->post_ok($route->{path} => $headers => json => $route->{body});
}

# A 401 from the gate, in the route's dialect, carrying the challenge and nothing of the caller.
sub is_refused {
  my ($t, $route, $headers, $message, $label) = @_;
  call($t, $route, $headers);
  $label = "$route->{method} $route->{path}, $label";
  $t->status_is(401, "$label: 401")
    ->header_is('WWW-Authenticate' => $CHALLENGE, "$label: Bearer challenge");
  my $face = $route->{face};
  if ($face eq 'anthropic') {
    $t->json_is('/type' => 'error', "$label: Anthropic envelope")
      ->json_is('/error/type' => 'authentication_error', "$label: authentication_error")
      ->json_is('/error/message' => $message, "$label: message");
  } elsif ($face eq 'ollama') {
    $t->json_is('/error' => $message, "$label: Ollama's plain string error");
  } else {
    $t->json_is('/error/message' => $message, "$label: message")
      ->json_is('/error/type' => 'invalid_request_error', "$label: OpenAI type")
      ->json_is('/error/code' => 'invalid_api_key', "$label: OpenAI code");
  }
  if ($face eq 'manifest') {
    $t->header_is('Cache-Control' => 'private, no-store', "$label: the manifest's cache headers")
      ->header_like(Vary => qr/Authorization/, "$label: varies on the identity");
  }
  my $body = $t->tx->res->body;
  for my $secret ($ALICE_KEY, $BOB_KEY, $MALLORY_KEY, $ALICE_ID, $BOB_ID, $MALLORY_ID) {
    unlike $body, qr/\Q$secret\E/, "$label: the body names neither key nor key id";
  }
  return;
}

sub is_let_in {
  my ($t, $route, $headers, $label) = @_;
  call($t, $route, $headers);
  $t->status_is($route->{pass}, "$route->{method} $route->{path}, $label: let in");
  return;
}

# --- without client_auth nothing is checked: a Skeid behind a gateway works as before ---
{
  my ($t, $skeid) = proxy(config_loader => sub { { names => { alice => $ALICE_ID } } });
  ok !$skeid->client_auth_enabled, 'no client_auth section: client authentication is off';
  ok $skeid->client_key_allowed('anonymous'), 'and every caller is allowed, no key included';

  $UPSTREAM_CALLS = 0;
  @USAGE = ();
  for my $route (@ROUTES) {
    is_let_in($t, $route, {}, 'no key, no client_auth');
    is_let_in($t, $route, { Authorization => "Bearer $MALLORY_KEY" }, 'unknown key, no client_auth');
    ok !defined($t->tx->res->headers->header('WWW-Authenticate')), "$route->{path}: no challenge";
  }
  settle();
  is $UPSTREAM_CALLS, 10, 'every routed POST reached the upstream, with and without a key';
  is scalar(@USAGE), 10, 'and was metered';
  $t->get_ok('/health')->status_is(200)->json_is('/status' => 'ok');
}

# --- with client_auth: no key or an unlisted key is 401 on every client route, and nothing else ---
{
  my ($t, $skeid) = proxy(
    admin_api_key => 'adm-secret',
    config_loader => sub { {
      names       => { alice => $ALICE_ID },
      client_auth => { keys => [ 'alice', $BOB_ID ] },
    } },
  );
  ok $skeid->client_auth_enabled, 'client_auth: client authentication is on';
  is_deeply $skeid->client_auth_keys, { $ALICE_ID => 1, $BOB_ID => 1 },
    'a names: entry resolves to its id, a key id stands as it is';
  ok !$skeid->client_key_allowed('anonymous'), 'anonymous is never on the list';
  ok !$skeid->client_key_allowed(undef), 'nor is no id at all';
  ok !$skeid->client_key_allowed($MALLORY_ID), 'an unlisted id is not allowed';
  ok $skeid->client_key_allowed($ALICE_ID), 'a listed id is';

  $UPSTREAM_CALLS = 0;
  @USAGE = ();
  @LOG = ();
  for my $route (@ROUTES) {
    is_refused($t, $route, {}, 'Missing API key', 'no key');
    is_refused($t, $route, { Authorization => "Bearer $MALLORY_KEY" }, 'Invalid API key', 'unknown bearer key');
    is_refused($t, $route, { 'x-api-key' => $MALLORY_KEY }, 'Invalid API key', 'unknown x-api-key');
    is_refused($t, $route, { Authorization => 'Bearer ' }, 'Missing API key', 'empty bearer');
  }
  settle();
  is $UPSTREAM_CALLS, 0, 'a refused request never reaches the upstream';
  is scalar(@USAGE), 0, 'and writes no usage event';
  my $metrics = $skeid->node_metrics('n1');
  is $metrics->{started}, 0, 'and takes no request.start';
  is $metrics->{inflight}, 0, 'so no slot can leak';
  my @loud = grep { $_->[0] =~ /\A(?:info|warn|error|fatal)\z/ } @LOG;
  is scalar(@loud), 0, 'a refusal is not logged: the routes are public, a line each would be a flood'
    or diag explain \@loud;
  for my $secret ($MALLORY_KEY, $MALLORY_ID) {
    ok !grep({ $_->[1] =~ /\Q$secret\E/ } @LOG), 'no log line at any level names the key or its id';
  }

  $t->get_ok('/nope')->status_is(404, 'an unknown path keeps its 404: only real client routes are gated');
  $t->get_ok('/health')->status_is(200, '/health stays open')->json_is('/status' => 'ok');
  $t->get_ok('/skeid/nodes' => { Authorization => 'Bearer adm-secret' })
    ->status_is(200, '/skeid/* takes the admin key, which is not on the client list');
  $t->get_ok('/skeid/nodes')->status_is(401, 'and keeps its own challenge')
    ->header_is('WWW-Authenticate' => 'Bearer realm="skeid-admin"');
  $t->get_ok('/skeid/registry/snapshot' => { Authorization => 'Bearer adm-secret' })
    ->status_is(404, 'the registry snapshot keeps its own rules (off here)');

  @USAGE = ();
  for my $route (@ROUTES) {
    is_let_in($t, $route, { Authorization => "Bearer $ALICE_KEY" }, 'listed by name, bearer');
    is_let_in($t, $route, { 'x-api-key' => $BOB_KEY }, 'listed by id, x-api-key');
    ok !defined($t->tx->res->headers->header('WWW-Authenticate')), "$route->{path}: no challenge";
  }
  settle();
  is $UPSTREAM_CALLS, 10, 'a listed key is routed';
  is_deeply [ sort { $a cmp $b } map { $_->{api_key_id} } @USAGE ],
    [ sort { $a cmp $b } ($ALICE_ID) x 5, ($BOB_ID) x 5 ], 'and metered under its own id';
}

# --- a short (pre-ADR 0016) id on the list matches the full id it is the prefix of ---
{
  my $short = substr($ALICE_ID, 0, 14);
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my ($t, $skeid) = proxy(config_loader => sub { { client_auth => { keys => $short } } });
  ok grep({ /short key id/ } @warnings), 'a short id loads with the deprecation warning';
  is_deeply $skeid->client_auth_keys, { $short => 1 }, 'a single id stands without a list';
  $t->get_ok('/v1/models' => { Authorization => "Bearer $ALICE_KEY" })
    ->status_is(200, 'the key whose full id starts with the short one is let in');
  $t->get_ok('/v1/models' => { Authorization => "Bearer $BOB_KEY" })->status_is(401, 'another is not');
}

# --- routing.trust_key_id_header: the identity routing believes is the one checked ---
{
  my ($t) = proxy(config_loader => sub { {
    routing     => { trust_key_id_header => 1 },
    client_auth => { keys => [ $ALICE_ID ] },
  } });
  $t->get_ok('/v1/models' => { 'x-skeid-key-id' => $ALICE_ID })
    ->status_is(200, 'trusted header naming a listed id, no key: let in');
  $t->get_ok('/v1/models' => { 'x-skeid-key-id' => $BOB_ID, Authorization => "Bearer $ALICE_KEY" })
    ->status_is(401, 'trusted header naming an unlisted id: refused, whatever key came along');
  $t->get_ok('/api/tags' => { 'x-api-key-id' => $ALICE_ID })->status_is(200, 'x-api-key-id too');

  my ($untrusting) = proxy(config_loader => sub { { client_auth => { keys => [ $ALICE_ID ] } } });
  $untrusting->get_ok('/v1/models' => { 'x-skeid-key-id' => $ALICE_ID })
    ->status_is(401, 'without trust_key_id_header the header names nobody');
}

# --- hot reload: on, rotate, a failed reload, off -- each from the next request ---
{
  my $cfg = {};
  my $loads = 0;
  my $now = 1_000_000;
  no warnings 'redefine';
  local *Langertha::Skeid::_now = sub { $now };
  my ($t, $skeid) = proxy(config_loader => sub { $loads++; return $cfg });
  my %models = (method => 'GET', path => '/v1/models', face => 'openai', pass => 200);
  my %tags   = (method => 'GET', path => '/api/tags',  face => 'ollama', pass => 200);

  is_let_in($t, \%models, {}, 'before client_auth');

  $cfg = { client_auth => { keys => [ $ALICE_ID ] } };
  is_refused($t, \%models, {}, 'Missing API key', 'switched on by a reload');
  is_refused($t, \%tags, { Authorization => "Bearer $BOB_KEY" }, 'Invalid API key', 'switched on, Ollama GET');
  is_let_in($t, \%models, { Authorization => "Bearer $ALICE_KEY" }, 'listed after the reload');

  $cfg = { client_auth => { keys => [ $BOB_ID ] } };
  is_refused($t, \%models, { Authorization => "Bearer $ALICE_KEY" }, 'Invalid API key', 'rotated out');
  is_let_in($t, \%models, { Authorization => "Bearer $BOB_KEY" }, 'rotated in');

  my $pasted = 'sk-pasted-instead-of-its-id';
  $cfg = { client_auth => { keys => [ $BOB_ID, $pasted ] } };
  my @warnings;
  {
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    is_let_in($t, \%models, { Authorization => "Bearer $BOB_KEY" }, 'a failed reload keeps the list');
    is_refused($t, \%models, { Authorization => "Bearer $ALICE_KEY" }, 'Invalid API key',
      'a failed reload lets nobody new in');
  }
  ok scalar(@warnings), 'the failed reload is warned';
  ok !grep({ /\Q$pasted\E/ } @warnings), 'and the warning does not carry the pasted value';
  like $skeid->reload_status->{error}, qr/client_auth\.keys entry 2 /, 'the error names the entry by position';
  unlike $skeid->reload_status->{error}, qr/\Q$pasted\E/, 'and not by value';

  # All or nothing: a config whose client_auth is fine but fails in a later section leaves the
  # list it would have set behind too. A failing loader is retried with a back-off (skeid #54),
  # hence the clock.
  $cfg = { client_auth => { keys => [ $ALICE_ID ] }, registry => { enabled => 1 } };
  $now += 120;
  {
    local $SIG{__WARN__} = sub { };
    is_let_in($t, \%models, { Authorization => "Bearer $BOB_KEY" }, 'a later section failed: list kept');
    is_refused($t, \%models, { Authorization => "Bearer $ALICE_KEY" }, 'Invalid API key',
      'a later section failed: its list was not applied');
  }
  like $skeid->reload_status->{error}, qr/registry/, 'the failure was the registry section';

  $cfg = {};
  $now += 120;
  is_let_in($t, \%models, {}, 'switched off by removing the section');
  is_let_in($t, \%tags, { Authorization => "Bearer $MALLORY_KEY" }, 'switched off, Ollama GET');
  ok !$skeid->client_auth_enabled, 'removed from the config, client authentication is off again';
  ok $loads > 1, 'the GETs themselves ran the reloads';
}

# --- the reload throttle holds on the gate: a public GET does not rerun the loader each time ---
{
  my $loads = 0;
  my ($t) = proxy(
    config_reload_interval => 3600,
    config_loader          => sub { $loads++; return { client_auth => { keys => [ $ALICE_ID ] } } },
  );
  $t->get_ok('/v1/models')->status_is(401) for 1 .. 5;
  is $loads, 1, 'five anonymous GETs inside the reload interval load nothing';
}

# --- a config file: the section switches on and off with the file ---
{
  my ($fh, $path) = tempfile();
  close $fh;
  my $mtime = time - 100;
  my $write = sub {
    my ($yaml) = @_;
    open my $out, '>', $path or die "open $path: $!";
    print {$out} $yaml;
    close $out or die "close $path: $!";
    $mtime += 10;
    utime($mtime, $mtime, $path) or die "utime $path: $!";
  };
  $write->("routing:\n  wait_poll_ms: 5\n");
  my ($t) = proxy(config_file => $path);
  $t->get_ok('/v1/models')->status_is(200, 'file without client_auth: open');

  $write->("names:\n  alice: $ALICE_ID\nclient_auth:\n  keys: [alice]\n");
  $t->get_ok('/v1/models')->status_is(401, 'file with client_auth: closed from the next GET');
  $t->get_ok('/v1/models' => { Authorization => "Bearer $ALICE_KEY" })->status_is(200, 'to all but the listed');

  $write->("routing:\n  wait_poll_ms: 5\n");
  $t->get_ok('/v1/models')->status_is(200, 'section removed from the file: open again');
  unlink $path;
}

# --- load errors: nothing ambiguous loads, and a pasted key is never echoed ---
{
  my $fails = sub {
    my ($cfg, $like, $label, $secret) = @_;
    my $ok = eval { Langertha::Skeid->new(config_loader => sub { $cfg }); 1 };
    my $err = $@ // '';
    ok !$ok, "$label: croaks";
    like $err, $like, "$label: says why";
    unlike $err, qr/\Q$secret\E/, "$label: without the offending value" if defined $secret;
  };
  $fails->({ client_auth => { keys => [ $ALICE_ID, 'sk-a-pasted-key' ] } },
    qr/client_auth\.keys entry 2 is neither a names: entry nor a key id/,
    'an entry that is neither a name nor an id', 'sk-a-pasted-key');
  $fails->({ client_auth => { keys => [ 'anonymous' ] } },
    qr/entry 1 is neither/, 'anonymous', undef);
  $fails->({ client_auth => { keys => [ { id => $ALICE_ID } ] } },
    qr/entry 1 is neither/, 'a structure as an entry', undef);
  $fails->({ client_auth => { keys => [ 'K_' . substr($ALICE_ID, 2) ] } },
    qr/entry 1 is neither/, 'an id that is not one, case and all', undef);
  $fails->({ names => { bob => 'sk-bob-pasted' }, client_auth => { keys => [ 'bob' ] } },
    qr/entry 1 is the names: entry 'bob', which does not map to a key id/,
    'a name that maps to no key id', 'sk-bob-pasted');
  $fails->({ client_auth => {} }, qr/client_auth needs a keys list/, 'client_auth without keys');
  $fails->({ client_auth => { keys => undef } }, qr/client_auth needs a keys list/, 'keys: ~');
  $fails->({ client_auth => undef }, qr/client_auth must be a hash/, 'an empty section');
  $fails->({ client_auth => [ $ALICE_ID ] }, qr/client_auth must be a hash/, 'a bare list as the section');
  $fails->({ client_auth => { keys => { a => $ALICE_ID } } }, qr/keys must be a list/, 'keys as a hash');
  $fails->({ client_auth => { keys => [ $ALICE_ID ], key => 'x' } },
    qr/client_auth: unknown key 'key'/, 'an unknown key in the section');
}

# --- an empty list loads, says so once, and lets nobody in ---
{
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my ($t, $skeid) = proxy(config_loader => sub { { client_auth => { keys => [] } } });
  is scalar(grep { /client_auth\.keys is empty/ } @warnings), 1, 'an empty list warns once at load';
  ok $skeid->client_auth_enabled, 'and is on, not off';
  $t->get_ok('/v1/models' => { Authorization => "Bearer $ALICE_KEY" })->status_is(401, 'nobody gets in');
  $t->get_ok('/v1/models')->status_is(401, 'not even without a key');
  is scalar(grep { /client_auth\.keys is empty/ } @warnings), 1, 'and the unchanged config does not warn again';
}

done_testing;
