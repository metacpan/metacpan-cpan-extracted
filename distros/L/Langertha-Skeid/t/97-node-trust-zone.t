#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Mojo;
use FindBin;
use lib "$FindBin::Bin/lib";
use File::Temp qw( tempdir );
use JSON::MaybeXS qw( encode_json );
use MIME::Base64 qw( encode_base64 );
use Mojo::IOLoop;
use Langertha::Skeid;
use Langertha::Skeid::Proxy;
use RealtimeHarness qw( settle run_until );

# The trust zone of a node (skeid k128, ADR 0032). A node is `external` (a provider) unless the
# main config says `internal`. An external node hears only an allowlist of the client's headers
# -- Content-Type, Accept, anthropic-version, anthropic-beta, OpenAI-Beta -- plus its own key and
# `User-Agent: Langertha-Skeid`: never who called, from where, under which trace, nor the client's
# credential. An internal node hears the trace ids but still not the client's address or cookies.
# An external node without a key source of its own cannot load, and a node file cannot grant its
# nodes a trust its main-config entry did not.

delete @ENV{qw( OPENBAO_ROLE_ID OPENBAO_SECRET_ID OPENBAO_ADDR SKEID_ADMIN_API_KEY
  SKEID_TRUST_KEY_ID_HEADER SKEID_USAGE_DB SKEID_K128_NODE_KEY )};

my $NODE_KEY    = 'sk-test-node-k128';
my $CALLER_KEY  = 'sk-test-caller-k128';
my $CORRELATION = 'X-Correlation-ID';
my $CLIENT_IP   = '203.0.113.7';

# Everything a caller -- or the deployment in front of Skeid -- may put on a request.
my %CALLER = (
  'X-Forwarded-For'   => "$CLIENT_IP, 10.0.0.1",
  'X-Forwarded-Proto' => 'https',
  'X-Forwarded-Host'  => 'api.example',
  'Forwarded'         => "for=$CLIENT_IP;proto=https",
  'X-Real-IP'         => $CLIENT_IP,
  'Cookie'            => 'session=cookie-k128',
  'X-Skeid-Anything'  => 'skeid-hint-k128',
  'X-Api-Key-Id'      => 'forged-key-id-k128',
  'X-Request-Id'      => 'req-k128-client',
  'traceparent'       => '00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01',
  'tracestate'        => 'acme=t61rcWkgMzE',
  'baggage'           => 'userId=alice-k128',
  'X-Acme-Tenant'     => 'tenant-k128',
  'User-Agent'        => 'AcmeAgent/1.0 (alice-k128)',
  'Authorization'     => "Bearer $CALLER_KEY",
  'X-Api-Key'         => $CALLER_KEY,
  $CORRELATION        => 'run-k128',
  'Accept'            => 'application/json',
  'anthropic-version' => '2023-06-01',
  'anthropic-beta'    => 'prompt-caching-2024-07-31',
  'OpenAI-Beta'       => 'assistants=v2',
);

my %CALLER_LC = map { lc($_) => $CALLER{$_} } keys %CALLER;

# The provider protocol headers an external node is told, exactly as the client sent them.
my @PROTOCOL = qw( anthropic-version anthropic-beta openai-beta );

# The caller's headers an external node must not hear, by lowercased name. Authorization and
# User-Agent are there, but with Skeid's values: checked by value, not by name.
my @EXTERNAL_FORBIDDEN = map { lc } grep {
  !/\A(?:accept|anthropic-version|anthropic-beta|openai-beta|authorization|user-agent)\z/i } keys %CALLER;

# What the transport itself adds to a request to a node: not the client's, so not judged.
my %TRANSPORT = map { $_ => 1 } qw( host content-length accept-encoding connection );

# Values that identify the caller; none may reach an external node in any header.
my @CALLER_VALUES = ($CLIENT_IP, $CALLER_KEY, 'cookie-k128', 'skeid-hint-k128', 'forged-key-id-k128',
  'req-k128-client', '0af7651916cd43dd8448eb211c80319c', 't61rcWkgMzE', 'alice-k128', 'tenant-k128', 'run-k128');

my @UPSTREAM;

sub remember {
  my ($c, $route) = @_;
  my $h = $c->req->headers;
  push @UPSTREAM, { route => $route, tag => $c->stash('tag'),
    headers => { map { lc($_) => $h->header($_) } @{ $h->names } } };
}

