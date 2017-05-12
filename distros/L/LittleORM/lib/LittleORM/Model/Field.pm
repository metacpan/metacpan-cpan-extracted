use strict;

package LittleORM::Model::Field;
use Moose;

has 'model' => ( is => 'rw',
		 isa => 'Str' );

has 'table_alias' => ( is => 'rw', isa => 'Str' );

has 'base_attr' => ( is => 'rw',
		     isa => 'Str',
		     default => '' );

has 'base_field' => ( is => 'rw',
		      isa => 'LittleORM::Model::Field' );

has 'db_func' => ( is => 'rw',
		   isa => 'Str' );

has 'db_func_tpl' => ( is => 'rw',
		       isa => 'Str',
		       default => '%s(%s)' );

has 'func_args_tpl' => ( is => 'rw',
			 isa => 'Str',
			 default => '%s' );

has 'select_as' => ( is => 'rw',
		     isa => 'Str',
		     default => \&get_select_as_field_name );

has 'post_process' => ( is => 'rw',
			isa => 'CodeRef',
			default => sub { sub { $_[ 0 ] } } );

has 'db_field_type' => ( is => 'rw',
			 isa => 'Str' );

has '_distinct' => ( is => 'rw',
		     isa => 'Bool',
		     default => 0 );

has 'orm_coerce' => ( is => 'rw',
		      isa => 'Bool',
		      default => 1 );

use Carp::Assert 'assert';
use Scalar::Util 'blessed';

{
	my $cnt = 0;

	sub get_select_as_field_name
	{
		$cnt ++;

		return '_f' . $cnt; # lowcase

	}
}

sub wrap_field
{
	my $self = shift;

	my $rv = LittleORM::Model::Field -> new( base_field => $self,
					   @_ );

	return $rv;
}

sub determine_ta_for_field_from_another_model
{
	my ( $self, $tables ) = @_;

	my $rv = $self -> table_alias();

	unless( $rv )
	{
		$rv = $self -> model() -> _db_table();

		if( $tables )
		{
eocEfjT38ttaOGys:
			foreach my $t ( @{ $tables } )
			{
				my ( $table, $alias ) = split( /\s+/, $t );
				if( $table eq $rv )
				{
					$rv = $alias;
					last eocEfjT38ttaOGys;
				}
			}
		}
	}

	return $rv;
}

sub this_is_field
{
	my ( $self, $attr ) = @_;

	my $rv = 0;

	if( blessed( $attr ) and ( $attr -> isa( 'LittleORM::Model::Field' ) ) )
	{
		$rv = 1;
	}
	return $rv;
}

sub assert_model_soft
{
	my ( $self, $model ) = @_;
	if( $self -> model() )
	{
		$self -> assert_model( $model );
	}
}

sub assert_model
{
	my ( $self, $model ) = @_;

	my $t = ( ref( $model ) or $model );
	assert( $self -> model() eq $t );
}

sub form_field_name_for_db_select
{
	my ( $self, $table ) = @_;

	my $rv = $self -> base_attr();

	if( $rv )
	{
		assert( $self -> model() );
		$rv = ( $table ? $table . '.' : '' ) .
		      &LittleORM::Model::__get_db_field_name( $self -> model() -> meta() -> find_attribute_by_name( $rv ) );

	} elsif( my $f = $self -> base_field() )
	{
		$rv = $f -> form_field_name_for_db_select();
	}

	if( my $f = $self -> db_func() )
	{
		$rv = sprintf( $self -> db_func_tpl(),
			       $f,
			       sprintf( $self -> func_args_tpl(),
					( $self -> _distinct() ? ' DISTINCT ' : '' ) . $rv ) );
	}

	return $rv;

}

sub form_field_name_for_db_select_with_as
{
	my $self = shift;

	my $rv = $self -> form_field_name_for_db_select( @_ ) . ' AS ' . $self -> select_as();

	return $rv;
}


394041;
