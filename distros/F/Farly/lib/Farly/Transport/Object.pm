package Farly::Transport::Object;

use 5.008008;
use strict;
use warnings;

our $VERSION = '0.26';

sub size {
    return $_[0]->last - $_[0]->first;
}

sub equals {
    my ( $self, $other ) = @_;

    if ( $other->isa('Farly::Transport::Object') ) {

        return $self->first == $other->first
          && $self->last == $other->last;
    }
}

sub contains {
    my ( $self, $other ) = @_;

    if ( $other->isa('Farly::Transport::Object') ) {

        return $self->first <= $other->first
          && $self->last >= $other->last;
    }
}

sub intersects {
    my ( $self, $other ) = @_;

    if ( $other->isa('Farly::Transport::Object') ) {

        return ( $self->first <= $other->first && $other->first <= $self->last )
          || ( $self->first <= $other->last && $other->last <= $self->last )
          || ( $other->first <= $self->first && $self->first <= $other->last );
    }
}

sub gt {
    my ( $self, $other ) = @_;

    if ( $other->isa('Farly::Transport::Object') ) {

        return $self->first > $other->last;
    }
}

sub lt {
    my ( $self, $other ) = @_;

    if ( $other->isa('Farly::Transport::Object') ) {

        return $self->last < $other->first;
    }
}

sub adjacent {
    my ( $self, $other ) = @_;

    if ( $other->isa('Farly::Transport::Object') ) {

        return $self->size() == $other->size()
          && ( $self->last + 1 ) == $other->first;
    }
}

sub compare {
    my ( $self, $other ) = @_;

    if ( $other->isa('Farly::Transport::Object') ) {

        return ( $self->first() <=> $other->first()
              || $other->last() <=> $self->last() );
    }
}

1;
__END__

=head1 NAME

Farly::Transport::Object - Transport base class

=head1 DESCRIPTION

This is an abstract base class for Farly::Transport classes. It can not be used directly.

=head1 METHODS
  
=head2 adjacent( <Farly::Transport::Object> )

Returns true if current Transport object is adjacent to the other Transport object

  $port_range->adjacent( $port );

=head2 contains( <Farly::Transport::Object> )

Returns true if current Transport object contains the other Transport object

  $port_range->contains( $port );

=head2 equals( <Farly::Transport::Object> )

Returns true if current Transport object contains the other Transport object

  $port_1->equals( $port_2 );

=head2 intersects( <Farly::Transport::Object> )

Returns true if current Transport object intersects the other Transport object

  $port_range_1->intersects( $port_range_2 );

=head2 gt( <Farly::Transport::Object> )

Returns true if current Transport object port or ports are greater
than the other Transport object port or ports.

  $port_range->gt( $port );

=head2 lt( <Farly::Transport::Object> )

Returns true if current Transport object port or ports are less
than the other Transport object port or ports.

  $port_range->lt( $port );

=head2 size( <Farly::Transport::Object> )

Returns the number of ports represented by the current Transport object

  my $number_of_ports = $port_range->size();

=head1 COPYRIGHT AND LICENSE

Farly::Transport::Object
Copyright (C) 2012  Trystan Johnson

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
