#!/usr/bin/env perl
# ABSTRACT: response_max_bytes bounds Content-Encoding decode on the provider/metrics paths
use strict;
use warnings;
use Test2::Bundle::More;

# karr k346 (security, from the k342/k343 review): decoded_content inflates a
# Content-Encoding (gzip/deflate/bzip2) with NO size bound, so a hostile or
# broken endpoint (a self-hosted /metrics, a gateway) could make a small
# compressed body expand to gigabytes in memory (a decompression bomb) on the
# provider/metrics decode sites -- Role::HTTP (_error_response_body, the
# parse_response trace), Role::OpenAICompatible (transcription_result) and
# Role::Runtime::MetricsPoll (poll_metrics_f). The k342 bounded-inflate path
# (Content::Image) is now shared via Langertha::HTTP::BoundedDecode and applied
# here through Role::HTTP::_bounded_decoded_content, capped at a generous
# response_max_bytes (256 MiB default; 0 = no cap), refusing with the same
# "too big" croak style. Charset decoding is preserved (the bomb is undone
# bounded, then the charset step runs on the already-bounded bytes).

use lib 't/lib';
use HTTP::Response;
use Future;
use Encode ();
use Scalar::Util qw( blessed );
use IO::Compress::Gzip qw( gzip );
use Test::LocalHTTPDaemon;
use Langertha::Request::SyncHTTP;
use LWP::UserAgent;
use Langertha::Engine::vLLM;

my $CAP   = 1000;
my $zeros = "\0" x ( 500 * $CAP );   # 500 KiB decoded from a tiny gzip body

sub gz { my ($in) = @_; my $out; gzip( \$in => \$out ) or die "gzip failed"; $out }

sub resp {
  my ( $encoding, $body, %h ) = @_;
  return HTTP::Response->new( 200, 'OK', [
    'Content-Type' => $h{ct} // 'text/plain',
    ( $encoding ? ( 'Content-Encoding' => $encoding ) : () ),
  ], $body );
}

# An injected async client (ADR 0027 seam): hands back one canned response.
{ package Mock::HTTP;
  sub new { my ( $class, $resp ) = @_; bless { resp => $resp }, $class }
  sub do_request { my ($self) = @_; Future->done( $self->{resp} ) } }

sub engine {
  my (%extra) = @_;
  return Langertha::Engine::vLLM->new( url => 'http://test.invalid:8000/v1', %extra );
}

my $gzip_bomb = gz($zeros);
ok length($gzip_bomb) < $CAP, 'the gzip bomb is under the cap on the wire';

# --- default ---
is engine()->response_max_bytes, 268_435_456, 'response_max_bytes defaults to 256 MiB';

# --- Role::HTTP::_bounded_decoded_content (covers _error_response_body + the
#     parse_response trace, which both route through it) ---
{
  my $e = engine( response_max_bytes => $CAP );

  is $e->_bounded_decoded_content( resp( undef, 'plain body' ) ), 'plain body',
    'an uncompressed body passes through';
  is $e->_bounded_decoded_content( resp( 'gzip', gz('small body') ) ), 'small body',
    'a gzip body under the cap is decoded';

  my $utf8 = Encode::encode( 'UTF-8', "caf\x{e9}" );
  is $e->_bounded_decoded_content(
      resp( 'gzip', gz($utf8), ct => 'text/plain; charset=utf-8' ),
      default_charset => 'UTF-8' ),
    "caf\x{e9}", 'the charset step runs on the bounded bytes (UTF-8 -> characters)';

  my $err = eval { $e->_bounded_decoded_content( resp( 'gzip', $gzip_bomb ) ); 1 } ? '' : $@;
  like $err, qr/Langertha::Engine::vLLM response body exceeds response_max_bytes \(\Q$CAP\E\)/,
    'a gzip body decoding past the cap is refused with the too-big croak'
    or diag "got: $err";

  my $uncapped = engine( response_max_bytes => 0 );
  is length( $uncapped->_bounded_decoded_content( resp( 'gzip', $gzip_bomb ) ) ),
    length($zeros), 'response_max_bytes => 0 removes the cap';
}

# --- Role::OpenAICompatible::transcription_result ---
{
  my $e = engine( response_max_bytes => $CAP );
  my $utf8 = Encode::encode( 'UTF-8', "caf\x{e9} transcript" );
  is $e->transcription_result( resp( 'gzip', gz($utf8), ct => 'text/plain; charset=utf-8' ) )->{text},
    "caf\x{e9} transcript", 'transcription: a small gzip transcript is decoded (charset kept)';

  my $err = eval { $e->transcription_result( resp( 'gzip', $gzip_bomb ) ); 1 } ? '' : $@;
  like $err, qr/response body exceeds response_max_bytes \(\Q$CAP\E\)/,
    'transcription: a gzip bomb is refused';
}

