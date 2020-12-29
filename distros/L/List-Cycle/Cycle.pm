package List::Cycle;

use warnings;
use strict;
use Carp ();

=head1 NAME

List::Cycle - Objects for cycling through a list of values

=head1 VERSION

Version 1.04

=cut

our $VERSION = '1.04';

=head1 SYNOPSIS

List::Cycle gives you an iterator object for cycling through a series
of values.  The canonical use is for cycling through a list of colors
for alternating bands of color on a report.

    use List::Cycle;

    my $colors = List::Cycle->new( {values => ['#000000', '#FAFAFA', '#BADDAD']} );
    print $colors->next; # #000000
    print $colors->next; # #FAFAFA
    print $colors->next; # #BADDAD
    print $colors->next; # #000000
    print $colors->next; # #FAFAFA
    ... etc ...

You'd call it at the top of a loop:

    while ( ... ) {
        my $color = $colors->next;
        print qq{<tr bgcolor="$color">;
        ...
    }

Note that a List::Cycle object is not a standard Perl blessed hash.
It's an inside-out object, as suggested in I<Perl Best Practices>.
In the seven years since I<PBP> has come out, inside-out objects have
been almost universally ignored, but I keep List::Cycle as an example.
If you don't care about the internals of the object, then List::Cycle
is a fine module for you to use.

=head1 FUNCTIONS

=head2 new( {values => \@values} )

Creates a new cycle object, using I<@values>.

The C<values> keyword can be C<vals>, if you like.

=cut

my %storage = (
    values  => \my %values_of,
    pointer => \my %pointer_of,
);

sub new {
    my $class = shift;
    my $args = shift;

    my $self = \do { my $scalar };
    bless $self, $class;

    $self->_init( %{$args} );

    return $self;
}

sub _init {
    my $self = shift;
    my @args = @_;

    $self->_store_pointer( 0 );
    while ( @args ) {
        my $key = shift @args;
        my $value = shift @args;

        if ( $key =~ /^val(?:ue)?s$/ ) {
            $self->set_values($value);
        }
        else {
            Carp::croak( "$key is not a valid constructor value" );
        }
    }

    return $self;
}

=head2 C<< $cycle->set_values(\@values) >>

Sets the cycle values and resets the internal pointer.

=cut

sub set_values {
    my ($self, $values) = @_;

    $values_of{ $self } = $values;
    $self->reset;

    return;
}

sub DESTROY {
    my $self = shift;

    for my $attr_ref ( values %storage ) {
        delete $attr_ref->{$self};
    }

    return;
}

sub _pointer {
    my $self = shift;

    return $pointer_of{ $self };
}

sub _store_pointer {
    my $self = shift;

    $pointer_of{ $self } = shift;

    return;
}

sub _inc_pointer {
    my $self = shift;
    my $ptr  = $self->_pointer;
    $self->_store_pointer(($ptr+1) % @{$values_of{$self}});

    return;
}

=head2 $cycle->reset

Sets the internal pointer back to the beginning of the cycle.

    my $color = List::Cycle->new( {values => [qw(red white blue)]} );
    print $color->next; # red
    print $color->next; # white
    $color->reset;
    print $color->next; # red, not blue

=cut

sub reset {
    my $self = shift;

    $self->_store_pointer(0);

    return;
}

=head2 $cycle->dump

Returns a handy string representation of internals.

=cut

sub dump {
    my $self = shift;
    my $str  = '';

    while ( my($key,$value) = each %storage ) {
        my $realval = $value->{$self};
        $realval = join( ',', @{$realval} ) if UNIVERSAL::isa( $realval, 'ARRAY' );
        $str .= "$key => $realval\n";
    }
    return $str;
}

=head2 $cycle->next

Gives the next value in the sequence.

=cut

sub next {
    my $self = shift;

    Carp::croak( 'no cycle values provided!' ) unless $values_of{ $self };

    my $ptr = $self->_pointer;
    $self->_inc_pointer;
    return $values_of{ $self }[$ptr];
}

=head1 AUTHOR

Andy Lester, C<< <andy at petdance.com> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc List::Cycle

You can also look for information at:

=over 4

=item * Project home page and source code repository

L<https://github.com/petdance/list-cycle>

=item * Issue tracker

L<https://github.com/petdance/list-cycle/issues>

=back

=head1 BUGS

Please report any bugs or feature requests at
L<https://github.com/petdance/list-cycle/issues>.

=head1 ACKNOWLEDGEMENTS

List::Cycle is a playground that uses some of the ideas in Damian Conway's
marvelous I<Perl Best Practices>.  L<http://www.oreilly.com/catalog/perlbp/>
One of the chapters mentions a mythical List::Cycle module, so I made
it real.

Thanks also to Ricardo SIGNES and Todd Rinaldo for patches.

=head1 COPYRIGHT & LICENSE

Copyright 2005-2012 Andy Lester.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License v2.0.

=cut

1; # End of List::Cycle
