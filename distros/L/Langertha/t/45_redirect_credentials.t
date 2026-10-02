#!/usr/bin/env perl
# ABSTRACT: a redirect to another origin never carries the engine's credential, on every HTTP backend
use strict; use warnings;
use Test2::Bundle::More;
use FindBin;
use lib "$FindBin::Bin/lib";

# Why (karr k374, from langertha-raider k119): an engine's API key is meant for
# the engine's own origin. LWP follows a GET redirect with every request header
# (it strips only Authorization, and only since 6.83), so an x-api-key went to
# whatever host a server redirected to; Gemini's ?key= went along whenever the
# server echoed the query into Location (nginx `return 301 https://new$request_uri`),
# on Net::Async::HTTP too. Core now follows redirects under one policy on every
# backend (Langertha::HTTP::Redirect): same origin keeps the request as it was,
# another origin gets only the representation headers and no query value the
# original request carried as a credential, and a request whose credential
# would still show in the URL, a POST, or an https -> http hop is not followed.

BEGIN {
  plan skip_all => 'fork-based HTTP::Daemon test not supported on Windows' if $^O eq 'MSWin32';
  eval { require Future::AsyncAwait; 1 }
    or plan skip_all => 'Requires Future::AsyncAwait';
}

use File::Temp ();
use HTTP::Request;
use HTTP::Response;
use JSON::MaybeXS;
use Test::LocalHTTPDaemon;
use Langertha::HTTP::Redirect;
use Langertha::Request::SyncHTTP;
use Langertha::Engine::Anthropic;
use Langertha::Engine::OpenAI;
use Langertha::Engine::Gemini;
use Langertha::Engine::OpenRouter;
use Langertha::Engine::vLLM;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $HAVE_NAHTTP = eval { require Net::Async::HTTP; require IO::Async::Loop; 1 };

# --- the policy itself (no network) ------------------------------------------

sub redirect {
  my ( $request, $code, $location, $previous ) = @_;
  my $response = HTTP::Response->new( $code, 'Redirect', [ defined $location ? ( Location => $location ) : () ] );
  $response->request($request);
  $response->previous($previous) if $previous;
  return $response;
}

