#!/usr/bin/env perl
# watch(): allowWatchBookmarks, BOOKMARK handling, the resume point after a
# watch started without resourceVersion, and HTTP 410 on the watch request
# itself (karr k69).
#
# Run:
#   prove -lv t/73_watch_bookmarks.t

use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock qw(mock_api);
use Kubernetes::REST;
use Kubernetes::REST::Server;
use Kubernetes::REST::AuthToken;
use Kubernetes::REST::APIError;
use JSON::MaybeXS ();

# A streaming IO that records the request URL and answers with a chosen status.
{
  package Local::WatchIO;
  use Moo;
  with 'Kubernetes::REST::Role::IO';

  has events => ( is => 'rw', default => sub { [] } );
  has status => ( is => 'rw', default => sub { 200 } );
  has urls   => ( is => 'ro', default => sub { [] } );

  sub call { die 'not used' }

  sub call_streaming {
    my ( $self, $req, $cb ) = @_;
    push @{ $self->urls }, $req->url;
    if ( $self->status != 200 ) {
      return Test::Kubernetes::Mock::Response->new(
        status  => $self->status,
        content => JSON::MaybeXS->new( utf8 => 1 )->encode( {
          kind => 'Status', status => 'Failure', code => $self->status + 0,
          reason => 'Expired', message => 'too old resource version',
        } ),
      );
    }
    my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
    $cb->( $json->encode($_) . "\n", undef ) for @{ $self->events };
    return Test::Kubernetes::Mock::Response->new( status => 200 );
  }
}

my $io  = Local::WatchIO->new;
my $api = Kubernetes::REST->new(
  server      => Kubernetes::REST::Server->new( endpoint => 'http://mock.local' ),
  credentials => Kubernetes::REST::AuthToken->new( token => 'MockToken' ),
  resource_map_from_cluster => 0,
  io => $io,
);

sub pod_event {
  my ( $type, $rv ) = @_;
  return {
    type   => $type,
    object => {
      apiVersion => 'v1', kind => 'Pod',
      metadata => { name => 'p'.$rv, namespace => 'default', resourceVersion => $rv },
    },
  };
}

sub bookmark {
  my ($rv) = @_;
  return {
    type   => 'BOOKMARK',
    object => {
      apiVersion => 'v1', kind => 'Pod',
      metadata => { resourceVersion => $rv },
    },
  };
}

sub run_watch {
  my ( $events, %args ) = @_;
  $io->events($events);
  $io->status(200);
  my @seen;
  my $rv = $api->watch( 'Pod',
    namespace => 'default',
    on_event  => sub { push @seen, $_[0] },
    %args,
  );
  return ( $rv, \@seen );
}

subtest 'allowWatchBookmarks=true is always sent' => sub {
  run_watch( [ pod_event( 'ADDED', 5 ) ] );
  like( $io->urls->[-1], qr/[?&]allowWatchBookmarks=true(?:&|$)/, 'without resourceVersion' );
  run_watch( [ pod_event( 'ADDED', 5 ) ], resourceVersion => 50 );
  like( $io->urls->[-1], qr/[?&]allowWatchBookmarks=true(?:&|$)/, 'with resourceVersion' );
  like( $io->urls->[-1], qr/[?&]resourceVersion=50(?:&|$)/, 'resourceVersion still sent' );
};

subtest 'BOOKMARK is not handed to on_event but sets the resume point' => sub {
  my ( $rv, $seen ) = run_watch( [ pod_event( 'ADDED', 5 ), bookmark(100) ] );
  is_deeply( [ map { $_->type } @$seen ], ['ADDED'], 'only the ADDED reached on_event' );
  is( $rv, 100, 'bookmark resourceVersion returned' );
};

subtest 'no start rv: initial ADDED rvs are no resume point' => sub {
  my ($rv) = run_watch( [ pod_event( 'ADDED', 5 ), pod_event( 'ADDED', 7 ), bookmark(100) ] );
  is( $rv, 100, 'ADDED 5, ADDED 7, BOOKMARK 100 -> 100' );

  ($rv) = run_watch( [ pod_event( 'ADDED', 5 ), pod_event( 'ADDED', 7 ) ] );
  is( $rv, undef, 'ADDED 5, ADDED 7, no BOOKMARK -> undef' );
};

subtest 'no start rv: events after the first BOOKMARK count again' => sub {
  my ($rv) = run_watch( [ bookmark(100), pod_event( 'MODIFIED', 101 ) ] );
  is( $rv, 101, 'BOOKMARK 100, MODIFIED 101 -> 101' );
};

subtest 'with start rv every event counts' => sub {
  my ($rv) = run_watch(
    [ pod_event( 'ADDED', 60 ), pod_event( 'MODIFIED', 61 ) ], resourceVersion => 50 );
  is( $rv, 61, 'last event rv returned' );

  ($rv) = run_watch( [ pod_event( 'ADDED', 60 ) ], resourceVersion => 50 );
  is( $rv, 60, 'event rv replaces the start rv' );

  my ( $rv2, $seen ) = run_watch(
    [ pod_event( 'ADDED', 60 ), bookmark(70) ], resourceVersion => 50 );
  is( $rv2, 70, 'bookmark counts' );
  is( scalar @$seen, 1, 'bookmark not handed to on_event' );

  ($rv) = run_watch( [], resourceVersion => 50 );
  is( $rv, 50, 'no events: start rv returned' );
};

subtest 'HTTP 410 on the watch request' => sub {
  $io->status(410);
  throws_ok {
    $api->watch( 'Pod', namespace => 'default', resourceVersion => 5, on_event => sub { } );
  } qr/410 Gone/, 'with resourceVersion: plain "410 Gone" croak';
  ok( !ref $@, 'a plain string, not an APIError' );
  like( $@, qr/^Watch expired \(410 Gone\)/, 'same text as the ERROR event' );

  $io->status(410);
  my $err;
  eval { $api->watch( 'Pod', namespace => 'default', on_event => sub { } ); 1 }
    or $err = $@;
  isa_ok( $err, 'Kubernetes::REST::APIError', 'without resourceVersion' );
  is( $err->code, 410, 'code 410' );
};

subtest 'other HTTP errors stay APIError' => sub {
  for my $code ( 403, 500 ) {
    $io->status($code);
    my $err;
    eval { $api->watch( 'Pod', namespace => 'default', resourceVersion => 5,
      on_event => sub { } ); 1 } or $err = $@;
    isa_ok( $err, 'Kubernetes::REST::APIError', "$code" );
    is( $err->code, $code, "code $code" );
  }
};

done_testing;