my $CHUNK = sub {
  'data: ' . encode_json({ id => 'c1', object => 'chat.completion.chunk', model => 'm',
    choices => [{ index => 0, delta => $_[0], finish_reason => $_[1] }] }) . "\n\n";
};

sub fake_chat {
  my ($c) = @_;
  remember($c, 'chat');
  my $body = $c->req->json || {};
  unless ($body->{stream}) {
    return $c->render(json => { id => 'c1', object => 'chat.completion', model => $body->{model},
      choices => [{ index => 0, message => { role => 'assistant', content => 'ok' }, finish_reason => 'stop' }],
      usage => { prompt_tokens => 3, completion_tokens => 1, total_tokens => 4 } });
  }
  $c->res->headers->content_type('text/event-stream');
  $c->write_chunk($CHUNK->({ role => 'assistant', content => 'ok' }, undef));
  $c->write_chunk($CHUNK->({}, 'stop'));
  $c->write_chunk("data: [DONE]\n\n" => sub { $c->finish });
}

sub fake_audio {
  my ($c) = @_;
  remember($c, 'audio');
  $c->render(json => { text => 'hallo', usage => { type => 'duration', seconds => 2 } });
}

sub fake_rerank {
  my ($c) = @_;
  remember($c, 'rerank');
  $c->render(json => { id => 'r1', model => 'm',
    results => [ { index => 0, relevance_score => 0.9 }, { index => 1, relevance_score => 0.1 } ],
    usage => { total_tokens => 7 } });
}

sub fake_docling {
  my ($c) = @_;
  remember($c, 'documents');
  $c->render(json => { document => { filename => 'a.pdf', md_content => '# A' }, status => 'success',
    errors => [], processing_time => 0.1, timings => {} });
}

# A proxy over a Skeid that sends the correlation header to its usage rows, with the fake nodes
# mounted on the same app. Nodes come from %nodes: id => { add_node fields }.
sub proxy {
  my (%nodes) = @_;
  @UPSTREAM = ();
  my $skeid = Langertha::Skeid->new(
    route_wait_timeout_ms  => 60,
    route_wait_poll_ms     => 5,
    config_reload_interval => 0,
    config_loader          => sub { +{ routing => { correlation_header => $CORRELATION } } },
    store_usage_event      => sub { return { ok => 1 } },
  );
  my $app = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
  $app->log->level('fatal');
  $app->routes->post('/__up/:tag/v1/chat/completions' => \&fake_chat);
  $app->routes->post('/__up/:tag/v1/audio/:kind'      => \&fake_audio);
  $app->routes->post('/__up/:tag/v1/rerank'           => \&fake_rerank);
  $app->routes->post('/__up/:tag/v1/convert/:kind'    => \&fake_docling);
  my $t = Test::Mojo->new($app);
  my $up = $t->ua->server->nb_url->clone;
  for my $id (sort keys %nodes) {
    $skeid->add_node(id => $id, url => $up->clone->path("/__up/$id")->to_string, engine => 'openai',
      max_conns => 4, %{ $nodes{$id} });
  }
  return ($t, $skeid);
}

my $BOUNDARY = 'k128-boundary-7f3a';
sub audio_form {
  my ($model) = @_;
  return join('',
    "--$BOUNDARY\r\n", qq{Content-Disposition: form-data; name="model"\r\n\r\n}, $model, "\r\n",
    "--$BOUNDARY\r\n", qq{Content-Disposition: form-data; name="file"; filename="a.wav"\r\n},
    "Content-Type: audio/wav\r\n\r\n", "RIFF\x00\x01 k128", "\r\n",
    "--$BOUNDARY--\r\n");
}

