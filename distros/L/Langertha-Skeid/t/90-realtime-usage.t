use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use File::Temp qw( tempdir );
use JSON::MaybeXS qw( decode_json encode_json );
use Path::Tiny qw( path );
use Encode ();
use Test::File::ShareDir -share => {
  -dist => { 'Langertha-Skeid' => 'share' },
};
use RealtimeHarness qw( settle run_until frame );
use Langertha::Skeid;

# What a realtime session costs on the usage side (skeid k95, ADR 0029): one event per session,
# written when it closes -- not one per completed transcription -- holding the session's length,
# the usage blocks of its transcriptions summed (tokens, or seconds of audio) and priced like
# any answer, and a status that says how it ended. A count the node never reported is absent,
# never zero.

delete @ENV{qw( OPENBAO_ROLE_ID OPENBAO_SECRET_ID OPENBAO_ADDR SKEID_ADMIN_API_KEY
  SKEID_TRUST_KEY_ID_HEADER SKEID_USAGE_DB )};

my $KEY = 'sk-usage-secret-k95';
my $ID  = Langertha::Skeid->key_id_for_key($KEY);
my $Q   = '/v1/realtime?model=house-asr&intent=transcription';
my $TMP = tempdir(CLEANUP => 1);

my $CFG = {
  aliases => { 'house-asr' => { tiers => [ { model => 'whisper-rt' } ] } },
  pricing => { 'whisper-rt' => { input_per_million => 1_000_000, output_per_million => 2_000_000 } },
};

sub completed {
  my ($item, $text, $usage) = @_;
  return { type => 'conversation.item.input_audio_transcription.completed', item_id => $item,
    transcript => $text, (defined $usage ? (usage => $usage) : ()) };
}

sub delta {
  my ($item, $text) = @_;
  return { type => 'conversation.item.input_audio_transcription.delta', item_id => $item, delta => $text };
}

