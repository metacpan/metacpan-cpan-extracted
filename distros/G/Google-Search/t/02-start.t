use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Google::Search;

my $maximum = 64;

my $referer = "http://search.cpan.org/~rkrimen/";
my $key = "ABQIAAAAtDqLrYRkXZ61bOjIaaXZyxQRY_BHZpnLMrZfJ9KcaAuQJCJzjxRJoUJ6qIwpBfxHzBbzHItQ1J7i0w";
my $search;

SKIP: {
    skip 'Do RELEASE_TESTING=1 to go out to Google and run some tests' unless $ENV{RELEASE_TESTING};
    my $s0 = Google::Search->Web( start => 0, q => { q => 'rock' } );
    my $s11 = Google::Search->Web( start => 11, q => { q => 'rock' } );
    diag( $s0->result( 11 )->uri );
    diag( $s0->first->uri );
    diag( $s11->first->uri );
    is( $s11->first->rank, 11 );
    is( $s0->result( 11 )->uri, $s11->first->uri );
}

1;
