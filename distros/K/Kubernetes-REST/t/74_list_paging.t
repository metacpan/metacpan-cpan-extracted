#!/usr/bin/env perl
# karr k74: list() pages (limit, continue, resourceVersion as query
# parameters) and inflate_list keeps the list's metadata (resourceVersion,
# continue, remainingItemCount) so list-then-watch can be built on the public
# API.
#
# Run:
#   prove -lv t/74_list_paging.t
use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock ();
use Kubernetes::REST;
use Kubernetes::REST::Server;
use Kubernetes::REST::AuthToken;
use Kubernetes::REST::HTTPResponse;
use JSON::MaybeXS ();

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

# Serves 5 Pods in pages by the continue token; records every URL.
{
  package Local::PagingIO;
  use Moo;
  with 'Kubernetes::REST::Role::IO';

  has urls => ( is => 'ro', default => sub { [] } );
  my @names = map { 'pod-'.$_ } 1 .. 5;

  sub _q {
    my ( $url, $key ) = @_;
    my ($q) = $url =~ /\?(.*)\z/ or return;
    for my $pair ( split /&/, $q ) {
      my ( $k, $v ) = split /=/, $pair, 2;
      return $v if $k eq $key;
    }
    return;
  }

  sub call {
    my ( $self, $req ) = @_;
    push @{ $self->urls }, $req->url;
    my $limit = _q( $req->url, 'limit' ) // 100;
    my $start = _q( $req->url, 'continue' ) // 0;
    $start = 0 unless $start =~ /\A\d+\z/;
    my $end   = $start + $limit - 1;
    $end = $#names if $end > $#names;
    my %meta  = ( resourceVersion => '9000' );
    if ( $end < $#names ) {
      $meta{continue}           = $end + 1;
      $meta{remainingItemCount} = $#names - $end;
    }
    return Test::Kubernetes::Mock::Response->new(
      status  => 200,
      content => JSON::MaybeXS->new( utf8 => 1 )->encode( {
        kind => 'PodList', apiVersion => 'v1', metadata => \%meta,
        items => [ map { { apiVersion => 'v1', kind => 'Pod',
          metadata => { name => $names[$_], namespace => 'default' } } } $start .. $end ],
      } ),
    );
  }

  sub call_streaming {
    my ( $self, $req, $cb ) = @_;
    push @{ $self->urls }, $req->url;
    return Test::Kubernetes::Mock::Response->new( status => 200 );
  }
}

my $io  = Local::PagingIO->new;
my $api = Kubernetes::REST->new(
  server      => Kubernetes::REST::Server->new( endpoint => 'http://mock.local' ),
  credentials => Kubernetes::REST::AuthToken->new( token => 'MockToken' ),
  resource_map_from_cluster => 0,
  io => $io,
);

subtest 'limit, continue, resourceVersion go out as query parameters' => sub {
  lives_ok { $api->list( 'Pod', namespace => 'default', limit => 2 ) } 'limit accepted';
  like $io->urls->[-1], qr{^http://mock\.local/api/v1/namespaces/default/pods\?.*\blimit=2(?:&|$)}, 'limit in URL';

  lives_ok { $api->list( 'Pod', namespace => 'default', continue => 'tok', resourceVersion => '77' ) }
    'continue and resourceVersion accepted';
  like $io->urls->[-1], qr/[?&]continue=tok(?:&|$)/, 'continue in URL';
  like $io->urls->[-1], qr/[?&]resourceVersion=77(?:&|$)/, 'resourceVersion in URL';

  lives_ok { $api->list( q(Pod), namespace => q(default) ) } q(plain list lives);
  unlike $io->urls->[-1], qr/limit|continue|resourceVersion|\?/, 'nothing sent when undefined';
  lives_ok { $api->list( q(Pod), namespace => q(default), limit => undef, continue => undef, resourceVersion => undef ) } q(undef values accepted);
  unlike $io->urls->[-1], qr/limit|continue|resourceVersion|\?/, 'undef values are not sent';
};

subtest 'unknown arguments still croak' => sub {
  throws_ok { $api->list( 'Pod', namespace => 'default', limt => 2 ) } qr/limt/, 'misspelt key croaks';
};

subtest 'inflate_list hands metadata to the list' => sub {
  my $res = Kubernetes::REST::HTTPResponse->new( status => 200, content => $json->encode( {
    kind => 'PodList', apiVersion => 'v1',
    metadata => { resourceVersion => '4711', continue => 'abc', remainingItemCount => 3 },
    items => [],
  } ) );
  my $list = $api->inflate_list( 'Pod', $res );
  ok defined $list->metadata, 'metadata present';
  my $m = $list->metadata;
  is eval { $m->resourceVersion }, q(4711), q(resourceVersion);
  is eval { $m->continue }, q(abc), q(continue);
  is eval { $m->remainingItemCount }, 3, q(remainingItemCount);

  my $bare = $api->inflate_list( 'Pod', Kubernetes::REST::HTTPResponse->new(
    status => 200, content => $json->encode( { kind => 'PodList', apiVersion => 'v1', items => [] } ) ) );
  ok !defined $bare->metadata, 'no metadata in response -> undef';
};

subtest 'paging loop over several pages' => sub {
  @{ $io->urls } = ();
  my ( @names, $cont, $last );
  my $pages = 0;
  do {
    my $list = $api->list( 'Pod', namespace => 'default', limit => 2,
      defined $cont ? ( continue => $cont ) : () );
    $pages++;
    push @names, map { $_->metadata->name } @{ $list->items };
    $cont = $list->metadata ? $list->metadata->continue : undef;
    $last = $list;
  } while ( $pages < 10 && defined $cont && length $cont );

  is $pages, 3, 'three pages';
  is_deeply \@names, [ map { 'pod-'.$_ } 1 .. 5 ], 'all items in order';
  is scalar @{ $io->urls }, 3, 'three requests';
  unlike $io->urls->[0], qr/continue/, 'first page has no continue';
  like $io->urls->[1], qr/[?&]continue=2(?:&|$)/, 'second page continues at 2';
  like $io->urls->[2], qr/[?&]continue=4(?:&|$)/, 'third page continues at 4';
  is $last->metadata->resourceVersion, '9000', 'last page has resourceVersion';

  $api->watch( 'Pod', namespace => 'default',
    resourceVersion => $last->metadata->resourceVersion, on_event => sub { } );
  like $io->urls->[-1], qr{/api/v1/namespaces/default/pods\?.*\bresourceVersion=9000(?:&|$)}, 'watch starts at the list resourceVersion';
  like $io->urls->[-1], qr/[?&]watch=true(?:&|$)|[?&]watch=1(?:&|$)/, 'it is a watch request';
};

done_testing;
