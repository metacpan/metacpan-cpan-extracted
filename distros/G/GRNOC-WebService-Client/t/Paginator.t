use strict;
use warnings;

use Test::More tests => 12;

use GRNOC::WebService::Client;
use Data::Dumper;

my $websvc = GRNOC::WebService::Client->new( url => "http://localhost:8529/test.cgi",
                                             use_pagination => 1 );

my $paginator = $websvc->page();

is( $paginator->offset(), 0, 'default offset 0' );
is( $paginator->limit(), 1000, 'default limit 1000' );
ok( $paginator->has_page(), 'initially has page' );

$paginator->next_page();

# we should know the total number of possible results now
is( $paginator->total(), 4, '4 total results' );

# there shouldn't be any more pages
ok( !$paginator->has_page(), 'no more pages' );

# make sure next page returns undef when there are no more pages
ok( !defined( $paginator->next_page() ), 'no next page' );

# try custom limit and offset
$paginator = $websvc->page( limit => 1,
                            offset => 2 );

my $num_pages = 0;

while ( $paginator->has_page() ) {

    $paginator->next_page();
    $num_pages++;
}

is( $num_pages, 2, '2 total pages from offset 2' );
is( $paginator->total(), 4, 'still 4 total results' );

# handle hard server errors
$paginator = $websvc->page( hard_error => 1 );

ok( !defined( $paginator->next_page() ), 'detect hard error properly' );
ok( !$paginator->has_page(), 'no more pages after hard error' );

# handle soft response errors
$paginator = $websvc->page( soft_error => 1 );

is( $paginator->next_page()->{'error'}, 1, 'detect soft error properly' );
ok( !$paginator->has_page(), 'no more pages after soft error' );
