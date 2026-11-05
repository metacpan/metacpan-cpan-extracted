########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::LRU::Order v2.0.0;
use v5.40;

use Carp    qw( croak );

########################################################################
# a hash finds the value, an array of keys keeps the order (newest
# first). a miss costs nothing but the hash lookup; a hit still has to
# find the key in the order array, and splice it to the front.
########################################################################

sub new( $class, %arg )
{
    my $limit   = $arg{ limit }
    // croak 'Botched new: missing limit';

    $limit > 0
    or croak "Botched new: limit '$limit' is not positive";

    bless
    {
        limit       => $limit
      , on_evict    => $arg{ on_evict } // sub {}
      , value       => {}
      , order       => []
    }
    => $class
}

# move a key already present to the front.

sub _touch( $self, $key )
{
    my $order   = $self->{ order };

    $order->[ 0 ] eq $key
    and return;

    my $at  = 0;

    ++$at while $order->[ $at ] ne $key;

    splice $order->@*, $at, 1;

    unshift $order->@*, $key;
}

sub get( $self, $key )
{
    exists $self->{ value }{ $key }
    or return undef;

    $self->_touch( $key );

    $self->{ value }{ $key }
}

sub put( $self, $key, $value )
{
    if( exists $self->{ value }{ $key } )
    {
        $self->_touch( $key );
    }
    else
    {
        unshift $self->{ order }->@*, $key;
    }

    $self->{ value }{ $key }    = $value;

    if( $self->{ order }->@* > $self->{ limit } )
    {
        my $old = pop $self->{ order }->@*;

        $self->{ on_evict }->( $old, delete $self->{ value }{ $old } );
    }

    $self
}

sub exists( $self, $key )
{
    exists $self->{ value }{ $key }
}

sub size( $self )
{
    scalar $self->{ order }->@*
}

sub limit( $self )
{
    $self->{ limit }
}

sub contents( $self )
{
    [ map { [ $_, $self->{ value }{ $_ } ] } $self->{ order }->@* ]
}

1
__END__

=head1 NAME

LinkedList::Single::Example::LRU::Order - least-recently-used cache: a hash and an order array

=head1 DESCRIPTION

Same interface as L<LinkedList::Single::Example::LRU>. A hit searches the order array
for the key (a string compare per entry) and splices.
