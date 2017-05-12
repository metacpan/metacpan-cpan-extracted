package Farly::Object;

use 5.008008;
use strict;
use warnings;
use Carp;

#Farly containers
use Farly::Object::List;
use Farly::Object::Set;
use Farly::Object::Aggregate;
#Farly reference object
require Farly::Object::Ref;
#Farly value objects
use Farly::Value::String;
use Farly::Value::Integer;
use Farly::IPv4::Address;
use Farly::IPv4::Network;
use Farly::IPv4::Range;
use Farly::IPv4::ICMPType;
use Farly::Transport::Port;
use Farly::Transport::PortGT;
use Farly::Transport::PortLT;
use Farly::Transport::PortRange;
use Farly::Transport::Protocol;

our $VERSION = '0.26';

sub new {
    my ($class) = @_;

    carp "constructor arguments not supported; use 'set'"
      if ( scalar(@_) > 1 );

    return bless {}, $class;
}

sub set {
    my ( $self, $key, $value ) = @_;

    confess "invalid key"
      unless ( defined($key) && length($key) );

    confess "a value object must be defined"
      unless ( defined($value) );

    # reference object, or list (i.e. $self is tree node), or set
    if ( $value->isa('Farly::Object') || $value->isa('Farly::Object::List')
         || $value->isa('Farly::Object::Set') )
    {
        $self->{$key} = $value;
        return;
    }

    # or value object
    confess "$value is not a valid value object type"
      unless ( $value->can('equals')
        && $value->can('contains')
        && $value->can('intersects')
        && $value->can('compare')
        && $value->can('as_string') );

    $self->{$key} = $value;
}

sub get {
    my ( $self, $key ) = @_;
    if ( defined( $self->{$key} ) ) {
        return $self->{$key};
    }
    else {
        confess $self->dump(), "\n undefined key $key. use 'has_defined' to
		  check for the existance of a key/value pair";
    }
}

sub has_defined {
    my ( $self, $key ) = @_;
    return 1 if defined $self->{$key};
}

sub delete_key {
    my ( $self, $key ) = @_;
    delete $self->{$key}
      or carp "key $key delete error";
}

sub get_keys {
    return keys %{ $_[0] };
}

sub equals {
    my ( $self, $other ) = @_;

    if ( $other->isa(__PACKAGE__) ) {

        if ( scalar( keys %$self ) != scalar( keys %$other ) ) {
            return undef;
        }

        return $self->matches($other);
    }
}

sub matches {
    my ( $self, $other ) = @_;

    if ( $other->isa(__PACKAGE__) ) {

        foreach my $key ( keys %$other ) {
            if ( !defined( $self->{$key} ) ) {
                return undef;
            }
            if ( !$self->{$key}->equals( $other->{$key} ) ) {
                return undef;
            }
        }
        return 1;
    }
}

sub intersects {
    my ( $self, $other ) = @_;

    if ( $other->isa(__PACKAGE__) ) {

        foreach my $key ( keys %$other ) {
            if ( !defined( $self->{$key} ) ) {
                return undef;
            }
            if ( !$self->{$key}->intersects( $other->{$key} ) ) {
                return undef;
            }
        }

        return 1;
    }
}

sub contains {
    my ( $self, $other ) = @_;

    if ( $other->isa(__PACKAGE__) ) {

        foreach my $key ( keys %$other ) {
            if ( !defined( $self->{$key} ) ) {
                return undef;
            }
            if ( !$self->{$key}->contains( $other->{$key} ) ) {
                return undef;
            }
        }

        return 1;
    }
}

sub contained_by {
    my ( $self, $other ) = @_;

    if ( $other->isa(__PACKAGE__) ) {

        foreach my $key ( keys %$other ) {
            if ( !defined( $self->{$key} ) ) {
                return undef;
            }
            if ( !$other->{$key}->contains( $self->{$key} ) ) {
                return undef;
            }
        }

        return 1;
    }
}

sub clone {
    my ($self) = @_;
    my %clone = %$self;
    return bless( \%clone, ref $self );
}

