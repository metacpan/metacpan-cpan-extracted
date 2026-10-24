use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use JSON::MaybeXS qw( decode_json encode_json );
use Mojo::IOLoop;
use RealtimeHarness qw( settle run_until frame );

# The relay of a realtime session (skeid k95, ADR 0029): frames both ways in order, the model of
# the session held to what the key was granted, closes mapped and passed on, and exactly one
# request.finish per session whichever side ends it and however. Frames are written by hand
# after OpenAI's documentation -- synthetic, not recorded from a live backend.

delete @ENV{qw( OPENBAO_ROLE_ID OPENBAO_SECRET_ID OPENBAO_ADDR SKEID_ADMIN_API_KEY
  SKEID_TRUST_KEY_ID_HEADER SKEID_USAGE_DB )};

my $Q = '/v1/realtime?model=house-asr&intent=transcription';
my $ALIASES = { 'house-asr' => { tiers => [ { model => 'whisper-rt' } ] } };

sub session {
  my (%opts) = @_;
  my $h = RealtimeHarness->new(config => { aliases => $ALIASES }, %opts);
  $h->add_node('rt1');
  my $c = $h->connect($Q);
  die 'no session: ' . ($c->{code} // 'none') unless ($c->{code} // 0) == 101;
  return ($h, $c, $h->upstream->[0]);
}

sub ended {
  my ($h) = @_;
  my $ok = run_until(sub { $h->metrics('rt1')->{inflight} == 0 && @{ $h->usage } }, 3);
  settle(0.05);
  return $ok;
}

sub paired {
  my ($h, $label) = @_;
  my $m = $h->metrics('rt1');
  is $m->{inflight}, 0, "$label: nothing in flight";
  is $m->{ok} + $m->{error} + $m->{aborted} + ($m->{rejected} // 0), $m->{started},
    "$label: request.start and request.finish pair";
  is $m->{started}, 1, "$label: one session, one slot";
  is scalar @{ $h->usage }, 1, "$label: one usage event";
  return $m;
}

subtest 'text frames both ways, in order; the node\'s bytes arrive as they were' => sub {
  my ($h, $c, $up) = session();
  my @sent = map { frame({ type => 'input_audio_buffer.append', audio => 'AAEC' . $_ }) } 1 .. 5;
  $h->send_text($c, $_) for @sent;
  ok run_until(sub { @{ $up->{received} } == 5 }), 'the node got five frames';
  is_deeply [ map { decode_json($_) } @{ $up->{received} } ], [ map { decode_json($_) } @sent ],
    'the same documents, in order';

  # A server frame with spacing and escapes of its own: relayed byte for byte.
  my $odd = '{"type":"conversation.item.input_audio_transcription.delta",  "item_id":"item_1",'
    . "\n" . ' "delta":"Grüße", "extra":{"a" : [1, 2.50, true]}}';
  $h->node_send($up, $odd);
  $h->node_send($up, { type => 'session.created', session => { id => 'sess_1' } });
  ok run_until(sub { @{ $c->{messages} } == 2 }), 'both server frames reached the client';
  is $c->{messages}[0], $odd, 'byte for byte, spacing and escapes kept';
  is decode_json($c->{messages}[1])->{type}, 'session.created', 'in order';

  $c->{tx}->finish(1000);
  ended($h);
  paired($h, 'relay');
};

subtest 'session.update: the served model written in, another model refused' => sub {
  my ($h, $c, $up) = session();
  $h->send_text($c, { type => 'session.update', session => { type => 'transcription',
    audio => { input => { transcription => { model => 'house-asr', language => 'de' } } } } });
  ok run_until(sub { @{ $up->{received} } == 1 }), 'forwarded';
  is decode_json($up->{received}[0])->{session}{audio}{input}{transcription}{model}, 'whisper-rt',
    'with the served model for the alias';

  $h->send_text($c, { type => 'transcription_session.update', event_id => 'evt_b',
    session => { input_audio_transcription => { model => 'house-asr' } } });
  ok run_until(sub { @{ $up->{received} } == 2 }), 'the beta dialect is relayed too';
  is decode_json($up->{received}[1])->{type}, 'transcription_session.update', 'untranslated';
  is decode_json($up->{received}[1])->{session}{input_audio_transcription}{model}, 'whisper-rt',
    'its model rewritten the same way';

  # A model the key was not granted: not forwarded, an error event back, the session goes on.
  $h->send_text($c, { type => 'session.update', event_id => 'evt_foreign',
    session => { audio => { input => { transcription => { model => 'gpt-4o-transcribe' } } } } });
  ok run_until(sub { @{ $c->{messages} } == 1 }), 'the client is told';
  my $err = decode_json($c->{messages}[0]);
  is $err->{type}, 'error', 'an error event';
  is $err->{error}{event_id}, 'evt_foreign', 'for that event';
  settle(0.05);
  is scalar @{ $up->{received} }, 2, 'and the frame never reached the node';

  # Spelled with escapes: a substring test would not see it, the decoder does.
  my $bs = chr(92);
  $h->send_text($c, '{"type":"session.up' . $bs . 'u0064ate","session":{"' . $bs
    . 'u006dodel":"gpt-4o"}}');
  ok run_until(sub { @{ $c->{messages} } == 2 }), 'the escaped spelling is refused too';
  is scalar @{ $up->{received} }, 2, 'and not forwarded';

  # The session is still on its model and still relays.
  $h->send_text($c, { type => 'input_audio_buffer.commit' });
  ok run_until(sub { @{ $up->{received} } == 3 }), 'the session goes on';
  is decode_json($up->{received}[2])->{type}, 'input_audio_buffer.commit', 'commit forwarded';

  $c->{tx}->finish(1000);
  ended($h);
  paired($h, 'policy frames');
  is $h->usage->[0]{ok}, 1, 'refused frames do not fail the session';
};

subtest 'frames that are not JSON objects, and binary frames, close 1003' => sub {
  for my $case (
    [ 'text that is not JSON', sub { $_[1]->{tx}->send({ text => 'not json at all' }) } ],
    [ 'a JSON array',          sub { $_[1]->{tx}->send({ text => '[1,2,3]' }) } ],
    [ 'a binary frame',        sub { $_[1]->{tx}->send({ binary => "\x00\x01\x02\xff" }) } ],
  ) {
    my ($label, $send) = @$case;
    my ($h, $c, $up) = session();
    $send->($h, $c);
    ok run_until(sub { $c->{closed} }), "$label: the client is closed";
    is $c->{closed}[0], 1003, "$label: with 1003";
    ok run_until(sub { $up->{closed} }), "$label: and the node's side too";
    is scalar @{ $up->{received} }, 0, "$label: nothing was forwarded";
    ended($h);
    paired($h, $label);
    is $h->usage->[0]{ok}, 0, "$label: recorded as failed";
    is $h->usage->[0]{status_code}, 400, "$label: the client's fault, 400";
  }
};

subtest 'close codes are passed on, both ways, and end the session once' => sub {
  {
    my ($h, $c, $up) = session();
    $c->{tx}->finish(1000, 'bye');
    ok run_until(sub { $up->{closed} }), 'a client close reaches the node';
    is $up->{closed}[0], 1000, 'as 1000';
    ended($h);
    paired($h, 'client closes');
    is $h->usage->[0]{ok}, 1, 'a normal close is not a failure';
    is $h->usage->[0]{status_code}, 200, 'status 200';
  }
  {
    my ($h, $c, $up) = session();
    $c->{tx}->finish(4001, 'app code');
    ok run_until(sub { $up->{closed} }), 'an application code reaches the node';
    is $up->{closed}[0], 4001, 'as it was';
    ended($h);
    paired($h, 'client closes 4001');
  }
  {
    my ($h, $c, $up) = session();
    $up->{c}->finish(1000, 'done');
    ok run_until(sub { $c->{closed} }), 'a node close reaches the client';
    is $c->{closed}[0], 1000, 'as 1000';
    ended($h);
    paired($h, 'node closes 1000');
    is $h->usage->[0]{ok}, 1, 'the node ending the session is not a failure';
  }
  {
    my ($h, $c, $up) = session();
    $up->{c}->finish(1011, 'oom');
    ok run_until(sub { $c->{closed} }), 'a node failure reaches the client';
    is $c->{closed}[0], 1011, 'as 1011';
    ended($h);
    paired($h, 'node closes 1011');
    is $h->usage->[0]{ok}, 0, 'recorded as failed';
    is $h->usage->[0]{status_code}, 502, 'status 502';
    is $h->usage->[0]{error_type}, 'upstream_error', 'upstream_error';
  }
};

subtest 'a connection that vanishes without a close frame' => sub {
  {
    my ($h, $c, $up) = session();
    Mojo::IOLoop->stream($c->{tx}->connection)->close;
    ok run_until(sub { $up->{closed} }), 'the node is closed when the client is gone';
    is $up->{closed}[0], 1000, 'with 1000';
    ended($h);
    my $m = paired($h, 'client vanishes');
    is $m->{aborted}, 1, 'counted as aborted';
    is $h->usage->[0]{error_type}, 'client_abort', 'a client abort';
    is $h->usage->[0]{status_code}, 499, 'status 499';
  }
  {
    my ($h, $c, $up) = session();
    Mojo::IOLoop->stream($up->{c}->tx->connection)->close;
    ok run_until(sub { $c->{closed} }), 'the client is closed when the node is gone';
    is $c->{closed}[0], 1011, 'with 1011';
    ended($h);
    paired($h, 'node vanishes');
    is $h->usage->[0]{ok}, 0, 'failed';
    is $h->usage->[0]{status_code}, 502, 'status 502';
  }
};

subtest 'an error event from the node alone keeps the session; error then close fails it' => sub {
  my ($h, $c, $up) = session();
  $h->node_send($up, { type => 'error', error => { type => 'invalid_request_error', message => 'x' } });
  ok run_until(sub { @{ $c->{messages} } == 1 }), 'the error event is relayed';
  settle(0.05);
  is $h->metrics('rt1')->{inflight}, 1, 'and the session is still open';
  $up->{c}->finish(1000);
  ok run_until(sub { $c->{closed} }), 'then the node closes it';
  ended($h);
  paired($h, 'error then close');
  is $h->usage->[0]{ok}, 0, 'an error event followed by a close is a failed session';
};

subtest 'many sessions leave nothing behind' => sub {
  my $h = RealtimeHarness->new(config => { aliases => $ALIASES });
  $h->add_node('rt1', max_conns => 2);
  my $streams = sub { scalar keys %{ Mojo::IOLoop->singleton->{in} || {} } };
  # One session first, so the baseline holds what the app keeps for good (the user agent's pool).
  my $c = $h->connect($Q);
  $h->send_text($c, { type => 'input_audio_buffer.commit' });
  $c->{tx}->finish(1000);
  run_until(sub { $c->{closed} });
  settle(0.1);
  my $before = $streams->();
  for my $i (1 .. 50) {
    my $client = $h->connect($Q);
    $h->send_text($client, { type => 'input_audio_buffer.append', audio => 'AAAA' });
    if ($i % 3 == 0) { Mojo::IOLoop->stream($client->{tx}->connection)->close }
    else { $client->{tx}->finish(1000) }
    run_until(sub { $client->{closed} }, 2);
  }
  settle(0.2);
  is $h->metrics('rt1')->{inflight}, 0, 'no slot is left';
  is $h->app->realtime->open_count, 0, 'no session is left open';
  my $m = $h->metrics('rt1');
  is $m->{ok} + $m->{error} + $m->{aborted} + ($m->{rejected} // 0), $m->{started}, 'every start has its finish';
  is scalar @{ $h->usage }, 51, 'one event each';
  cmp_ok $streams->(), '<=', $before + 1, 'and no connection is left on the loop';
};

done_testing;
