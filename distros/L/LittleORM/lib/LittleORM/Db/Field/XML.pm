use strict;

package LittleORM::Db::Field::XML;

use Moose;

extends 'LittleORM::Db::Field::Default';

sub appropriate_op
{
	my ( $self, $op ) = @_;


	return undef;
}

42;