sub as_string {
    my ($self) = @_;
    my $string;
    foreach my $key ( sort keys %$self ) {
        $string .= $key . " => " . $self->get($key) . " ";
    }
    return $string;
}

sub dump {
    my ($self) = @_;
    my $string;
    foreach my $key ( sort keys %$self ) {
        $string .=
            $key . " => "
          . ref( $self->get($key) ) . " "
          . $self->get($key)->as_string() . "\n";
    }
    return $string;

}

1;
__END__

=head1 NAME

Farly::Object - Generic Farly entity object 

=head1 SYNOPSIS

  use Farly::Object;
  
  my $object1 = Farly::Object->new();
  my $object2 = Farly::Object->new();
  
  $object1->set( 'id', Farly::Value::String->new('id1234') );
  $object2->set( 'id', Farly::Value::String->new('id1234') );

  print $object1->get( 'id' )->as_string();

  $object1->equals( $object2 ) ? print "Yes, the objects are equal";

=head1 DESCRIPTION

Farly::Object is a generic entity object which can be used to model
a variety of objects without having to write a large number of classes.

Farly::Objects use string keys to set and access value objects.

Value objects must be wrapped in an object supporting the "equals,"
"contains," "intersects," "as_string," and "compare" methods.

The "equals," "contains," and "intersects," methods allow
two Farly::Object object properties to be compared.

The "equals," "contains," and "intersects" methods allow searching
of Farly::Object objects within a Farly::Object::List.

The "compare" method allows Farly::Objects to be easily sorted and
grouped.

=head1 METHODS

=head2 new()

The constructor.

   my $object = Farly::Object->new();

No arguments.
   
=head2 clone()

Returns a new Farly::Object object with the same key value pairs as
the original object.

  my $cloned_object = $object->clone(); 

Does not copy the value objects.

=head2 set( <string>, <value object> )

Set a key value pair.

  $object->set( 'key',  Farly::Value::String->new("string") );

Set throws an exception if the value object does not support
the required methods.

Same as:

  $object->{ 'key' } = Farly::Value::String->new("string");

Without type checking.

=head2 get( <string> )

Get a value object.

  my $value = $object->get( 'key' );

Throws an exception if the specified key if not defined.

Same as:

  my $value = $object->{'key'};

Without checking that the key is defined.

=head2 equals( $other<Farly::Object> )

Returns true if all keys exist in both objects and the
corresponding value objects are equal.

  $object1->equals( $object2 );
  
=head2 matches( $other<Farly::Object> )

Returns true if all keys in $object2 exist in $object1 and the
corresponding value objects are equal.

Returns false if $object2 has a key which does not exist in $object1.

  $object1->matches( $object2 );

=head2 intersects( $other<Farly::Object> )

Returns true if all keys in $object2 exist in $object1 and the
corresponding value objects intersect.

Returns false if $object2 has a key which does not exist in $object1.

  $object1->intersects( $object2 );

=head2 contains( $other<Farly::Object> )

Returns true if all keys in $object2 exist in $object1 and the
corresponding value objects in $object1 contain the corresponding 
value objects in $object2.

Returns false if $object2 has a key which does not exist in $object1.

  $object1->contains( $object2 );

=head2 contained_by( $other<Farly::Object> )

Returns true if all keys in $object2 exist in $object1 and the
corresponding value objects in $object2 contain the corresponding 
value objects in $object1.

Returns false if $object2 has a key which does not exist in $object1.

  $object1->contained_by( $object2 );

=head2 get_keys()

Returns 'ARRAY' of currently defined keys.

  my @keys = $object->get_keys()

Same as:

  my @keys = keys( %$object );

=head2 has_defined( <string> )

Returns true if a key value pair is defined.

  $object->has_defined( 'key' );

Same as:

  defined( $object->{'key'} );

=head2 delete_key( <string> )

Delete a key value pair.

  $object->delete_key( 'key' );

Same as.

  delete( $object->{'key'} );

=head2 as_string()

For debugging only.

=head2 dump()

For debugging only.

  print $object->dump();

=head1 COPYRIGHT AND LICENCE

Farly::Object
Copyright (C) 2013  Trystan Johnson

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
