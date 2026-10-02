#!/usr/bin/env perl
# ABSTRACT: Inline image fetch: download cap and URL filter on every backend
use strict;
use warnings;
use Test2::Bundle::More;
use lib 't/lib';

use Future;
use File::Temp ();
use MIME::Base64 qw( encode_base64 );
use HTTP::Response;
use LWP::UserAgent;
use Test::LocalHTTPDaemon;
use IO::Compress::Gzip qw( gzip );
use IO::Compress::Deflate qw( deflate );
use IO::Compress::RawDeflate qw( rawdeflate );
use IO::Compress::Bzip2 qw( bzip2 );
use Langertha::Content::Image;
use Langertha::Request::SyncHTTP;
use Langertha::Engine::Gemini;

# karr k337 (security, from k325): engines that have to inline images fetch
# URL images from the caller's messages -- the knarr/skeid gateway pattern
# forwards those from untrusted clients. The fetch read the whole body into
# memory without a limit, and fetched any host, so a message could make the
# server download gigabytes or reach loopback, the private network or the
# cloud metadata endpoint (SSRF). Now inline_image_max_bytes (default 20 MiB)
# caps the download on every backend, with a Content-Length check up front,
# and the optional inline_image_url_filter vets the image URL and every
# redirect hop before it is requested. Content::Image->deny_private_hosts is
# the ready-made filter. The error texts are the same on every backend.
#
# karr k343: deny_private_hosts let through IPv6 addresses that carry an IPv4
# address a gateway translates to: NAT64 (64:ff9b::/96, local 64:ff9b:1::/48),
# 6to4 (2002::/16) and SIIT (::ffff:0:0:0/96). On an IPv6-only host with
# DNS64/NAT64 a name with a synthesized AAAA reached 169.254.169.254 that way.
# The embedded IPv4 address is now checked like a plain one, and 198.18.0.0/15
# and 192.0.0.0/24 joined the IPv4 list.
#
# karr k346: Teredo 2001:0000::/32 (RFC 4380) was the one IPv4-embedding range
# k343 deferred -- its client IPv4 is obfuscated in the last 32 bits, so it
# cannot be re-checked like 6to4/NAT64 and the whole prefix is now refused
# outright (a non-Teredo 2001::/16 address such as 2001:4860:... stays public).
#
# karr k342: the cap measured the bytes on the wire, but the body was stored
# through decoded_content, which inflates a Content-Encoding without a bound:
# a 48 KB gzip body stored 50 MB (a 20 MiB one inflates to about 20 GB). The
# cap now holds for the decoded size too, on every backend, with the same
# size error: the body is inflated in blocks and refused once it passes.

my $CAP = 1000;
my $PNG = "\x89PNG" . ( 'k' x 496 );   # 500 bytes
my $B64 = encode_base64( $PNG, '' );

# Content-Encoding bodies: bombs whose wire size is under $CAP but decode to
# 500 times it, and small images that must still be stored decoded.
my $zeros = "\0" x ( 500 * $CAP );
sub squeeze { my ( $how, $in ) = @_; my $out;
  { gzip => \&gzip, deflate => \&deflate, raw => \&rawdeflate, bzip2 => \&bzip2 }->{$how}->( \$in => \$out );
  return $out }
my %encoded = (
  '/bomb-gzip.png'       => [ gzip      => squeeze( gzip  => $zeros ) ],
  '/bomb-x-gzip.png'     => [ 'x-gzip'  => squeeze( gzip  => $zeros ) ],
  '/bomb-deflate.png'    => [ deflate   => squeeze( deflate => $zeros ) ],
  '/bomb-rawdeflate.png' => [ deflate   => squeeze( raw   => $zeros ) ],
  '/bomb-bzip2.png'      => [ bzip2     => squeeze( bzip2 => $zeros ) ],
  '/gzip-small.png'      => [ gzip      => squeeze( gzip  => $PNG ) ],
  '/gzip-exact.png'      => [ gzip      => squeeze( gzip  => 'x' x $CAP ) ],
  '/layered-small.png'   => [ 'deflate, gzip' => squeeze( gzip => squeeze( deflate => $PNG ) ) ],
  '/br.png'              => [ br        => 'not really brotli' ],
);
length( $_->[1] ) < $CAP or die "fixture over the wire cap" for values %encoded;

my $hits = File::Temp->new;   # one line per request the daemon served
sub hit_paths {
  open my $fh, '<', $hits->filename or return ();
  return map { chomp; $_ } <$fh>;
}