sub get_req { HTTP::Request->new( GET => $_[0], [ @_[ 1 .. $#_ ] ] ) }

# The next request, or a stand-in that fails every check on it when the
# redirect was not followed (so a regression fails here instead of dying).
sub followed {
  my ($next) = @_;
  return $next if $next;
  fail 'redirect was followed';
  return HTTP::Request->new( GET => 'http://not-followed.invalid/?not=followed', [ 'X-Not-Followed' => 1 ] );
}

{
  my $same = \&Langertha::HTTP::Redirect::same_origin;
  ok $same->( 'http://a.example/x', 'HTTP://A.EXAMPLE:80/y?z' ), 'same origin: case and default port do not matter';
  ok !$same->( 'https://a.example/', 'http://a.example/' ), 'another scheme is another origin';
  ok !$same->( 'http://a.example/', 'http://a.example:8080/' ), 'another port is another origin';
  ok !$same->( 'http://a.example/', 'http://b.example/' ), 'another host is another origin';

  my $next = \&Langertha::HTTP::Redirect::next_request;
  my $req = get_req( 'https://a.example/v1/models', 'x-api-key' => 'SEKRET-HEADER-KEY',
    Accept => 'application/json', Cookie => 'c=1', 'X-Custom' => 'v' );

  my $n = followed( $next->( $req, redirect( $req, 307, '/moved/models' ) ) );
  is "".$n->uri, 'https://a.example/moved/models', 'a relative Location resolves against the request (keeps https)';
  is $n->header('x-api-key'), 'SEKRET-HEADER-KEY', 'same origin: the credential header stays';
  is $n->header('X-Custom'), 'v', 'same origin: other headers stay';
  ok !defined $n->header('Cookie'), 'Cookie is never forwarded (as LWP)';
  is $req->header('x-api-key'), 'SEKRET-HEADER-KEY', 'the original request is not modified';

  $n = followed( $next->( $req, redirect( $req, 302, 'https://b.example/v1/models' ) ) );
  is "".$n->uri, 'https://b.example/v1/models', 'cross origin: followed';
  is_deeply [ sort map { lc } $n->header_field_names ], [ 'accept' ],
    'cross origin: only the representation headers are left';

  for my $code ( 301, 302, 303, 307, 308 ) {
    ok $next->( $req, redirect( $req, $code, 'https://b.example/' ) ), "$code is followed for GET";
  }
  ok !$next->( $req, redirect( $req, 300, 'https://b.example/' ) ), '300 is not followed';
  ok !$next->( $req, redirect( $req, 307, undef ) ), 'a redirect without Location is not followed';
  ok !$next->( $req, redirect( $req, 307, 'http://b.example/' ) ), 'https -> http is not followed';
  ok !$next->( $req, redirect( $req, 307, 'ftp://b.example/' ) ), 'a non-HTTP Location is not followed';
  my $post = HTTP::Request->new( POST => 'https://a.example/v1/chat', [ 'x-api-key' => 'SEKRET-HEADER-KEY' ], '{"key":"SEKRET-BODY"}' );
  ok !$next->( $post, redirect( $post, $_, 'https://a.example/elsewhere' ) ), "POST is not followed on $_"
    for 302, 303, 307;

  my $gem = get_req('https://a.example/v1beta/models?key=SEKRET-QUERY-KEY&pageSize=5');
  $n = followed( $next->( $gem, redirect( $gem, 301, 'https://b.example/v1beta/models?key=SEKRET-QUERY-KEY&pageToken=abc' ) ) );
  is $n->uri->query, 'pageToken=abc', 'cross origin: the echoed query key is dropped, the rest stays';
  $n = followed( $next->( $gem, redirect( $gem, 301, 'https://b.example/cb?k=SEKRET-QUERY-KEY' ) ) );
  is $n->uri->query, undef, '... under any parameter name';
  $n = followed( $next->( $gem, redirect( $gem, 301, 'https://a.example/v2/models?key=SEKRET-QUERY-KEY' ) ) );
  is $n->uri->query, 'key=SEKRET-QUERY-KEY', 'same origin: the query key stays';

  my $bearer = get_req( 'https://a.example/v1/models', Authorization => 'Bearer SEKRET-BEARER' );
  $n = followed( $next->( $bearer, redirect( $bearer, 307, 'https://b.example/?access=SEKRET-BEARER&x=1' ) ) );
  is $n->uri->query, 'x=1', 'cross origin: a header credential echoed into the query is dropped';

  my $signed = 'https://cdn.example/f?X-Amz-Signature=ab%2Fcd&X-Amz-Credential=zz';
  $n = followed( $next->( $gem, redirect( $gem, 302, $signed ) ) );
  is "".$n->uri, $signed, "cross origin: the target's own query is kept byte for byte";

  ok !$next->( $gem, redirect( $gem, 302, 'https://b.example/key/SEKRET-QUERY-KEY/models' ) ),
    'cross origin: not followed when the credential would still be in the URL';

  $n = followed( $next->( $req, redirect( $req, 302, 'https://user:pw@b.example/' ) ) );
  ok !defined $n->uri->userinfo, 'cross origin: userinfo is dropped';

  # A same-origin hop first, then a hop away that echoes the first request's key.
  my $hop1 = redirect( $gem, 302, 'https://a.example/v1beta/other' );
  my $mid  = followed( $next->( $gem, $hop1 ) );
  $n = followed( $next->( $mid, redirect( $mid, 302, 'https://b.example/x?key=SEKRET-QUERY-KEY', $hop1 ) ) );
  is $n->uri->query, undef, 'a credential from an earlier hop of the chain is dropped too';

  my $guard = \&Langertha::HTTP::Redirect::guard_referral;
  my $referral = get_req( 'https://b.example/v1/models', 'x-goog-api-key' => 'SEKRET-GOOG', Accept => '*/*' );
  ok $guard->( $referral, redirect( get_req( 'https://a.example/v1/models', 'x-goog-api-key' => 'SEKRET-GOOG' ), 307, 'https://b.example/v1/models' ) ),
    'guard_referral allows a cross-origin hop';
  is_deeply [ map { lc } $referral->header_field_names ], [ 'accept' ], '... and strips it in place';

  # An agent whose requests_redirectable lists POST, and LWP turning a 302 POST
  # into a GET referral: the method checked is the original request's.
  my $posted = redirect( $post, 302, 'https://b.example/elsewhere' );
  ok !$guard->( get_req('https://b.example/elsewhere'), $posted ), 'guard_referral refuses a redirected POST';
  like $posted->header('Client-Warning'), qr/\Aredirect not followed: Langertha::HTTP::Redirect: only GET and HEAD are redirected, not POST\z/,
    '... and says why on the response';

  my $down = redirect( $req, 307, 'http://b.example/' );
  $next->( $req, $down );
  like $down->header('Client-Warning'), qr/Langertha::HTTP::Redirect: not from https to http/, 'a downgrade refusal says why';
  my $leak = redirect( $gem, 302, 'https://b.example/key/SEKRET-QUERY-KEY/models' );
  $next->( $gem, $leak );
  like $leak->header('Client-Warning'), qr/credential of the request would be in the URL/, 'a credential-in-URL refusal says why';
  my $done = redirect( $req, 307, 'https://b.example/' );
  $next->( $req, $done );
  ok !defined $done->header('Client-Warning'), 'a followed redirect carries no warning';

  # Gemini paginates with pageToken: a cursor, not a credential.
  my $paged = get_req('https://a.example/v1beta/models?key=SEKRET-QUERY-KEY&pageToken=CURSOR-0123456789');
  $n = followed( $next->( $paged, redirect( $paged, 301,
    'https://b.example/v1beta/models?key=SEKRET-QUERY-KEY&pageToken=CURSOR-0123456789' ) ) );
  is $n->uri->query, 'pageToken=CURSOR-0123456789', 'cross origin: pageToken survives, the key does not';
  for my $cursor (qw( page_token nextPageToken )) {
    my $r = get_req("https://a.example/m?$cursor=CURSOR-0123456789");
    $n = followed( $next->( $r, redirect( $r, 301, "https://b.example/m?$cursor=CURSOR-0123456789" ) ) );
    is $n->uri->query, "$cursor=CURSOR-0123456789", "... and so does $cursor";
  }
  for my $cred (qw( key api_key api-key apikey access_token token auth client_secret password sig )) {
    my $r = get_req("https://a.example/m?$cred=CRED-0123456789");
    $n = followed( $next->( $r, redirect( $r, 301, "https://b.example/m?$cred=CRED-0123456789&x=1" ) ) );
    is $n->uri->query, 'x=1', "cross origin: a $cred query value is dropped";
  }
}

# --- real round-trips: origin A redirects to origin B --------------------------

sub recorder {
  my $file = File::Temp->new;
  my $name = $file->filename;
  return {
    file  => $file,
    log   => sub {
      my ($r) = @_;
      my %h = map { lc($_) => scalar $r->header($_) } $r->header_field_names;
      open my $fh, '>>', $name or die $!;
      print {$fh} $json->encode({ method => $r->method, uri => $r->uri->path_query, headers => \%h }), "\n";
      close $fh;
    },
    seen  => sub { open my $fh, '<', $name or return []; [ map { $json->decode($_) } <$fh> ] },
    reset => sub { open my $fh, '>', $name or die $! },
  };
}

sub ok_body {
  my ($r) = @_;
  return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'text/plain' ], "vllm:num_requests_running 2\n" )
    if $r->uri->path =~ m{/metrics\z};
  return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ],
    $json->encode({ data => [], models => [], has_more => JSON::MaybeXS::false() }) );
}

