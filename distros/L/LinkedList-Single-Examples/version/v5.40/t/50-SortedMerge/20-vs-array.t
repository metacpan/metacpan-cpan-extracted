########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::Testy;
use v5.40;
use FindBin::libs;

use List::Util  qw( min );

use Test::More;
use Test::Deep;

use LinkedList::Single::Example::SortedMerge;
use LinkedList::Single::Example::SortedMerge::Array;

########################################################################
# package variables
########################################################################

# fixed seed: a failure is reproducible.

srand 20261031;

# one implementation under test.

sub impl( $name, $sorter )
{
    return
    {
        name    => $name
      , sorter  => $sorter
    };
}

my @impl
= (
    impl( 'list-relink',    LinkedList::Single::Example::SortedMerge->new( how => 'relink' ) )
  , impl( 'list-copy',      LinkedList::Single::Example::SortedMerge->new( how => 'copy'   ) )
  , impl( 'array',          LinkedList::Single::Example::SortedMerge::Array->new )
);

########################################################################
# utility
########################################################################

# an item is [ $key, $seq ]. the keys come from a small range so that
# there are plenty of ties; $seq is unique and increasing, so a stable
# sort puts tied items in $seq order and the expected result is
# unambiguous.

sub items( $count, $first_seq )
{
    map { [ int rand 12, $first_seq + $_ ] } 0 .. $count - 1
}

sub by_key_then_seq( @item )
{
    sort { $a->[ 0 ] <=> $b->[ 0 ] || $a->[ 1 ] <=> $b->[ 1 ] } @item
}

# the items as one string: cheap to compare after every case.

sub flat( $item )
{
    join '|', map { join ',', $_->@* } $item->@*
}

########################################################################
# tests
#
# merge two sorted lists, and sort an unsorted one, through every
# implementation; the expected result is perl's own sort with the
# sequence number as the tie-break, which a stable merge must equal.
########################################################################

my %seen
= (
    cases       => 0
  , empty_side  => 0
  , ties        => 0
);

my $bad = 0;

# merge: every pair of sizes from 0 up to 9, then random larger ones.

my @size
= (
    (
        map
        {
            my $nx  = $_;

            map { [ $nx, $_ ] } 0 .. 9
        }
        0 .. 9
    )
  , ( map { [ int rand 60, int rand 60 ] } 1 .. 200 )
);

for my $size ( @size )
{
    my( $nx, $ny )  = $size->@*;

    # the left list's sequence numbers all precede the right's.

    my @x   = by_key_then_seq items $nx, 0;
    my @y   = by_key_then_seq items $ny, $nx;
    my $want
    = flat [ by_key_then_seq @x, @y ];

    ++$seen{ cases };
    ++$seen{ empty_side }   if ! $nx || ! $ny;

    # (looking at $x[ 0 ][ 0 ] of an empty @x would create an item)

    ++$seen{ ties }
    if @x && grep { $_->[ 0 ] == $x[ 0 ][ 0 ] } @y;

    for my $impl ( @impl )
    {
        my $sorter  = $impl->{ sorter };
        my $merged  = $sorter->merge( $sorter->build( @x ), $sorter->build( @y ) );
        my $have    = flat $sorter->contents( $merged );

        $have eq $want
        and next;

        ++$bad;

        fail "merge of $nx and $ny items: $impl->{ name }";

        diag "  have: $have\n  want: $want";
    }
}

is $bad, 0, "Merged $seen{ cases } pairs of lists identically to a stable sort";

cmp_ok $seen{ empty_side }, '>', 15, 'Some merges had an empty side';
cmp_ok $seen{ ties       }, '>', 15, 'Some merges had equal keys on both sides';

# merge_sort: every size from 0 to 40, then random larger ones.

$bad    = 0;

for my $count ( 0 .. 40, map { int rand 400 } 1 .. 60 )
{
    my @item    = items $count, 0;
    my $want    = flat [ by_key_then_seq @item ];

    for my $impl ( @impl )
    {
        my $sorter  = $impl->{ sorter };
        my $sorted  = $sorter->merge_sort( $sorter->build( @item ) );
        my $have    = flat $sorter->contents( $sorted );

        $have eq $want
        and next;

        ++$bad;

        fail "merge_sort of $count items: $impl->{ name }";
    }

    # the sort that goes through a perl array, for the lists.

    my $sorter  = $impl[ 0 ]{ sorter };
    my $viaa    = $sorter->sort_via_array( $sorter->build( @item ) );

    flat( $sorter->contents( $viaa ) ) eq $want
    or ++$bad
    and fail "sort_via_array of $count items";
}

is $bad, 0, 'merge_sort equals a stable sort for every size and implementation';

# a different comparator: descending by string.

my @word
= map
{
    [ join( '', map { chr( 97 + int rand 5 ) } 1 .. 3 ), $_ ]
}
1 .. 80;

my $down
= sub( $x, $y )
{
    $y cmp $x
};

my $want
= flat
[
    sort { $b->[ 0 ] cmp $a->[ 0 ] || $a->[ 1 ] <=> $b->[ 1 ] } @word
];

for my $how ( qw( relink copy ) )
{
    my $sorter  = LinkedList::Single::Example::SortedMerge->new( how => $how, cmp => $down );
    my $sorted  = $sorter->merge_sort( $sorter->build( @word ) );

    is flat( $sorter->contents( $sorted ) ), $want, "Descending string order, list-$how";
}

# sort_via_array has a separate path when a comparator is supplied.

{
    my $sorter  = LinkedList::Single::Example::SortedMerge->new( cmp => $down );
    my $sorted  = $sorter->sort_via_array( $sorter->build( @word ) );

    is flat( $sorter->contents( $sorted ) ), $want
    , 'Descending string order, sort_via_array with a comparator (stable)';
}

{
    my $sorter  = LinkedList::Single::Example::SortedMerge::Array->new( cmp => $down );

    is flat( $sorter->contents( $sorter->merge_sort( $sorter->build( @word ) ) ) ), $want
    , 'Descending string order, array';
}

# halves: the left gets the extra node.

for my $impl ( @impl )
{
    my $sorter  = $impl->{ sorter };

    for my $count ( 2 .. 9 )
    {
        my @item    = items $count, 0;
        my( $l, $r )= $sorter->split_half( $sorter->build( @item ) );

        my $got
        = flat [ $sorter->contents( $l )->@*, $sorter->contents( $r )->@* ];

        $got eq flat \@item
        or ++$bad
        and diag "$impl->{ name }: halves of $count lost or reordered items";

        $sorter->contents( $l )->@* == int( ( $count + 1 ) / 2 )
        or ++$bad
        and diag "$impl->{ name }: left half of $count has the wrong size";
    }
}

is $bad, 0, 'Halves rejoin to the original and the left has the extra item';

done_testing
__END__
