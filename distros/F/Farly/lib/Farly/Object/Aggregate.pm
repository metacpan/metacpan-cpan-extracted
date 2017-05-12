package Farly::Object::Aggregate;
use 5.008008;
use strict;
use warnings;
use Carp;
require Exporter;
require Farly::Object::List;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(NEXTVAL);

our $VERSION = '0.26';

sub new {
    my ( $class, $container ) = @_;

    confess "container object required"
      unless ( defined($container) );

    confess "Farly::Object::List object required"
      unless ( $container->isa('Farly::Object::List') );

    my $self = {
        CONTAINER => $container,    # input
        GROUPED   => undef,         # @array of objects grouped by identity
    };

    bless $self, $class;

    return $self;
}

sub container {
    return $_[0]->{'CONTAINER'};
}

sub iter {
    return @{ $_[0]->{'GROUPED'} };
}

sub NEXTVAL { $_[0]->() }

# iterator over the aggregate identities
sub id_iterator {
    my ($self) = @_;

    my @arr = $self->iter();
    my $i   = 0;

    # the iterator code ref
    return sub {
        return undef if ( $i == scalar(@arr) );

        my $object = Farly::Object->new();

        foreach my $property ( $arr[$i]->get_keys() ) {
            if ( $property ne '__AGG__' ) {
                $object->set( $property, $arr[$i]->get($property) );
            }
        }

        $i++;

        return $object;
      }
}

sub list_iterator {
    my ($self) = @_;

    my @arr = $self->iter();
    my $i   = 0;

    # the iterator code ref
    return sub {
        return undef if ( $i == scalar(@arr) );
        my $set = $arr[$i]->get('__AGG__');
        $i++;
        return $set;
      }
}

# CONTAINER objects which have defined all keys
# return \@array
sub _has_defined_keys {
    my ( $self, $keys ) = @_;

    my @r;

    foreach my $obj ( $self->container->iter() ) {

        my $all_keys_defined = 1;

        foreach my $key (@$keys) {
            if ( !$obj->has_defined($key) ) {
                $all_keys_defined = undef;
                last;
            }
            if ( !$obj->get($key)->can('compare') ) {

                #warn "$self skipped ", $obj->dump(), " in groupby\n";
                $all_keys_defined = undef;
                last;
            }
        }

        if ($all_keys_defined) {
            push @r, $obj;
        }
    }

    return \@r;
}

# [ {  KEY1 => value object,
#      KEY2 => value object,
#   __AGG__ => Farly::Object::List }, ]
# __AGG__ is a set of all objects sharing the
# common identity formed by KEY1 and KEY2,
# i.e $obj1->{KEY1} equals $obj2->{KEY1}
# and $obj1->{KEY2} equals $obj2->{KEY2}
# for all objects in __AGG__

sub groupby {
    my ($self) = shift;
    my @keys = @_;

    confess "a list of keys is required"
      unless ( scalar(@keys) > 0 );

    # $list will include objects that have defined all @keys
    my $list = $self->_has_defined_keys( \@keys );

    # check list size?

    my @sorted = sort {

        my $r;
        foreach my $key (@keys) {
            $r = $a->get($key)->compare( $b->get($key) );
            return $r if ( $r != 0 );
        }
        return $r;

    } @$list;

    my @grouped;

    for ( my $i = 0 ; $i != scalar(@sorted) ; $i++ ) {

        my $root = Farly::Object->new();

        foreach my $key (@keys) {
            $root->set( $key, $sorted[$i]->get($key) );
        }

        my $result = Farly::Object::List->new();

        my $j = $i;

        while ( $sorted[$j]->matches($root) ) {

            $result->add( $sorted[$j] );

            $j++;

            last() if $j == scalar(@sorted);
        }

        $i = $j - 1;

        $root->set( '__AGG__', $result );

        push @grouped, $root;
    }

    $self->{'GROUPED'} = \@grouped;
}

# input = search object
# return the __AGG__ object on first match
sub matches {
    my ( $self, $search ) = @_;

    foreach my $object ( $self->iter() ) {
        if ( $object->matches($search) ) {
            return $object->get('__AGG__');
        }
    }

    #return an empty List on no match
    return Farly::Object::List->new();
}

# input = search object and new __AGG__
sub update {
    my ( $self, $search, $list ) = @_;

    confess "Farly::Object::List required"
      unless defined($list);

    confess "Farly::Object::List required"
      unless $list->isa('Farly::Object::List');

    foreach my $object ( $self->iter() ) {
        if ( $object->matches($search) ) {
            $object->set( '__AGG__', $list );
            return;
        }
    }

    confess $search->dump(), " not found";
}

1;
__END__

=head1 NAME

Farly::Object::Aggregate - Group Farly::Objects with common identity

=head1 SYNOPSIS

  use Farly::Object;
 
  my $list = Farly::Object::List->new();
 
  my $object1 = Farly::Object->new();
  my $object2 = Farly::Object->new();
  
  $object1->set( 'id', Farly::Value::String->new('id1234') );
  $object2->set( 'id', Farly::Value::String->new('id1234') );
  .
  .
  .
  More $object attributes
  
  $list->add($object1);
  $list->add($object2);
 
  my $aggregate = Farly::Object::Aggregate->new( $list );
  $aggregate->groupby( 'id' );

  my $id = Farly::Object->new();
  $id->set( 'id', Farly::Value::String->new('id1234') );

  my $list = $aggregate->matches( $id );

=head1 DESCRIPTION

Farly::Object::Aggregate groups Farly::Objects with a common
identity (i.e. equal key/value pairs) into Farly::Object::Lists.

=head1 METHODS

=head2 new()

The constructor. An Farly::Object::List must be provided.

  $aggregate = Farly::Object::Aggregate->new( $list<Farly::Object::List> );

=head2 groupby( 'key1', 'key2', 'key3' ... )

All objects in the supplied list of keys, with equal value objects for the 
specified keys, will be grouped into a Farly::Object::List. 

  $aggregate->groupby( 'key1', 'key2', 'key3' );

Farly::Objects without the specified property/key will be skipped.

=head2 matches( $search<Farly::Object> )

Return the Farly::Object::List with the specified identity.

  $set = $aggregate->matches( $identity<Farly::Object> );

=head2 update( $search<Farly::Object>, $new_list<Farly::Object::List> )

Search for the identity specified by $search and update the aggregate object
with the new Farly::Object::List.

  $set = $aggregate->matches( $identity<Farly::Object> );

=head2 iter()

Return an array of aggregate objects.

  @objects = $aggregate->iter();

=head2 list_iterator()

Return an iterator code reference to an iterator function which iterates over
all aggregate objects defined in the Farly::Object::Aggregate. Each aggregate
contains objects with the same identity as defined by the 'groupby' method.

  use Farly::Object::Aggregate qw(NEXTVAL);
  
  $it = $aggregate->list_iterator()

=head2 id_iterator()

Return a code reference to an iterator function which iterates over
all identities defined in the aggregate. The identities are Farly::Objects with
the identity as defined by the 'groupby' method.

  use Farly::Object::Aggregate qw(NEXTVAL);
  
  $it = $aggregate->id_iterator()

=head1 FUNCTIONS

=head2 NEXTVAL()

Advance the iterator to the next object.

  while ( my $list = NEXTVAL($it) ) {
      # do something with $list
  }

=head1 COPYRIGHT AND LICENCE

Farly::Object::Aggregate
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
