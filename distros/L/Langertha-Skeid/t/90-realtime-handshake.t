use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use Mojo::IOLoop;
use RealtimeHarness qw( settle run_until frame );
use Langertha::Skeid;

# The handshake of GET /v1/realtime (skeid k95, ADR 0029). Everything that can refuse a session
# does so as a plain HTTP answer, before an upgrade and before a socket is open: the client gate,
# the missing model, the key's policy, saturation. The node is opened first, so a node that
# refuses is a 502 and not an accepted-then-closed socket, and in every one of these paths the
# node's slot is given back exactly once -- the metrics pair request.start and request.finish.

delete @ENV{qw( OPENBAO_ROLE_ID OPENBAO_SECRET_ID OPENBAO_ADDR SKEID_ADMIN_API_KEY
  SKEID_TRUST_KEY_ID_HEADER SKEID_K95_NODE_KEY SKEID_K95_UNSET_KEY SKEID_USAGE_DB )};
$ENV{SKEID_K95_NODE_KEY} = 'node-secret-k95';

my $ALICE_KEY = 'sk-alice-secret-k95';
my $ALICE_ID  = Langertha::Skeid->key_id_for_key($ALICE_KEY);
my $BOB_KEY   = 'sk-bob-secret-k95';
my $BOB_ID    = Langertha::Skeid->key_id_for_key($BOB_KEY);
my $MALLORY_KEY = 'sk-mallory-secret-k95';

my $Q = '/v1/realtime?model=whisper-rt&intent=transcription';

