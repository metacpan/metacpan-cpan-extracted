package Farly::Remove::Address;

use 5.008008;
use strict;
use warnings;
use Carp;

our $VERSION = '0.26';

sub new {
    my ( $class, $container ) = @_;

    confess "firewall configuration container object required"
      unless ( defined($container) );

    confess "Farly::Object::List object required"
      unless ( $container->isa("Farly::Object::List") );

    my $self = {
        FW     => $container,
        REMOVE => Farly::Object::List->new(),
    };
    bless $self, $class;

    return $self;
}

sub fw { return $_[0]->{FW} }

# remove can be called many times
# all objects in {REMOVE} need to be removed from {FW}
sub remove {
    my ( $self, $ip ) = @_;

    confess "ip not defined" unless defined($ip);

    confess "Farly::IPv4::Address address required"
      unless defined( $ip->isa('Farly::IPv4::Address') );

    #print "\nsearching for references to ", $ip->as_string, "...\n";

    my $garbage_list = $self->_address_search($ip);

    my $objects_for_cleanup = $self->_collect_garbage($garbage_list);

    if ( $objects_for_cleanup->size() != 0 ) {

        #print "\nstoring removed objects in reverse order\n\n";
        $self->_add_reversed_list($objects_for_cleanup);
        $self->_cleanup();
    }
}

sub result { return $_[0]->{REMOVE} }

# all objects being removed will have been marked with the
# 'REMOVE' property.  Update the $self->{CONFIG} container to
# exclude all objects which are being removed. This allows
# the remove() method to be called multiple times for the
# same configuration.
sub _cleanup {
    my ($self) = @_;

    my $new_list = Farly::Object::List->new();

    foreach my $object ( $self->fw->iter() ) {

        #print $object->dump(),"\n";
        if ( !$object->has_defined('REMOVE') ) {
            $new_list->add($object);
        }
    }

    $self->{FW} = $new_list;
}

sub _address_search {
    my ( $self, $ip ) = @_;

    my $fw = $self->{FW};

    my $search        = Farly::Object->new();
    my $search_result = Farly::Object::List->new();

    $search->set( "OBJECT", $ip );
    $fw->contained_by( $search, $search_result );
    $search->delete_key("OBJECT");

    $search->set( "SRC_IP", $ip );
    $fw->contained_by( $search, $search_result );
    $search->delete_key("SRC_IP");

    $search->set( "DST_IP", $ip );
    $fw->contained_by( $search, $search_result );

    return $search_result;
}

sub _collect_garbage {
    my ( $self, $garbage_list ) = @_;

    my $fw = $self->{CONFIG};

    my $agg = Farly::Object::Aggregate->new( $self->fw );
    $agg->groupby( 'ENTRY', 'ID' );

    my $NAME      = Farly::Value::String->new('NAME');
    my $GROUP     = Farly::Value::String->new('GROUP');
    my $RULE      = Farly::Value::String->new('RULE');
    my $OBJECT    = Farly::Value::String->new('OBJECT');
    my $INTERFACE = Farly::Value::String->new('INTERFACE');
    my $ROUTE     = Farly::Value::String->new('ROUTE');

    my @stack;
    my $remove = Farly::Object::List->new();

    push @stack, $garbage_list->iter();

    while (@stack) {

        my $object = pop @stack;

        if ( $object->get('ENTRY')->equals($GROUP) ) {

            # convert the $object to a reference object
            my $ref_obj = $self->_create_reference($object);

            #it's a group, check the size
            my $actual = $agg->matches($ref_obj);

            if ( !defined $actual ) {
                confess "error ", $object->dump(), " actual not found";
            }

            # if the size of the group is 1 all references to the
            # group must be removed first
            if ( $actual->size == 1 ) {

                # if the group can be removed no members of that group
                # should be in $remove, i.e. the group has already been
                # emptied out so take all other group member objects out
                # of remove
                $remove = $self->_remove_copy( $remove, $ref_obj );

                $object->set( 'REMOVE', Farly::Value::String->new('GROUP') );
                $remove->add($object);

             # each referring object must be checked to see if it can be removed
             # all references to 'object' will be in @remove after 'object'

                my @result = $self->_reference_search($ref_obj);
                push @stack, @result;
            }
            else {

                # group size > 1

              # create a new ::Set, minus the group member $object to be removed
                my $new_set = $self->_remove_copy( $actual, $object );

                # update the index to reflect that $object is removed
                # because more objects could be removed from the group later on
                $agg->update( $ref_obj, $new_set );

                $object->set( 'REMOVE', Farly::Value::String->new('OBJECT') );
                $remove->add($object);
            }

        }
        elsif ( $object->get('ENTRY')->equals($OBJECT) ) {

            # set the object to be removed
            $object->set( 'REMOVE', Farly::Value::String->new('OBJECT') );
            $remove->add($object);

            # reformat the object into a reference object
            my $ref_obj = $self->_create_reference($object);

            # find everything that references the removed object
            my @result = $self->_reference_search($ref_obj);
            push @stack, @result;

        }
        elsif ( $object->get('ENTRY')->equals($RULE) ) {

            # rules which refer to the Address directly can be removed
            # immediately
            $object->set( 'REMOVE', Farly::Value::String->new('RULE') );
            $remove->add($object);

        }
        elsif ( $object->get('ENTRY')->equals($NAME) ) {
            next;
        }
        elsif ( $object->get('ENTRY')->equals($INTERFACE) ) {
            next;
        }
        elsif ( $object->get('ENTRY')->equals($ROUTE) ) {
            next;
        }
        else {
            warn "\nunknown object:\n", $object->dump();
            next;
        }
    }

    return $remove;
}