sub run_session {
  my ($h, $script, %o) = @_;
  $h->add_node('rt1');
  my $c = $h->connect($Q, headers => { Authorization => "Bearer $KEY" });
  die 'no session' unless ($c->{code} // 0) == 101;
  my $up = $h->upstream->[0];
  $script->($h, $c, $up);
  settle($o{linger} // 0.05);
  $c->{tx}->finish(1000);
  run_until(sub { $h->metrics('rt1')->{inflight} == 0 }, 3);
  settle(0.05);
  return $c;
}

subtest 'tokens of two transcriptions: one event, summed and priced' => sub {
  my $h = RealtimeHarness->new(config => $CFG);
  run_session($h, sub {
    my ($h, $c, $up) = @_;
    $h->node_send($up, completed('item_1', 'Hallo', { type => 'tokens', input_tokens => 14,
      output_tokens => 6, total_tokens => 20 }));
    $h->node_send($up, completed('item_2', 'Welt', { type => 'tokens', input_tokens => 10,
      output_tokens => 4, total_tokens => 14 }));
    run_until(sub { @{ $c->{messages} } == 2 });
  }, linger => 0.2);
  is scalar @{ $h->usage }, 1, 'two completed transcriptions, one event';
  my $ev = $h->usage->[0];
  is $ev->{endpoint}, '/v1/realtime', 'endpoint';
  is $ev->{api_key_id}, $ID, 'the key id';
  is $ev->{model}, 'whisper-rt', 'served model';
  is $ev->{requested_model}, 'house-asr', 'requested model';
  is $ev->{input_tokens}, 24, 'input tokens summed';
  is $ev->{output_tokens}, 10, 'output tokens summed';
  is $ev->{ok}, 1, 'ok';
  is $ev->{status_code}, 200, 'status';
  cmp_ok $ev->{duration_ms}, '>=', 150, 'the length of the session, not of one answer';
  ok !exists $ev->{audio_seconds}, 'no seconds were reported, none are claimed';
  ok !exists $ev->{content_bytes}, 'no text deltas were seen, no byte count is claimed';
  cmp_ok $ev->{cost_total_usd}, '==', 24 + 20, 'priced on the summed usage (24 in, 10 out)';
  is $h->metrics('rt1')->{started}, 1, 'one slot for the session';
};

subtest 'seconds of audio and the text relayed' => sub {
  my $h = RealtimeHarness->new(config => $CFG);
  run_session($h, sub {
    my ($h, $c, $up) = @_;
    $h->node_send($up, delta('item_1', 'Grü'));
    $h->node_send($up, delta('item_1', 'ße'));
    $h->node_send($up, completed('item_1', 'Grüße', { type => 'duration', seconds => 12 }));
    $h->node_send($up, completed('item_2', 'Köln', { type => 'duration', seconds => 7.5 }));
    run_until(sub { @{ $c->{messages} } == 4 });
  });
  my $ev = $h->usage->[0];
  is $ev->{audio_seconds}, 19.5, 'seconds summed over the transcriptions';
  is $ev->{content_bytes}, length(Encode::encode_utf8('Grüße')), 'the UTF-8 bytes of the deltas';
  is scalar @{ $h->usage }, 1, 'still one event';
};

subtest 'a node that reports nothing leaves a duration and a status' => sub {
  my $h = RealtimeHarness->new(config => $CFG);
  run_session($h, sub {
    my ($h, $c, $up) = @_;
    $h->node_send($up, completed('item_1', 'ohne usage'));
    $h->node_send($up, { type => 'session.created', session => { id => 's' } });
    run_until(sub { @{ $c->{messages} } == 2 });
  });
  my $ev = $h->usage->[0];
  is $ev->{ok}, 1, 'ok';
  ok $ev->{duration_ms} >= 0, 'a duration';
  ok !exists $ev->{audio_seconds}, 'no audio_seconds key';
  ok !exists $ev->{content_bytes}, 'no content_bytes key';
  ok !$ev->{input_tokens}, 'no tokens';
  ok !$ev->{cost_total_usd}, 'nothing priced';
};

subtest 'a session that ends in an error is one failed event with what it had' => sub {
  my $h = RealtimeHarness->new(config => $CFG);
  $h->add_node('rt1');
  my $c = $h->connect($Q, headers => { Authorization => "Bearer $KEY" });
  my $up = $h->upstream->[0];
  $h->node_send($up, completed('item_1', 'eins', { type => 'tokens', input_tokens => 5,
    output_tokens => 2, total_tokens => 7 }));
  run_until(sub { @{ $c->{messages} } == 1 });
  $up->{c}->finish(1011, 'out of memory');
  run_until(sub { @{ $h->usage } });
  my $ev = $h->usage->[0];
  is $ev->{ok}, 0, 'failed';
  is $ev->{status_code}, 502, 'status 502';
  is $ev->{error_type}, 'upstream_error', 'upstream_error';
  is $ev->{input_tokens}, 5, 'the transcription that did complete is still billed';
};

subtest 'no key material in the event, the log or the node\'s view' => sub {
  my $h = RealtimeHarness->new(config => $CFG);
  $h->add_node('rt1');
  my $c = $h->connect($Q, protocols => [ 'realtime', "openai-insecure-api-key.$KEY" ]);
  is $c->{code}, 101, 'a browser-style handshake';
  $h->node_send($h->upstream->[0], completed('item_1', 'x', { type => 'tokens', input_tokens => 1,
    output_tokens => 1, total_tokens => 2 }));
  run_until(sub { @{ $c->{messages} } == 1 });
  $c->{tx}->finish(1000);
  run_until(sub { @{ $h->usage } });
  is $h->usage->[0]{api_key_id}, $ID, 'metered under the key id';
  unlike encode_json($h->usage->[0]), qr/\Q$KEY\E/, 'the key is not in the event';
  unlike join("\n", map { $_->[1] } @{ $h->log }), qr/\Q$KEY\E/, 'nor in the log';
};

subtest 'the configured stores write and report a session' => sub {
  eval { require DBI; require DBD::SQLite; 1 } or plan skip_all => 'DBI/DBD::SQLite not available';
  for my $store (
    [ jsonlog => { backend => 'jsonlog', path => "$TMP/jsonlog", mode => 'dir' } ],
    [ sqlite  => { backend => 'sqlite', sqlite_path => "$TMP/usage.sqlite" } ],
  ) {
    my ($name, $cfg) = @$store;
    my $h = RealtimeHarness->new(config => $CFG, usage_store => $cfg);
    run_session($h, sub {
      my ($h, $c, $up) = @_;
      $h->node_send($up, delta('item_1', 'Hallo'));
      $h->node_send($up, completed('item_1', 'Hallo', { type => 'duration', seconds => 12 }));
      run_until(sub { @{ $c->{messages} } == 2 });
    });
    my $report = $h->skeid->call_function('usage.report', {});
    is $report->{totals}{requests}, 1, "$name: one event in the store";
    is $report->{totals}{audio_seconds}, 12, "$name: its seconds in the report";
    is $report->{by_key}[0]{api_key_id}, $ID, "$name: under the key id";
    is $report->{by_model}[0]{model}, 'whisper-rt', "$name: and the served model";
  }
};

done_testing;
