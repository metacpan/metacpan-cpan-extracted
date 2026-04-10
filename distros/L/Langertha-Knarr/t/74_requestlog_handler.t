use strict;
use warnings;
use Test2::V0;
use Future;
use File::Temp qw( tempdir );
use JSON::MaybeXS;
use Path::Tiny;

use Langertha::Knarr::Session;
use Langertha::Knarr::Request;
use Langertha::Knarr::Handler::Code;
use Langertha::Knarr::Handler::RequestLog;
use Langertha::Knarr::Config;
use Langertha::Knarr::RequestLog;

my $json = JSON::MaybeXS->new( utf8 => 1 );

# Build a config with log_file pointing at a tempdir.
my $tmp = tempdir( CLEANUP => 1 );
my $log_file = "$tmp/requests.jsonl";

my $config = Langertha::Knarr::Config->new(
  data => {
    listen   => ['127.0.0.1:0'],
    models   => {},
    logging  => { file => $log_file },
  },
);

my $rlog = Langertha::Knarr::RequestLog->new( config => $config );
ok( $rlog->_enabled, 'rlog enabled with log_file' );

my $session = Langertha::Knarr::Session->new( id => 's' );

# --- Sync chat: log entry written ---
{
  my $inner = Langertha::Knarr::Handler::Code->new( code => sub { 'sync-out' } );
  my $h = Langertha::Knarr::Handler::RequestLog->new(
    wrapped     => $inner,
    request_log => $rlog,
  );
  my $req = Langertha::Knarr::Request->new(
    protocol => 'openai',
    model    => 'gpt-test',
    messages => [ { role => 'user', content => 'hi' } ],
  );
  my $r = $h->handle_chat_f( $session, $req )->get;
  is( $r->{content}, 'sync-out', 'inner result passed through' );

  ok( -e $log_file, 'log file written' );
  my @lines = grep { length } split /\n/, path($log_file)->slurp_utf8;
  is( scalar @lines, 1, 'one log entry' );
  my $entry = $json->decode( $lines[0] );
  is( $entry->{output}, 'sync-out', 'output recorded' );
  is( $entry->{model},  'gpt-test', 'model recorded' );
  is( $entry->{format}, 'openai',   'format recorded' );
  is( $entry->{status}, 'ok',       'status ok' );
}

# --- Streaming chat: accumulated text logged once at the end ---
{
  unlink $log_file;
  my $inner = Langertha::Knarr::Handler::Code->new(
    code        => sub { 'fallback' },
    stream_code => sub { my @p = ('alp', 'ha-', 'bet'); sub { @p ? shift @p : undef } },
  );
  my $h = Langertha::Knarr::Handler::RequestLog->new(
    wrapped     => $inner,
    request_log => $rlog,
  );
  my $req = Langertha::Knarr::Request->new(
    protocol => 'openai',
    model    => 'gpt-stream',
    stream   => 1,
    messages => [ { role => 'user', content => 'hi' } ],
  );
  my $stream = $h->handle_stream_f( $session, $req )->get;
  my @chunks;
  while ( defined( my $c = $stream->next_chunk_f->get ) ) {
    push @chunks, $c;
  }
  is( join('', @chunks), 'alpha-bet', 'all chunks collected' );

  my @lines = grep { length } split /\n/, path($log_file)->slurp_utf8;
  is( scalar @lines, 1, 'one stream log entry' );
  my $entry = $json->decode( $lines[0] );
  is( $entry->{output}, 'alpha-bet', 'accumulated stream output logged' );
  is( $entry->{model},  'gpt-stream', 'stream model logged' );
}

done_testing;
