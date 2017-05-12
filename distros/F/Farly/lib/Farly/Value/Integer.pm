package Farly::Value::Integer;

use 5.008008;
use strict;
use warnings;
use Carp;

our $VERSION = '0.26';

sub new {
    my ( $class, $number ) = @_;

    confess "integer required"
      unless defined($number);

    $number =~ s/^\s+|\s+$//g;

    confess "not an integer"
      unless ( $number =~ /^\d+$/ );

    return bless( \$number, $class );
}

sub number { return ${ $_[0] } }

sub as_string { return ${ $_[0] } }

sub equals {
    my ( $self, $other ) = @_;

    if ( $other->isa('Farly::Value::Integer') ) {
        return $self->number() == $other->number();
    }
}

sub contains {
    my ( $self, $other ) = @_;
    return $self->equals($other);
}

sub intersects {
    my ( $self, $other ) = @_;
    return $self->equals($other);
}

sub compare {
    my ( $self, $other ) = @_;

    if ( $other->isa('Farly::Value::Integer') ) {
        return $self->number() <=> $other->number();
    }
}

sub gt {
    my ( $self, $other ) = @_;

    if ( $other->isa('Farly::Value::Integer') ) {
        return $self->number() > $other->number();
    }
}

sub lt {
    my ( $self, $other ) = @_;

    if ( $other->isa('Farly::Value::Integer') ) {
        return $self->number() < $other->number();
    }
}

sub incr {
    ${ $_[0] }++;
}

sub decr {
    ${ $_[0] }--;
}

1;
__END__

=head1 NAME

Farly::Value::Integer - Integer value class

=head1 SYNOPSIS

  use Farly::Value::Integer;
  
  my $integer_1 = Farly::Value::Integer->new( 2 );
  my $integer_2 = Farly::Value::Integer->new( 3 );

  print $integer_1->as_string();

  $integer_1->equals( $integer_2 ) ? print "Yes, the objects are equal";

=head1 DESCRIPTION

Farly::Value::Integer is a integer wrapper class for use as a value
object in a Farly::Object.

=head1 METHODS

=head2 new( integer )

The constructor.

   my $integer = Farly::Value::Integer->new( 345 );

Integer to be wrapped must be provided as an argument. Leading and trailing
whitespace is stripped.

=head2 equals( <Farly::Value::Integer> )

Returns true if the wrapped integers are '=='

  $integer_1->equals( $integer_2 );

=head2 contains( <Farly::Value::Integer> )

Returns true if the wrapped integers are '=='

  $integer_1->contains( $integer_2 );

=head2 intersects( <Farly::Value::Integer> )

Returns true if the wrapped strings are '=='

  $integer_1->intersects( $integer_2 );

=head2 gt( <Farly::Value::Integer> )

Returns true if this integer object is '>' other

  $integer_1->gt( $integer_2 );

=head2 lt( <Farly::Value::Integer> )

Returns true if this integer object is '<' other

  $integer_1->lt( $integer_2 );

=head2 incr( <Farly::Value::Integer> )

Add 1 to the integer. '++'

  $integer_1->incr();

=head2 decr( <Farly::Value::Integer> )

Subtract 1 from the integer. '--'

  $integer_1->decr();

=head2 number()

Returns the integer value

  $integer_1->number();
  
=head2 as_string()

Returns the integer value

  $integer_1->as_string();

=head1 COPYRIGHT AND LICENCE

Farly::Value::Integer
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
