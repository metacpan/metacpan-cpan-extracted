use strict;

package LittleORM::Meta::Trait;

use Moose::Role;

has 'description' => ( is => 'rw',
		       isa => 'HashRef',
		       lazy => 1,
		       default => sub { {} } );

no Moose::Role;

1;

