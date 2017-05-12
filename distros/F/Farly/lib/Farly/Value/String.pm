package Farly::Value::String;

use 5.008008;
use strict;
use warnings;
use Carp;

our $VERSION = '0.26';

sub new {
    my ( $class, $string ) = @_;

    confess "string required"
      unless defined($string);

    $string =~ s/^\s+|\s+$//g;

    return bless( \$string, $class );
}

sub as_string { return ${ $_[0] } }

sub equals {
    my ( $self, $other ) = @_;

    if ( $other->isa('Farly::Value::String') ) {
        return $self->as_string() eq $other->as_string();
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

    if ( $other->isa('Farly::Value::String') ) {
        return $self->as_string() cmp $other->as_string();
    }
}

1;
__END__

=head1 NAME

Farly::Value::String - String value class

=head1 SYNOPSIS

  use Farly::Value::String;
  
  my $string_1 = Farly::Value::String->new("some string");
  my $string_2 = Farly::Value::String->new("some string");

  print $string_1->as_string();

  $string_1->equals( $string_2 ) ? print "Yes, the objects are equal";

=head1 DESCRIPTION

Farly::Value::String is a string wrapper class for use as a value
object in a Farly::Object.

=head1 METHODS

=head2 new( 'string' )

The constructor.

   my $string = Farly::Value::String->new( "string" );

String to be wrapped must be provided as an argument. Leading and trailing
whitespace is stripped.

=head2 equals( <Farly::Value::String> )

Returns true if the wrapped strings are 'eq'

  $string_1->equals( $string_2 );

=head2 contains( <Farly::Value::String> )

Returns true if the wrapped strings are 'eq'

  $string_1->contains( $string_2 );

=head2 intersects( <Farly::Value::String> )

Returns true if the wrapped strings are 'eq'

  $string_1->intersects( $string_2 );

=head2 as_string()

Returns the string value

  $string_1->as_string();

=head1 COPYRIGHT AND LICENCE

Farly::Value::String
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
