use strict;

use LittleORM::Db::Field::Default;
use LittleORM::Db::Field::XML;

package LittleORM::Db::Field;

sub by_type
{
	my ( $self, $type ) = @_;

	$type = lc( $type );

	my $rv = undef;

	if( $type eq 'xml' )
	{
		$rv = LittleORM::Db::Field::XML -> new();
	} else
	{
		$rv = LittleORM::Db::Field::Default -> new();
	}

	return $rv;
}

42;
