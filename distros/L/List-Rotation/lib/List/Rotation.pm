package List::Rotation;
use 5.006;
our $VERSION = '1.010';

package List::Rotation::Cycle;
use strict;
use warnings;

use Memoize;
memoize('new');

sub new {
    my $class = shift;

    do {
        require Carp;
        Carp::croak ("Incorrect number of arguments; must be >= 1.");
    } unless 1 <= @_;
    my $r_values = [ @_ ];
    my $position = undef;
    my $length = @$r_values;

    my $method = {
        _next => sub {
            $position = defined $position ? ++$position : 0;
            my $i = $position % $length;
            return $r_values->[$i];
        },
        _prev => sub {
            $position = defined $position ? --$position : -1;
            my $i = $position % $length;
            return $r_values->[$i];
        },
        _curr => sub {
            return unless defined $position;
            my $i = $position % $length;
            return $r_values->[$i];
        },
        _reset => sub {
            $position = undef;
        },
    };

    my $closure = sub {
        my $call = shift;
        &{ $method->{$call} };
    };

    bless $closure, $class;
}

sub next  { my $self = shift; &{ $self }( '_next'  ); }
sub prev  { my $self = shift; &{ $self }( '_prev'  ); }
sub curr  { my $self = shift; &{ $self }( '_curr'  ); }
sub reset { my $self = shift; &{ $self }( '_reset' ); }

#-------------------------------------------------------------------------------

package List::Rotation::Alternate;

use strict;

use vars qw( @ISA );
@ISA = qw(List::Rotation::Cycle);  

sub new {
    my $class = shift;

    do {
        require Carp;
        Carp::croak ("Incorrect number of arguments; must be <2>.");
    } unless 2 == @_;

    $class->SUPER::new(@_);
}

#-------------------------------------------------------------------------------

package List::Rotation::Toggle;

use strict;

use vars qw( @ISA );
@ISA = qw(List::Rotation::Alternate);  

sub new {
    my $class = shift;

    do {
        require Carp;
        Carp::croak ("No arguments accepted.");
    } unless 0 == @_;

    $class->SUPER::new( 1 == 1, 0 == 1 );
}

#-------------------------------------------------------------------------------

1;


__END__

=head1 NAME

List::Rotation - Loop (Cycle, Alternate or Toggle) through a list of values via a singleton object implemented as closure.

=head1 SYNOPSIS

    use List::Rotation;

    my @array = qw( A B C );

    my $first_cycle  = List::Rotation::Cycle->new(@array);

    print $first_cycle->next;  ## prints A
    print $first_cycle->next;  ## prints B
    print $first_cycle->next;  ## prints C
    print $first_cycle->next;  ## prints A, looping back to beginning
    print $first_cycle->next;  ## prints B
    print $first_cycle->next;  ## prints C

    print $first_cycle->prev;  ## prints B, going back
    print $first_cycle->prev;  ## prints A, going back
    print $first_cycle->prev;  ## prints C, looping forward to last
    print $first_cycle->curr;  ## prints C, at current position

    my $second_cycle = List::Rotation::Cycle->new(@array);  ##  the same object is returned as above
    $first_cycle->reset;       ## reset position
    print $first_cycle->next;  ## prints A
    print $second_cycle->next; ## prints B
    print $first_cycle->next;  ## prints C
    print $second_cycle->next; ## prints A, looping back to beginning

    my $alternation  = List::Rotation::Alternate->new( qw( odd even ) );

    print $alternation->next;  ## prints odd
    print $alternation->next;  ## prints even
    print $alternation->next;  ## prints odd
    $alternation->reset;       ## reset the alternation to first item
    print $alternation->next;  ## prints odd

    my $switch  = List::Rotation::Toggle->new;

    ##  prints even numbers between 2 and 10
    foreach ( 2..10 ) {
        print "$_\n" if $switch->next;
    }

=head1 DESCRIPTION

Use C<List::Rotation> to loop through a list of values.
Once you get to the end of the list, you go back to the beginning.
Alternatively you can walk backwards through your list of values.

C<List::Rotation> is implemented as a Singleton Pattern. You always just
get 1 (the very same) Rotation object if you use the C<new> method several times
with the exact same set of parameters.
This is done by using C<Memoize> on the C<new> method. It returns the same object
for every use of C<new> that comes with the same list of parameters.

The class C<List::Rotation> contains three subclasses:

=over 4

=item C<List::Rotation::Cycle>

Loop through a list of arbitrary values. The list must not be empty.

=item C<List::Rotation::Alternate>

Alternate two values.

=item C<List::Rotation::Toggle>

Toggle between true and false.

=back

=head1 OBJECT METHODS

=over 4

=item new

Create a Cycle object for the list of values in the list.

=item next

Return the next element.

=item prev

Return the previous element.

=item curr

Return the element at the current position.

=item reset

Reset the list to the beginning; the following call of C<next> will return the first item of the list again.

=back

=head1 References

There are several similar modules available:

=over 4

=item C<Tie::FlipFlop>

by Abigail:
Alternate between two values.

=item C<List::Cycle>

by Andi Lester:
Objects for cycling through a list of values

=item C<Tie::Cycle>

by Brian D. Foy:
Cycle through a list of values via a scalar.

=item C<Tie::Toggle>

by Brian D. Foy:
False and true, alternately, ad infinitum.

=back

=head1 AUTHOR

Imre Saling, C<< <pelagicatcpandotorg> >>

=head1 COPYRIGHT and LICENSE

Copyright 2010, Imre Saling, All rights reserved.

This software is available under the same terms as perl.

=cut

