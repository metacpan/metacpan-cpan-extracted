use strict;
use warnings;
use Test::More;
use Test::Mojo;
use JSON::MaybeXS qw( decode_json encode_json );
use MIME::Base64 qw( encode_base64 );
use Mojo::IOLoop;
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# Live test of the realtime relay (skeid ADR 0029) against a real speaches node. Skipped unless
# SKEID_LIVE_SPEACHES_URL is set (xt/live/skeid-live start speaches; eval "$(xt/live/skeid-live env)").
# SKEID_LIVE_AUDIO is a 16 bit mono wav with speech, SKEID_LIVE_MODEL the loaded model (default
# Systran/faster-whisper-tiny.en). What speaches really does, as recorded in
# t/data/realtime/speaches.jsonl: it speaks the flat session of the conversation API, not the
# transcription session, ends a turn by VAD only after more than 3 s of audio, sends no delta
# events and reports `usage: { type: duration, seconds }`.

my $URL = $ENV{SKEID_LIVE_SPEACHES_URL}
  or plan skip_all => 'set SKEID_LIVE_SPEACHES_URL to run against a real speaches node';
my $WAV = $ENV{SKEID_LIVE_AUDIO}
  or plan skip_all => 'set SKEID_LIVE_AUDIO to a 16 bit mono wav with speech';
my $MODEL = $ENV{SKEID_LIVE_MODEL} // 'Systran/faster-whisper-tiny.en';

open my $fh, '<:raw', $WAV or die "$WAV: $!";
my $data = do { local $/; <$fh> };
my ($rate) = unpack 'x24V', $data;
my @in  = unpack 's<*', substr $data, 44;
my @out = map { my $p = $_ * $rate / 24000; my $i = int $p; my $f = $p - $i;
  int( $in[$i] * ( 1 - $f ) + $in[ $i + 1 < @in ? $i + 1 : $i ] * $f ) } 0 .. int( @in * 24000 / $rate ) - 1;
my $audio = pack( 's<*', @out ) . ( "\0" x 120000 );

my $KEY = 'sk-live-client';
my $ID  = Langertha::Skeid->key_id_for_key($KEY);
my @usage;
my $skeid = Langertha::Skeid->new(
  config_reload_interval => 0,
  config_loader => sub { +{
    client_auth => { keys => [$ID] },
    aliases     => { 'live-asr' => { tiers => [ { model => $MODEL } ] } },
    nodes       => [ { id => 'speaches-live', url => "$URL/v1", engine => 'openai', model => $MODEL, max_conns => 2,
      ( defined $ENV{SKEID_LIVE_SPEACHES_KEY} ? ( api_key_env => 'SKEID_LIVE_SPEACHES_KEY' ) : () ) } ],
  } },
  store_usage_event => sub { push @usage, $_[1]; return { ok => 1 } },
);
my $t = Test::Mojo->new( Langertha::Skeid::Proxy->build_app( skeid => $skeid ) );
$t->ua->inactivity_timeout(120);

my ( @frames, $closed );
$t->ua->websocket( "/v1/realtime?model=live-asr&intent=transcription" => { Authorization => "Bearer $KEY" } => sub {
  my ( $ua, $tx ) = @_;
  $tx->is_websocket or do { diag 'no websocket: ' . ( $tx->res->code // 'none' ); Mojo::IOLoop->stop; return };
  my $sent;
  $tx->on( finish => sub { $closed = 1; Mojo::IOLoop->stop } );
  $tx->on( text => sub {
    my $f = decode_json( $_[1] );
    push @frames, $f;
    if ( $f->{type} eq 'session.created' && !$sent++ ) {
      $tx->send( { text => encode_json( { type => 'session.update',
        session => { input_audio_transcription => { model => 'live-asr', language => 'en' } } } ) } );
    }
    elsif ( $f->{type} eq 'session.updated' ) {
      for ( my $o = 0; $o < length $audio; $o += 4800 ) {
        $tx->send( { text => encode_json( { type => 'input_audio_buffer.append',
          audio => encode_base64( substr( $audio, $o, 4800 ), '' ) } ) } );
      }
    }
    elsif ( $f->{type} eq 'conversation.item.input_audio_transcription.completed' ) { $tx->finish(1000) }
  } );
} );
my $guard = Mojo::IOLoop->timer( 100 => sub { Mojo::IOLoop->stop } );
Mojo::IOLoop->start;
Mojo::IOLoop->remove($guard);
my $deadline = time + 5;
until ( @usage || time > $deadline ) { Mojo::IOLoop->one_tick }

my ($done) = grep { $_->{type} eq 'conversation.item.input_audio_transcription.completed' } @frames;
ok $done, 'a real transcription came back through the relay' or diag explain [ map { $_->{type} } @frames ];
like $done->{transcript} // '', qr/\w/, 'with text' or diag explain $done;
is $done->{usage}{type}, 'duration', 'speaches reports its usage as a duration';

is scalar(@usage), 1, 'one usage event for the session';
is $usage[0]{endpoint}, '/v1/realtime', 'endpoint';
is $usage[0]{model}, $MODEL, 'served model';
is $usage[0]{requested_model}, 'live-asr', 'requested model';
is $usage[0]{ok}, 1, 'ok';
cmp_ok $usage[0]{audio_seconds} // 0, '>', 0, 'audio seconds read off the real usage' or diag explain $usage[0];

done_testing;
