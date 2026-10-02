#!/usr/bin/env perl
# ABSTRACT: The inline image fetch talks only http/https; other schemes croak before any I/O
use strict;
use warnings;
use Test2::Bundle::More;
use lib 't/lib';

use Future;
use File::Temp ();
use JSON::MaybeXS;
use MIME::Base64 qw( encode_base64 );
use HTTP::Response;
use LWP::UserAgent;
use Test::LocalHTTPDaemon;
use Langertha::Content::Image;
use Langertha::Request::SyncHTTP;
use Langertha::Engine::Gemini;
use Langertha::Engine::Ollama;

# karr k325 (security): engines that have to inline images (Gemini, Ollama
# native, LM Studio native, inline-only OpenAI-shape endpoints) fetched a URL
# image with LWP's default protocol set, so a file:///etc/passwd image_url in a
# caller's message -- the knarr/skeid gateway pattern forwards those -- was
# read from the server's disk and sent to the provider. The fetch now takes
# only http/https (data: URLs are decoded in process); every other scheme
# croaks with one message on every path before any I/O, and a redirect to
# another scheme is not followed (LWP protocols_allowed, also on the sync
# LWP fallback of the _f paths). SSRF to private hosts: t/47_image_fetch_limits.t (k337).

my $json = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );
my $PNG  = "\x89PNG-k325";
my $B64  = encode_base64( $PNG, '' );

my $secret = File::Temp->new;
print {$secret} "k325-SECRET-FILE-CONTENT\n";
close $secret;
my $file_url   = 'file://' . $secret->filename;
my $secret_b64 = encode_base64( "k325-SECRET-FILE-CONTENT\n", '' );

sub refusal {
  my ($scheme) = @_;
  return qr/Langertha::Content::Image refuses to fetch image URL with scheme '\Q$scheme\E' \(only http\/https; use Content::Image->from_file for local files\)/;
}

# Every LWP request in this process goes through send_request; count them.
my $lwp_calls = 0;
{
  no warnings 'redefine';
  my $orig = \&LWP::UserAgent::send_request;
  *LWP::UserAgent::send_request = sub { $lwp_calls++; goto &$orig };
}

# An async client that must never be asked.
{ package My::ForbiddenHTTP; sub new { bless { calls => 0 }, shift }
  sub do_request { $_[0]{calls}++; Future->fail("fetch attempted\n") } }

# --- from_url refuses other schemes, before any I/O ---
for my $url ( $file_url, 'FILE:///etc/passwd', 'ftp://127.0.0.1/x.png', 'gopher://127.0.0.1/x' ) {
  my ($scheme) = $url =~ /\A([^:]+):/;
  $lwp_calls = 0;
  my $img = eval { Langertha::Content::Image->from_url($url) };
  ok !$img, "from_url($scheme:...) croaks";
  like $@, refusal($scheme), '... with the refusal naming the scheme';
  is $lwp_calls, 0, '... without any request';
}
ok !eval { Langertha::Content::Image->from_url('/etc/passwd') }, 'a URL without a scheme croaks';
like $@, qr/refuses to fetch image URL without a scheme \(only http\/https/, '... and says so';
ok eval { Langertha::Content::Image->from_url('https://example.com/a.png') }, 'https is accepted';
ok eval { Langertha::Content::Image->from_url('http://example.com/a.png') },  'http is accepted';

# --- An object built around from_url is still checked at the fetch ---
{
  $lwp_calls = 0;
  my $img = Langertha::Content::Image->new( url => $file_url, media_type => 'image/png' );
  ok !eval { $img->ensure_base64; 1 }, 'ensure_base64 on a file: URL croaks';
  like $@, refusal('file'), '... with the refusal';
  is $lwp_calls, 0, '... before any request';
  ok !$img->has_base64, '... nothing stored';

  my $http = My::ForbiddenHTTP->new;
  my $f = $img->ensure_base64_f($http);
  ok $f->is_failed, 'ensure_base64_f on a file: URL fails';
  like scalar $f->failure, refusal('file'), '... with the same refusal (sync/async parity)';
  is $http->{calls}, 0, '... without asking the client';

  my $f2 = Langertha::Content::Image->new( url => $file_url )
    ->ensure_base64_f( Langertha::Request::SyncHTTP->new( user_agent => LWP::UserAgent->new ) );
  like scalar $f2->failure, refusal('file'), '... also over the sync LWP shim';
  is $lwp_calls, 0, '... without an LWP request';
}

# --- data: URLs are decoded in process, no client involved ---
{
  $lwp_calls = 0;
  my $img = Langertha::Content::Image->from_url("data:image/png;base64,$B64");
  is $img->ensure_base64, $B64, 'data: URL decoded by ensure_base64';
  is $img->media_type, 'image/png', '... media_type taken from the data: URL';
  is $lwp_calls, 0, '... without LWP';

  my $http = My::ForbiddenHTTP->new;
  my $img2 = Langertha::Content::Image->from_url("data:image/png;base64,$B64");
  is $img2->ensure_base64_f($http)->get, $B64, 'data: URL decoded by ensure_base64_f';
  is $http->{calls}, 0, '... without the client';
}

# --- Engines: the image_url part / Content object from a message ---
{
  my $g = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-2.5-flash' );
  my $msg = { role => 'user', content => [ 'hi', { type => 'image_url', image_url => { url => $file_url } } ] };
  $lwp_calls = 0;
  my $req = eval { $g->chat_request( $g->chat_messages($msg) ) };
  ok !$req, 'Gemini sync: an image_url part with a file: URL croaks';
  like $@, refusal('file'), '... with the refusal';
  unlike $req ? $req->content : '', qr/\Q$secret_b64\E/, '... and the file never reaches a request';
  is $lwp_calls, 0, '... no request at all';

  my $http = My::ForbiddenHTTP->new;
  my $ga = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-2.5-flash', _async_http => $http );
  my $f = $ga->chat_f( messages => [$msg] );
  $f->await;
  ok $f->is_failed, 'Gemini chat_f: fails';
  like scalar $f->failure, refusal('file'), '... with the same refusal';
  is $http->{calls}, 0, '... before any request (no fetch, no chat call)';

  my $o = Langertha::Engine::Ollama->new( url => 'http://h:11434', model => 'm' );
  my $img_msg = { role => 'user', content => [ 'x', Langertha::Content::Image->new( url => $file_url ) ] };
  ok !eval { $o->chat_request( $o->chat_messages($img_msg) ); 1 }, 'Ollama native sync: a file: Content::Image croaks';
  like $@, qr/\ALangertha::Engine::Ollama: this endpoint takes only inline images .*refuses to fetch image URL with scheme 'file'/s,
    '... with the engine-named inline error carrying the refusal';
  my $err_sync = $@ =~ s/ at \S+ line \d+.*//sr;

  my $http2 = My::ForbiddenHTTP->new;
  my $oa = Langertha::Engine::Ollama->new( url => 'http://h:11434', model => 'm', _async_http => $http2 );
  my $f2 = $oa->chat_f( messages => [$img_msg] );
  $f2->await;
  is scalar( $f2->failure ) =~ s/\s+\z//r, $err_sync =~ s/\s+\z//r, 'Ollama native chat_f: the same error text';
  is $http2->{calls}, 0, '... before any request';
}

# --- Redirects: an http URL that redirects elsewhere is not followed ---
my $server = Test::LocalHTTPDaemon->start( sub {
  my ($req) = @_;
  my $path = $req->uri->path;
  return HTTP::Response->new( 302, 'Found', [ Location => $file_url ], '' ) if $path eq '/to-file.png';
  return HTTP::Response->new( 302, 'Found', [ Location => "ftp://127.0.0.1:1/x.png" ], '' )
    if $path eq '/to-ftp.png';
  return HTTP::Response->new( 302, 'Found', [ Location => '/ok.png' ], '' ) if $path eq '/to-http.png';
  return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'image/png' ], $PNG ) if $path eq '/ok.png';
  return HTTP::Response->new( 404, 'Not Found', [], 'nope' );
} );
my $base = $server->url;