# One request on each route that relays to a node: [ label, route, request ].
sub requests {
  my ($model) = @_;
  my $msgs = [{ role => 'user', content => 'hi' }];
  return (
    [ 'openai json',      'chat', [ post => '/v1/chat/completions', json => { model => $model, messages => $msgs } ] ],
    [ 'openai stream',    'chat', [ post => '/v1/chat/completions', json => { model => $model, messages => $msgs, stream => \1 } ] ],
    [ 'anthropic json',   'chat', [ post => '/v1/messages', json => { model => $model, max_tokens => 5, messages => $msgs } ] ],
    [ 'anthropic stream', 'chat', [ post => '/v1/messages', json => { model => $model, max_tokens => 5, messages => $msgs, stream => \1 } ] ],
    [ 'ollama json',      'chat', [ post => '/api/chat', json => { model => $model, messages => $msgs, stream => \0 } ] ],
    [ 'audio',            'audio', [ post => '/v1/audio/transcriptions',
        { 'Content-Type' => "multipart/form-data; boundary=$BOUNDARY" }, audio_form($model) ] ],
    [ 'rerank',           'rerank', [ post => '/v1/rerank', json => { model => $model, query => 'q', documents => [ 'a', 'b' ] } ] ],
  );
}

# Runs a request with every caller header set; returns what the node received.
sub call {
  my ($t, $request) = @_;
  my ($method, $path, @rest) = @$request;
  my %headers = %CALLER;
  %headers = (%headers, %{ shift @rest }) if ref($rest[0]) eq 'HASH';
  my $before = @UPSTREAM;
  my $tx = $t->ua->build_tx(uc($method) => $path => \%headers => @rest);
  $t->request_ok($tx);
  # A stream finishes on the node after the client has its answer.
  run_until(sub { @UPSTREAM > $before }, 2);
  return $UPSTREAM[-1] if @UPSTREAM > $before;
  return;
}

# What an external node must and must not have been sent.
sub external_contract {
  my ($label, $seen, %o) = @_;
  my $h = $seen->{headers};
  ok !exists $h->{$_}, "$label: no $_ for an external node" for @EXTERNAL_FORBIDDEN, 'x-api-key';
  is $h->{'user-agent'}, 'Langertha-Skeid', "$label: the User-Agent is Skeid's, not the caller's";
  is $h->{authorization}, "Bearer $NODE_KEY", "$label: Authorization is the node's key, not the caller's";
  is $h->{$_}, $CALLER_LC{$_}, "$label: $_ goes on as the caller sent it" for @PROTOCOL;
  is $h->{accept}, 'application/json', "$label: Accept goes on" unless $o{no_accept};
  like $h->{'content-type'} // '', $o{content_type} || qr{\Aapplication/json}, "$label: Content-Type goes on";
  my %allowed = (%TRANSPORT, map { $_ => 1 } @PROTOCOL, qw( accept content-type authorization user-agent ),
    @{ $o{transport} || [] });
  my @extra = grep { !$allowed{$_} } sort keys %$h;
  is_deeply \@extra, [], "$label: nothing outside the allowlist reaches the node" or diag explain $h;
  my $all = join "\n", map { "$_: $h->{$_}" } sort keys %$h;
  my @leaked = grep { index($all, $_) >= 0 } @CALLER_VALUES;
  is_deeply \@leaked, [], "$label: no value identifying the caller is in any header";
}

subtest 'external node: only the allowlist, its own key and Skeid\'s User-Agent' => sub {
  local $ENV{SKEID_K128_NODE_KEY} = $NODE_KEY;
  my ($t) = proxy(ext => { model => 'm-ext', api_key_env => 'SKEID_K128_NODE_KEY' });
  for my $case (requests('m-ext')) {
    my ($label, $route, $request) = @$case;
    my $seen = call($t, $request);
    $t->status_is(200, "$label: answered");
    ok $seen, "$label: the request reached the node" or next;
    is $seen->{route}, $route, "$label: at the node's $route endpoint";
    is $seen->{tag}, 'ext', "$label: the external node";
    external_contract($label, $seen,
      ($route eq 'audio' ? (content_type => qr{\Amultipart/form-data; boundary=}) : ()));
  }
};

subtest 'external documents node: the same allowlist on the documents relay' => sub {
  local $ENV{SKEID_K128_NODE_KEY} = $NODE_KEY;
  my ($t) = proxy('ext-docs' => { kind => 'documents', api_key_env => 'SKEID_K128_NODE_KEY' });
  my $body = encode_json({ options => { to_formats => ['md'] },
    file_sources => [ { base64_string => encode_base64('%PDF-1.4 k128', ''), filename => 'a.pdf' } ] });
  my $seen = call($t, [ post => '/v1/convert/source', { 'Content-Type' => 'application/json' }, $body ]);
  $t->status_is(200, 'documents: answered');
  ok $seen, 'documents: the request reached the node' or return;
  is $seen->{tag}, 'ext-docs', 'documents: the external node';
  external_contract('documents', $seen);
};

