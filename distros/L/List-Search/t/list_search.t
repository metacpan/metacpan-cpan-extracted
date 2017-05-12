use strict;
use warnings;

use Test::More 'no_plan';

use List::Search qw( list_search nlist_search );

my @numbers = 0 .. 10;
my @floats  = map { $_ / 10 } @numbers;
my @words   = qw( alpha bravo charlie delta foxtrot );

# Test that all the words are found correctly
{
    my $word_index = 0;
    foreach my $word (@words) {
        my $idx = list_search( $word, \@words );
        is $idx, $word_index, "word $word is at $word_index";
        $word_index++;
    }
}

# Test that all the numbers are found correctly
{
    my $number_index = 0;
    foreach my $number (@numbers) {

        # integers
        my $int_idx = nlist_search( $number, \@numbers );
        is $int_idx, $number_index, "number $number is at $number_index";

        # floats
        my $float = $number / 10;
        my $float_idx = nlist_search( $float, \@floats );
        is $float_idx, $number_index, "float $float is at $number_index";

        # offset ints
        my $offset = $number - 0.5;
        my $offset_idx = nlist_search( $offset, \@numbers );
        is $offset_idx, $number_index, "offset $offset is at $number_index";

        $number_index++;
    }
}

# Test that edge cases work as expected.
is list_search( 'aaa', \@words ), 0,  "aaa is at 0";
is list_search( 'ccc', \@words ), 2,  "ccc is at 2";
is list_search( 'zzz', \@words ), -1, "zzz is at -1";
