########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::LRU::Array v2.0.0;
use v5.40;

use Carp    qw( croak );

########################################################################
# the plain array cache: [ $key, $value ] pairs, newest first.
#
# there is no index, so a hit is a linear search, a splice out and an
# unshift. this is what the problem looks like to a programmer who
# reaches for an array first; LinkedList::Single::Example::LRU::Order and
# LinkedList::Single::Example::LRU::Lazy are what a programmer who has seen this cost writes.
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
      , item        => []
    }
    => $class
}

sub _find( $self, $key )
{
    my $item    = $self->{ item };

    for my $at ( 0 .. $#$item )
    {
        $item->[ $at ][ 0 ] eq $key
        and return $at;
    }

    undef
}

sub get( $self, $key )
{
    my $at  = $self->_find( $key )
    // return undef;

    my $item    = $self->{ item };

    unshift $item->@*, splice $item->@*, $at, 1;

    $item->[ 0 ][ 1 ]
}

sub put( $self, $key, $value )
{
    my $item    = $self->{ item };
    my $at      = $self->_find( $key );

    if( defined $at )
    {
        splice $item->@*, $at, 1;
    }

    unshift $item->@*, [ $key, $value ];

    if( @$item > $self->{ limit } )
    {
        $self->{ on_evict }->( pop( $item->@* )->@* );
    }

    $self
}

sub exists( $self, $key )
{
    defined $self->_find( $key )
}

sub size( $self )
{
    scalar $self->{ item }->@*
}

sub limit( $self )
{
    $self->{ limit }
}

sub contents( $self )
{
    [ map { [ $_->@* ] } $self->{ item }->@* ]
}

1
__END__

=head1 NAME

LinkedList::Single::Example::LRU::Array - least-recently-used cache as one array of pairs

=head1 DESCRIPTION

Same interface as L<LinkedList::Single::Example::LRU>. Newest first; a hit searches the
whole array. The test oracle for the list version, and its slowest rival.