subtest 'external realtime node: the handshake carries the allowlist only' => sub {
  local $ENV{SKEID_K128_NODE_KEY} = $NODE_KEY;
  my $h = RealtimeHarness->new;
  $h->add_node('rt-ext', trust => 'external', api_key_env => 'SKEID_K128_NODE_KEY');
  my %headers = %CALLER;
  my $client = $h->connect('/v1/realtime?model=whisper-rt&intent=transcription', headers => \%headers);
  is $client->{code}, 101, 'realtime: the handshake is upgraded';
  my $seen = $h->upstream->[0];
  ok $seen, 'realtime: the node was asked' or return;
  # The WebSocket handshake is Skeid's own; its Sec-WebSocket-* and Upgrade are the transport's.
  my @ws = grep { /\A(?:upgrade|sec-websocket-)/ } keys %{ $seen->{headers} };
  external_contract('realtime', $seen, transport => \@ws, no_accept => 1, content_type => qr/\A\z/);
  $client->{tx}->finish(1000);
  run_until(sub { $client->{closed} }, 2);
  settle(0.05);
};

subtest 'internal node: trace ids go on, the client\'s address, cookies and correlation id do not' => sub {
  my ($t) = proxy(int => { model => 'm-int', trust => 'internal' });
  for my $case (requests('m-int')) {
    my ($label, $route, $request) = @$case;
    my $seen = call($t, $request);
    $t->status_is(200, "$label: answered");
    ok $seen, "$label: the request reached the node" or next;
    my $h = $seen->{headers};
    is $h->{'x-request-id'}, 'req-k128-client', "$label: X-Request-Id reaches an internal node";
    is $h->{traceparent}, $CALLER{traceparent}, "$label: traceparent too";
    is $h->{tracestate}, $CALLER{tracestate}, "$label: and tracestate";
    is $h->{'x-acme-tenant'}, 'tenant-k128', "$label: a deployment header goes on to an internal node";
    is $h->{'user-agent'}, $CALLER{'User-Agent'}, "$label: the caller's User-Agent goes on";
    # A keyless internal node from the main config: the documented pass-through.
    is $h->{authorization}, "Bearer $CALLER_KEY", "$label: a keyless internal node gets the caller's key";
    ok !exists $h->{$_}, "$label: no $_ for an internal node"
      for qw( x-forwarded-for x-forwarded-proto x-forwarded-host forwarded x-real-ip cookie );
    # ADR 0032 / k121: the correlation header never reaches a node, internal or external. The
    # card's test line says an internal node "gets the correlation header"; that contradicts its
    # own rule 3 ("the correlation header rule stays as it is"), and the rule is what is tested.
    ok !exists $h->{lc $CORRELATION}, "$label: the correlation header stays in Skeid";
    unlike join("\n", values %$h), qr/\Q$CLIENT_IP\E/, "$label: the client's address is in no header";
  }
};

subtest 'an external node without a key source does not load' => sub {
  my $keyless = { id => 'provider', url => 'http://provider.example/v1', model => 'm' };
  for my $case (
    [ 'trust left out',      { %$keyless } ],
    [ 'trust: external',     { %$keyless, trust => 'external' } ],
    [ 'an empty api_key_env', { %$keyless, api_key_env => '' } ],
  ) {
    my ($label, $node) = @$case;
    ok !eval { Langertha::Skeid->new(config_loader => sub { +{ nodes => [ $node ] } }); 1 },
      "$label: the config fails to load";
    like $@, qr/'provider' is external and names no key source/, "$label: and says why";
  }
  ok eval { Langertha::Skeid->new(config_loader => sub { +{ nodes => [ { %$keyless, api_key_ref => 'secret/skeid/p' } ] } }); 1 },
    'an api_key_ref is a key source' or diag $@;
  ok eval { Langertha::Skeid->new(config_loader => sub { +{ nodes => [ { %$keyless, trust => 'internal' } ] } }); 1 },
    'a keyless internal node loads' or diag $@;
  ok !eval { Langertha::Skeid->new(config_loader => sub { +{ nodes => [ { %$keyless, trust => 'partner', api_key_env => 'X' } ] } }); 1 },
    'an unknown trust fails the load';

  my $s = Langertha::Skeid->new;
  ok !eval { $s->add_node(%$keyless); 1 }, 'add_node refuses a keyless external node too';
  is_deeply $s->nodes, [], 'and adds nothing';

  # A reload with such a node fails and keeps what was in force.
  my $cfg = { nodes => [ { id => 'good', url => 'http://good.example/v1', model => 'm', api_key_env => 'SKEID_K128_NODE_KEY' } ] };
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my $r = Langertha::Skeid->new(config_reload_interval => 0, config_loader => sub { $cfg });
  is_deeply [ map { $_->{id} } @{ $r->nodes } ], ['good'], 'a keyed external node loads';
  is $r->nodes->[0]{trust}, 'external', 'as external, the default';
  $cfg = { nodes => [ { id => 'good', url => 'http://good.example/v1', model => 'm', api_key_env => 'SKEID_K128_NODE_KEY' },
                      { %$keyless } ] };
  $r->maybe_reload_config;
  is $r->reload_status->{ok}, 0, 'the reload with a keyless external node fails';
  like $r->reload_status->{error}, qr/names no key source/, 'with the reason';
  is_deeply [ map { $_->{id} } @{ $r->nodes } ], ['good'], 'and the previous inventory stays';
};

