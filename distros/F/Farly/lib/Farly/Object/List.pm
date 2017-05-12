package Farly::Object::List;

use 5.008008;
use strict;
use warnings;
use Carp;

our $VERSION = '0.26';

sub new {
    my ($class) = @_;
    return bless [], $class;
}

sub add {
    my ( $self, $object ) = @_;

    croak "Farly::Object object required"
      unless ( $object->isa('Farly::Object') );

    push @$self, $object;
}

sub iter {
    return @{ $_[0] };
}

sub size {
    return scalar( @{ $_[0] } );
}

sub clone {
    my ($self) = @_;

    my $result = Farly::Object::List->new();

    foreach my $object ( $self->iter() ) {
        $result->add( $object->clone() );
    }

    return $result;
}

sub includes {
    my ( $self, $other ) = @_;

    foreach my $object ( $self->iter() ) {
        if ( $object->matches($other) ) {
            return 1;
        }
    }
}

sub matches {
    my ( $self, $other, $result ) = @_;

    $self->_validate( $other, $result );

    foreach my $object ( $self->iter() ) {
        if ( $object->matches($other) ) {
            $result->add($object);
        }
    }
}

sub contains {
    my ( $self, $other, $result ) = @_;

    $self->_validate( $other, $result );

    foreach my $object ( $self->iter() ) {
        if ( $object->contains($other) ) {
            $result->add($object);
        }
    }
}

sub contained_by {
    my ( $self, $other, $result ) = @_;

    $self->_validate( $other, $result );

    foreach my $object ( $self->iter() ) {
        if ( $object->contained_by($other) ) {
            $result->add($object);
        }
    }
}

sub intersects {
    my ( $self, $other, $result ) = @_;

    $self->_validate( $other, $result );

    foreach my $object ( $self->iter() ) {
        if ( $object->intersects($other) ) {
            $result->add($object);
        }
    }
}

sub search {
    my ( $self, $other, $result ) = @_;

    $self->_validate( $other, $result );

    foreach my $object ( $self->iter() ) {
        if ( $object->matches($other) ) {
            $result->add($object);
        }
        elsif ( $object->contains($other) ) {
            $result->add($object);
        }
        elsif ( $object->contained_by($other) ) {
            $result->add($object);
        }
        elsif ( $object->intersects($other) ) {
            $result->add($object);
        }
    }
}

sub _validate {
    my ( $self, $other, $result ) = @_;

    confess "other not defined"
      unless ( defined $other );

    confess "container for result required"
      unless ( defined $result );

    confess "the search object must be an Farly::Object or Farly::Object::Ref"
      unless ( $other->isa("Farly::Object") );

    confess "the result container must be an Farly::Object::List or Farly::Object::Set"
      unless ( $result->isa("Farly::Object::List") || $result->isa("Farly::Object::Set") );
}

1;
__END__

=head1 NAME

Farly::Object::List - Searchable container of Farly::Objects

=head1 SYNOPSIS

  use Farly::Object::List;
  use Farly::Object;
  use Farly::Value::String;
  
  my $object_1 = Farly::Object->new();
  $object_1->set( "id",        Farly::Value::String->new("id1234") );
  $object_1->set( "last_name", Farly::Value::String->new("Hofstadter") );
  my $object_n = Farly::Object->new();    

  $object_n->set( "id", Farly::Value::String->new("id9999") );

  my $container = Farly::Object::List->new();

  $container->add( $object_1 );
  $container->add( $object_n );

  my $search = Farly::Object->new();
  $search->set( "id", Farly::Value::String->new("id1234") );

  my $search_result = Farly::Object::List->new();

  $container->matches( $search, $search_result );

  foreach my $object ( $search_result->iter() ) {
      print $object->get("last_name")->as_string() if ( $object->has_defined("last_name") );
      print "\n";
  }

=head1 DESCRIPTION

Farly::Object::List is a searchable 'ARRAY' based container of
Farly::Objects.

=head1 METHODS

=head2 new()

The constructor.

   my $container = Farly::Object::List->new();

No arguments.
   
=head2 add( <Farly::Object> )

Add a new Farly::Object object to the container.

  $container->add( $object ); 

=head2 clone()

Return a new Farly::Object::List of cloned Farly::Object objects

  my $new_container = $container->clone(); 

Farly::Object->clone() does not clone the value objects in the
Farly::Object container elements.

=head2 iter()

Returns 'ARRAY' of the Farly::Object container elements.

  my @objects = $container->iter();

=head2 includes( $object<Farly::Object> )

Returns true if an object in this List 'matches' the other object.

  $set1->includes( $object );

=head2 matches( $search<Farly::Object>, $result<Farly::Object::List> )

Store all objects which match $search in $result.

  $container->matches( $search, $result );

=head2 contains( $search<Farly::Object>, $result<Farly::Object::List> )

Store all objects which contain $search in $result.

  $container->contains( $search, $result );

=head2 contained_by( $search<Farly::Object>, $result<Farly::Object::List> )

Store all objects which are contained by $search in $result.

  $container->contained_by( $search, $result );

=head2 search( $search<Farly::Object>, $result<Farly::Object::List> )

Store all objects which match, contain, are contained by, or intersect
$search in $result.

Applies matches, contains, contained_by, and intersects methods in that
order.

  $container->search( $search, $result );

=head2 size()

Returns a count of the number of objects currently in the container.

  my $size = $container->size();

=head1 COPYRIGHT AND LICENCE

Farly::Object::List
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
