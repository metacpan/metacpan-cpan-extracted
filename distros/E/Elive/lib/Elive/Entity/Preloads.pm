package Elive::Entity::Preloads;
use warnings; use strict;

use Mouse;
use Mouse::Util::TypeConstraints;

=head1 NAME

Elive::Entity::Preloads - List of Preloads 

=cut

use Elive::Entity::Preload;

extends 'Elive::DAO::Array';
__PACKAGE__->separator(',');
__PACKAGE__->element_class('Elive::Entity::Preload');

our $class = 'Elive::Entity::Preloads';
coerce $class => from 'ArrayRef|Str'
          => via {
	      $class->new( $_ );
          };

1;
