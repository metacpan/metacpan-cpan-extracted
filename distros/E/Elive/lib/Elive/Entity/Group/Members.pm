package Elive::Entity::Group::Members;
use warnings; use strict;

=head1 NAME

Elive::Entity::Group::Members - Group Members entity class

=cut

use Mouse;
use Mouse::Util::TypeConstraints;
use Scalar::Util;
use Elive::Util;

use Elive::Entity::Group;
use Elive::Entity::User;

extends 'Elive::DAO::Array';
__PACKAGE__->separator(',');

# Elements are likley to be
# - group objects
# - user-ids as strings: 'someuser'
# - group-ids strings: '*my_group'

__PACKAGE__->element_class('Elive::Entity::Group|Str');

sub _build_array {
    my $class = shift;
    my $spec = shift;

    my $type = Elive::Util::_reftype( $spec );

    my @members;

    if ($type eq 'ARRAY') {
	@members = map {$class->__build_elem($_)} @$spec;
    }
    else {
	@members = split($class->separator, Elive::Util::string( $spec ));
    }

    return \@members;
}

sub __build_elem {
    my $class = shift;
    my $elem = shift;

    my $reftype = Elive::Util::_reftype($elem);

    if ($reftype eq 'HASH') {
	# blessed or unblessed user struct
	if (exists $elem->{userId}) {
	    return $elem->{userId};
	}
	elsif (exists $elem->{groupId}) {

	    $elem = Elive::Entity::Group->new($elem)
		unless Scalar::Util::blessed($elem);

	    return $elem;
	}
    }

    return Elive::Util::string($elem);
}

our $class = 'Elive::Entity::Group::Members';
coerce $class => from 'ArrayRef|Str'
          => via {
	      $class->new( $_ );
          };

1;
