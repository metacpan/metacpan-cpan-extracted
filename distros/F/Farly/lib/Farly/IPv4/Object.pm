package Farly::IPv4::Object;

use 5.008008;
use strict;
use warnings;
use Carp;

our $VERSION = '0.26';

sub size {
    my ($self) = @_;
    return $self->last - $self->first + 1;
}

sub equals {
    my ( $self, $other ) = @_;

    if ( $other->isa('Farly::IPv4::Object') ) {

        return $self->first == $other->first
          && $self->last == $other->last
          && $self->size == $other->size;
    }
}

sub contains {
    my ( $self, $other ) = @_;

    if ( $other->isa('Farly::IPv4::Object') ) {

        return $self->first <= $other->first
          && $self->last >= $other->last;
    }
}

sub intersects {
    my ( $self, $other ) = @_;

    if ( $other->isa('Farly::IPv4::Object') ) {

        return ( $self->first <= $other->first && $other->first <= $self->last )
          || ( $self->first <= $other->last && $other->last <= $self->last )
          || ( $other->first <= $self->first && $self->first <= $other->last );
    }
}

sub gt {
    my ( $self, $other ) = @_;

    if ( $other->isa('Farly::IPv4::Object') ) {

        return $self->first > $other->last;
    }
}

sub lt {
    my ( $self, $other ) = @_;

    if ( $other->isa('Farly::IPv4::Object') ) {

        return $self->last < $other->first;
    }
}

sub adjacent {
    my ( $self, $other ) = @_;

    if ( $other->isa('Farly::IPv4::Object') ) {

        return ( ( $self->last + 1 ) == $other->first )
          || ( ( $other->last + 1 ) == $self->first );
    }
}

sub compare {
    my ( $self, $other ) = @_;

    if ( $other->isa('Farly::IPv4::Object') ) {

        return ( $self->first() <=> $other->first()
              || $other->last() <=> $self->last() );
    }
}

1;
__END__

=head1 NAME

Farly::IPv4::Object - IPv4 base class

=head1 DESCRIPTION

This is a base class for Farly::IPv4 classes. It can not be used directly.

=head1 METHODS
  
=head2 adjacent( <Farly::IPv4::Object> )

Returns true if current IPv4 object is adjacent to the other IPv4 object

  $ip_network->adjacent( $ip_range );

=head2 contains( <Farly::IPv4::Object> )

Returns true if current IPv4 object contains the other IPv4 object

  $ip_network->contains( $ip_address );

=head2 equals( <Farly::IPv4::Object> )

Returns true if current IPv4 object contains the other IPv4 object

  $ip_network_1->equals( $ip_network_2 );

=head2 intersects( <Farly::IPv4::Object> )

Returns true if current IPv4 object intersects the other IPv4 object

  $ip_range_1->intersects( $ip_range_2 );

=head2 gt( <Farly::IPv4::Object> )

Returns true if current IPv4 object address or addresses are greater
than the other IPv4 object address or addresses.

  $ip_network->gt( $ip_range );

=head2 lt( <Farly::IPv4::Object> )

Returns true if current IPv4 object address or addresses are less
than the other IPv4 object address or addresses.

  $ip_address->lt( $ip_network );

=head2 size( <Farly::IPv4::Object> )

Returns the number of IP addresses represented by the current IPv4 object

  my $number_of_addresses = $ip_network->size();

=head1 COPYRIGHT AND LICENSE

Farly::IPv4::Object
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
