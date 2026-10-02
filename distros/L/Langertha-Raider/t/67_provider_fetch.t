#!/usr/bin/env perl
# ABSTRACT: The bounded provider-manifest fetch: https only, checked and pinned addresses, same-origin redirects, limits, no credentials (k118)
use strict;
use warnings;
use Test2::V0;
use Future;
use IO::Async::Loop;
use IO::Socket::INET;
use lib 't/lib';
use Test::Raider::FakeHTTPS;
use Langertha::Raider::Provider::Fetch;

my $CLASS = 'Langertha::Raider::Provider::Fetch';
my $PATH  = '/.well-known/langertha.json';

subtest 'target_url: what a command-line target may be' => sub {
  my $f = $CLASS->new;
  is( $f->target_url('provider.example'), 'https://provider.example/.well-known/langertha.json', 'HOST' );
  is( $f->target_url('Provider.Example:8443'), 'https://provider.example:8443/.well-known/langertha.json', 'HOST:PORT, lower-cased' );
  is( $f->target_url('provider.example:443'), 'https://provider.example/.well-known/langertha.json', 'the default port folds away' );
  is( $f->target_url('[::1]:9443'), 'https://[::1]:9443/.well-known/langertha.json', '[IPv6]:PORT' );
  is( $f->target_url('https://provider.example'), 'https://provider.example/.well-known/langertha.json', 'https origin' );
  is( $f->target_url('https://provider.example/'), 'https://provider.example/.well-known/langertha.json', 'https origin with /' );
  is( $f->target_url('https://provider.example'.$PATH), 'https://provider.example/.well-known/langertha.json', 'the well-known URL itself' );

  my %bad = (
    'http://provider.example'              => qr/only https/,
    'ftp://provider.example'               => qr/only https/,
    'https://user:pw@provider.example'     => qr/credentials/,
    'user@provider.example'                => qr/not HOST, HOST:PORT/,
    'https://provider.example/?key=1'      => qr/query/,
    'https://provider.example/#x'          => qr/fragment/,
    'https://provider.example/v1'          => qr{lives at /\.well-known/langertha\.json},
    'provider.example/v1'                  => qr/not HOST, HOST:PORT/,
    'provider.example:0'                   => qr/invalid port/,
    'provider.example:99999'               => qr/invalid port/,
    'provider example'                     => qr/spaces or control/,
    ''                                     => qr/no provider given/,
  );
  for my $target ( sort keys %bad ) {
    like( dies { $f->target_url($target) }, $bad{$target}, "refused: '$target'" );
  }
};

subtest 'address_kind: public, releasable internal, never' => sub {
  my $f = $CLASS->new;
  my @cases = (
    [ '93.184.216.34',    'public' ],
    [ '8.8.8.8',          'public' ],
    [ '2606:4700::1111',  'public' ],
    [ '127.0.0.1',        'loopback', 1 ],
    [ '127.8.9.10',       'loopback', 1 ],
    [ '::1',              'loopback', 1 ],
    [ '10.1.2.3',         'private', 1 ],
    [ '172.16.0.1',       'private', 1 ],
    [ '172.31.255.255',   'private', 1 ],
    [ '172.32.0.1',       'public' ],
    [ '192.168.1.1',      'private', 1 ],
    [ '100.64.0.1',       'private', 1 ],
    [ 'fd12:3456::1',     'private', 1 ],
    [ '169.254.1.1',      'link-local', 1 ],
    [ 'fe80::1%eth0',     'link-local', 1 ],
    [ '192.0.2.10',       'reserved', 1 ],
    [ '2001:db8::1',      'reserved', 1 ],
    [ '169.254.169.254',  'metadata', 0 ],
    [ '100.100.100.200',  'metadata', 0 ],
    [ 'fd00:ec2::254',    'metadata', 0 ],
    [ '0.0.0.0',          'unspecified', 0 ],
    [ '::',               'unspecified', 0 ],
    [ '224.0.0.1',        'multicast', 0 ],
    [ 'ff02::1',          'multicast', 0 ],
    [ '255.255.255.255',  'reserved', 0 ],
    [ '::ffff:127.0.0.1', 'loopback', 1 ],     # IPv4-mapped
    [ '::ffff:169.254.169.254', 'metadata', 0 ],
    [ '::ffff:8.8.8.8',   'public' ],
    [ '64:ff9b::10.0.0.1', 'private', 1 ],     # NAT64
    [ '2002:0a00:0001::1', 'private', 1 ],     # 6to4 of 10.0.0.1
    [ 'provider.example', 'invalid', 0 ],
  );
  for my $case (@cases) {
    my ( $address, $kind, $releasable ) = @$case;
    my @got = $f->address_kind($address);
    is( \@got, [ $kind, defined $releasable ? $releasable : () ], "$address: $kind" );
  }
};

