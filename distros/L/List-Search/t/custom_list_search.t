use strict;
use warnings;

use Test::More 'no_plan';

use List::Search qw( custom_list_search );

my $cmp_sub = sub { lc( $_[0] ) cmp lc( $_[1] ) };

my @words =
  sort { $cmp_sub->( $a, $b ) }    # sort using this sub
  qw( alpha BRAVO charlie DELTA foxtrot );

my $word_index = 0;
foreach my $word ( map { lc $_ } @words ) {
    my $idx = custom_list_search( $cmp_sub, $word, \@words );
    my $match = $words[$idx];
    is $idx, $word_index, "word $word is at $word_index ($match)";
    $word_index++;
}
