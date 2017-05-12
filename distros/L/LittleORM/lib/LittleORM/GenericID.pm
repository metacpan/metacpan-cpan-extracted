
use strict;

use LittleORM::Model;

package LittleORM::GenericID;

# Generic PK ID column for inheritance.

use Moose;

extends 'LittleORM::Model';

has 'id' => ( metaclass => 'LittleORM::Meta::Attribute',
	      isa => 'Int',
	      is => 'rw',
	      description => { primary_key => 1, db_field_type => 'int' } );


42;
