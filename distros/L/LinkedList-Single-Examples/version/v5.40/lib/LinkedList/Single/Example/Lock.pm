########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::Lock v2.0.0;
use v5.40;

use Carp        qw( croak );
use Time::HiRes qw( time  );

########################################################################
# methods
########################################################################

sub new( $class )
{
    bless
    {
        held        => 0
      , acquired    => 0
      , held_secs   => 0
    }
    => $class
}

########################################################################
# run $code with the lock held.
#
# there are no real threads here (perl ithreads clone their data and
# cannot share a linked list), so the lock is a stand-in that records
# what a real one would make other threads wait for: how many times it
# was taken, and for how long.
#
# the result is returned in scalar context. the lock is released
# whether or not $code dies.
########################################################################

sub hold( $self, $code, @arg )
{
    $self->{ held }
    and croak 'Botched hold: the lock is not re-entrant';

    $self->{ held } = 1;

    ++$self->{ acquired };

    my $start   = time;
    my $result;

    my $ok
    = eval
    {
        $result = $code->( @arg );

        1
    };

    my $err     = $@;

    $self->{ held_secs }    += time - $start;
    $self->{ held }         = 0;

    $ok
    or die $err;

    $result
}

########################################################################
# introspection
########################################################################

sub acquired( $self )
{
    $self->{ acquired }
}

sub held_secs( $self )
{
    $self->{ held_secs }
}

sub reset( $self )
{
    $self->{ acquired }     = 0;
    $self->{ held_secs }    = 0;

    $self
}

1
__END__

=head1 NAME

LinkedList::Single::Example::Lock - a stand-in lock that records how long it was held

=head1 SYNOPSIS

    my $lock   = LinkedList::Single::Example::Lock->new;

    my $result = $lock->hold( sub( @arg ) { ... }, @arg );

    printf "%d acquisitions, %.6f seconds held\n"
    , $lock->acquired
    , $lock->held_secs;

=head1 DESCRIPTION

See L<LinkedList::Single::Example::Handoff::POD>. The lock is not re-entrant: taking it while
it is held croaks, which catches a method that calls another locked
method.
