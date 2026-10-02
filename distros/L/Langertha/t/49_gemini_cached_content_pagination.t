#!/usr/bin/env perl
# ABSTRACT: Role::CachedContent list pagination — multi-page walk vs. one-page options (karr #104)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use HTTP::Response;
use LWP::UserAgent;
use URI;

use Langertha::Engine::Gemini;
use Langertha::Request::SyncHTTP;

# list_cached_contents_f walks the cachedContents collection until the server
# stops handing out a nextPageToken, but the documented page_size / page_token
# options are meant to hand back exactly one page. karr #104: that early exit
# was written as `last` inside a do{}while, which is not a loop block in Perl,
# so both one-page options blew up *after* the request had already gone on the
# wire. t/47 only ever called the method without options, so nothing caught it.
#
# Everything here is offline: a scripted LWP::UserAgent subclass answers from a
# queue and records what was asked for (the sync methods use it directly, the
# _f methods through the sync transport shim), so the assertions are about the URLs
# that would actually go on the wire.
#
# Each scenario is a named sub called at file scope, deliberately NOT a bare
# block: a bare block IS a loop block in Perl, so a stray `last` unwinding out
# of the role would quietly break out of the block and silently skip the rest
# of the scenario's assertions instead of failing. Called with no enclosing
# loop in the dynamic scope, the same `last` is the fatal
# 'Can't "last" outside a loop block' this file exists to pin.

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

{
  package Test::PagingUA;
  our @ISA = ('LWP::UserAgent');

  sub new {
    my ( $class, @pages ) = @_;
    my $self = LWP::UserAgent::new($class);
    $self->{pages} = [@pages];
    $self->{seen}  = [];
    return $self;
  }

  sub seen { return $_[0]->{seen} }

  sub request {
    my ( $self, $req ) = @_;
    push @{ $self->{seen} }, $req;
    main::BAIL_OUT('Test::PagingUA ran out of scripted pages')
      unless @{ $self->{pages} };
    my $res = HTTP::Response->new( 200, 'OK' );
    $res->header( 'Content-Type' => 'application/json' );
    $res->content( shift @{ $self->{pages} } );
    return $res;
  }
}

# One list page: named caches plus an optional nextPageToken.
sub page {
  my ( $next, @ids ) = @_;
  my %body = ( cachedContents => [
    map { { name => "cachedContents/$_", model => 'models/gemini-2.5-pro' } } @ids
  ] );
  $body{nextPageToken} = $next if defined $next;
  return $json->encode( \%body );
}

# The query params of the n-th request the engine issued.
sub query_of {
  my ( $ua, $n ) = @_;
  return { URI->new( $ua->seen->[$n]->uri )->query_form };
}

sub engine_with {
  my ( @pages ) = @_;
  my $ua = Test::PagingUA->new(@pages);
  my $engine = Langertha::Engine::Gemini->new(
    api_key    => 'k',
    model      => 'gemini-2.5-pro',
    user_agent => $ua,
    # The _f methods send through the async transport (k329); the sync shim
    # over the same scripted UA keeps the pages and the record in one place.
    _async_http => Langertha::Request::SyncHTTP->new( user_agent => $ua ),
  );
  return ( $engine, $ua );
}

# --- Unpaginated: walk until the server stops sending nextPageToken ------

sub test_unpaginated_walk {
  my ( $engine, $ua ) = engine_with(
    page( 'tok2', 'a', 'b' ),
    page( 'tok3', 'c' ),
    page( undef,  'd', 'e' ),
  );

  my @all = $engine->list_cached_contents_f->get;

  is( scalar @{ $ua->seen }, 3, 'unpaginated walk issues one request per page' );
  is( join( ',', map { $_->name } @all ),
    'cachedContents/a,cachedContents/b,cachedContents/c,cachedContents/d,cachedContents/e',
    'unpaginated walk concatenates every page in order' );

  ok( !exists query_of( $ua, 0 )->{pageToken},
    'first request of a walk carries no pageToken' );
  is( query_of( $ua, 1 )->{pageToken}, 'tok2',
    'second request replays the first response nextPageToken' );
  is( query_of( $ua, 2 )->{pageToken}, 'tok3',
    'third request replays the second response nextPageToken' );

  is( scalar( grep { exists query_of( $ua, $_ )->{pageSize} } 0 .. 2 ), 0,
    'a walk without page_size never sends pageSize' );

  return;
}

# --- page_size: exactly one page, even when more are on offer ------------

sub test_page_size_stops_after_one_page {
  # The server answers with a nextPageToken; the caller asked for one page,
  # so the walk must stop anyway rather than follow it.
  my ( $engine, $ua ) = engine_with( page( 'tok2', 'a', 'b' ) );

  my @page = $engine->list_cached_contents_f( page_size => 10 )->get;

  is( scalar @{ $ua->seen }, 1, 'page_size stops after the first response' );
  is( scalar @page, 2, 'page_size returns just that page' );
  is( query_of( $ua, 0 )->{pageSize}, 10, 'page_size goes on the wire as pageSize' );

  return;
}

# The sync wrapper is the documented entry point and reaches the same loop.
sub test_page_size_sync_wrapper {
  my ( $engine, $ua ) = engine_with( page( 'tok2', 'a', 'b' ) );

  my $aref = $engine->list_cached_contents( page_size => 10 );

  is( ref $aref, 'ARRAY', 'sync list_cached_contents(page_size) returns an arrayref' );
  is( scalar @$aref, 2, 'sync wrapper returns the same single page' );
  is( scalar @{ $ua->seen }, 1, 'sync wrapper issues one request too' );

  return;
}

# --- page_token: resume from an opaque token, one page only --------------

sub test_page_token_stops_after_one_page {
  # An opaque server token with characters that must be percent-encoded —
  # the reason pagination goes through URI instead of the seam's query list.
  my $token = 'tok/2+a b';
  my ( $engine, $ua ) = engine_with( page( 'tok3', 'c' ) );

  my @page = $engine->list_cached_contents_f( page_token => $token )->get;

  is( scalar @{ $ua->seen }, 1, 'page_token stops after the first response' );
  is( scalar @page, 1, 'page_token returns just that page' );
  is( query_of( $ua, 0 )->{pageToken}, $token,
    'page_token round-trips percent-encoded through the request URI' );
  ok( !exists query_of( $ua, 0 )->{pageSize},
    'page_token alone does not invent a pageSize' );

  return;
}

# --- both options together -----------------------------------------------

sub test_both_page_options {
  my ( $engine, $ua ) = engine_with( page( 'tok9', 'a' ) );

  my @page = $engine->list_cached_contents_f( page_token => 'tok8', page_size => 5 )->get;

  is( scalar @{ $ua->seen }, 1, 'page_token + page_size stops after one response' );
  is( scalar @page, 1, 'page_token + page_size returns one page' );
  is_deeply(
    { map { $_ => query_of( $ua, 0 )->{$_} } qw( pageToken pageSize ) },
    { pageToken => 'tok8', pageSize => 5 },
    'both pagination params ride the same request' );

  return;
}

# --- an empty collection is not an error ---------------------------------

sub test_empty_collection {
  my ( $engine, $ua ) = engine_with( page(undef) );

  my @all = $engine->list_cached_contents_f->get;

  is( scalar @all, 0, 'an empty collection yields an empty list' );
  is( scalar @{ $ua->seen }, 1, 'and costs exactly one request' );

  return;
}

test_unpaginated_walk();
test_page_size_stops_after_one_page();
test_page_size_sync_wrapper();
test_page_token_stops_after_one_page();
test_both_page_options();
test_empty_collection();

done_testing;
