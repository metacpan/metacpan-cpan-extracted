########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::Probe v2.0.0;
use v5.40;

########################################################################
# package variables
########################################################################

our %gone   = ();

########################################################################
# methods
########################################################################

sub new( $class, $id )
{
    bless { id => $id } => $class
}

sub id( $self )
{
    $self->{ id }
}

sub DESTROY( $self )
{
    ++$gone{ $self->{ id } };
}

# ids of the probes destroyed so far, in order.

sub destroyed( $class )
{
    sort { $a <=> $b } keys %gone
}

sub reset( $class )
{
    %gone   = ();
}

1
__END__

=head1 NAME

LinkedList::Single::Example::Probe - payload object that records when it is destroyed

=head1 SYNOPSIS

    use LinkedList::Single::Example::Probe;

    LinkedList::Single::Example::Probe->reset;

    $window->record( $time, LinkedList::Single::Example::Probe->new( $id ) );

    my @ids = LinkedList::Single::Example::Probe->destroyed;

=head1 DESCRIPTION

A linked list releases each node as soon as nothing refers to it.
That is hard to see from the outside; these objects make it visible
by noting their id when perl destroys them. The examples use them to
show that consuming a Fragment destroys its payloads one at a time
as the Fragment advances.
