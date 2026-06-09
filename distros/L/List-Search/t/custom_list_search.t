use strict;
use warnings;

use Test::More tests => 7;

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

# We gave these examples in section SYNOPSIS.
{
    my $cmp_code = sub { lc( $_[0] ) cmp lc( $_[1] ) };
    my @custom_list = sort { $cmp_code->( $a, $b ) }
        qw( FOO bar BAZ bundy );
    is_deeply \@custom_list, [ qw( bar BAZ bundy FOO ) ],
        "pod example: check!";
    is custom_list_search( $cmp_code, 'foo', \@custom_list ),
        3, "pod example: itself";
}
