#!/usr/bin/env perl
# ABSTRACT: Role::CachedContent _f methods go through the async transport: injected client, sync/async parity over real LWP and Net::Async::HTTP, timeout
use strict;
use warnings;
use Test2::Bundle::More;
use lib 't/lib';

BEGIN {
  plan skip_all => 'fork-based HTTP::Daemon test not supported on Windows' if $^O eq 'MSWin32';
  eval { require Net::Async::HTTP; require IO::Async::Loop; 1 }
    or plan skip_all => 'Requires Net::Async::HTTP and IO::Async (the async backend under test)';
}

use Future;
use IO::Socket::INET;
use HTTP::Response;
use JSON::MaybeXS;
use LWP::UserAgent;
use URI;
use Test::MockAsyncHTTP;
use Test::LocalHTTPDaemon;
use Langertha::Request::SyncHTTP;
use Langertha::Engine::Gemini;

# karr k329 (ADR 0027): create/get/list/update/delete_cached_content_f were
# async subs that sent their request with the blocking user_agent. An async
# caller's IO::Async loop stood still for every call, an injected _async_http
# never saw the request, and user_agent_timeout (k278) did not bound it on
# Net::Async::HTTP. They now go through _async_do_request_f and must answer
# exactly like the sync methods on every backend -- the same value and, for
# an HTTP error, the same croak text (k312).

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

sub json_response { HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ], $json->encode( $_[0] ) ) }

sub resource {
  my ($id) = @_;
  return { name => "cachedContents/$id", model => 'models/gemini-2.5-pro',
    expireTime => '2099-01-01T00:00:00Z', usageMetadata => { totalTokenCount => 42 } };
}

# --- the injected client carries every _f request -----------------------------

{
  package Test::NoSyncUA;
  our @ISA = ('LWP::UserAgent');
  sub request { die "blocking user_agent used\n" }
}

subtest 'every _f method sends through the injected async client' => sub {
  my $mock = Test::MockAsyncHTTP->new( responses => [
    json_response( resource('new') ),
    json_response( resource('new') ),
    json_response( { cachedContents => [ resource('a') ], nextPageToken => 'p2' } ),
    json_response( { cachedContents => [ resource('b') ] } ),
    json_response( resource('new') ),
    json_response( {} ),
  ] );
  my $e = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-2.5-pro',
    user_agent => Test::NoSyncUA->new, _async_http => $mock );

  my $created = eval { $e->create_cached_content_f( model => 'models/gemini-2.5-pro', ttl => '60s' )->get };
  is $@, '', 'create_cached_content_f does not touch the blocking user_agent';
  is $created && $created->name, 'cachedContents/new', 'create: parsed resource';
  my $got = eval { $e->get_cached_content_f('new')->get };
  is $got && $got->name, 'cachedContents/new', 'get: parsed resource';
  my @all = eval { $e->list_cached_contents_f->get };
  is join( ',', map { $_->name } @all ), 'cachedContents/a,cachedContents/b', 'list: walks both pages';
  my $updated = eval { $e->update_cached_content_f( 'new', ttl => '120s' )->get };
  is $updated && $updated->name, 'cachedContents/new', 'update: parsed resource';
  my $deleted = eval { $e->delete_cached_content_f('new')->get };
  is $deleted, 1, 'delete: 1';

  my @req = $mock->requests;
  is scalar @req, 6, 'six requests reached the injected client';
  is_deeply [ map { $_->method } @req ], [qw( POST GET GET GET PATCH DELETE )], 'in call order';
  is { URI->new( $req[3]->uri )->query_form }->{pageToken}, 'p2', 'the second list page replays the token';
  like $req[4]->uri, qr/updateMask=ttl/, 'update carries its updateMask';
};

# --- parity over the real transports ----------------------------------------------

my $ERROR_BODY = $json->encode( { error => { code => 403, message => 'Permission denied on cached content', status => 'PERMISSION_DENIED' } } );

my $server = Test::LocalHTTPDaemon->start( sub {
  my ($request) = @_;
  my $path = $request->uri->path;
  return HTTP::Response->new( 403, 'Forbidden', [ 'Content-Type' => 'application/json' ], $ERROR_BODY )
    if $path =~ m{^/denied/};
  my %q = URI->new( $request->uri )->query_form;
  my $method = $request->method;
  if ( $path =~ m{/v1beta/cachedContents\z} ) {
    return json_response( { %{ resource('new') },
      displayName => $json->decode( $request->content )->{displayName} } ) if $method eq 'POST';
    return json_response( { cachedContents => [ resource('b') ] } ) if ( $q{pageToken} // '' ) eq 'p2';
    return json_response( { cachedContents => [ resource('a') ], nextPageToken => 'p2' } );
  }
  if ( $path =~ m{/v1beta/cachedContents/(\w+)\z} ) {
    my $id = $1;
    return json_response( {} ) if $method eq 'DELETE';
    return json_response( { %{ resource($id) }, ttlSeen => $method eq 'PATCH' ? $json->decode( $request->content )->{ttl} : undef } );
  }
  return HTTP::Response->new( 404, 'Not Found' );
} );
my $base = $server->url;

my $loop = IO::Async::Loop->new;

sub engine {
  my ( $url, $backend, %args ) = @_;
  my $e = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-2.5-pro', url => $url, %args,
    $backend eq 'shim' ? ( _async_http => Langertha::Request::SyncHTTP->new( user_agent => LWP::UserAgent->new ) ) : () );
  ok $e->_async_http->isa('Net::Async::HTTP'), 'engine runs on Net::Async::HTTP' if $backend eq 'nahttp';
  return $e;
}