sub paired {
  my ($h, $id, $label) = @_;
  my $m = $h->metrics($id);
  is $m->{inflight}, 0, "$label: nothing in flight on $id";
  is $m->{ok} + $m->{error} + $m->{aborted} + ($m->{rejected} // 0), $m->{started},
    "$label: every request.start on $id has its request.finish";
  return $m;
}

sub close_client {
  my ($h, $client, $code) = @_;
  $client->{tx}->finish($code // 1000);
  run_until(sub { $client->{closed} }, 2);
  settle(0.05);
  return;
}

subtest 'a session: served model upstream, node key in, client key out' => sub {
  my $h = RealtimeHarness->new(config => {
    aliases => { 'house-asr' => { tiers => [ { model => 'whisper-rt' } ] } },
  });
  $h->add_node('rt1', api_key_env => 'SKEID_K95_NODE_KEY');

  my $c = $h->connect('/v1/realtime?model=house-asr&intent=transcription&language=de',
    headers => { Authorization => "Bearer $ALICE_KEY", Origin => 'https://app.example' });
  is $c->{code}, 101, 'the handshake is upgraded';
  is $h->metrics('rt1')->{inflight}, 1, 'the session holds its slot';

  my $up = $h->upstream->[0];
  is_deeply $up->{query}{model}, ['whisper-rt'], 'the node is asked for the served model';
  is_deeply $up->{query}{intent}, ['transcription'], 'the other query parameters go on as sent';
  is_deeply $up->{query}{language}, ['de'], 'all of them';
  is $up->{headers}{authorization}, 'Bearer node-secret-k95', 'the node gets its own key';
  ok !grep({ index($_ // '', $ALICE_KEY) >= 0 } values %{ $up->{headers} }),
    'and no header of the handshake carries the client\'s key';
  ok !exists $up->{headers}{origin}, 'the client\'s Origin is not the node\'s';

  close_client($h, $c);
  paired($h, 'rt1', 'after the session');
  is scalar @{ $h->usage }, 1, 'one usage event for the session';
  my $ev = $h->usage->[0];
  is $ev->{endpoint}, '/v1/realtime', 'endpoint';
  is $ev->{api_format}, 'openai', 'api_format';
  is $ev->{model}, 'whisper-rt', 'the served model';
  is $ev->{requested_model}, 'house-asr', 'and the one asked for';
  is $ev->{api_key_id}, $ALICE_ID, 'the key id, not the key';
  is $ev->{ok}, 1, 'ok';
};

subtest 'client_auth: 401 before the upgrade, key in the subprotocol, never echoed' => sub {
  my $h = RealtimeHarness->new(config => { client_auth => { keys => [ $ALICE_ID ] } });
  $h->add_node('rt1', api_key_env => 'SKEID_K95_NODE_KEY');

  for my $case (
    [ 'no key',            {}, [] ],
    [ 'a key not listed',  { Authorization => "Bearer $MALLORY_KEY" }, [] ],
    [ 'a subprotocol key not listed', {}, [ 'realtime', "openai-insecure-api-key.$MALLORY_KEY" ] ],
  ) {
    my ($label, $headers, $protocols) = @$case;
    my $c = $h->connect($Q, headers => $headers, protocols => $protocols);
    is $c->{code}, 401, "$label: a plain 401";
    ok !$c->{tx}->is_websocket, "$label: no socket";
    like $c->{error_body}, qr/invalid_api_key/, "$label: in the OpenAI shape";
    is $c->{error_headers}{'WWW-Authenticate'}, 'Bearer realm="skeid"', "$label: with the challenge";
    ok !grep({ /\A(?:upgrade|sec-websocket-accept)\z/i } keys %{ $c->{error_headers} }),
      "$label: and no upgrade headers on it";
  }
  is scalar @{ $h->upstream }, 0, 'no node was asked';
  is $h->metrics('rt1')->{started}, 0, 'no slot was taken';
  is scalar @{ $h->usage }, 0, 'nothing was metered';

  # The browser's way: the key in the subprotocol list beside `realtime`.
  my $c = $h->connect($Q, protocols => [ 'realtime', "openai-insecure-api-key.$ALICE_KEY" ]);
  is $c->{code}, 101, 'a listed key in the subprotocol is let in';
  is $c->{protocol}, 'realtime', 'the answer selects realtime';
  unlike join("\n", map { "$_: $c->{headers}{$_}" } sort keys %{ $c->{headers} }), qr/\Q$ALICE_KEY\E/,
    'and the key is nowhere in the answer';
  my $up = $h->upstream->[0];
  ok !grep({ index($_ // '', $ALICE_KEY) >= 0 } values %{ $up->{headers} }),
    'nor in what the node got';
  ok !exists $up->{headers}{'sec-websocket-protocol'}, 'the node was offered no subprotocol list';
  is $up->{headers}{authorization}, 'Bearer node-secret-k95', 'the node got its own key';
  close_client($h, $c);

  # Only the key entry offered: no subprotocol is selected, and the key is still not echoed.
  $c = $h->connect($Q, protocols => [ "openai-insecure-api-key.$ALICE_KEY" ]);
  is $c->{code}, 101, 'with only the key entry offered the session still opens';
  ok !defined($c->{protocol}) || $c->{protocol} eq '', 'and no subprotocol is chosen';
  close_client($h, $c);

  # A header wins over the subprotocol: lowest priority is the subprotocol.
  $c = $h->connect($Q, headers => { Authorization => "Bearer $MALLORY_KEY" },
    protocols => [ 'realtime', "openai-insecure-api-key.$ALICE_KEY" ]);
  is $c->{code}, 401, 'an Authorization header decides before the subprotocol does';
  $c = $h->connect($Q, headers => { Authorization => "Bearer $ALICE_KEY" },
    protocols => [ 'realtime', "openai-insecure-api-key.$MALLORY_KEY" ]);
  is $c->{code}, 101, 'and a good header is not undone by a bad subprotocol';
  close_client($h, $c);

  my $everything = join "\n", map { $_->[1] } @{ $h->log };
  unlike $everything, qr/\Q$ALICE_KEY\E|\Q$MALLORY_KEY\E/, 'no key in the log';
  unlike $everything, qr/openai-insecure-api-key/i, 'nor the subprotocol entry';
  unlike join("\n", map { JSON::MaybeXS::encode_json($_) } @{ $h->usage }),
    qr/\Q$ALICE_KEY\E|\Q$MALLORY_KEY\E/, 'no key in a usage event';
};

subtest 'the subprotocol key counts on this route only' => sub {
  my $h = RealtimeHarness->new(config => { client_auth => { keys => [ $ALICE_ID ] } });
  $h->add_node('rt1');
  $h->t->get_ok('/v1/models' => { 'Sec-WebSocket-Protocol' => "realtime, openai-insecure-api-key.$ALICE_KEY" })
    ->status_is(401, 'another route does not read the subprotocol');
};

subtest 'the model: exactly one, in the query' => sub {
  my $h = RealtimeHarness->new;
  $h->add_node('rt1');
  for my $case (
    [ 'no model',                      '/v1/realtime' ],
    [ 'intent=transcription alone',    '/v1/realtime?intent=transcription' ],
    [ 'an empty model',                '/v1/realtime?model=' ],
    [ 'two models',                    '/v1/realtime?model=whisper-rt&model=other' ],
  ) {
    my ($label, $path) = @$case;
    my $c = $h->connect($path);
    is $c->{code}, 400, "$label: 400";
    like $c->{error_body}, qr/invalid_request_error/, "$label: in the OpenAI shape";
  }
  is $h->metrics('rt1')->{started}, 0, 'none of them took a slot';
  is scalar @{ $h->usage }, 0, 'or made an event';
  is scalar @{ $h->upstream }, 0, 'or asked a node';

  my $c = $h->connect('/v1/realtime?model=nobody-serves-this');
  is $c->{code}, 503, 'a model no node serves is 503, as everywhere';
};

subtest 'the key\'s policy applies to the handshake model' => sub {
  my $h = RealtimeHarness->new(config => {
    keys => { $ALICE_ID => { models => ['whisper-rt'] }, $BOB_ID => { models => ['something-else'] } },
  });
  $h->add_node('rt1');
  my $c = $h->connect($Q, headers => { Authorization => "Bearer $BOB_KEY" });
  is $c->{code}, 403, 'a model the key was not granted is 403';
  like $c->{error_body}, qr/permission_error/, 'a permission error';
  is $h->metrics('rt1')->{started}, 0, 'no slot';
  $c = $h->connect($Q, headers => { Authorization => "Bearer $ALICE_KEY" });
  is $c->{code}, 101, 'the granted one opens';
  close_client($h, $c);
  paired($h, 'rt1', 'policy');
};

subtest 'admission is per session: 429 while a session holds the slot, free after' => sub {
  my $h = RealtimeHarness->new;
  $h->add_node('rt1', max_conns => 1);
  my $first = $h->connect($Q);
  is $first->{code}, 101, 'the first session opens';
  my $second = $h->connect($Q);
  is $second->{code}, 429, 'the second finds the node saturated';
  like $second->{error_body}, qr/rate_limit_error/, 'a rate limit error';
  is scalar @{ $h->upstream }, 1, 'and the node was asked once';
  is $h->metrics('rt1')->{inflight}, 1, 'the slot is still the first session\'s';

  close_client($h, $first);
  is $h->metrics('rt1')->{inflight}, 0, 'closing the session frees the slot';
  my $third = $h->connect($Q);
  is $third->{code}, 101, 'and the next one opens';
  close_client($h, $third);
  paired($h, 'rt1', 'admission');
};

subtest 'a node that refuses the handshake is a 502, with no slot left' => sub {
  my $h = RealtimeHarness->new;
  $h->add_node('rt1');
  $h->mode('refuse');
  my $c = $h->connect($Q);
  is $c->{code}, 502, 'the client gets a 502';
  ok !$c->{tx}->is_websocket, 'not an accepted-then-closed socket';
  like $c->{error_body}, qr/upstream_error/, 'in the OpenAI shape';
  unlike $c->{error_body}, qr/bad node key/, 'without the node\'s own words';
  settle(0.05);
  my $m = paired($h, 'rt1', 'refused');
  is $m->{started}, 1, 'the slot had been taken';
  is $m->{error}, 1, 'and is finished as a failure';
  is scalar @{ $h->usage }, 1, 'one failed event';
  is $h->usage->[0]{ok}, 0, 'ok 0';
  is $h->usage->[0]{status_code}, 502, 'status 502';
  is $h->usage->[0]{error_type}, 'upstream_error', 'upstream_error';
};

subtest 'a node key that cannot be resolved fails closed' => sub {
  my $h = RealtimeHarness->new;
  $h->add_node('rt1', api_key_env => 'SKEID_K95_UNSET_KEY');
  my $c = $h->connect($Q, headers => { Authorization => "Bearer $ALICE_KEY" });
  is $c->{code}, 503, '503, not a pass-through of the client\'s key';
  is scalar @{ $h->upstream }, 0, 'the node was never asked';
  paired($h, 'rt1', 'unkeyed');
  is $h->usage->[0]{error_type}, 'upstream_key_unavailable', 'one failed event, named';
};

# A raw client: it can send the upgrade request and hang up without waiting for an answer.
sub raw_upgrade {
  my ($h, $path) = @_;
  my $client = { closed => 0 };
  my $port = $h->t->ua->server->nb_url->port;
  Mojo::IOLoop->client({ address => '127.0.0.1', port => $port } => sub {
    my ($loop, $err, $stream) = @_;
    return $client->{error} = $err if $err;
    $client->{stream} = $stream;
    $stream->timeout(0);
    $stream->on(close => sub { $client->{closed} = 1 });
    $stream->write(join "\r\n", "GET $path HTTP/1.1", 'Host: 127.0.0.1', 'Upgrade: websocket',
      'Connection: Upgrade', 'Sec-WebSocket-Version: 13',
      'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==', '', '');
  });
  run_until(sub { $client->{stream} }, 2);
  return $client;
}

subtest 'a client that leaves while the node is being opened gives the slot back' => sub {
  my $h = RealtimeHarness->new;
  $h->add_node('rt1');
  $h->mode('slow');
  my $raw = raw_upgrade($h, $Q);
  ok run_until(sub { @{ $h->upstream } == 1 }, 2), 'the node was asked';
  is $h->metrics('rt1')->{inflight}, 1, 'and the handshake holds a slot';
  $raw->{stream}->close;
  ok run_until(sub { $h->metrics('rt1')->{inflight} == 0 }, 2), 'the client leaves: the slot is back';
  $h->release;
  settle(0.1);
  my $m = paired($h, 'rt1', 'abandoned during the upstream wait');
  is $m->{aborted}, 1, 'counted as aborted';
  is scalar @{ $h->usage }, 1, 'one event';
  is $h->usage->[0]{error_type}, 'client_abort', 'a client abort';
  is $h->usage->[0]{status_code}, 499, 'status 499';
};

subtest 'a client that leaves while waiting for capacity never takes the slot' => sub {
  my $h = RealtimeHarness->new(route_wait_timeout_ms => 1500);
  $h->add_node('rt1', max_conns => 1);
  my $first = $h->connect($Q);
  is $first->{code}, 101, 'the node is taken';
  my $raw = raw_upgrade($h, $Q);
  settle(0.1);
  is $h->metrics('rt1')->{started}, 1, 'the waiter has no slot yet';
  $raw->{stream}->close;
  settle(0.1);
  close_client($h, $first);
  settle(0.2);
  my $m = $h->metrics('rt1');
  is $m->{started}, 1, 'the abandoned waiter did not take the slot the first session left';
  is $m->{inflight}, 0, 'nothing in flight';
  is scalar @{ $h->upstream }, 1, 'and the node was asked once';
};

done_testing;
