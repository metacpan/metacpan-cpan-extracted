use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Google::Search;

my $maximum = 64;

my $referer = "http://search.cpan.org/~rkrimen/";
my $key = "ABQIAAAAtDqLrYRkXZ61bOjIaaXZyxQRY_BHZpnLMrZfJ9KcaAuQJCJzjxRJoUJ6qIwpBfxHzBbzHItQ1J7i0w";
my ( $search, $request );

ok( Google::Search->$_( q => { q => $_ } ) ) for qw/ Web Local Video Image Book News Patent /;

$search = Google::Search->Web( q => 'rock', v => '1.2', referer => 't' );
ok( $search );
is( $search->query, 'rock' );
is( $search->q, 'rock' );
is( $search->version, '1.2' );
is( $search->v, '1.2' );
is( $search->referer, 't' );
is( $search->referrer, 't' );
$request = $search->build;
like( $request->uri, qr{^http://ajax\.googleapis\.com/ajax/services/search/web\?} );
cmp_deeply( { $request->uri->query_form }, { q => 'rock', v => '1.2', rsz => 'large' } );

$search = Google::Search->Web( query => 'rock', version => '1.2', referer => 't' );
ok( $search );
is( $search->query, 'rock' );
is( $search->q, 'rock' );
is( $search->version, '1.2' );
is( $search->v, '1.2' );
is( $search->referer, 't' );
is( $search->referrer, 't' );
$request = $search->build;
like( $request->uri, qr{^http://ajax\.googleapis\.com/ajax/services/search/web\?} );
cmp_deeply( { $request->uri->query_form }, { q => 'rock', v => '1.2', rsz => 'large' } );

$search = Google::Search->Web( 'rock' );
is( $search->query, 'rock' );
$request = $search->build;
like( $request->uri, qr{^http://ajax\.googleapis\.com/ajax/services/search/web\?} );
cmp_deeply( { $request->uri->query_form }, { q => 'rock', v => '1.0', rsz => 'large' } );

$search = Google::Search->Web( 'rock', unknown => 'de' );
$request = $search->build;
like( $request->uri, qr{^http://ajax\.googleapis\.com/ajax/services/search/web\?} );
cmp_deeply( { $request->uri->query_form }, { q => 'rock', v => '1.0', rsz => 'large', unknown => 'de' } );

SKIP: {
    skip 'Do RELEASE_TESTING=1 to go out to Google and run some tests' unless $ENV{RELEASE_TESTING};
    my $search = Google::Search->Web( referer => $referer, key => $key, q => { q => 'rock' } );
    ok( $search );
    ok( $search->first ) || diag $search->error->http_response->as_string;
    ok( $search->result( 59 ) ) || diag $search->error->http_response->as_string;
    is( $search->first->rank, 0 );
    is( $search->result( 59 )->rank, 59 );

    ok( !$search->result( 64 ) );
    my $error = $search->error;
    ok( $error );
    is( $error->code, 400 );
    is( $error->message, "out of range start" );
    ok( $error->http_response );
    is( $error->http_response->status_line, "200 OK" );

    my $count = 0;
    while ( my $result = $search->next ) {
        is( $result->number, $count );
        ok( $result->uri );
        ok( $result );
        $count += 1;
    }
    is( $count, 64 );
    is( scalar @{ $search->all }, 64  );
    is( scalar $search->match( sub { 1 } ), 64  );

    is( $search->first_match( sub { 1 } ), $search->first );
    is( $search->first_match( sub { shift->number eq 27 } ), $search->result( 27 ) );
}

1;
