########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::Ordered::Buckets v2.0.0;
use v5.40;

use Carp    qw( croak );

########################################################################
# the array programmer's version of the same two-level design: an array
# of buckets, each a small sorted array of [ key, value ] pairs, with
# the bucket's low key beside it. binary search over the lows finds the
# bucket, binary search inside it finds the pair, a splice moves at
# most 2 * bucket pairs. a bucket at twice its size is split in two; an
# empty one is removed.
########################################################################

sub new( $class, %arg )
{
    # the default is the fastest found for lists of up to 100,000 entries
    # (see the POD); LLS_BUCKET_SIZE overrides it.

    my $bucket
    = $arg{ bucket }
    // $ENV{ LLS_BUCKET_SIZE }
    // 3
    ;

    $bucket > 0
    or croak "Botched new: bucket '$bucket' is not positive";

    bless
    {
        bucket  => $bucket
      , index   => [ { low => undef, item => [] } ]
    }
    => $class
}

# the position of the bucket that holds, or would hold, a key.

sub _locate( $self, $key )
{
    my $index   = $self->{ index };
    my( $lo, $hi ) = ( 0, $#$index );

    while( $lo < $hi )
    {
        my $mid = ( $lo + $hi + 1 ) >> 1;

        if( $index->[ $mid ]{ low } <= $key )
        {
            $lo = $mid;
        }
        else
        {
            $hi = $mid - 1;
        }
    }

    $lo
}

# the position in a bucket of the first pair not below $key.

sub _lower( $item, $key )
{
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
    my $at      = $self->_locate( $key );
    my $item    = $self->{ index }[ $at ]{ item };
    my $pos     = _lower $item, $key;

    if( $pos < @$item && $item->[ $pos ][ 0 ] == $key )
    {
        $item->[ $pos ][ 1 ] = $value;
    }
    else
    {
        splice $item->@*, $pos, 0, [ $key, $value ];

        if( @$item > 2 * $self->{ bucket } )
        {
            my @second  = splice $item->@*, $self->{ bucket };

            splice $self->{ index }->@*, $at + 1, 0
            , { low => $second[ 0 ][ 0 ], item => \@second };
        }
    }

    $self
}

sub get( $self, $key )
{
    my $item    = $self->{ index }[ $self->_locate( $key ) ]{ item };
    my $pos     = _lower $item, $key;

    $pos < @$item && $item->[ $pos ][ 0 ] == $key
    ? $item->[ $pos ][ 1 ]
    : undef
}

sub delete( $self, $key )
{
    my $at      = $self->_locate( $key );
    my $item    = $self->{ index }[ $at ]{ item };
    my $pos     = _lower $item, $key;

    $pos < @$item && $item->[ $pos ][ 0 ] == $key
    or return undef;

    my $value   = ( splice $item->@*, $pos, 1 )[ 0 ][ 1 ];

    @$item
    or $at
    and splice $self->{ index }->@*, $at, 1;

    $value
}

sub range( $self, $lo, $hi )
{
    my $index   = $self->{ index };
    my $at      = $self->_locate( $lo );
    my @found   = ();

    for my $position ( $at .. $#$index )
    {
        my $bucket  = $index->[ $position ];

        defined $bucket->{ low }
        and $bucket->{ low } > $hi
        and last;

        for my $pair ( $bucket->{ item }->@* )
        {
            $pair->[ 0 ] > $hi
            and return \@found;

            $pair->[ 0 ] >= $lo
            and push @found, [ $pair->@* ];
        }
    }

    \@found
}

sub cut( $self, $lo, $hi )
{
    my $index   = $self->{ index };
    my $at      = $self->_locate( $lo );
    my @found   = ();

    while( $at <= $#$index )
    {
        my $bucket  = $index->[ $at ];

        defined $bucket->{ low }
        and $bucket->{ low } > $hi
        and last;

        my $item    = $bucket->{ item };
        my $from    = _lower $item, $lo;
        my $to      = $from;

        ++$to while $to < @$item && $item->[ $to ][ 0 ] <= $hi;

        push @found, splice $item->@*, $from, $to - $from;

        if( @$item || ! $at )
        {
            ++$at;
        }
        else
        {
            splice $index->@*, $at, 1;
        }
    }

    \@found
}

sub size( $self )
{
    my $size    = 0;

    $size   += @{ $_->{ item } } for $self->{ index }->@*;

    $size
}

sub contents( $self )
{
    [ map { [ $_->@* ] } map { $_->{ item }->@* } $self->{ index }->@* ]
}

1
__END__

=head1 NAME

LinkedList::Single::Example::Ordered::Buckets - ordered map as an array of small sorted arrays

=head1 DESCRIPTION

Same interface as L<LinkedList::Single::Example::Ordered>; the array programmer's version of
its design.