{
  my $img = Langertha::Content::Image->from_url("$base/to-http.png");
  is $img->ensure_base64, $B64, 'sync: an http -> http redirect is followed';

  my $to_file = Langertha::Content::Image->from_url("$base/to-file.png");
  ok !eval { $to_file->ensure_base64; 1 }, 'sync: an http -> file: redirect is not followed';
  like $@, qr/failed to fetch \Q$base\E\/to-file\.png: 302/, '... the fetch fails on the redirect itself';
  ok !$to_file->has_base64, '... nothing stored';

  # LWP only refuses file: redirects on its own; protocols_allowed covers the rest.
  my $to_ftp = Langertha::Content::Image->from_url("$base/to-ftp.png");
  ok !eval { $to_ftp->ensure_base64; 1 }, 'sync: an http -> ftp: redirect is not followed';
  like $@, qr/Access to 'ftp' URIs has been disabled/, '... refused by protocols_allowed';
}

# The async LWP fallback runs the engine's own user_agent, which allows every
# scheme: the fetch goes through a restricted copy of it.
{
  my $shim = Langertha::Request::SyncHTTP->new( user_agent => LWP::UserAgent->new );
  my $ok = Langertha::Content::Image->from_url("$base/to-http.png");
  is $ok->ensure_base64_f($shim)->get, $B64, 'sync LWP shim: an http -> http redirect is followed';

  for my $case ( [ file => qr/failed to fetch \S+: 302/ ], [ ftp => qr/Access to 'ftp' URIs has been disabled/ ] ) {
    my ( $to, $re ) = @$case;
    my $img = Langertha::Content::Image->from_url("$base/to-$to.png");
    my $f = $img->ensure_base64_f($shim);
    ok $f->is_failed, "sync LWP shim: an http -> $to: redirect is not followed";
    like scalar $f->failure, $re, '... and the fetch fails';
    ok !$img->has_base64, '... nothing stored';
  }
  ok !$shim->user_agent->protocols_allowed, "... the engine's own user_agent is left unrestricted";
}

SKIP: {
  skip 'Net::Async::HTTP not installed', 5 unless eval { require Net::Async::HTTP; require IO::Async::Loop; 1 };
  my $loop = IO::Async::Loop->new;
  my $nah  = Net::Async::HTTP->new;
  $loop->add($nah);

  my $ok = Langertha::Content::Image->from_url("$base/to-http.png");
  is $ok->ensure_base64_f($nah)->get, $B64, 'Net::Async::HTTP: an http -> http redirect is followed';
  for my $to (qw( file ftp )) {
    my $img = Langertha::Content::Image->from_url("$base/to-$to.png");
    my $f = $img->ensure_base64_f($nah);
    $f->await;
    ok $f->is_failed, "Net::Async::HTTP: an http -> $to: redirect is not followed";
    ok !$img->has_base64, '... nothing stored';
  }
}

done_testing;
