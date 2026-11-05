########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::SortedMerge::Array v2.0.0;
use v5.40;

use Carp    qw( croak );

########################################################################
# the same interface over arrays. an item is [ $key, @payload ]; the
# comparator sees the keys only; a merge is stable.
#
# the arrays are not consumed: merge and merge_sort return new arrays
# and leave their arguments as they were. (the list versions cannot
# leave their arguments intact; the tests compare the results only.)
########################################################################

sub new( $class, %arg )
{
    my $cmp = $arg{ cmp } // sub( $x, $y ) { $x <=> $y };

    bless { cmp => $cmp } => $class
}

########################################################################
# two indexes, one output.
########################################################################

sub merge( $self, $x, $y )
{
    my $cmp = $self->{ cmp };
    my @out = ();
    my $i   = 0;
    my $j   = 0;

    while( $i < $x->@* && $j < $y->@* )
    {
        push @out
        , $cmp->( $x->[ $i ][ 0 ], $y->[ $j ][ 0 ] ) <= 0
        ? $x->[ $i++ ]
        : $y->[ $j++ ]
        ;
    }

    push @out, $x->@[ $i .. $x->$#* ];
    push @out, $y->@[ $j .. $y->$#* ];

    \@out
}

sub split_half( $self, $list )
{
    my $count   = $list->@*;

    $count > 1
    or croak "Botched split_half: a list of $count nodes has no halves";

    my $half    = int( ( $count + 1 ) / 2 );

    (
        [ $list->@[ 0 .. $half - 1       ] ]
      , [ $list->@[ $half .. $list->$#*  ] ]
    )
}

sub merge_sort( $self, $list )
{
    $list->@* > 1
    or return [ $list->@* ];

    my( $left, $right ) = $self->split_half( $list );

    $self->merge
    (
        $self->merge_sort( $left  )
      , $self->merge_sort( $right )
    )
}

########################################################################
# test support
########################################################################

sub build( $self, @item )
{
    [ map { [ $_->@* ] } @item ]
}

sub contents( $self, $list )
{
    [ map { [ $_->@* ] } $list->@* ]
}

1
__END__

=head1 NAME

LinkedList::Single::Example::SortedMerge::Array - merge and merge sort on perl arrays

=head1 DESCRIPTION

The array twin of L<LinkedList::Single::Example::SortedMerge>, with the same interface,
used as the reference for the tests and the comparison in the
benchmarks.
