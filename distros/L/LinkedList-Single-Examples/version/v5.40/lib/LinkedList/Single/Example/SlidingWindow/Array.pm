########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::SlidingWindow::Array v2.0.0;
use v5.40;

use Carp    qw( croak );

########################################################################
# methods
########################################################################

sub new( $class, %arg )
{
    my $span = $arg{ span }
    // croak 'Botched new: missing span';

    bless
    {
        span    => $span
      , window  => []
    }
    => $class
}

sub record( $self, $time, @payload )
{
    push $self->{ window }->@*, [ $time, @payload ];

    $self
}

sub expire( $self, $now, $handler = sub {} )
{
    my $window  = $self->{ window };
    my $cutoff  = $now - $self->{ span };

    # count the expired prefix, then splice it off the front.

    my $count   = 0;

    ++$count
    while $count < $window->@*
    && $window->[ $count ][ 0 ] < $cutoff;

    $count
    or return 0;

    my @dead    = splice $window->@*, 0, $count;

    $handler->( $_->@* ) for @dead;

    $count
}

sub contents( $self )
{
    [ map { [ $_->@* ] } $self->{ window }->@* ]
}

sub size( $self )
{
    scalar $self->{ window }->@*
}

1
__END__

=head1 NAME

LinkedList::Single::Example::SlidingWindow::Array - the same window held in a perl array

=head1 DESCRIPTION

The array twin of L<LinkedList::Single::Example::SlidingWindow>, with the same interface,
used as the reference for the tests and the comparison in the
benchmarks.
