package List::Rotation::Cycle;
use vars qw( $VERSION );
$VERSION = 1.009;

use strict;
use warnings;

use Memoize;
memoize('new');

sub new {
    my $class = shift;

    do {
        require Carp;
        Carp::croak ("Incorrect number of arguments; must be >= 1.");
    } unless @_ >= 1;

    my $self = [ @_ ];

    my $closure = sub {
        push @$self, shift  @$self;
        return $self->[-1];
    };

    bless $closure, $class;
}

sub next {
    my $self = shift;
    &{ $self };
}

"List::Rotation::Cycle";


__END__

=head1 NAME

List::Rotation::Cycle - Cycle through a list of values via a singleton object implemented as closure.

=head1 SYNOPSIS

    use List::Rotation::Cycle;

    my @array = qw( A B C );

    my $first_cycle  = List::Rotation::Cycle->new(@array);
    my $second_cycle = List::Rotation::Cycle->new(@array);

    print $first_cycle->next;  ## prints A
    print $second_cycle->next; ## prints B
    print $first_cycle->next;  ## prints C
    print $second_cycle->next; ## prints A, looping back to beginning

=head1 DESCRIPTION

Use C<List::Rotation::Cycle> to loop through a list of values.
Once you get to the end of the list, you go back to the beginning.

C<List::Rotation::Cycle> is implemented as a Singleton Pattern. You always just
get 1 (the very same) Cycle object even if you use the new method several times.
This is done by using C<Memoize> on the C<new> method. It returns the same object
for every use of C<new> that comes with the same List of parameters.

=head1 OBJECT METHODS

=over 4

=item new

Create a Cycle object for the list of values in the list.

=item next

Return the next element.  This method is implemented as a closure.

=back

=head1 AUTHOR

Imre Saling, C<< <pelagicatcpandotorg> >>

=head1 COPYRIGHT and LICENSE

Copyright 2000-2004, Imre Saling, All rights reserved.

This software is available under the same terms as perl.

=cut
