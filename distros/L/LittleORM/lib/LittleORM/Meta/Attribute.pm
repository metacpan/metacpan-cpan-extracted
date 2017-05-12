use strict;

package LittleORM::Meta::Attribute;

use Moose;

extends 'Moose::Meta::Attribute';
with 'LittleORM::Meta::Trait';

no Moose; 

1;
