package Farly::Remove::Rule;

use 5.008008;
use strict;
use warnings;
use Carp;
use Farly::Object::Aggregate qw(NEXTVAL);

our $VERSION = '0.26';

sub new {
    my ( $class, $list ) = @_;

    confess "configuration Farly::Object::List required"
      unless ( defined($list) );

    confess "configuration Farly::Object::List required"
      unless ( $list->isa("Farly::Object::List") );

    my $self = {
        FW     => $list,
        RESULT => Farly::Object::List->new(),
    };
    bless $self, $class;

    return $self;
}

sub fw     { return $_[0]->{FW} }
sub result { return $_[0]->{RESULT} }

sub _removes {
    my ( $self, $list ) = @_;

    my $remove = Farly::Object::List->new();

    foreach my $rule ( $list->iter() ) {
        if ( $rule->has_defined('REMOVE') ) {
            $remove->add($rule);
        }
    }

    return $remove;
}

sub _keeps {
    my ( $self, $list ) = @_;

    my $keep = Farly::Object::List->new();

    foreach my $rule ( $list->iter() ) {
        if ( !$rule->has_defined('REMOVE') ) {
            $keep->add($rule);
        }
    }

    return $keep;
}

# convert an object into a reference object
sub _create_ref {
    my ( $self, $object ) = @_;

    my $ref = Farly::Object::Ref->new();
    $ref->set( 'ENTRY', $object->get('ENTRY') );
    $ref->set( 'ID',    $object->get('ID') );

    return $ref;
}

sub _is_expanded {
    my ( $self, $list ) = @_;

    foreach my $object ( $list->iter() ) {
        foreach my $property ( $object->get_keys() ) {
            if ( $object->get($property)->isa('Farly::Object') ) {
                confess "an expanded rule set is required";
            }
        }
    }
}

sub _is_unique {
    my ( $self, $id, $list ) = @_;

    foreach my $object ( $list->iter() ) {
        if ( !$object->matches($id) ) {
            die "list is not unique";
        }
    }
}

sub _aggregate {
    my ( $self, $list ) = @_;
    my $agg = Farly::Object::Aggregate->new($list);
    $agg->groupby( 'ENTRY', 'ID', 'LINE' );
    return $agg;
}

sub remove {
    my ( $self, $list ) = @_;

    my $rule_id = $self->_create_ref( $list->[0] );

    # validate list
    $self->_is_unique( $rule_id, $list );
    $self->_is_expanded($list);

    # get the config rules
    my $cfg_rules = Farly::Object::List->new();
    $self->fw->matches( $rule_id, $cfg_rules );

    # remove_agg will have the list of entries to be removed
    my $remove_agg = $self->_aggregate( $self->_removes($list) );

    # keep_agg will have the set of entries which need to be kept
    my $keep_agg = $self->_aggregate( $self->_keeps($list) );

    my $it = $remove_agg->id_iterator();

    while ( my $id = NEXTVAL($it) ) {

        # identity of the entries which are being kept
        my $keep_list = $keep_agg->matches($id);

        # add the entries which are being kept
        foreach my $keep_rule ( $keep_list->iter() ) {

            $self->result->add($keep_rule);
        }

        # add the config rule being removed
        foreach my $object ( $cfg_rules->iter() ) {

            if ( $object->matches($id) ) {

                my $clone = $object->clone();
                $clone->set( 'REMOVE', Farly::Value::String->new('RULE') );
                $clone->delete_key('LINE');

                $self->result->add($clone);
            }
        }
    }
}

1;
__END__

=head1 NAME

Farly::Remove::Rule - Removes firewall rule entries from the configuration

=head1 DESCRIPTION

Farly::Remove::Rule replaces a firewall rule configuration with the set of 
firewall rule entries to be kept. i.e. If the firewall configuration rule uses
a group, then the configuration rule is removed and the expanded firewall rule
entries are used in the configuration.

Farly::Remove::Rule must be provided with the original configuration container 
and a unique expanded $list<Farly::Object::List> of firewall rule entries where
entries to be removed have the 'REMOVE' property set.

The commands needed to remove the 'REMOVE' firewall rule entries from the given 
firewall configuration will be generated.

=head1 METHODS

=head2 new( $config<Farly::Object::List> )

The constructor. The firewall configuration container is required.

  $remover = Farly::Remove::Rule->new( $config<Farly::Object::List> );

=head2 remove( $expanded_rules<Farly::Object::List> )

Removes entries with the 'REMOVE' property from the given Farly firewall $config model.

  $remover->remove( $expanded_rules );

Rules entry objects being removed from the config must have the 'REMOVE' property
set within $expanded_rules.

=head2 result()

Returns a Farly::Object::List<Farly::Object> object containing all objects
which need to be removed or added to the current Farly firewall model in order
to remove all references to the removed firewall rule entries.

  $remove_result_set = $remover->result();

=head1 COPYRIGHT AND LICENCE

Farly::Remove::Rule
Copyright (C) 2012-2013  Trystan Johnson

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