# A CachedContent compared by what it says, not by object identity.
sub flat {
  my ($value) = @_;
  return [ map { flat($_) } @$value ] if ref $value eq 'ARRAY';
  return $value unless ref $value && eval { $value->isa('Langertha::CachedContent') };
  return { map { ( $_ => $value->$_ ) } qw( name model expire_time total_token_count display_name ) };
}

# One call on the sync method and on its _f over both backends.
sub run_all {
  my ( $url, $method, @args ) = @_;
  my %out;
  my $sync = engine( $url, 'sync' );
  $out{sync} = eval { { value => flat( scalar $sync->$method(@args) ), error => '' } } // { error => $@ };
  my $method_f = $method eq 'list_cached_contents' ? 'list_cached_contents_f' : "${method}_f";
  for my $backend (qw( nahttp shim )) {
    my $e = engine( $url, $backend );
    my $f = $e->$method_f(@args);
    $loop->await($f) unless $f->is_ready;
    $out{$backend} = $f->is_done
      ? { value => flat( $method eq 'list_cached_contents' ? [ $f->get ] : scalar $f->get ), error => '' }
      : { error => scalar $f->failure };
  }
  s/ at \S+ line \d+\.?\n?\z// for map { $_->{error} } values %out;
  return \%out;
}

sub parity {
  my ( $out, $want, $label ) = @_;
  for my $backend (qw( sync nahttp shim )) {
    is $out->{$backend}{error}, '', "$label: no error ($backend)";
    is_deeply $out->{$backend}{value}, $want, "$label: value ($backend)";
  }
}

sub want { my ( $id, %more ) = @_;
  return { name => "cachedContents/$id", model => 'models/gemini-2.5-pro',
    expire_time => '2099-01-01T00:00:00Z', total_token_count => 42, display_name => undef, %more } }

subtest 'the lifecycle answers the same on every backend' => sub {
  parity( run_all( $base, 'create_cached_content', model => 'models/gemini-2.5-pro', ttl => '60s', display_name => 'r' ),
    want( 'new', display_name => 'r' ), 'create' );
  parity( run_all( $base, 'get_cached_content', 'abc' ), want('abc'), 'get' );
  parity( run_all( $base, 'list_cached_contents' ), [ want('a'), want('b') ], 'list walks every page' );
  parity( run_all( $base, 'update_cached_content', 'abc', ttl => '120s' ), want('abc'), 'update' );
  parity( run_all( $base, 'delete_cached_content', 'abc' ), 1, 'delete' );
};

subtest 'an HTTP error fails every _f call with the sync croak text' => sub {
  for my $call (
    [ 'create_cached_content', model => 'models/gemini-2.5-pro', ttl => '60s' ],
    [ 'get_cached_content', 'abc' ],
    [ 'list_cached_contents' ],
    [ 'update_cached_content', 'abc', ttl => '120s' ],
    [ 'delete_cached_content', 'abc' ],
  ) {
    my ( $method, @args ) = @$call;
    my $out = run_all( "$base/denied", $method, @args );
    like $out->{sync}{error}, qr/\ALangertha::Engine::Gemini request failed: 403 Forbidden.*Permission denied on cached content/s,
      "$method: sync croaks";
    is $out->{$_}{error}, $out->{sync}{error}, "$method: $_ fails with the same text" for qw( nahttp shim );
  }
};

subtest 'user_agent_timeout bounds the _f calls on Net::Async::HTTP (k278)' => sub {
  my $hang = IO::Socket::INET->new( Listen => 5, LocalAddr => '127.0.0.1', LocalPort => 0,
    Proto => 'tcp', ReuseAddr => 1 ) or die "listen: $!";
  my $hang_url = 'http://127.0.0.1:' . $hang->sockport;
  for my $call (
    [ 'create_cached_content_f', model => 'models/gemini-2.5-pro', ttl => '60s' ],
    [ 'get_cached_content_f', 'abc' ],
    [ 'list_cached_contents_f' ],
    [ 'update_cached_content_f', 'abc', ttl => '120s' ],
    [ 'delete_cached_content_f', 'abc' ],
  ) {
    my ( $method, @args ) = @$call;
    my $e = engine( $hang_url, 'nahttp', user_agent_timeout => 1 );
    my $f = $e->$method(@args);
    my $cap = $loop->delay_future( after => 10 );
    $loop->await( Future->wait_any( $f->without_cancel, $cap ) );
    $cap->cancel unless $cap->is_ready;
    ok $f->is_failed, "$method fails instead of hanging";
    my ( $message, $category ) = $f->is_failed ? $f->failure : ( '', '' );
    like $message, qr{\ALangertha::Engine::Gemini: request to http://127\.0\.0\.1:\d+/v1beta/cachedContents\S* timed out after 1s\n\z},
      "$method: engine-named timeout, no key in the message";
    is $category, 'timeout', "$method: timeout category";
  }
};

done_testing;
