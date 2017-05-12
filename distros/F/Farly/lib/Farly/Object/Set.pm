package Farly::Object::Set;

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
      unless ( defined $object );

    croak "Farly::Object object required"
      unless ( $object->isa('Farly::Object') );

    push @{$self}, $object;
}

sub size {
    return scalar( @{ $_[0] } );
}

sub iter {
    return @{ $_[0] };
}

sub equals {
    my ( $self, $other ) = @_;

    if ( $other->isa(__PACKAGE__) ) {

        if ( $self->size() != $other->size() ) {
            return undef;
        }

        foreach my $s ( $self->iter() ) {
            my $match;
            foreach my $o ( $other->iter() ) {
                if ( $s->equals($o) ) {
                    $match = 1;
                }
            }
            if ( !$match ) {
                return undef;
            }
        }

        return 1;
    }
}

sub contains {
    my ( $self, $other ) = @_;

    if ( $other->isa(__PACKAGE__) ) {

        foreach my $o ( $other->iter() ) {
            my $contained;
            foreach my $s ( $self->iter() ) {
                if ( $s->contains($o) ) {
                    $contained = 1;
                    last;
                }
            }
            if ( !$contained ) {
                return undef;
            }
        }
        return 1;
    }

    if ( $other->isa('Farly::Object') ) {
        foreach my $s ( $self->iter() ) {
            return 1 if ( $s->contains($other) );
        }
    }
}

sub includes {
    my ( $self, $other ) = @_;

    if ( $other->isa(__PACKAGE__) ) {

        foreach my $o ( $other->iter() ) {
            my $included;
            foreach my $s ( $self->iter() ) {
                if ( $s->matches($o) ) {
                    $included = 1;
                    last;
                }
            }
            if ( !$included ) {
                return undef;
            }
        }
        return 1;
    }

    if ( $other->isa('Farly::Object') ) {
        foreach my $s ( $self->iter() ) {
            if ( $s->matches($other) ) {
                return 1;
            }
        }
    }
}

sub intersects {
    my ( $self, $other ) = @_;
    return 1 if ( $self->intersection($other)->size() >= 1 );
}

sub intersection {
    my ( $self, $other ) = @_;

    confess "Set required"
      unless $other->isa(__PACKAGE__);

    my $isect = __PACKAGE__->new();

    foreach my $s ( $self->iter() ) {
        foreach my $o ( $other->iter() ) {
            if ( $s->matches($o) ) {
                $isect->add($s);
                last;
            }
        }
    }

    return $isect;
}

sub union {
    my ( $self, $other ) = @_;

    confess "Set required"
      unless $other->isa(__PACKAGE__);

    my $union = __PACKAGE__->new();

    foreach my $s ( $self->iter() ) {
        $union->add($s);
    }

    foreach my $o ( $other->iter() ) {
        if ( !$union->includes($o) ) {
            $union->add($o);
        }
    }

    return $union;
}

sub disjoint {
    my ( $self, $other ) = @_;
    my $isect = $self->intersection($other);
    return $isect->size() == 0;
}

sub difference {
    my ( $self, $other ) = @_;

    confess "Set required"
      unless $other->isa(__PACKAGE__);

    my $diff = __PACKAGE__->new();

    foreach my $s ( $self->iter() ) {
        my $in_other;
        foreach my $o ( $other->iter() ) {
            if ( $s->matches($o) ) {
                $in_other = 1;
                last;
            }
        }
        if ( !$in_other ) {
            $diff->add($s);
        }
    }

    return $diff;
}

sub as_string {
    my ($self) = @_;

    #carp "called as_string on Set";
    my $string;
    foreach my $s ( $self->iter() ) {
        $string .= $s->as_string() . " ";
    }
    return $string;
}

1;
__END__

=head1 NAME

Farly::Object::Set - Set calculations on Farly::Objects

=head1 SYNOPSIS

  use Farly::Object::Set;
  use Farly::Object;
  
  my $object_1 = Farly::Object->new();
  $object_1->set( "id", Farly::Value::String->new("id1234") );
  
  my $object_n = Farly::Object->new();    
  $object_n->set( "id", Farly::Value::String->new("id1234") );

  my $set1 = Farly::Object::Set->new();
  my $set2 = Farly::Object::Set->new();

  $set1->add( $object_1 );
  $set2->add( $object_n );

  my $intersection = $set1->intersection($set2);

  foreach my $object ( $intersection->iter() ) {
      print $object->get("id")->as_string() if ( $object->has_defined("id") );
      print "\n";
  }

=head1 DESCRIPTION

List based Set calculations on an arrays of Farly::Objects.

=head1 METHODS

=head2 new()

The constructor.

  my $set = Farly::Object::Set->new();

No arguments.
   
=head2 add( <object> )

Add a new Farly::Object object to the Set.

  $set->add( $object ); 

=head2 iter()

Returns 'ARRAY' of the Set members.

  my @objects = $set->iter();

=head2 size()

Returns integer value of the Set cardinality.

  my $set_size = $set1->size();

=head2 equals( $set<Farly::Object::Set> )

Returns true if both sets are the same size and every object
in this Set has an equal object in the other Set.

  $set1->equals($set2);

=head2 contains( $set<Farly::Object::Set> or $object<Farly::Object> )

Returns true if objects in this Set 'contains' every object in the
other Set.

  $set1->contains( $set2 );

Returns true if an object in this Set 'contains' the other object.

  $set1->contains( $object );

=head2 includes( $set<Farly::Object::Set> or $other<Farly::Object> )

Returns true if objects in this Set 'matches' every object in the
other Set.

  $set1->includes( $set2 );

Returns true if an object in this Set 'matches' the other object.

  $set1->includes( $object );

=head2 difference( $set<Farly::Object::Set> )
 
Returns a Set with the relative complement, which is the set of 
objects in self, but not in other.

  $set1->difference( $set2 );

=head2 disjoint( $set<Farly::Object::Set> )

Returns true if the Sets are disjoint.

  $set1->disjoint( $set2 );

=head2 intersects( $set<Farly::Object::Set> )

Returns true if the Sets intersect.

  $set1->intersects( $set2 );

=head2 intersection( $set<Farly::Object::Set> )

Returns a Set containing the objects which exist in both Sets.

  $intersection = $set1->intersection( $set2 );

=head2 union( $set<Farly::Object::Set> )

Returns a Set containing all the objects which exist in both Sets.

  $union = $set1->union( $set2 );

=head1 COPYRIGHT AND LICENCE

Farly::Object::Set
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