my $server = Test::LocalHTTPDaemon->start( sub {
  my ($req) = @_;
  my $path = $req->uri->path;
  if ( open my $log, '>>', $hits->filename ) { print {$log} "$path\n"; close $log }
  my $png = [ 'Content-Type' => 'image/png' ];
  return HTTP::Response->new( 200, 'OK', $png, $PNG ) if $path eq '/small.png';
  if ( my $enc = $encoded{$path} ) {
    return HTTP::Response->new( 200, 'OK', [ @$png, 'Content-Encoding' => $enc->[0] ], $enc->[1] );
  }
  return HTTP::Response->new( 200, 'OK', $png, 'x' x $CAP ) if $path eq '/exact.png';
  return HTTP::Response->new( 200, 'OK', $png, 'x' x ( 2 * $CAP ) ) if $path eq '/big.png';
  if ( $path eq '/big-chunked.png' ) {   # no Content-Length: only the body count stops it
    my $left = 10;
    return HTTP::Response->new( 200, 'OK', $png, sub { $left-- > 0 ? 'y' x 200 : undef } );
  }
  if ( $path eq '/endless.png' ) {       # 64 MiB, effectively endless for a 1000 byte cap
    my $left = 16 * 1024;
    return HTTP::Response->new( 200, 'OK', $png, sub { $left-- > 0 ? 'z' x 4096 : undef } );
  }
  if ( $path eq '/lying-length.png' ) {  # announces 20 MiB + 1, sends a few bytes
    return "HTTP/1.1 200 OK\r\nContent-Type: image/png\r\nContent-Length: 20971521\r\n"
      . "Connection: close\r\n\r\nshort";
  }
  return HTTP::Response->new( 302, 'Found', [ Location => '/blocked.png' ], '' ) if $path eq '/to-blocked.png';
  return HTTP::Response->new( 302, 'Found', [ Location => '/small.png' ], '' )   if $path eq '/to-small.png';
  return HTTP::Response->new( 200, 'OK', $png, $PNG ) if $path eq '/blocked.png';
  if ( $path eq '/to-localhost.png' ) {
    my ($p) = ( $req->header('Host') // '' ) =~ /:(\d+)\z/;
    return HTTP::Response->new( 302, 'Found', [ Location => "http://localhost:$p/small.png" ], '' );
  }
  return HTTP::Response->new( 404, 'Not Found', [], 'nope' );
}, keep_alive => 1 );
my $base = $server->url;
my ($port) = $base =~ /:(\d+)\z/;

# An injected async client that follows redirects on its own (plain LWP).
{ package My::PlainHTTP;
  sub new { bless { ua => LWP::UserAgent->new( timeout => 10 ) }, shift }
  sub do_request { my ( $self, %a ) = @_; Future->done( $self->{ua}->request( $a{request} ) ) } }

my ( $loop, $nah );
if ( eval { require Net::Async::HTTP; require IO::Async::Loop; 1 } ) {
  $loop = IO::Async::Loop->new;
  $nah  = Net::Async::HTTP->new;
  $loop->add($nah);
}

# Every backend, one call shape: (base64 or undef, error without "at FILE line N").
my %backend = (
  'sync LWP'         => sub { my ( $img, %o ) = @_; $img->ensure_base64(%o) },
  'sync LWP shim'    => sub { my ( $img, %o ) = @_;
    $img->ensure_base64_f( Langertha::Request::SyncHTTP->new( user_agent => LWP::UserAgent->new ), %o )->get },
  'injected client'  => sub { my ( $img, %o ) = @_; $img->ensure_base64_f( My::PlainHTTP->new, %o )->get },
  ( $nah ? ( 'Net::Async::HTTP' => sub { my ( $img, %o ) = @_;
    Future->wait_any( $img->ensure_base64_f( $nah, %o ),
      $loop->delay_future( after => 10 )->then_fail("test timeout: fetch not abandoned\n") )->get } ) : () ),
);
my @backends = sort keys %backend;
diag 'Net::Async::HTTP not installed: its cases are skipped' unless $nah;

sub fetch {
  my ( $name, $path, %opt ) = @_;
  my $img = Langertha::Content::Image->from_url("$base$path");
  my $b64 = eval { $backend{$name}->( $img, %opt ) };
  my $err = $@;
  $err =~ s/ at \S+ line \d+.*//s;
  return ( $b64, $err, $img );
}

sub too_big { my ( $path, $n ) = @_;
  "Langertha::Content::Image image at $base$path exceeds inline_image_max_bytes ($n)" }

# --- Download cap ---
for my $name (@backends) {
  my ( $b64, $err ) = fetch( $name, '/small.png', max_bytes => $CAP );
  is $b64, $B64, "$name: a body under the cap is stored";
  ( $b64, $err ) = fetch( $name, '/exact.png', max_bytes => $CAP );
  is $b64, encode_base64( 'x' x $CAP, '' ), "$name: a body of exactly the cap is stored";

  for my $path (qw( /big.png /big-chunked.png /endless.png )) {
    my ( $b64, $err, $img ) = fetch( $name, $path, max_bytes => $CAP );
    ok !defined $b64, "$name: $path over the cap fails";
    is $err, too_big( $path, $CAP ), '... with the size error';
    ok !$img->has_base64, '... nothing stored';
  }

  ( $b64, $err ) = fetch( $name, '/lying-length.png' );
  is $err, too_big( '/lying-length.png', 20971520 ),
    "$name: a Content-Length over the default cap (20 MiB) fails without options";

  ( $b64, $err ) = fetch( $name, '/big.png', max_bytes => 0 );
  is $b64, encode_base64( 'x' x ( 2 * $CAP ), '' ), "$name: max_bytes => 0 removes the cap";
}
# --- Download cap: the decoded size (k342) ---
for my $name (@backends) {
  for my $path (qw( /bomb-gzip.png /bomb-x-gzip.png /bomb-deflate.png /bomb-rawdeflate.png /bomb-bzip2.png )) {
    my ( $b64, $err, $img ) = fetch( $name, $path, max_bytes => $CAP );
    ok !defined $b64, "$name: $path decoding past the cap fails";
    # Net::Async::HTTP inflates deflate itself and reads only the zlib form:
    # on raw deflate its own decoder fails the fetch first.
    if ( $name eq 'Net::Async::HTTP' && $path eq '/bomb-rawdeflate.png' ) {
      ok length $err, '... with its decode error';
    }
    else {
      is $err, too_big( $path, $CAP ), '... with the size error';
    }
    ok !$img->has_base64, '... nothing stored';
  }
  my ( $b64, $err ) = fetch( $name, '/gzip-small.png', max_bytes => $CAP );
  is $b64, $B64, "$name: a gzip body under the cap is stored decoded";
  ( $b64, $err ) = fetch( $name, '/gzip-exact.png', max_bytes => $CAP );
  is $b64, encode_base64( 'x' x $CAP, '' ), "$name: a gzip body decoding to exactly the cap is stored";
  ( $b64, $err ) = fetch( $name, '/layered-small.png', max_bytes => $CAP );
  is $b64, $B64, "$name: layered encodings are undone in reverse order";
  ( $b64, $err ) = fetch( $name, '/bomb-gzip.png', max_bytes => 0 );
  is $b64, encode_base64( $zeros, '' ), "$name: max_bytes => 0 decodes without a cap";
  ( $b64, $err ) = fetch( $name, '/br.png', max_bytes => $CAP );
  is $err, "ensure_base64: failed to fetch $base/br.png: cannot decode Content-Encoding 'br' "
    . "within inline_image_max_bytes", "$name: an encoding that cannot be bounded is refused";
}

is Langertha::Content::Image::DEFAULT_MAX_BYTES(), 20_971_520, 'default cap is 20 MiB';

# --- URL filter ---
my @seen;
my $no_blocked = sub { push @seen, "$_[0]"; $_[0]->path ne "/blocked.png" };
for my $name (@backends) {
  truncate $hits->filename, 0;
  @seen = ();
  my ( $b64, $err, $img ) = fetch( $name, '/blocked.png', url_filter => $no_blocked );
  ok !defined $b64, "$name: a URL the filter refuses fails";
  is $err, "Langertha::Content::Image refuses to fetch image URL $base/blocked.png: "
    . 'rejected by inline_image_url_filter', '... with the refusal';
  is_deeply [ hit_paths() ], [], '... before any request';
  isa_ok $seen[0] && URI->new( $seen[0] ), 'URI';

  truncate $hits->filename, 0;
  ( $b64, $err, $img ) = fetch( $name, '/to-blocked.png', url_filter => $no_blocked );
  ok !defined $b64, "$name: a redirect to a refused URL fails";
  is $err, "Langertha::Content::Image refuses to fetch image URL $base/blocked.png: "
    . 'rejected by inline_image_url_filter', '... with the refusal naming the hop';
  ok !$img->has_base64, '... nothing stored';
  if ( $name eq 'injected client' ) {
    # This client followed the redirect itself: checked after the fact.
    is_deeply [ hit_paths() ], [ '/to-blocked.png', '/blocked.png' ],
      '... (an injected client is checked after its own redirects)';
  }
  else {
    is_deeply [ hit_paths() ], ['/to-blocked.png'], '... and the refused hop is never requested';
  }

  @seen = ();
  ( $b64, $err ) = fetch( $name, '/to-small.png', url_filter => $no_blocked );
  is $b64, $B64, "$name: an allowed redirect is followed";
  is_deeply \@seen, [ "$base/to-small.png", "$base/small.png" ], '... the filter saw both hops';

  ( $b64, $err ) = fetch( $name, '/small.png', url_filter => sub { die "boom\n" } );
  is $err, "Langertha::Content::Image refuses to fetch image URL $base/small.png: "
    . 'inline_image_url_filter died: boom', "$name: a filter that dies refuses";
}

# --- deny_private_hosts ---
{
  my %dns;
  my @asked;
  my $deny = Langertha::Content::Image->deny_private_hosts(
    resolver => sub { push @asked, $_[0]; @{ $dns{ $_[0] } // [] } } );
  my @private = qw( 127.0.0.1 127.1.2.3 0.0.0.0 10.1.2.3 172.16.0.1 172.31.255.255
    192.168.1.1 169.254.169.254 169.254.1.1 100.64.0.1 100.127.255.255 224.0.0.1 255.255.255.255
    ::1 :: fe80::1 fec0::1 fc00::1 fd00:ec2::254 ff02::1 ::ffff:127.0.0.1 ::ffff:10.0.0.1 ::127.0.0.1
    198.18.0.1 198.19.255.255 192.0.0.170 192.0.0.171 192.0.0.1 240.0.0.1 255.255.255.255
    64:ff9b::a9fe:a9fe 64:ff9b::7f00:1 64:ff9b::10.0.0.1 64:ff9b::c0a8:101
    64:ff9b:1::a00:1 64:ff9b:1::a9fe:a9fe 64:ff9b:1:a9fe:a9:fe00:: 64:ff9b:1:1::808:808
    2002:a9fe:a9fe:: 2002:7f00:1:: 2002:a00:1::1 2002:c0a8:101:1::
    ::ffff:0:7f00:1 ::ffff:0:a9fe:a9fe ::ffff:0:10.0.0.1
    2001::1 2001:0:4136:e378:8000:63bf:3fff:fdd2 2001:0:53aa:64c:0:5efe:a00:1 2001::ffff:ffff );
  my @public = qw( 93.184.216.34 8.8.8.8 172.32.0.1 172.15.255.255 100.128.0.1 100.63.255.255
    192.169.0.1 2606:4700::1111 ::ffff:8.8.8.8
    198.17.255.255 198.20.0.1 192.0.1.1 191.255.255.255
    64:ff9b::808:808 64:ff9b:1::808:808 2002:808:808:: ::ffff:0:808:808 64:ff9c::a00:1 2003::a00:1
    2001:4860:4860::8888 );
  for my $ip (@private) {
    $dns{'h.test'} = [$ip];
    ok !$deny->( URI->new('http://h.test/x.png') ), "deny_private_hosts refuses $ip";
  }
  for my $ip (@public) {
    $dns{'h.test'} = [$ip];
    ok $deny->( URI->new('http://h.test/x.png') ), "deny_private_hosts allows $ip";
  }
  $dns{'h.test'} = [ '93.184.216.34', '10.0.0.1' ];
  ok !$deny->( URI->new('https://h.test/') ), 'refused when any resolved address is private';
  $dns{'h.test'} = [];
  ok !$deny->( URI->new('https://h.test/') ), 'refused when the host does not resolve';
  @asked = ();
  $dns{'2001:db8::1'} = ['2606:4700::1111'];
  ok $deny->( URI->new('http://[2001:db8::1]:8080/x.png') ), 'an IPv6 literal host';
  is_deeply \@asked, ['2001:db8::1'], '... reaches the resolver without brackets';

  # The system resolver, on IP literals only (no DNS lookup).
  my $real = Langertha::Content::Image->deny_private_hosts;
  ok !$real->( URI->new('http://127.0.0.1/x.png') ),       'system resolver: 127.0.0.1 refused';
  ok !$real->( URI->new('http://169.254.169.254/latest') ), 'system resolver: metadata address refused';
  ok !$real->( URI->new('http://[::1]/x.png') ),           'system resolver: ::1 refused';
  ok $real->( URI->new('http://93.184.216.34/x.png') ),    'system resolver: a public literal allowed';

  # End to end: the image host "resolves" public, the redirect target
  # localhost resolves private -- that hop is never requested.
  my $e2e = Langertha::Content::Image->deny_private_hosts( resolver => sub {
    $_[0] eq '127.0.0.1' ? ('93.184.216.34') : $_[0] eq 'localhost' ? ('127.0.0.1') : () } );
  for my $name (@backends) {
    next if $name eq 'injected client';
    truncate $hits->filename, 0;
    my $img = Langertha::Content::Image->from_url("$base/small.png");
    ok eval { $backend{$name}->( $img, url_filter => $e2e ); 1 }, "$name: deny_private_hosts allows a public host";
    truncate $hits->filename, 0;
    my ( $b64, $err ) = fetch( $name, '/to-localhost.png', url_filter => $e2e );
    is $err, "Langertha::Content::Image refuses to fetch image URL http://localhost:$port/small.png: "
      . 'rejected by inline_image_url_filter', "$name: a redirect to a private host is refused";
    is_deeply [ hit_paths() ], ['/to-localhost.png'], '... before it is requested';
  }
}

# --- Engines: the attributes reach every fetch ---
{
  my $g = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-2.5-flash' );
  is $g->inline_image_max_bytes, 20_971_520, 'engine: inline_image_max_bytes defaults to 20 MiB';
  ok !defined $g->inline_image_url_filter, 'engine: no url filter by default';

  my $msg = { role => 'user', content => [ 'hi', Langertha::Content::Image->from_url("$base/big.png") ] };
  my %args = ( api_key => 'k', model => 'gemini-2.5-flash', inline_image_max_bytes => $CAP );
  my $sync = Langertha::Engine::Gemini->new(%args);
  ok !eval { $sync->chat_request( $sync->chat_messages($msg) ); 1 }, 'engine sync: an image over the cap croaks';
  my $err = $@ =~ s/ at \S+ line \d+.*//sr;
  my $too = too_big( '/big.png', $CAP );
  like $err, qr/\ALangertha::Engine::Gemini: this endpoint takes only inline images .*\Q$too\E/s,
    '... with the engine-named error carrying the size error';

  my @clients = ( Langertha::Request::SyncHTTP->new( user_agent => LWP::UserAgent->new ), $nah ? $nah : () );
  for my $http (@clients) {
    my $img = { role => 'user', content => [ 'hi', Langertha::Content::Image->from_url("$base/big.png") ] };
    my $f = Langertha::Engine::Gemini->new( %args, _async_http => $http )->chat_f( messages => [$img] );
    $f->await;
    is scalar( $f->failure ) =~ s/\s+\z//r, $err =~ s/\s+\z//r, 'engine chat_f via ' . ref($http) . ': the same error text';
  }

  truncate $hits->filename, 0;
  my $filtered = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-2.5-flash',
    inline_image_url_filter => Langertha::Content::Image->deny_private_hosts );
  my $local = { role => 'user', content => [ 'hi', Langertha::Content::Image->from_url("$base/small.png") ] };
  ok !eval { $filtered->chat_request( $filtered->chat_messages($local) ); 1 },
    'engine sync: deny_private_hosts refuses the loopback image host';
  like $@, qr/\ALangertha::Engine::Gemini: this endpoint takes only inline images .*refuses to fetch image URL \Q$base\E\/small\.png: rejected by inline_image_url_filter/s,
    '... with the engine-named error carrying the refusal';
  for my $http (@clients) {
    my $f = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-2.5-flash', _async_http => $http,
      inline_image_url_filter => Langertha::Content::Image->deny_private_hosts )->chat_f( messages => [
      { role => 'user', content => [ 'hi', Langertha::Content::Image->from_url("$base/small.png") ] } ] );
    $f->await;
    like scalar $f->failure, qr/refuses to fetch image URL \Q$base\E\/small\.png: rejected by inline_image_url_filter/,
      'engine chat_f via ' . ref($http) . ': refused too';
  }
  is_deeply [ hit_paths() ], [], '... and the loopback host was never requested';
}

done_testing;
