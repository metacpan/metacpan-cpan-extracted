use strict;

package LittleORM::Db::Field::Default;

use Moose;

sub appropriate_op
{
	my ( $self, $op, $val ) = @_;

	if( ( $op eq '=' ) and ( not defined $val ) )
	{
		$op = 'IS';
	}

	return $op;
}

42;
