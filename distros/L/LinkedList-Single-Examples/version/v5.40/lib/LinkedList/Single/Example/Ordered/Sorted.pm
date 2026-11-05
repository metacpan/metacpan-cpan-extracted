########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::Ordered::Sorted v2.0.0;
use v5.40;

########################################################################
# one sorted array of [ key, value ] pairs. a binary search finds a key
# in O(log n); an insert or a delete is a splice, which moves everything
# after it (in C, in one block, so it is fast for a long while).
########################################################################

sub new( $class, %arg )
{
    bless { item => [] } => $class
}

# the position of the first pair whose key is not below $key.

sub _lower( $self, $key )
{
    my $item    = $self->{ item };
    my( $lo, $hi ) = ( 0, scalar @$item );

    while( $lo < $hi )
    {
        my $mid = ( $lo + $hi ) >> 1;

        if( $item->[ $mid ][ 0 ] < $key )
        {
            $lo = $mid + 1;
        }
        else
        {
            $hi = $mid;
        }
    }

    $lo
}

sub put( $self, $key, $value )
{
    my $item    = $self->{ item };
    my $at      = $self->_lower( $key );

    if( $at < @$item && $item->[ $at ][ 0 ] == $key )
    {
        $item->[ $at ][ 1 ] = $value;
    }
    else
    {
        splice $item->@*, $at, 0, [ $key, $value ];
    }

    $self
}

sub get( $self, $key )
{
    my $item    = $self->{ item };
    my $at      = $self->_lower( $key );

    $at < @$item && $item->[ $at ][ 0 ] == $key
    ? $item->[ $at ][ 1 ]
    : undef
}

sub delete( $self, $key )
{
    my $item    = $self->{ item };
    my $at      = $self->_lower( $key );

    $at < @$item && $item->[ $at ][ 0 ] == $key
    or return undef;

    ( splice $item->@*, $at, 1 )[ 0 ][ 1 ]
}

sub range( $self, $lo, $hi )
{
    my $item    = $self->{ item };
    my $from    = $self->_lower( $lo );
    my @found   = ();

    for my $at ( $from .. $#$item )
    {
        $item->[ $at ][ 0 ] > $hi
        and last;

        push @found, [ $item->[ $at ]->@* ];
    }

    \@found
}

sub cut( $self, $lo, $hi )
{
    my $item    = $self->{ item };
    my $from    = $self->_lower( $lo );
    my $to      = $from;

    ++$to while $to < @$item && $item->[ $to ][ 0 ] <= $hi;

    [ splice $item->@*, $from, $to - $from ]
}

sub size( $self )
{
    scalar $self->{ item }->@*
}

sub contents( $self )
{
    [ map { [ $_->@* ] } $self->{ item }->@* ]
}

1
__END__

=head1 NAME

LinkedList::Single::Example::Ordered::Sorted - ordered map as one sorted array

=head1 DESCRIPTION

Same interface as L<LinkedList::Single::Example::Ordered>.
