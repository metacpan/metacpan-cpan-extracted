########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::Ordered::Hash v2.0.0;
use v5.40;

########################################################################
# a hash: the fastest lookup, insert and delete of all, and no order.
# a range, or the contents, must sort the keys, O(n log n) every time.
########################################################################

sub new( $class, %arg )
{
    bless { value => {} } => $class
}

sub put( $self, $key, $value )
{
    $self->{ value }{ $key }    = $value;

    $self
}

sub get( $self, $key )
{
    $self->{ value }{ $key }
}

sub delete( $self, $key )
{
    delete $self->{ value }{ $key }
}

sub range( $self, $lo, $hi )
{
    [
        map { [ $_, $self->{ value }{ $_ } ] }
        sort { $a <=> $b }
        grep { $_ >= $lo && $_ <= $hi }
        keys $self->{ value }->%*
    ]
}

sub cut( $self, $lo, $hi )
{
    my $found   = $self->range( $lo, $hi );

    delete $self->{ value }{ $_->[ 0 ] } for $found->@*;

    $found
}

sub size( $self )
{
    scalar keys $self->{ value }->%*
}

sub contents( $self )
{
    [
        map { [ $_, $self->{ value }{ $_ } ] }
        sort { $a <=> $b }
        keys $self->{ value }->%*
    ]
}

1
__END__

=head1 NAME

LinkedList::Single::Example::Ordered::Hash - ordered map as a hash, sorted on demand

=head1 DESCRIPTION

Same interface as L<LinkedList::Single::Example::Ordered>.
