use strict;

# DBH-related routines which were inside ORM/Model.pm earlier

use LittleORM::Db::Connector ();

package LittleORM::Model;

use Carp::Assert 'assert';

sub set_read_dbh
{
	my ( $self, $dbh ) = @_;

	# arrayref expected
	$self -> meta() -> _littleorm_rdbh( $dbh );
}

sub set_write_dbh
{
	my ( $self, $dbh ) = @_;

	# arrayref expected
	$self -> meta() -> _littleorm_wdbh( $dbh );
}

sub set_dbh
{
	my ( $self, $dbh ) = @_;

	if( ref( $dbh ) eq 'HASH' )
	{
		my ( $rdbh, $wdbh ) = @{ $dbh }{ 'read', 'write' };
		assert( $rdbh and $wdbh );

		$self -> set_read_dbh( ref( $rdbh ) eq 'ARRAY' ? $rdbh : [ $rdbh ] );
		$self -> set_write_dbh( ref( $wdbh ) eq 'ARRAY' ? $wdbh : [ $wdbh ]  );

	} else
	{
		$self -> set_read_dbh( [ $dbh ] );
		$self -> set_write_dbh( [ $dbh ] );
	}
}

# old methods

sub __get_dbh
{
	my $self = shift;
	my %args = @_;

	unless( exists $args{ '_for_what' } )
	{
		# warn( "'_for_what' not specified, failing back to write DBH" );
		$args{ '_for_what' } = 'write';
	}

	assert( my $for_what = $args{ '_for_what' } ); # i must know what this DBH you need for

	my $class_dbh = $self -> __get_class_dbh( $for_what );

	unless( $class_dbh )
	{
		$self -> __set_db_connector_object_if_required();
		if( my $c = $self -> meta() -> _littleorm_db_connector() )
		{
			$class_dbh = $c -> get_dbh( $for_what );
			$self -> __set_class_dbh( $class_dbh, $for_what );
		}
	}

	my $dbh = ( $args{ '_dbh' }
		    or
		    $class_dbh
		    or
		    &LittleORM::Db::get_dbh( $for_what ) );

	# assert( &LittleORM::Db::dbh_is_ok( $dbh ), 'this method is supposed to return valid dbh' );

	return $dbh;
}



# full old version saved for reference
# sub __get_dbh
# {
# 	my $self = shift;
# 	my %args = @_;

# 	assert( my $for_what = $args{ '_for_what' } ); # i must know what this DBH you need for

# 	my $dbh = &LittleORM::Db::dbh_is_ok( $self -> __get_class_dbh( $for_what ) );

# 	unless( $dbh )
# 	{
# 		if( my $t = $args{ '_dbh' } )
# 		{
# 			$dbh = $t;
# 			$self -> __set_class_dbh( $dbh, $for_what );
# 		}
# 	}

# 	unless( $dbh )
# 	{
# 		if( my $t = &LittleORM::Db::get_dbh( $for_what ) )
# 		{
# 			$dbh = $t;
# 			$self -> __set_class_dbh( $dbh, $for_what );
# 		}
# 	}

# 	assert( &LittleORM::Db::dbh_is_ok( $dbh ), 'this method is supposed to return valid dbh' );

# 	return $dbh;
# }

sub get_class_dbh
{
	return &__get_class_dbh( @_ );
}

sub set_class_dbh
{
	return &__set_class_dbh( @_ );
}

sub __get_class_dbh
{

	my ( $self, $for_what ) = @_;

	my $rv = undef;

	if( $for_what eq 'write' )
	{
		if( my $t = $self -> meta() -> _littleorm_wdbh() )
		{
			$rv = &LittleORM::Db::__get_rand_array_el( $t );
		}
	} else
	{
		if( my $t = $self -> meta() -> _littleorm_rdbh() )
		{
			$rv = &LittleORM::Db::__get_rand_array_el( $t );
		}
	}


	# this is to prevent stale disconnected $dbh from being used,
	# as it remains true value in conditions

	return &LittleORM::Db::dbh_is_ok( $rv );
}

sub __set_class_dbh
{
	my ( $self, $dbh, $for_what ) = @_;

	if( $for_what )
	{
		if( $for_what eq 'read' )
		{
			$self -> set_read_dbh( [ $dbh ] );
		} elsif( $for_what eq 'write' )
		{
			$self -> set_write_dbh( [ $dbh ] );
		} else
		{
			assert( 0, 'for what? ' . $for_what );
		}
	} else
	{
		$self -> set_read_dbh( [ $dbh ] );
		$self -> set_write_dbh( [ $dbh ] );
	}

	# ancient DBH storing technique:

	# my $calling_package = ( ref( $self ) or $self );
	# {
	# 	no strict "refs";
	# 	${ $calling_package . "::_dbh" } = $dbh;
	# }

}

sub __set_db_connector_object_if_required
{
	my $self = shift;

	my $m = 'littleorm_db_connector_config';

	if( $self -> can( $m ) )
	{
		unless( $self -> meta() -> _littleorm_db_connector() )
		{
			if( my @args = $self -> $m() )
			{
				my $c = LittleORM::Db::Connector -> new( @args );
				$self -> meta() -> _littleorm_db_connector( $c );
			}
		}
	}
}

42;