subtest 'check_addresses: every address counts, --allow-internal releases only releasable ones' => sub {
  my $strict = $CLASS->new;
  my $open   = $CLASS->new( allow_internal => 1 );
  is( $strict->check_addresses( 'p.example', '93.184.216.34' ), undef, 'public passes' );
  like( $strict->check_addresses( 'p.example', '93.184.216.34', '10.0.0.5' ),
    qr/p\.example resolves to 10\.0\.0\.5 \(private address\); only --allow-internal/,
    'one private address among public ones refuses the host' );
  is( $open->check_addresses( 'p.example', '93.184.216.34', '10.0.0.5' ), undef, 'released with allow_internal' );
  like( $open->check_addresses( '169.254.169.254', '169.254.169.254' ),
    qr/^169\.254\.169\.254 is \(metadata address\); never allowed, not even with --allow-internal/,
    'metadata stays refused with allow_internal' );
  like( $strict->check_addresses('p.example'), qr/resolves to no address/, 'no address' );
};

# The PKI and one server shared by the fetch tests.
my $pki = Test::Raider::FakeHTTPS->pki( names => [ 'provider.example', 'localhost' ] );
my $manifest = '{"schema_version":1}';
my $big = 'x' x 5000;
my $srv = Test::Raider::FakeHTTPS->new( pki => $pki, routes => {
  $PATH        => sub { Test::Raider::FakeHTTPS->json( 200, $manifest ) },
  '/same'      => sub { Test::Raider::FakeHTTPS->response( 302, '', Location => $PATH ) },
  '/away'      => sub { Test::Raider::FakeHTTPS->response( 302, '', Location => 'https://evil.example'.$PATH ) },
  # Same host and port, only the scheme differs.
  '/downgrade' => sub { Test::Raider::FakeHTTPS->response( 301, '', Location => 'http://'.$_[0]{headers}{host}.$PATH ) },
  '/otherport' => sub { Test::Raider::FakeHTTPS->response( 307, '', Location => 'https://provider.example:1'.$PATH ) },
  '/loop'      => sub { Test::Raider::FakeHTTPS->response( 302, '', Location => '/loop' ) },
  '/missing'   => sub { Test::Raider::FakeHTTPS->response( 404, 'nope' ) },
  '/declared'  => sub { Test::Raider::FakeHTTPS->response( 200, $big ) },
  '/streamed'  => sub { Test::Raider::FakeHTTPS->response( 200, $big, 'Content-Length' => undef ) },
  '/slow'      => sub { { sleep => 5, then => Test::Raider::FakeHTTPS->json( 200, $manifest ) } },
} );
my $port = $srv->port;
my $base = 'https://provider.example:'.$port;