subtest 'node files: the entry grants the trust, a file cannot' => sub {
  my $dir = tempdir(CLEANUP => 1);
  my $file = "$dir/gpm-nodes.yaml";
  my $write = sub {
    open my $out, '>', $file or die "open $file: $!";
    print {$out} $_[0];
    close $out or die "close $file: $!";
  };
  my $load = sub {
    my (%entry) = @_;
    return Langertha::Skeid->new(config_loader => sub { +{ node_files => [ {
      path => $file, allow_url_hosts => ['*.cai-gpm.svc'],
      allow_api_key_env => '^SKEID_NODE_GPM_[A-Z0-9_]+_API_KEY$', %entry } ] } });
  };
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };

  $write->("- { id: own, url: 'http://own.cai-gpm.svc/v1', trust: internal }\n");
  my $s = $load->(trust => 'internal');
  is_deeply [ map { $_->{id} } @{ $s->nodes } ], ['own'], 'trust: internal under an internal entry is accepted';
  is $s->nodes->[0]{trust}, 'internal', 'and the node is internal';
  is_deeply $s->node_files_status->[0]{rejected}, [], 'nothing rejected';

  $s = $load->();
  is_deeply $s->nodes, [], 'the same file under an entry of default trust adds nothing';
  is_deeply $s->node_files_status->[0]{rejected}, [ { position => 0, rule => 'trust' } ],
    'the node is rejected with rule trust';
  is_deeply $s->reload_status, { ok => 1 }, 'and the main config still loads';

  $write->("- { id: narrow, url: 'http://own.cai-gpm.svc/v1', trust: external, api_key_env: SKEID_NODE_GPM_A_API_KEY }\n");
  $s = $load->(trust => 'internal');
  is_deeply $s->node_files_status->[0]{rejected}, [ { position => 0, rule => 'trust' } ],
    'a node may not name another trust than its entry\'s, a narrower one either';

  $write->(join '',
    "- { id: keyed, url: 'http://gpu-1.cai-gpm.svc/v1', api_key_env: SKEID_NODE_GPM_GPU1_API_KEY }\n",
    "- { id: keyless, url: 'http://gpu-2.cai-gpm.svc/v1' }\n",
    "- { id: said, url: 'http://gpu-3.cai-gpm.svc/v1', trust: external, api_key_env: SKEID_NODE_GPM_GPU3_API_KEY }\n");
  $s = $load->();
  is_deeply [ map { $_->{id} } @{ $s->nodes } ], [qw( keyed said )], 'the rest of the file loads';
  is_deeply [ map { $_->{trust} } @{ $s->nodes } ], [qw( external external )], 'as external nodes';
  is_deeply $s->node_files_status->[0]{rejected}, [ { position => 1, rule => 'key_required' } ],
    'an external node of the file without a key is rejected with rule key_required';
  is_deeply $s->reload_status, { ok => 1 }, 'without failing the load';

  ok !eval { $load->(trust => 'partner'); 1 }, 'an unknown trust on the entry fails the main config';
  like $@, qr/trust must be internal or external/, '...and says so';
};

done_testing;