# convert an object into a reference object
sub _create_reference {
    my ( $self, $object ) = @_;

    my $ref = Farly::Object::Ref->new();
    $ref->set( 'ENTRY', $object->get('ENTRY') );
    $ref->set( 'ID',    $object->get('ID') );

    return $ref;
}

# find every object which refers to $search
sub _reference_search {
    my ( $self, $search ) = @_;

    my @search_result;

    foreach my $object ( $self->fw->iter ) {
        foreach my $property ( $object->get_keys ) {
            if ( $object->get($property)->equals($search) ) {
                push @search_result, $object;
            }
        }
    }

    return @search_result;
}

# Copies the objects in $set into a new ::Set, except for the objects
# that match $remove, which are not copied.
sub _remove_copy {
    my ( $self, $set, $remove ) = @_;

    my $r = Farly::Object::List->new();

    foreach my $object ( $set->iter ) {
        if ( !$object->matches($remove) ) {
            $r->add($object);
        }
    }

    return $r;
}

# reverse the order of the remove list
# objects to remove must be processed last in first out order
# because they where pushed on the @remove array
sub _add_reversed_list {
    my ( $self, $remove ) = @_;

    for ( my $i = $remove->size() - 1 ; $i >= 0 ; $i-- ) {
        $remove->[$i]->delete_key('LINE') if $remove->[$i]->has_defined('LINE');
        $self->result->add( $remove->[$i] );
    }
}

1;
__END__

=head1 NAME

Farly::Remove::Address - Remove an address or network from the firewall model

=head1 DESCRIPTION

Farly::Remove::Address removes a specified address or network from the firewall
configuration, taking into account configuration dependencies. For example, if
a group becomes empty as a result of removing the given IP address then all
firewall rules refering to the now empty group willl be removed before the
group is removed.

=head1 METHODS

=head2 new( $list<Farly::Object::List<Farly::Object>> )

The constructor. A firewall configuration $list must be provided.

  $remover = Farly::Remove::Address->new( $list );

=head2 remove( $ip<Farly::IPv4::Object> )

Resolves dependencies and removes the specified IP object from the 
current Farly firewall model.

  $remover->remove( $ip );

The remove method may be called for multiple IP addresses.

=head2 result()

Returns a Farly::Object::List<Farly::Object> object containing all objects
which need to be removed from the current Farly firewall model in order to
remove all references to the specified addresses.

  $remove_result_set = $remover->result();

=head1 COPYRIGHT AND LICENCE

Farly::Remove::Address
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