# --- Role::Runtime::MetricsPoll::poll_metrics_f ---
my $prom = "# HELP vllm:x running\n# TYPE vllm:x gauge\nvllm:x 3\n";
{
  my $e = engine( response_max_bytes => $CAP,
    _async_http => Mock::HTTP->new( resp( 'gzip', gz($prom) ) ) );
  my $records = $e->poll_metrics_f->get;
  is ref($records), 'ARRAY', 'metrics: a small gzip body is decoded and parsed';
  ok scalar(@$records), '... into records';
}
{
  my $e = engine( response_max_bytes => $CAP,
    _async_http => Mock::HTTP->new( resp( 'gzip', $gzip_bomb ) ) );
  my $err = eval { $e->poll_metrics_f->get; 1 } ? '' : $@;
  like $err, qr/response body exceeds response_max_bytes \(\Q$CAP\E\)/,
    'metrics: a gzip bomb is refused (the future fails)';
}

# --- Transport parity across real backends (Test::LocalHTTPDaemon) ---
# The mock cases above don't exercise the real HTTP backends, which is where the
# Net::Async::HTTP gap hid: when the client decodes content it inflates the body
# itself while streaming and moves Content-Encoding to X-Original-Content-Encoding,
# so _bounded_decoded_content sees nothing to bound. A gzip bomb served over
# loopback must be refused on BOTH the sync LWP path (bounded on the still-encoded
# body by _bounded_decoded_content) and Net::Async::HTTP (bounded by the streamed
# decoded-byte counter in _async_do_request_f when the client decodes; by
# _bounded_decoded_content on the still-encoded body when it does not). poll_metrics_f
# and the non-streaming chat request share the same _async_do_request_f path.
{
  my $prom = "# HELP vllm:x running\n# TYPE vllm:x gauge\nvllm:x 3\n";
  my $server = Test::LocalHTTPDaemon->start( sub {
    my ($req) = @_;
    my $bomb = $req->uri->path =~ m{/bomb/};
    return HTTP::Response->new( 200, 'OK',
      [ 'Content-Type' => 'text/plain', 'Content-Encoding' => 'gzip' ],
      gz( $bomb ? $zeros : $prom ) );
  }, keep_alive => 1 );
  my $base = $server->url;

  my ( $loop, @clients );
  push @clients, [ 'sync LWP' => Langertha::Request::SyncHTTP->new( user_agent => LWP::UserAgent->new ) ];
  if ( eval { require Net::Async::HTTP; require IO::Async::Loop; 1 } ) {
    $loop = IO::Async::Loop->new;
    # decode_content => 1 is the reviewer's scenario (the client inflates while
    # streaming); => 0 is the current library default (body stays gzipped).
    for my $decode ( 1, 0 ) {
      my $client = Net::Async::HTTP->new( decode_content => $decode, pipeline => 0 );
      $loop->add($client);
      push @clients, [ "Net::Async::HTTP(decode_content=$decode)" => $client ];
    }
  }
  else {
    diag 'Net::Async::HTTP not installed: its transport-parity cases are skipped';
  }

  my $run = sub {
    my ( $engine, $client ) = @_;
    my $f = $engine->poll_metrics_f;
    return $f->get unless $loop && blessed($client) && $client->isa('Net::Async::HTTP');
    return Future->wait_any( $f,
      $loop->delay_future( after => 10 )->then_fail("test timeout: fetch not abandoned\n") )->get;
  };

  for my $pair (@clients) {
    my ( $name, $client ) = @$pair;
    my $small = engine( url => "$base/small/v1", response_max_bytes => $CAP, _async_http => $client );
    my $records = eval { $run->( $small, $client ) };
    is ref($records), 'ARRAY', "$name: a small gzip /metrics body is decoded over the wire"
      or diag "got: $@";
    ok scalar(@{ $records || [] }), '... into records';

    my $bomb = engine( url => "$base/bomb/v1", response_max_bytes => $CAP, _async_http => $client );
    my $err = eval { $run->( $bomb, $client ); 1 } ? '' : $@;
    like $err, qr/response body exceeds response_max_bytes \(\Q$CAP\E\)/,
      "$name: a gzip bomb /metrics body is refused over the wire";
  }
}

done_testing;