# provider.example exists nowhere: the resolver says 127.0.0.1, so a
# fetch that works proves the connection went to the resolved, checked
# address -- and TLS still checked the certificate against the name.
my @resolved;
sub fetcher {
  my ( %arg ) = @_;
  my $answer = delete $arg{resolve} // ['127.0.0.1'];
  # Far above the 10s default, so a loaded machine does not time a fetch
  # out; the timeout subtest passes its own (k136).
  return $CLASS->new(
    timeout        => 120,
    allow_internal => 1,
    ssl_options    => { SSL_ca_file => $pki->{ca} },
    resolver       => sub { push @resolved, $_[0]; Future->done(@$answer) },
    %arg,
  );
}
sub new_requests {
  my ( $before ) = @_;
  my @all = $srv->requests;
  return @all[ $before .. $#all ];
}

subtest 'a manifest is fetched from the checked address, with the name kept for TLS and Host' => sub {
  @resolved = ();
  my $seen = () = $srv->requests;
  my $r = fetcher()->fetch_f( $base.$PATH )->get;
  is( $r->{status}, 'completed', 'completed' ) or diag $r->{error};
  is( $r->{body}, $manifest, 'the body' );
  is( $r->{address}, '127.0.0.1', 'the address connected to' );
  is( \@resolved, ['provider.example'], 'the name was resolved once' );
  my ( $req ) = new_requests($seen);
  is( $req->{path}, $PATH, 'the well-known path' );
  is( $req->{headers}{host}, 'provider.example:'.$port, 'Host is the name, not the address' );
  like( $req->{headers}{'user-agent'}, qr{^raider/}, 'a User-Agent' );
  ok( !exists $req->{headers}{$_}, "no $_ header" )
    for qw( authorization cookie x-api-key proxy-authorization accept-encoding );
};

subtest 'TLS checks the certificate against the name, not the address' => sub {
  my $r = fetcher()->fetch_f( 'https://other.example:'.$port.$PATH )->get;
  is( $r->{status}, 'failed', 'a name the certificate does not carry fails' );
  like( $r->{error}, qr/verif/i, 'as a verification failure' );
  my $untrusted = $CLASS->new( allow_internal => 1, resolver => sub { Future->done('127.0.0.1') } );
  is( $untrusted->fetch_f( $base.$PATH )->get->{status}, 'failed', 'an unknown CA fails' );
  my $lax = $CLASS->new( allow_internal => 1, resolver => sub { Future->done('127.0.0.1') },
    ssl_options => { SSL_verify_mode => 0, SSL_verifycn_name => 'other.example' } );
  is( $lax->fetch_f( $base.$PATH )->get->{status}, 'failed', 'ssl_options cannot switch the checks off' );
};

subtest 'F35: an internal address is refused before any connection' => sub {
  my $seen = () = $srv->requests;
  my $strict = fetcher( allow_internal => 0 );
  my $r = $strict->fetch_f( $base.$PATH )->get;
  is( $r->{status}, 'refused', 'a name resolving to loopback is refused' );
  like( $r->{error}, qr/provider\.example resolves to 127\.0\.0\.1 \(loopback address\)/, 'saying why' );
  ok( !exists $r->{address}, 'no address was connected to' );
  is( [ new_requests($seen) ], [], 'nothing reached the server' );

  $r = $strict->fetch_f( 'https://127.0.0.1:'.$port.$PATH )->get;
  is( $r->{status}, 'refused', 'an address literal is checked too' );

  $r = fetcher( allow_internal => 0, resolve => [ '93.184.216.34', '10.0.0.7' ] )->fetch_f( $base.$PATH )->get;
  like( $r->{error}, qr/10\.0\.0\.7 \(private address\)/, 'one internal address among public ones refuses the host' );

  $r = fetcher( resolve => ['169.254.169.254'] )->fetch_f( $base.$PATH )->get;
  is( $r->{status}, 'refused', 'a metadata address is refused even with allow_internal' );
  like( $r->{error}, qr/never allowed/, 'saying so' );
};

subtest 'F36: --allow-internal releases a deliberately internal origin' => sub {
  my $r = fetcher( allow_internal => 1 )->fetch_f( $base.$PATH )->get;
  is( $r->{status}, 'completed', 'loopback origin fetched with allow_internal' );
};

subtest 'redirects: followed within the origin only' => sub {
  my $r = fetcher()->fetch_f( $base.'/same' )->get;
  is( $r->{status}, 'completed', 'a same-origin redirect is followed' );
  is( $r->{redirects}, [ $base.$PATH ], 'and reported' );
  is( $r->{final_url}, $base.$PATH, 'final_url' );

  my $seen = () = $srv->requests;
  $r = fetcher()->fetch_f( $base.'/away' )->get;
  is( $r->{status}, 'refused', 'F34: a redirect to another origin is not followed' );
  is( $r->{location}, 'https://evil.example'.$PATH, 'the target is reported' );
  like( $r->{error}, qr/leaves the origin/, 'saying why' );
  is( [ map { $_->{path} } new_requests($seen) ], ['/away'], 'only the redirecting request was sent' );

  is( fetcher()->fetch_f( $base.'/downgrade' )->get->{status}, 'refused', 'https to http on the same host and port is another origin' );
  is( fetcher()->fetch_f( $base.'/otherport' )->get->{status}, 'refused', 'another port is another origin' );

  $r = fetcher( max_redirects => 2 )->fetch_f( $base.'/loop' )->get;
  is( $r->{status}, 'failed', 'a redirect loop ends' );
  like( $r->{error}, qr/more than 2 redirects/, 'at max_redirects' );
  is( scalar @{ $r->{redirects} }, 2, 'after following that many' );
};

subtest 'limits: size and time' => sub {
  my $r = fetcher( max_bytes => 1000 )->fetch_f( $base.'/declared' )->get;
  is( $r->{status}, 'failed', 'a Content-Length over max_bytes' );
  like( $r->{error}, qr/too large: Content-Length 5000 exceeds 1000/, 'stops at the header' );

  $r = fetcher( max_bytes => 1000 )->fetch_f( $base.'/streamed' )->get;
  is( $r->{status}, 'failed', 'a body without length growing over max_bytes' );
  like( $r->{error}, qr/too large: more than 1000 bytes/, 'stops while it arrives' );

  is( fetcher( max_bytes => 5000 )->fetch_f( $base.'/declared' )->get->{status}, 'completed',
    'exactly max_bytes is accepted' );

  my $t0 = time;
  $r = fetcher( timeout => 1 )->fetch_f( $base.'/slow' )->get;
  is( $r->{status}, 'failed', 'a stalled server' );
  like( $r->{error}, qr/timed out after 1s/, 'times out' );
  ok( time - $t0 < 4, 'within the limit, not the server delay' );

  my $stuck = fetcher( timeout => 1, resolver => sub { IO::Async::Loop->new->new_future } );
  is( $stuck->fetch_f( $base.$PATH )->get->{error}, 'timed out after 1s', 'the limit covers resolving too' );
};

subtest 'failures are reports, not exceptions' => sub {
  my $r = fetcher()->fetch_f( $base.'/missing' )->get;
  is( $r->{status}, 'failed', 'HTTP 404' );
  like( $r->{error}, qr/HTTP 404/, 'with the status' );

  $r = fetcher( resolver => sub { Future->fail("no such host\n") } )->fetch_f( $base.$PATH )->get;
  is( $r->{status}, 'failed', 'a resolver failure' );
  like( $r->{error}, qr/cannot resolve provider\.example: no such host/, 'names the host' );

  # A port nothing listens on.
  my $closed = do {
    my $s = IO::Socket::INET->new( Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0 ) or die $!;
    my $p = $s->sockport; close $s; $p;
  };
  $r = fetcher( resolve => ['127.0.0.1'] )->fetch_f( 'https://provider.example:'.$closed.$PATH )->get;
  is( $r->{status}, 'failed', 'connection refused' );
  like( $r->{error}, qr/connect/, 'as a connect failure' );

  # The server listens on 127.0.0.1 only, so 127.0.0.2 refuses the
  # connection and the next checked address is tried.
  $r = fetcher( resolve => [ '127.0.0.2', '127.0.0.1' ] )->fetch_f( $base.$PATH )->get;
  is( $r->{status}, 'completed', 'a refused connection moves on to the next checked address' );
  is( $r->{address}, '127.0.0.1', 'and says which one answered' );
};

done_testing;
