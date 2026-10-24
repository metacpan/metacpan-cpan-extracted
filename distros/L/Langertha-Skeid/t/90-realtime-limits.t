use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use JSON::MaybeXS qw( decode_json );
use Mojo::IOLoop;
use Time::HiRes qw( time );
use RealtimeHarness qw( settle run_until frame );

# The bounds of a realtime session (skeid k95, ADR 0029): nothing a peer does may grow the
# worker or hold a slot for good. Message size, bytes waiting for a peer that does not read,
# silence, age, and a graceful stop of the process -- each closes the session with its own code,
# gives the slot back once and leaves one usage event.

delete @ENV{qw( OPENBAO_ROLE_ID OPENBAO_SECRET_ID OPENBAO_ADDR SKEID_ADMIN_API_KEY
  SKEID_TRUST_KEY_ID_HEADER SKEID_USAGE_DB )};

my $Q = '/v1/realtime?model=whisper-rt';

sub session {
  my ($realtime, %opts) = @_;
  my $h = RealtimeHarness->new(config => { realtime => $realtime }, %opts);
  $h->add_node('rt1');
  my $c = $h->connect($Q);
  die 'no session: ' . ($c->{code} // 'none') unless ($c->{code} // 0) == 101;
  return ($h, $c, $h->upstream->[0]);
}

sub ended {
  my ($h, $max) = @_;
  my $ok = run_until(sub { $h->metrics('rt1')->{inflight} == 0 && @{ $h->usage } }, $max // 3);
  settle(0.05);
  return $ok;
}

sub paired {
  my ($h, $label) = @_;
  my $m = $h->metrics('rt1');
  is $m->{inflight}, 0, "$label: nothing in flight";
  is $m->{ok} + $m->{error} + $m->{aborted} + ($m->{rejected} // 0), $m->{started},
    "$label: request.start and request.finish pair";
  is scalar @{ $h->usage }, 1, "$label: one usage event";
  return $m;
}

subtest 'a message above max_message_bytes closes 1009' => sub {
  my ($h, $c, $up) = session({ max_message_bytes => 2000 });
  $h->send_text($c, { type => 'input_audio_buffer.append', audio => 'A' x 100 });
  ok run_until(sub { @{ $up->{received} } == 1 }), 'a small frame goes through';
  $h->send_text($c, { type => 'input_audio_buffer.append', audio => 'A' x 3000 });
  ok run_until(sub { $c->{closed} }), 'a frame above the limit closes the client';
  is $c->{closed}[0], 1009, 'with 1009';
  ok run_until(sub { $up->{closed} }), 'and the node';
  is scalar @{ $up->{received} }, 1, 'nothing of the large frame reached it';
  ended($h);
  paired($h, 'client oversize');
  is $h->usage->[0]{ok}, 0, 'a failed session';
  is $h->usage->[0]{status_code}, 413, 'the client\'s fault, 413';

  # The node's side: a frame above the limit from the node.
  ($h, $c, $up) = session({ max_message_bytes => 2000 });
  $h->node_send($up, { type => 'x', pad => 'B' x 3000 });
  ok run_until(sub { $c->{closed} }), 'an oversize frame from the node closes the session';
  is $c->{closed}[0], 1011, 'the client hears 1011, the node having failed';
  is scalar @{ $c->{messages} }, 0, 'and never got the frame';
  ended($h);
  paired($h, 'node oversize');
  is $h->usage->[0]{ok}, 0, 'failed';
};

subtest 'a node that does not read, a client that does not stop: 1013, bounded' => sub {
  my ($h, $c, $up);
  $h = RealtimeHarness->new(config => { realtime => { max_queued_bytes => 100_000, max_message_bytes => 70_000 } });
  $h->add_node('rt1');
  $h->mode('stall');
  $c = $h->connect($Q);
  is $c->{code}, 101, 'the session opens';
  $up = $h->upstream->[0];
  my $frame = frame({ type => 'input_audio_buffer.append', audio => 'A' x 60_000 });
  my $sent = 0;
  my $feeder = Mojo::IOLoop->recurring(0.002 => sub {
    return if $c->{closed} || $sent >= 600;
    for (1 .. 4) { $c->{tx}->send({ text => $frame }); $sent++ }
  });
  my $closed = run_until(sub { $c->{closed} }, 20);
  Mojo::IOLoop->remove($feeder);
  ok $closed, 'the session is closed before the sender runs out';
  is $c->{closed}[0], 1013, 'with 1013, try again later';
  cmp_ok $sent, '<', 600, 'and well before it had sent everything';
  ended($h);
  paired($h, 'queue overflow');
  is $h->usage->[0]{ok}, 0, 'a failed session';
  is $h->usage->[0]{error_type}, 'realtime_queue_overflow', 'named';
};

subtest 'a client that does not read the node\'s frames: 1013 as well' => sub {
  my ($h, $c, $up) = session({ max_queued_bytes => 100_000, max_message_bytes => 70_000 });
  Mojo::IOLoop->stream($c->{tx}->connection)->stop;
  my $frame = frame({ type => 'conversation.item.input_audio_transcription.delta', delta => 'x' x 60_000 });
  my $sent = 0;
  my $feeder = Mojo::IOLoop->recurring(0.002 => sub {
    return if $up->{closed} || $sent >= 600;
    for (1 .. 4) { $up->{c}->send({ text => $frame }); $sent++ }
  });
  my $closed = run_until(sub { $up->{closed} }, 20);
  Mojo::IOLoop->remove($feeder);
  ok $closed, 'the node is closed before it runs out';
  is $up->{closed}[0], 1013, 'with 1013';
  Mojo::IOLoop->stream($c->{tx}->connection)->start if Mojo::IOLoop->stream($c->{tx}->connection);
  ended($h);
  paired($h, 'client does not read');
  is $h->usage->[0]{error_type}, 'realtime_queue_overflow', 'named';
};

subtest 'silence closes at idle_timeout, traffic keeps a session alive' => sub {
  my ($h, $c, $up) = session({ idle_timeout => 1 });
  my $t0 = time;
  # Traffic every 0.4 s for 2 s: the 1 s limit is not reached by a session that is not silent.
  my $n = 0;
  my $tick = Mojo::IOLoop->recurring(0.4 => sub {
    $h->send_text($c, { type => 'input_audio_buffer.append', audio => 'AAAA' }) unless $c->{closed};
    $n++;
  });
  run_until(sub { $n >= 5 || $c->{closed} }, 4);
  ok !$c->{closed}, 'still open after 2 s of traffic with a 1 s idle limit';
  Mojo::IOLoop->remove($tick);
  my $quiet_from = time;
  ok run_until(sub { $c->{closed} }, 4), 'then silence closes it';
  my $waited = time - $quiet_from;
  cmp_ok $waited, '>=', 0.5, 'not at once';
  cmp_ok $waited, '<', 3, 'and long before Mojolicious\'s own 30 s';
  is $c->{closed}[0], 1000, 'with 1000';
  is $c->{closed}[1], 'idle timeout', 'and the reason';
  ended($h);
  paired($h, 'idle');
  is $h->usage->[0]{ok}, 1, 'an idle close is not a failure';
};

subtest 'max_session_seconds closes a session that keeps talking' => sub {
  my ($h, $c, $up) = session({ max_session_seconds => 1, idle_timeout => 30 });
  my $tick = Mojo::IOLoop->recurring(0.1 => sub {
    $h->send_text($c, { type => 'input_audio_buffer.append', audio => 'AAAA' }) unless $c->{closed};
  });
  ok run_until(sub { $c->{closed} }, 4), 'the session ends';
  Mojo::IOLoop->remove($tick);
  is $c->{closed}[0], 1000, 'with 1000';
  is $c->{closed}[1], 'session time limit', 'and the reason';
  ok run_until(sub { $up->{closed} }), 'the node is closed too';
  ended($h);
  paired($h, 'lifetime');
  cmp_ok $h->usage->[0]{duration_ms}, '>=', 900, 'the event holds the session\'s length';
};

subtest 'a graceful stop closes open sessions 1001 and records them' => sub {
  my ($h, $c, $up) = session({});
  my $second = $h->connect($Q);
  is $second->{code}, 101, 'two sessions open';
  is $h->metrics('rt1')->{inflight}, 2, 'two slots';
  # The event a worker's loop emits on SIGQUIT before it waits for its connections.
  Mojo::IOLoop->singleton->emit('finish');
  ok run_until(sub { $c->{closed} && $second->{closed} }), 'both clients are closed';
  is $c->{closed}[0], 1001, 'with 1001, going away';
  is $second->{closed}[0], 1001, 'both';
  ok run_until(sub { @{ $h->usage } == 2 }), 'both events were written';
  settle(0.05);
  my $m = $h->metrics('rt1');
  is $m->{inflight}, 0, 'both slots are back';
  is $m->{ok} + $m->{error} + $m->{aborted} + ($m->{rejected} // 0), 2, 'each finished once';
  is $h->usage->[0]{ok}, 1, 'a shutdown is not a failed session';
};

subtest 'the limits are read when a session opens: a reload holds for the next' => sub {
  my ($h, $c, $up) = session({ max_message_bytes => 5000 });
  $c->{tx}->finish(1000);
  ended($h);
  $h->config({ realtime => { max_message_bytes => 500 } });
  my $next = $h->connect($Q);
  is $next->{code}, 101, 'a new session after the reload';
  $h->send_text($next, { type => 'input_audio_buffer.append', audio => 'A' x 1000 });
  ok run_until(sub { $next->{closed} }), 'it holds the new, smaller limit';
  is $next->{closed}[0], 1009, 'closed 1009';
};

done_testing;
