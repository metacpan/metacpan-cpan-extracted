use strict;

package LittleORM::Model::Value;
use Moose;

has 'db_field_type' => ( is => 'rw',
			 isa => 'Str' );

has 'value' => ( is => 'rw',
		 isa => 'Any' );

has 'orm_coerce' => ( is => 'rw',
		      isa => 'Bool',
		      default => 1 );

sub this_is_value
{
	my ( $self, $attr ) = @_;

	my $rv = 0;

	if( blessed( $attr ) and ( $attr -> isa( 'LittleORM::Model::Value' ) ) )
	{
		$rv = 1;
	}
	return $rv;
}

434445;