my $b_log = recorder();
my $b = Test::LocalHTTPDaemon->start( sub { $b_log->{log}->( $_[0] ); ok_body( $_[0] ) } );
my $B = $b->url;

my $a_log = recorder();
my $a = Test::LocalHTTPDaemon->start( sub {
  my ($r) = @_;
  $a_log->{log}->($r);
  my $pq = $r->uri->path_query;
  # /x/...    -> 307 to the same path and query on origin B (the query echoed)
  # /same/... -> 307 to /final/... on this origin
  return HTTP::Response->new( 307, 'Temporary Redirect', [ Location => "$B$pq" ], '' ) if $pq =~ m{\A/x/};
  return HTTP::Response->new( 307, 'Temporary Redirect', [ Location => $pq =~ s{\A/same/}{/final/}r ], '' )
    if $pq =~ m{\A/same/};
  # /pathleak/ -> 307 to origin B with the request's x-api-key in the path
  return HTTP::Response->new( 307, 'Temporary Redirect',
    [ Location => "$B/key/" . ( $r->header('x-api-key') // 'none' ) . '/models' ], '' ) if $pq =~ m{\A/pathleak/};
  # /loop/N -> 307 to /loop/N+1 on this origin, forever
  return HTTP::Response->new( 307, 'Temporary Redirect', [ Location => '/loop/' . ( $1 + 1 ) ], '' )
    if $pq =~ m{\A/loop/(\d+)};
  return ok_body($r);
} );
my $A = $a->url;

my %ENGINE = (
  Anthropic => { class => 'Langertha::Engine::Anthropic', secret => 'SEKRET-ANTHROPIC-KEY', header => 'x-api-key' },
  OpenAI    => { class => 'Langertha::Engine::OpenAI',    secret => 'SEKRET-OPENAI-KEY',    header => 'authorization' },
  Gemini    => { class => 'Langertha::Engine::Gemini',    secret => 'SEKRET-GEMINI-KEY',    query  => 1 },
);

# Every way a credential could reach B.
my @CRED_HEADERS = qw( authorization proxy-authorization x-api-key x-goog-api-key api-key x-custom-token cookie );

sub leaked {
  my ( $req, $secret ) = @_;
  my @found = grep { exists $req->{headers}{$_} } @CRED_HEADERS;
  push @found, "secret in URL" if index( $req->{uri}, $secret ) >= 0;
  push @found, "secret in a header" if grep { index( $_, $secret ) >= 0 } values %{ $req->{headers} };
  return @found;
}

sub carries {
  my ( $req, $spec ) = @_;
  return index( $req->{uri}, $spec->{secret} ) >= 0 if $spec->{query};
  return index( $req->{headers}{ $spec->{header} } // '', $spec->{secret} ) >= 0;
}

# A backend makes an engine and runs one GET (list models) and one POST (chat).
my @BACKENDS = (
  [ 'sync LWP' => sub { $_[0]->new( @_[ 1 .. $#_ ] ) },
    sub { $_[0]->list_models( force_refresh => 1 ) }, sub { $_[0]->simple_chat('hi') } ],
  [ 'sync fallback shim' => sub {
      my ( $class, %args ) = @_;
      my $ua = $class->new(%args)->user_agent;
      $class->new( %args, user_agent => $ua, _async_http => Langertha::Request::SyncHTTP->new( user_agent => $ua ) );
    },
    sub { my $r = $_[0]->async_request_f( $_[0]->list_models_request )->get; die $r->status_line unless $r->is_success },
    sub { $_[0]->simple_chat_f('hi')->get } ],
  ( $HAVE_NAHTTP ? [ 'Net::Async::HTTP' => sub { $_[0]->new( @_[ 1 .. $#_ ] ) },
    sub { my $r = $_[0]->async_request_f( $_[0]->list_models_request )->get; die $r->status_line unless $r->is_success },
    sub { $_[0]->simple_chat_f('hi')->get } ] : () ),
);
diag 'Net::Async::HTTP not installed: its backend is not exercised' unless $HAVE_NAHTTP;

for my $backend (@BACKENDS) {
  my ( $bname, $make, $get, $post ) = @$backend;
  for my $ename ( sort keys %ENGINE ) {
    my $spec = $ENGINE{$ename};
    my %args = ( api_key => $spec->{secret}, model => 'm' );

    subtest "$bname / $ename: GET redirected to another origin" => sub {
      $_->{reset}->() for $a_log, $b_log;
      my $engine = $make->( $spec->{class}, %args, url => "$A/x" );
      my $ok = eval { $get->($engine); 1 };
      ok $ok, 'the redirect is followed and B answers' or diag $@;
      my ($at_a) = @{ $a_log->{seen}->() };
      ok $at_a && carries( $at_a, $spec ), 'A received the credential (the fixture really sent one)';
      my @at_b = @{ $b_log->{seen}->() };
      is scalar @at_b, 1, 'B received the redirected GET';
      is_deeply [ map { leaked( $_, $spec->{secret} ) } @at_b ], [], 'B received no credential';
    };

    subtest "$bname / $ename: GET redirected on the same origin" => sub {
      $_->{reset}->() for $a_log, $b_log;
      my $engine = $make->( $spec->{class}, %args, url => "$A/same" );
      my $ok = eval { $get->($engine); 1 };
      ok $ok, 'the redirect is followed' or diag $@;
      my @final = grep { $_->{uri} =~ m{\A/final/} } @{ $a_log->{seen}->() };
      is scalar @final, 1, 'the new location on A was requested';
      ok $final[0] && carries( $final[0], $spec ), 'the credential stays on the same origin';
      is scalar @{ $b_log->{seen}->() }, 0, 'B saw nothing';
    };

    subtest "$bname / $ename: POST is not redirected" => sub {
      $_->{reset}->() for $a_log, $b_log;
      my $engine = $make->( $spec->{class}, %args, url => "$A/x" );
      my $ok = eval { $post->($engine); 1 };
      ok !$ok, 'the chat call fails';
      like $@, qr/307/, '... naming the redirect status';
      is scalar @{ $b_log->{seen}->() }, 0, 'B received no request (and no body)';
    };
  }

  subtest "$bname: any header outside the representation set stays behind" => sub {
    $_->{reset}->() for $a_log, $b_log;
    my $engine = $make->( 'Langertha::Engine::OpenAI', api_key => 'SEKRET-OPENAI-KEY', url => "$A/x" );
    my $req = HTTP::Request->new( GET => "$A/x/raw", [
      Authorization         => 'Bearer SEKRET-ONE',
      'Proxy-Authorization' => 'Basic SEKRET-TWO',
      'x-api-key'           => 'SEKRET-THREE',
      'x-goog-api-key'      => 'SEKRET-FOUR',
      'api-key'             => 'SEKRET-FIVE',
      'X-Custom-Token'      => 'SEKRET-SIX',
      Accept                => 'application/json',
    ] );
    my $res = $bname eq 'sync LWP' ? $engine->user_agent->request($req) : $engine->async_request_f($req)->get;
    ok $res->is_success, 'followed to B';
    my ($at_b) = @{ $b_log->{seen}->() };
    is_deeply [ leaked( $at_b, 'SEKRET-' ) ], [], 'B received none of them';
    is $at_b->{headers}{accept}, 'application/json', 'Accept is kept';
  };

  subtest "$bname: a refused redirect comes back as the 3xx and says why" => sub {
    $_->{reset}->() for $a_log, $b_log;
    my $engine = $make->( 'Langertha::Engine::OpenAI', api_key => 'SEKRET-OPENAI-KEY', url => "$A/x" );
    my $req = HTTP::Request->new( GET => "$A/pathleak/m", [ 'x-api-key' => 'SEKRET-PATH-KEY-1' ] );
    my $res = $bname eq 'sync LWP' ? $engine->user_agent->request($req) : $engine->async_request_f($req)->get;
    is $res->code, 307, 'the 307 is the result';
    like $res->header('Client-Warning') // '', qr/redirect not followed: Langertha::HTTP::Redirect: a credential/,
      'Client-Warning names the reason';
    is scalar @{ $b_log->{seen}->() }, 0, 'B received nothing';
  };

  subtest "$bname: running out of hops returns the last 3xx" => sub {
    $_->{reset}->() for $a_log, $b_log;
    my $engine = $make->( 'Langertha::Engine::OpenAI', api_key => 'SEKRET-OPENAI-KEY', url => "$A/x" );
    my $req = HTTP::Request->new( GET => "$A/loop/0" );
    my $res = $bname eq 'sync LWP' ? $engine->user_agent->request($req) : $engine->async_request_f($req)->get;
    is $res->code, 307, 'the last redirect is the result';
    ok defined $res->header('Client-Warning'), '... with a Client-Warning';
    if ( $bname eq 'Net::Async::HTTP' ) {
      is scalar @{ $a_log->{seen}->() }, 4, 'the request plus the client default of 3 hops';
      like $res->header('Client-Warning'), qr/Langertha::HTTP::Redirect: hop limit reached/, '... named as the hop limit';
      $a_log->{reset}->();
      $res = $engine->async_request_f( $req, max_redirects => 1 )->get;
      is scalar @{ $a_log->{seen}->() }, 2, 'a max_redirects option is the hop limit';
    }
    else {
      is scalar @{ $a_log->{seen}->() }, 8, "the request plus LWP's max_redirect of 7";
    }
  };

  if ( $bname ne 'Net::Async::HTTP' ) {
    subtest "$bname: POST stays unredirected even if requests_redirectable lists it" => sub {
      $_->{reset}->() for $a_log, $b_log;
      my $engine = $make->( 'Langertha::Engine::OpenAI', api_key => 'SEKRET-OPENAI-KEY', model => 'm', url => "$A/x" );
      $engine->user_agent->requests_redirectable( [qw( GET HEAD POST )] );
      my $ok = eval { $bname eq 'sync LWP' ? $engine->simple_chat('hi') : $engine->simple_chat_f('hi')->get; 1 };
      ok !$ok, 'the chat call fails';
      like $@, qr/307/, '... on the 307';
      is scalar @{ $b_log->{seen}->() }, 0, 'B received no request and no body';
    };
  }

  next if $bname eq 'sync LWP';

  subtest "$bname: a streaming GET gets a redirect that was not followed" => sub {
    $_->{reset}->() for $a_log, $b_log;
    my $engine = $make->( 'Langertha::Engine::OpenAI', api_key => 'SEKRET-OPENAI-KEY', url => "$A/x" );
    my @codes;
    my $req = HTTP::Request->new( GET => "$A/pathleak/m", [ 'x-api-key' => 'SEKRET-PATH-KEY-1' ] );
    my $res = $engine->async_request_f( $req, on_header => sub {
      my ($header) = @_;
      push @codes, $header->code;
      return sub { return $header unless @_; return };
    } )->get;
    is_deeply \@codes, [ 307 ], 'on_header saw the 307';
    like $res->header('Client-Warning') // '', qr/Langertha::HTTP::Redirect/, '... with the reason';
    is scalar @{ $b_log->{seen}->() }, 0, 'B received nothing';
  };

  subtest "$bname: a streaming GET sees only the response it ends on" => sub {
    $_->{reset}->() for $a_log, $b_log;
    my $engine = $make->( 'Langertha::Engine::OpenAI', api_key => 'SEKRET-OPENAI-KEY', url => "$A/x" );
    my ( @codes, $body );
    my $res = $engine->async_request_f( $engine->list_models_request, on_header => sub {
      my ($header) = @_;
      push @codes, $header->code;
      return sub { $body .= $_[0] if @_ && defined $_[0]; return $header unless @_; return };
    } )->get;
    is_deeply \@codes, [ 200 ], 'on_header saw the final response only, not the redirect';
    like $body // '', qr/"data"/, '... and its body';
    is_deeply [ map { leaked( $_, 'SEKRET-OPENAI-KEY' ) } @{ $b_log->{seen}->() } ], [], 'B received no credential';
  };

  subtest "$bname: probe_model_capabilities_f goes through the same policy" => sub {
    $_->{reset}->() for $a_log, $b_log;
    my $engine = $make->( 'Langertha::Engine::OpenRouter', api_key => 'SEKRET-ROUTER-KEY', model => 'm', url => "$A/x" );
    my $ok = eval { $engine->probe_model_capabilities_f( models => ['m'] )->get; 1 };
    ok $ok, 'probe followed the redirect' or diag $@;
    my @at_b = @{ $b_log->{seen}->() };
    is scalar @at_b, 1, 'B received the probe';
    is_deeply [ map { leaked( $_, 'SEKRET-ROUTER-KEY' ) } @at_b ], [], 'without the credential';
  };

  subtest "$bname: poll_metrics_f follows a cross-origin redirect (no credential involved)" => sub {
    $_->{reset}->() for $a_log, $b_log;
    my $engine = $make->( 'Langertha::Engine::vLLM', url => "$A/x/v1", model => 'm' );
    my $metrics = eval { $engine->poll_metrics_f->get };
    ok $metrics, 'metrics read from B' or diag $@;
    is scalar @{ $b_log->{seen}->() }, 1, 'B served /metrics';
  };
}

done_testing;
