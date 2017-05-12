package Farly::IPv4::ICMPType;

use 5.008008;
use strict;
use warnings;
use Carp;

our $VERSION = '0.26';

sub new {
    my ( $class, $type ) = @_;

    confess "type number required" unless ( defined $type );

    $type =~ s/\s+//g;

    confess "$type is not a number"
      unless ( $type =~ /^\d+$/ || $type =~ /^-1$/ );

    confess "invalid type $type"
      unless ( ( $type >= -1 && $type <= 255 ) );

    return bless( \$type, $class );
}

sub type {
    return ${ $_[0] };
}

sub as_string {
    return ${ $_[0] };
}

sub equals {
    my ( $self, $other ) = @_;

    if ( $other->isa('Farly::IPv4::ICMPType') ) {

        return $self->type() == $other->type();
    }
}

sub contains {
    my ( $self, $other ) = @_;

    if ( $other->isa('Farly::IPv4::ICMPType') ) {

        if ( $self->type() == -1 ) {
            return 1;
        }

        return $self->equals($other);
    }
}

sub intersects {
    my ( $self, $other ) = @_;

    if ( $self->contains($other) || $other->contains($self) ) {
        return 1;
    }
}

sub compare {
    my ( $self, $other ) = @_;

    if ( $other->isa('Farly::IPv4::ICMPType') ) {
        return $self->type() <=> $other->type();
    }
}

1;
__END__

=head1 NAME

Farly::IPv4::ICMPType - IPv4 ICMP type class

=head1 DESCRIPTION

Represents an 8 bit ICMP type integer as an object

=head1 METHODS

=head2 new()

The constructor.

   my $type = Farly::IPv4::ICMPType->new( $number );

An digit between -1 and 255 is required.

=head2 type()

Returns the 8 bit ICMP type integer.

  my $8_bit_int = $type->type();

=head2 equals( <Farly::IPv4::ICMPType> )

Returns true if the ICMP types are equal.

  $type->equals( $type_2 );

=head2 contains( <Farly::IPv4::ICMPType> )

Returns true if $type is '-1' (any) ICMP type.
Returns true if the types are equal.

  $type->contains( $type_2 );

=head2 intersects( <Farly::IPv4::ICMPType> )

Returns true if the types are equal.

  $type->intersects( $type_2 );

=head2 as_string()

Returns the string value

  $type->as_string();

=head1 COPYRIGHT AND LICENSE

Farly::IPv4::ICMPType
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
along with this program.  If not, see L<http://www.gnu.org/licenses/>.
