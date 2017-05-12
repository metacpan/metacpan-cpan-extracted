use strict;

use LittleORM::Db ();
use LittleORM::Db::Field ();
use LittleORM::Meta::LittleORMHasDbh ();

package LittleORM::Model;

use Moose -traits => 'LittleORMHasDbh';
use Moose::Util::TypeConstraints;

has '_rec' => ( is => 'rw', isa => 'HashRef', required => 1, metaclass => 'LittleORM::Meta::Attribute', description => { ignore => 1 } );

use Carp::Assert 'assert';
use Scalar::Util 'blessed';
use Module::Load ();
use LittleORM::Model::Field ();
use LittleORM::Model::Value ();
use LittleORM::Model::Dbh ();

sub _db_table{ assert( 0, '" _db_table " method must be redefined.' ) }

# Let it be separate method, m'kay?
sub _clear
{
	my $self = shift;

	foreach my $attr ( $self -> meta() -> get_all_attributes() )
	{
		next if &__descr_attr( $attr, 'do_not_clear_on_reload' ); # well, kinda crutch...
									  #		- Kain

		if( $attr -> has_clearer() )
		{

# http://search.cpan.org/~doy/Moose-2.0603/lib/Class/MOP/Attribute.pm
# $attr->clearer
#     The accessor, reader, writer, predicate, and clearer methods all
#     return exactly what was passed to the constructor, so it can be
#     either a string containing a method name, or a hash reference.

			# -- why does it have to be so complex?
			
			my $clearer = $attr -> clearer();

			# ok, as doc above says:
			if( ref( $clearer ) )
			{
				my $code = ${ [ values %{ $clearer } ] }[ 0 ];
				$code -> ( $self );

			} else
			{
				$self -> $clearer();
			}
			
		} else
		{
			$attr -> clear_value( $self );
		}
	}

	return 1;
}

sub __for_read
{
	return ( _for_what => 'read' );
}

sub __for_write
{
	return ( _for_what => 'write' );
}

sub equals
{
        my ( $self, $other ) = @_;

	my $rv = 0;
	my @pks = $self -> __find_primary_keys();
	
        if( $other and blessed( $other ) and $other -> isa( ref( $self ) ) and @pks )
        {

		$rv = 1;
			
TPfHSgZ9BCDTx58w:
		foreach my $key ( @pks )
		{
			assert( my $method_name = $key -> name() );
			unless( $self -> $method_name() eq $other -> $method_name() ) # no check if $other actually can do $key()
			{
				$rv = 0;
			}
		}
		
        } elsif( $other and ( not ref( $other ) ) and ( scalar @pks == 1 ) )
	{
		my $method_name = $pks[ 0 ] -> name();

		if( $self -> $method_name() eq $other )
		{
			$rv = 1;
		}
	}

        return $rv;
}

sub reload
{
	my $self = shift;

	if( my @pk = $self -> __find_primary_keys() )
	{
		my %get_args = ();

		foreach my $pk ( @pk )
		{
			my $pkname = $pk -> name();
			$get_args{ $pkname } = $self -> $pkname();
		}

		$self -> _clear();

		my $sql = $self -> __form_get_sql( %get_args,
						   _limit => 1 );

		my $rec = &LittleORM::Db::getrow( $sql, $self -> __get_dbh( &__for_read() ) );
		$self -> _rec( $rec );

	} else
	{
		assert( 0, 'reload in only supported for models with PK' );
	}
}

sub clone
{
	my $self = shift;

	my $class = ref( $self );

	return $class -> new( _rec => $self -> _rec() );
}

sub get
{
	my $self = shift;

	my @args = @_;
	my %args = @args;

	my $sql = $self -> __form_get_sql( @args, _limit => 1 );

	if( $args{ '_debug' } )
	{
		return $sql;
	}

	my $rec = &LittleORM::Db::getrow( $sql, $self -> __get_dbh( @args,
							      &__for_read() ) );

	my $rv = undef;

	if( $rec )
	{
		$rv = $self -> create_one_return_value_item( $rec, @args );
	}

	return $rv;
}

sub borrow_field
{
	my $self = shift;
	my $attrname = shift;
	my %more = @_;

	if( $attrname )
	{
		unless( exists $more{ 'db_field_type' } )
		{
			my $attr = $self -> meta() -> find_attribute_by_name( $attrname );
			if( my $t = &__descr_attr( $attr, 'db_field_type' ) )
			{
				$more{ 'db_field_type' } = $t;
			}
		}
	}

	my $rv = LittleORM::Model::Field -> new( model => ( ref( $self ) or $self ),
					   %more );
	if( $attrname )
	{
		assert( my $attr = $self -> meta() -> find_attribute_by_name( $attrname ) );
		$rv -> base_attr( $attrname );
	}

	return $rv;
}

sub create_one_return_value_item
{
	my $self = shift;
	my $rec = shift;
	my %args = @_;

	my $rv = undef;

	if( $rec )
	{
		if( $args{ '_fieldset' } or $args{ '_groupby' } )
		{
			$rv = LittleORM::DataSet -> new();

			if( my $fs = $args{ '_fieldset' } )
			{
				foreach my $f ( @{ $fs } )
				{
					unless( LittleORM::Model::Field -> this_is_field( $f ) )
					{
						$f = $self -> borrow_field( $f,
									    select_as => &__get_db_field_name( $self -> meta() -> find_attribute_by_name( $f ) ) );
					}

					my $dbfield = $f -> select_as();
					my $value = $f -> post_process() -> ( $rec -> { $dbfield } );

					$rv -> add_to_set( { model => $f -> model(),
							     base_attr => $f -> base_attr(),
							     orm_coerce => $f -> orm_coerce(),
							     dbfield => $dbfield,
							     value => $value } );
				}
			}

			if( my $grpby = $args{ '_groupby' } )
			{
				foreach my $f ( @{ $grpby } )
				{
					my ( $dbfield,
					     $post_process,
					     $base_attr,
					     $orm_coerce,
					     $model ) = ( undef,
							  undef,
							  undef,
							  1,
							  ( ref( $self ) or $self ) );

					if( LittleORM::Model::Field -> this_is_field( $f ) )
					{
						$dbfield = $f -> select_as();
						$base_attr = $f -> base_attr();
						$post_process = $f -> post_process();
						$model = $f -> model();
						$orm_coerce = $f -> orm_coerce();

					} else
					{
						$dbfield = &__get_db_field_name( $self -> meta() -> find_attribute_by_name( $f ) );
					}

					my $value = ( $post_process ? $post_process -> ( $rec -> { $dbfield } ) : $rec -> { $dbfield } );
					$rv -> add_to_set( { model => $model,
							     base_attr => $base_attr,
							     dbfield => $dbfield,
							     orm_coerce => $orm_coerce,
							     value => $value } );
				}
			}
		} else
		{
			$rv = $self -> new( _rec => $rec );
		}
	}
	return $rv;
}

sub values_list
{
	my ( $self, $fields, $args ) = @_;

	# example: @values = Class -> values_list( [ 'id', 'name' ], [ something => { '>', 100 } ] );
	# will return ( [ id, name ], [ id1, name1 ], ... )

	my @rv = ();

	foreach my $o ( $self -> get_many( @{ $args } ) )
	{
		my @l = map { $o -> $_() } @{ $fields };

		push @rv, \@l;
	}

	return @rv;
}

sub get_or_create
{
	my $self = shift;

	my $r = $self -> get( @_ );

	unless( $r )
	{
		$r = $self -> create( @_ );
	}

	return $r;
}

sub get_many
{
	my $self = shift;
	my @args = @_;
	my %args = @args;
	my @outcome = ();

	my $sql = $self -> __form_get_sql( @args );

	if( $args{ '_debug' } )
	{
		return $sql;
	}

	my $sth = &LittleORM::Db::prep( $sql, $self -> __get_dbh( @args,
							    &__for_read() ) );
	$sth -> execute();

	while( my $data = $sth -> fetchrow_hashref() )
	{
		my $o = $self -> create_one_return_value_item( $data, @args );
		push @outcome, $o;
	}

	$sth -> finish();

	return @outcome;
}

sub _sql_func_on_attr
{
	my $self = shift;
	my $func = shift;
	my $attr = shift;

	my @args = @_;
	my %args = @args;

	my $outcome = 0;

	my $sql = $self -> __form_sql_func_sql( _func => $func,
						_attr => $attr,
						@args );
	if( $args{ '_debug' } )
	{
		return $sql;
	}

	my $sth = &LittleORM::Db::prep( $sql, $self -> __get_dbh( @args,
							    &__for_read() ) );
	$sth -> execute();
	my $rows = $sth -> rows();
	
	if( $args{ '_groupby' } )
	{
		$outcome = [];

		while( my $data = $sth -> fetchrow_hashref() )
		{
			my $set = LittleORM::DataSet -> new();
			while( my ( $k, $v ) = each %{ $data } )
			{
				my $field = { model => ( ref( $self ) or $self ),
					      dbfield => $k,
					      orm_coerce => 1,
					      value => $v };

				$set -> add_to_set( $field );
			}
			push @{ $outcome }, $set;
		}

	} elsif( $rows == 1 )
	{
		$outcome = $sth -> fetchrow_hashref() -> { $func };

	} else
	{
		assert( 0,
			sprintf( "Got '%s' for '%s'",
				 $rows,
				 $sql ) );
	}

	$sth -> finish();

	return $outcome;
}

sub max
{
	my $self = shift;

	assert( my $attrname = $_[ 0 ] );

	my $rv = $self -> _sql_func_on_attr( 'max', @_ );

	my $attr = undef;

	if( LittleORM::Model::Field -> this_is_field( $attrname ) )
	{
		assert( $attr = $self -> meta() -> find_attribute_by_name( $attrname -> base_attr() ) );
	} else
	{
		assert( $attr = $self -> meta() -> find_attribute_by_name( $attrname ) );
	}

	if( my $coerce_from = &__descr_attr( $attr, 'coerce_from' ) )
	{
		$rv = $coerce_from -> ( $rv );
	}

	return $rv;
}


sub min
{
	my $self = shift;

	assert( my $attrname = $_[ 0 ] );

	my $rv = $self -> _sql_func_on_attr( 'min', @_ );

	my $attr = undef;

	if( LittleORM::Model::Field -> this_is_field( $attrname ) )
	{
		assert( $attr = $self -> meta() -> find_attribute_by_name( $attrname -> base_attr() ) );
	} else
	{
		assert( $attr = $self -> meta() -> find_attribute_by_name( $attrname ) );
	}

	if( my $coerce_from = &__descr_attr( $attr, 'coerce_from' ) )
	{
		$rv = $coerce_from -> ( $rv );
	}

	return $rv;
}


# sub min
# {
# 	my $self = shift;

# 	assert( my $attrname = $_[ 0 ] );

# 	my $rv = $self -> _sql_func_on_attr( 'min', @_ );

# 	assert( my $attr = $self -> meta() -> find_attribute_by_name( $attrname ) );

# 	if( my $coerce_from = &__descr_attr( $attr, 'coerce_from' ) )
# 	{
# 		$rv = $coerce_from -> ( $rv );
# 	}

# 	return $rv;
# }

sub __default_db_field_name_for_func
{
	my ( $self, %args ) = @_;

	my $rv = '';
	assert( my $func = $args{ '_func' } );

	if( $func eq 'count' )
	{
		$rv = '*';
		if( my $d = $args{ '_distinct' } )
		{
			my @distinct_on = $self -> __get_distinct_on_attrs( $d );

			if( @distinct_on )
			{
				assert( scalar @distinct_on == 1, "count of distinct is not yet supported for multiple PK models" );
				my @fields = map { sprintf( "%s.%s",
							    ( $args{ '_table_alias' } or $self -> _db_table() ),
							    &__get_db_field_name( $_ ) ) } @distinct_on;
				$rv = 'DISTINCT ' . join( ", ", @fields );
			} else
			{
				warn( sprintf( "Don't know on what to DISTINCT (no PK and fields not passed) for %s",
					       ( ref( $self ) or $self ) ) );
			}
		}
	}

	return $rv;
}

sub __get_distinct_on_attrs
{
	my ( $self, $d ) = @_;

	my @distinct_on = ();

	if( ref( $d ) eq 'ARRAY' )
	{
		foreach my $aname ( @{ $d } )
		{
			my $model_name = ( ref( $self ) or $self );
			if( LittleORM::Model::Field -> this_is_field( $aname ) )
			{
				assert( $aname -> model() eq $model_name,
					sprintf( "field %s from %s can not be used in model %s",
						 $aname -> base_attr(),
						 $aname -> model(),
						 $model_name ) );
				$aname = $aname -> base_attr();
			}

			assert( my $attr = $self -> meta() -> get_attribute( $aname ),
				sprintf( 'invalid attr "%s" passed for model "%s"',
					 $aname,
					 $model_name ) );
			push @distinct_on, $attr;
		}
		
		
	} else
	{
		@distinct_on = $self -> __find_primary_keys();
	}
	
	return @distinct_on;
	
}

sub __form_sql_func_sql
{
	my $self = shift;

	my @args = @_;
	my %args = @args;

	my @where_args = $self -> __form_where( @args,
						&__for_read() );

	my @tables_to_select_from = ( $self -> _db_table() );

	if( my $t = $args{ '_tables_to_select_from' } )
	{
		@tables_to_select_from = @{ $t };
	}
	assert( my $func = $args{ '_func' } );
	my $dbf = $self -> __default_db_field_name_for_func( %args );

	if( my $attrname = $args{ '_attr' } )
	{
		if( LittleORM::Model::Field -> this_is_field( $attrname ) )
		{
			$dbf = $attrname -> form_field_name_for_db_select( $attrname -> determine_ta_for_field_from_another_model( $args{ '_tables_used' } ) );
		} else
		{
			assert( my $attr = $self -> meta() -> find_attribute_by_name( $attrname ) );
			$dbf = &__get_db_field_name( $attr );
		}
	}

	my $sql = sprintf( "SELECT %s%s(%s) FROM %s WHERE %s",
			   $self -> __form_sql_func_sql_more_fields( @args ),
			   $func,
			   $dbf,
			   join( ',', @tables_to_select_from ), 
			   join( ' ' . ( $args{ '_logic' } or 'AND' ) . ' ', @where_args ) );

	$sql .= $self -> __form_additional_sql( @args );

	return $sql;
}

sub __form_sql_func_sql_more_fields
{
	my $self = shift;
	
	my @args = @_;
	my %args = @args;
	my $rv = '';
	
	if( my $t = $args{ '_groupby' } )
	{
		my @sqls = ();

		my $ta = ( $args{ '_table_alias' }
			   or
			   $self -> _db_table() );

		foreach my $grp ( @{ $t } )
		{
			my $f = undef;

			if( LittleORM::Model::Field -> this_is_field( $grp ) )
			{
				my $use_ta = $ta;

				if( $grp -> model() and ( $grp -> model() ne $self ) )
				{
					$use_ta = $grp -> determine_ta_for_field_from_another_model( $args{ '_tables_used' } );

				}
				$f = $grp -> form_field_name_for_db_select_with_as( $use_ta );#form_field_name_for_db_select( $use_ta );

			} else
			{
				$f = sprintf( "%s.%s",
					      $ta,
					      &__get_db_field_name( $self -> meta() -> find_attribute_by_name( $grp ) ) );
			}
			push @sqls, $f;
		}

		$rv .= join( ',', @sqls );
		$rv .= ',';
	}

	return $rv;
}

sub count
{
	my $self = shift;
	return $self -> _sql_func_on_attr( 'count', '', @_ );

}

sub create
{
	my $self = shift;
	my @args = @_;

	my %args = $self -> __correct_insert_args( @args );
	my $sql = $self -> __form_insert_sql( %args );

	if( $args{ '_debug' } )
	{
		return $sql;
	}

	my $allok = undef;

	# if( my @pk = $self -> __find_primary_keys() )

	my $dbh = $self -> __get_dbh( @args,
				      &__for_write() );

	{
		my $sth = &LittleORM::Db::prep( $sql, $dbh );
		my $rc = $sth -> execute();

		if( $rc == 1 )
		{
			# $allok = 1;
			my $data = $sth -> fetchrow_hashref();
			$allok = $self -> create_one_return_value_item( $data, @args );

			# foreach my $pk ( @pk )
			# {
			# 	unless( $args{ $pk -> name() } )
			# 	{
			# 		my $field = &__get_db_field_name( $pk );
			# 		$args{ $pk -> name() } = $data -> { $field };
			# 	}
			# }
		}

		$sth -> finish();

	}

	if( $allok )
	{
		return $allok; #$self -> get( $self -> __leave_only_pk( %args ) );
	}

	assert( 0, sprintf( "%s: %s", $sql, &LittleORM::Db::errstr( $dbh ) ) );
}





sub _process_create_many_args
{
	my $self = shift;

	my @args = @_;



	my $new_records_data = ();
	my $extra_args_data = {};

	my $index_of_first_args_el_which_is_not_ref = ${ [ grep { not ref( $args[ $_ ] ) } ( 0 .. $#args ) ] }[ 0 ];

	if( $index_of_first_args_el_which_is_not_ref )
	{

		@{ $new_records_data } = @args[ 0 .. $index_of_first_args_el_which_is_not_ref - 1 ];
		%{ $extra_args_data } = @args[ $index_of_first_args_el_which_is_not_ref .. $#args ];
	} else
	{
		$new_records_data = \@args;
	}

	return ( $new_records_data,
		 $extra_args_data );

}

sub create_many
{
	my $self = shift;

	my ( $new_records_data,
	     $extra_args_data ) = $self -> _process_create_many_args( @_ );

	{
		assert( my $cnt = scalar @{ $new_records_data } );

		for( my $i = 0; $i < $cnt; $i ++ )
		{
			my %args = $self -> __correct_insert_args( @{ $new_records_data -> [ $i ] } );
			$new_records_data -> [ $i ] = \%args;
		}
	}

	my $fields = undef;
	my @values_sets = ();
	my $dbh = $self -> __get_dbh( %{ $extra_args_data },
				      &__for_write() );

	foreach my $nrd ( @{ $new_records_data } )
	{
		my ( $f, $v ) = $self -> __form_fields_and_values_for_insert_sql( %{ $nrd } );
		assert( $f and $v );
		unless( defined $fields )
		{
			$fields = $f;
		}
		push @values_sets, join( ',', @{ $v } );
	}

	my $sql = sprintf( "INSERT INTO %s (%s) VALUES %s RETURNING *",
			   $self -> _db_table(),
			   join( ',', @{ $fields } ),
			   join( ',', map { '(' . $_ . ')' } @values_sets ) );
			   

	if( $extra_args_data -> { '_debug' } )
	{
		return $sql;
	}

	my @rv = ();

	{
		my $sth = &LittleORM::Db::prep( $sql, $dbh ); #$self -> __get_dbh( %{ $extra_args_data } ) );
		my $rc = $sth -> execute();

		if( $rc == scalar @{ $new_records_data } )
		{
			while( my $data = $sth -> fetchrow_hashref() )
			{
				my $o = $self -> create_one_return_value_item( $data, %{ $extra_args_data } );
				push @rv, $o;
			}

		} else
		{
			assert( 0, 'insert error' );
		}
		
		$sth -> finish();
	}

	return @rv;
}

sub __leave_only_pk
{
	my $self = shift;

	my %args = @_;
	my %rv = ();

	foreach my $attr ( $self -> __find_primary_keys() )
	{
		my $aname = $attr -> name();
		if( exists $args{ $aname } )
		{
			$rv{ $aname } = $args{ $aname };
		}
	}
	
	unless( %rv )
	{
		%rv = %args;
	}

	return %rv;
}

sub __find_attr_by_its_db_field_name
{
	my ( $self, $db_field_name ) = @_;

	my $rv = undef;

pgmxcobWi7lULIJW:
	foreach my $attr ( $self -> meta() -> get_all_attributes() )
	{
		if( &__get_db_field_name( $attr ) eq $db_field_name )
		{
			$rv = $attr;
			last pgmxcobWi7lULIJW;
		}
	}

	return $rv;
}

sub update
{
	my $self = shift;

	my %args = ();

	if( scalar @_ == 1 )
	{
		$args{ '_debug' } = $_[ 0 ];
	} else
	{
		%args = @_;
	}
	
	my @upadte_pairs = $self -> __get_update_pairs_for_update_request( %args );

	my $where = $self -> __form_update_request_where_part( %args );
	my $sql = sprintf( 'UPDATE %s SET %s WHERE %s',
			   $self -> _db_table(),
			   join( ',', @upadte_pairs ),
			   $where );

	my $rc = undef;
	my $dbh = $self -> __get_dbh( &__for_write() );

	if( $args{ '_debug' } )
	{
		return $sql;
	} else
	{
		$rc = &LittleORM::Db::doit( $sql, $dbh );
		
		if( ref( $self ) )
		{
			if( $rc != 1 )
			{
				assert( 0, sprintf( "%s: %s", $sql, &LittleORM::Db::errstr( $dbh ) ) );
			}
		}
	}
	return $rc;
}


sub __get_update_pairs_for_update_request
{
	my $self = shift;
	my %args = @_;

	my @upadte_pairs = ();


	if( ref( $self ) )
	{
		@upadte_pairs = $self -> __get_update_pairs_for_update_request_called_from_instance( %args );
	} else
	{
		@upadte_pairs = $self -> __get_update_pairs_for_update_request_called_from_class( %args );
	}

	return @upadte_pairs;

}

sub __get_update_pairs_for_update_request_called_from_instance
{
	my $self = shift;
	my %args = @_;

	my @upadte_pairs = ();

ETxc0WxZs0boLUm1:
	foreach my $attr ( $self -> meta() -> get_all_attributes() )
	{
		if( $self -> __should_ignore_on_write( $attr ) )
		{
			next ETxc0WxZs0boLUm1;
		}
		
		my $aname = $attr -> name();
		
		if( exists $args{ $aname } )
		{
			$self -> $aname( $args{ $aname } );
		}
		
		my $value = &__prep_value_for_db( $attr, $self -> $aname() );
		
		push @upadte_pairs, sprintf( '%s=%s',
					     &__get_db_field_name( $attr ),
					     &LittleORM::Db::dbq( $value, $self -> __get_dbh( &__for_write() ) ) );
		
	}
	
	return @upadte_pairs;

}

sub __get_update_pairs_for_update_request_called_from_class
{
	my $self = shift;
	my %args = @_;

	my @upadte_pairs = ();

	while( my ( $k, $v ) = each %args )
	{
		unless( $k =~ /^_/ ) # only system props and no real class attrs should start with underscore
		{
			assert( my $attr = $self -> meta() -> find_attribute_by_name( $k ) );

			if( $self -> __should_ignore_on_write( $attr ) )
			{
				assert( 0, 'attr which should be ignored passed into update:' . $k );
			} else
			{
				my $value = &__prep_value_for_db( $attr, $v );
				my $typecast = '';

				if( LittleORM::Model::Field -> this_is_field( $value ) )
				{
					if( ( my $t1 = &__descr_attr( $attr, 'db_field_type' ) )
					    and
					    ( my $t2 = $value -> db_field_type() ) )
					{
						unless( $t1 eq $t2 )
						{
							$typecast = '::' . $t1;
						}
					}
					$value = $value -> form_field_name_for_db_select();

				} else
				{
					$value = &LittleORM::Db::dbq( $value, $self -> __get_dbh( &__for_write() ) );
				}

				push @upadte_pairs, sprintf( '%s=%s%s',
							     &__get_db_field_name( $attr ),
							     $value,
							     $typecast );
			}

		}
	}
	
	return @upadte_pairs;
}

sub __form_update_request_where_part
{
	my $self = shift;
	my %args = @_;

	my @where = ();

	if( my $w = $args{ '_where' } )
	{
		assert( not ref( $self ) ); # only class call, not instance call
		if( ref( $w ) eq 'ARRAY' )
		{
			@where = $self -> __form_where( @{ $w },
							&__for_write() );
		} else
		{
			push @where, $w;
		}

	} else
	{
		assert( my @pkattr = $self -> __find_primary_keys(), 'cant update without primary key' );

		my %where_args = ();

		foreach my $pkattr ( @pkattr )
		{
			my $pkname = $pkattr -> name();
			$where_args{ $pkname } = $self -> $pkname();
		}
		@where = $self -> __form_where( %where_args,
						&__for_write() );
	}

	assert( my $where = join( ' AND ', @where ) );

	return $where;
}

sub copy
{
	my $self = shift;

	my %args = @_;

	assert( my $class = ref( $self ), 'this is object method' );

	my %copied_args = %args;

kdCcjt3iG8jOfthJ:
	foreach my $attr ( $self -> meta() -> get_all_attributes() )
	{
		if( $self -> __should_ignore_on_write( $attr ) )
		{
			next kdCcjt3iG8jOfthJ;
		}
		my $aname = $attr -> name();

		unless( exists $copied_args{ $aname } )
		{
			$copied_args{ $aname } = $self -> $aname();
		}
	}

	return $class -> create( %copied_args );
}

sub delete
{
	my $self = shift;

	my @args = @_;
	my %args = @args;

	my $sql = $self -> __form_delete_sql( @args );

	if( $args{ '_debug' } )
	{
		return $sql;
	}

	my $rc = &LittleORM::Db::doit( $sql, $self -> __get_dbh( @args,
							   &__for_write() ) );

	return $rc;
}

sub meta_change_attr
{
	my $self = shift;

	my $arg = shift;

	my %attrs = @_;

	my $arg_obj = $self -> meta() -> find_attribute_by_name( $arg );

	my $cloned_arg_obj = $arg_obj -> clone();

	my $d = ( $cloned_arg_obj -> description() or sub {} -> () );

	my %new_description = %{ $d };

	while( my ( $k, $v ) = each %attrs )
	{
		if( $v )
		{
			$new_description{ $k } = $v;
		} else
		{
			delete $new_description{ $k };
		}
	}

	$cloned_arg_obj -> description( \%new_description );

	$self -> meta() -> add_attribute( $cloned_arg_obj );
}

sub BUILD
{
	my $self = shift;

	my $orm_initialized_attr_desc_option = '__orm_initialized_attr_' . ref( $self );
	my $orm_initialized_attr_desc_option_hf = '__orm_initialized_attr_has_field_';


FXOINoqUOvIG1kAG:
	foreach my $attr ( $self -> meta() -> get_all_attributes() )
	{
		my $aname = $attr -> name();

		if( $self -> __should_ignore( $attr ) 
		    or
		    &__descr_attr( $attr, $orm_initialized_attr_desc_option )
		    or
		    &__descr_attr( $attr, $orm_initialized_attr_desc_option_hf ) )
		{
			# internal attrs start with underscore, skip them
			next FXOINoqUOvIG1kAG;
		}

		{

			my $newdescr = ( &__descr_or_undef( $attr ) or {} );
			$newdescr -> { $orm_initialized_attr_desc_option } = 1;

			my $predicate = $attr -> predicate();
			my $trigger   = $attr -> trigger();
			my $clearer   = $attr -> clearer(); # change made by Kain
							    # I really need this sometimes in case of processing thousands of objects
							    # and manual cleanup so I'm avoiding cache-related memleaks
							    # so if you want to give me whole server RAM - wipe it out :)

			my $handles   = ( $attr -> has_handles() ? $attr -> handles() : undef ); # also made by kain

			my $orig_method = $self -> meta() -> get_method( $aname );

			$attr -> default( undef );
			$self -> meta() -> add_attribute( $aname, ( is => 'rw',
								    isa => $attr -> { 'isa' },
								    coerce => $attr -> { 'coerce' },


								    ( defined $predicate ? ( predicate => $predicate ) : () ),
								    ( defined $trigger   ? ( trigger => $trigger )     : () ),
								    ( defined $clearer   ? ( clearer => $clearer )     : () ),
								    ( defined $handles   ? ( handles => $handles )     : () ),

								    lazy => 1,
								    metaclass => 'LittleORM::Meta::Attribute',
								    description => $newdescr,
								    default => sub { $_[ 0 ] -> __lazy_build_value( $attr ) } ) );

			if( $orig_method and $orig_method -> isa( 'Class::MOP::Method::Wrapped' ) )
			{
				my $new_method = $self -> meta() -> get_method( $aname );
				my $new_meta_method = Class::MOP::Method::Wrapped -> wrap( $new_method );
				
				map { $new_meta_method -> add_around_modifier( $_ ) } $orig_method -> around_modifiers();
				map { $new_meta_method -> add_before_modifier( $_ ) } $orig_method -> before_modifiers();
				map { $new_meta_method -> add_after_modifier( $_ )  } $orig_method -> after_modifiers();
				
				$self -> meta() -> add_method( $aname, $new_meta_method );
			}
		}
	}
}

sub __lazy_build_value
{
	my $self = shift;
	my $attr = shift;

	my $rec_field_name = &__get_db_field_name( $attr );

	my $t = $self -> __lazy_build_value_actual( $attr,
						    $self -> _rec() -> { $rec_field_name } );

	return $t;
}


sub __lazy_build_value_actual
{
	my ( $self, $attr, $t ) = @_;

	my $coerce_from = &__descr_attr( $attr, 'coerce_from' );

	if( defined $coerce_from )
	{
		$t = $coerce_from -> ( $t );
		
	} elsif( my $foreign_key = &__descr_attr( $attr, 'foreign_key' ) )
	{
		if( $foreign_key eq 'yes' )
		{
			# sugar
			assert( $attr -> has_type_constraint() );
			$foreign_key = $attr -> type_constraint() -> name();
		}

		&__load_module( $foreign_key );

		my $foreign_key_attr_name = &__descr_attr( $attr, 'foreign_key_attr_name' );

		unless( $foreign_key_attr_name )
		{
			my $his_pk = $foreign_key -> __find_primary_key();
			$foreign_key_attr_name = $his_pk -> name();
		}
		
		$t = $foreign_key -> get( $foreign_key_attr_name => $t,
					  _dbh => ( $foreign_key -> __get_dbh( &__for_read() ) 
						    or
						    $self -> __get_dbh( &__for_read() ) ) );
	}
	
	return $t;

}


sub __load_module
{
	my $mn = shift;

	Module::Load::load( $mn );

}

sub __correct_insert_args
{
	my $self = shift;
	my %args = @_;

	my $dbh = $self -> __get_dbh( %args,
				      &__for_write() );

wus2eQ_YY2I_r3rb:
	foreach my $attr ( $self -> meta() -> get_all_attributes() )
	{

		if( &__descr_attr( $attr, 'ignore' ) 
		    or 
		    &__descr_attr( $attr, 'ignore_write' ) )
		{
			next wus2eQ_YY2I_r3rb;
		}

		my $aname = $attr -> name();
		unless( exists $args{ $aname } )
		{
			if( my $seqname = &__descr_attr( $attr, 'sequence' ) )
			{
				my $nv = &LittleORM::Db::nextval( $seqname, $dbh );

				$args{ $aname } = $nv;
			} else
  			{
  				$args{ $aname } = &__default_insert_field_cached();
  			}
		}
	}

	return %args;
}

{
	my $rv = undef;

	sub __default_insert_field_cached
	{
		unless( $rv )
		{
			$rv = LittleORM::Model::Field -> new( db_func => 'DEFAULT',
							db_func_tpl => '%s' );
		}
		return $rv;
	}
}


sub __form_fields_and_values_for_insert_sql
{
	my $self = shift;
	my %args = @_;

	my @fields = ();
	my @values = ();

	my $dbh = $self -> __get_dbh( %args,
				      &__for_write() );

XmXRGqnrCTqWH52Z:
	foreach my $arg ( sort keys %args ) # sort here is crucial for create_many() , see test 040
	{
		my $val = $args{ $arg };
		if( $arg =~ /^_/ )
		{
			next XmXRGqnrCTqWH52Z;
		}

		assert( my $attr = $self -> meta() -> find_attribute_by_name( $arg ), 
			sprintf( 'invalid attr name passed: %s', $arg ) );

		if( &__descr_attr( $attr, 'ignore' ) 
		    or 
		    &__descr_attr( $attr, 'ignore_write' ) )
		{
			next XmXRGqnrCTqWH52Z;
		}

		( undef,
		  $val,
		  undef,
		  undef,
		  undef ) = $self -> determine_op_and_col_and_correct_val( $arg,
									   $val,
									   $self -> _db_table(),
									   { %args,
									     __we_do_insert_now => 'yes' },
									   $dbh );

		my $field_name = &__get_db_field_name( $attr );
		
		push @fields, $field_name;
		push @values, $val;
	}

	return ( \@fields, \@values );
}



sub __form_insert_sql
{
	my $self = shift;

	my %args = @_;
	my ( $fields, $values ) = $self -> __form_fields_and_values_for_insert_sql( %args );
	
	my $dbh = $self -> __get_dbh( %args,
				      &__for_write() );
	my $sql = sprintf( "INSERT INTO %s (%s) VALUES (%s) RETURNING *",
			   $self -> _db_table(),
			   join( ',', @{ $fields } ),
			   join( ',', @{ $values } ) );

	return $sql;
}

sub __prep_value_for_db
{
	my ( $attr, $value ) = @_;

	my $isa = $attr -> { 'isa' };
	my $perform_coercion = 1;

	if( LittleORM::Model::Value -> this_is_value( $value ) )
	{
		unless( $value -> orm_coerce() )
		{
			$perform_coercion = 0;
		}
		$value = $value -> value(); # %)
	}

	if( $perform_coercion )
	{
		my $ftc = find_type_constraint( $isa );

		if( $ftc and $ftc -> has_coercion() )
		{
			$value = $ftc -> coerce( $value );
		}
	}

	my $rv = $value;

	unless( LittleORM::Model::Field -> this_is_field( $value ) )
	{
		if( $perform_coercion
		    and 
		    ( my $coerce_to = &__descr_attr( $attr, 'coerce_to' ) ) )
		{
			$rv = $coerce_to -> ( $value );
		}
		
		if( blessed( $value ) and &__descr_attr( $attr, 'foreign_key' ) )
		{
			my $foreign_key_attr_name = &__descr_attr( $attr, 'foreign_key_attr_name' );
			
			unless( $foreign_key_attr_name )
			{
				my $his_pk = $value -> __find_primary_key();
				$foreign_key_attr_name = $his_pk -> name();
			}
			$rv = $value -> $foreign_key_attr_name();
		}
	}
	
	return $rv;
}

sub __form_delete_sql
{
	my $self = shift;

	my @args = @_;
	my %args = @args;

	if( ref( $self ) )
	{
		if( my @pk = $self -> __find_primary_keys() )
		{
			foreach my $pk ( @pk )
			{

				my $pkname = $pk -> name();
				$args{ $pkname } = $self -> $pkname();
			}
		} else
		{
			foreach my $attr ( $self -> meta() -> get_all_attributes() )
			{
				my $aname = $attr -> name();
				$args{ $aname } = $self -> $aname();
			}
		}
	}

	my @where_args = $self -> __form_where( %args,
						&__for_write() );

	my $sql = sprintf( "DELETE FROM %s WHERE %s", $self -> _db_table(), join( ' AND ', @where_args ) );

	return $sql;
}

sub __should_ignore_on_write
{
	my ( $self, $attr ) = @_;
	my $rv = $self -> __should_ignore( $attr );

	unless( $rv )
	{
		if( &__descr_attr( $attr, 'primary_key' )
		    or
		    &__descr_attr( $attr, 'ignore_write' ) )
		{
			$rv = 1;
		}
	}

	return $rv;
}

sub __should_ignore
{
	my ( $self, $attr ) = @_;
	my $rv = 0;

	unless( $rv )
	{
		my $aname = $attr -> name();
		if( $aname =~ /^_/ )
		{
			$rv = 1;
		}
	}

	unless( $rv )
	{

		if( &__descr_attr( $attr, 'ignore' ) )
		{
			$rv = 1;
		}
	}

	return $rv;
}

sub __collect_field_names
{
	my $self = shift;
	my %args = @_;

	my @rv = ();

	my $groupby = undef;
	if( my $t = $args{ '_groupby' } )
	{
		my %t = map { $_ => 1 } grep { not LittleORM::Model::Field -> this_is_field( $_ ) } @{ $t };
		$groupby = \%t;
	}

	my $field_set = $args{ '_fieldset' };

	my $ta = ( $args{ '_table_alias' }
		   or
		   $self -> _db_table() );

QGVfwMGQEd15mtsn:
	foreach my $attr ( $self -> meta() -> get_all_attributes() )
	{
		if( $self -> __should_ignore( $attr ) )
		{
			next QGVfwMGQEd15mtsn;
		}

		my $aname = $attr -> name();

		my $db_fn = $ta .
		            '.' .
			    &__get_db_field_name( $attr );

		if( $groupby )
		{
			if( exists $groupby -> { $aname } )
			{
				push @rv, $db_fn;
			}

		} else
		{
			unless( $field_set )
			{
				push @rv, $db_fn;
			}
		}
	}

	if( $field_set )
	{
		foreach my $f ( @{ $field_set } )
		{
			unless( LittleORM::Model::Field -> this_is_field( $f ) )
			{
				$f = $self -> borrow_field( $f,
							    select_as => &__get_db_field_name( $self -> meta() -> find_attribute_by_name( $f ) ) );
			}

			my $select = $f -> form_field_name_for_db_select_with_as( $ta );

			if( $f -> model() )
			{
#				unless( $f -> model() eq $self )
#				{
				my $ta = $f -> determine_ta_for_field_from_another_model( $args{ '_tables_used' } );
				$select = $f -> form_field_name_for_db_select_with_as( $ta );
#				}
			}
			push @rv, $select;# . ' AS ' . $f -> select_as();
		}
	}

	return @rv;
}

sub __form_get_sql
{
	my $self = shift;

	my @args = @_;
	my %args = @args;

	my @where_args = $self -> __form_where( @args,
						&__for_read() );

	my @fields_names = $self -> __collect_field_names( @args );

	my @tables_to_select_from = ( $self -> _db_table() );

	if( my $t = $args{ '_tables_to_select_from' } )
	{
		@tables_to_select_from = @{ $t };
	}

	my $distinct_select = '';

	if( my $d = $args{ '_distinct' } )
	{
		$distinct_select = 'DISTINCT';

		if( my @distinct_on = $self -> __get_distinct_on_attrs( $d ) )
		{
			my @fields = map { sprintf( "%s.%s",
						    ( $args{ '_table_alias' } or $self -> _db_table() ),
						    &__get_db_field_name( $_ ) ) } @distinct_on;

			$distinct_select .= sprintf( " ON ( %s ) ", join( ',', @fields ) );
		} else
		{

			warn( sprintf( "Don't know on what to DISTINCT (no PK and fields not passed) for %s",
				       ( ref( $self ) or $self ) ) );

		}
	}

	my $sql = sprintf( "SELECT %s %s FROM %s WHERE %s",
			   $distinct_select,
			   join( ',', @fields_names ),
			   join( ',', @tables_to_select_from ), 
			   join( ' ' . ( $args{ '_logic' } or 'AND' ) . ' ', @where_args ) );

	$sql .= $self -> __form_additional_sql( @args );

	return $sql;
}

sub __form_additional_sql
{
	my $self = shift;

	my @args = @_;
	my %args = @args;

	my $sql = '';

	$sql .= $self -> __form_additional_sql_groupby( @args );

	if( my $t = $args{ '_sortby' } )
	{
		if( ref( $t ) eq 'HASH' )
		{
			# then its like
			# { field1 => 'DESC',
			#   field2 => 'ASC' ... }

			my @pairs = ();

			while( my ( $k, $sort_order ) = each %{ $t } )
			{
				my $dbf = $k;

				if( my $t = $self -> meta() -> find_attribute_by_name( $k ) )
				{
					$dbf = ( $args{ '_table_alias' }
						 or
						 $self -> _db_table() ) .
						 '.' .
						 &__get_db_field_name( $t );

				}

				push @pairs, sprintf( '%s %s',
						      $dbf, 
						      $sort_order );
			}
			$sql .= ' ORDER BY ' . join( ',', @pairs );
		} elsif(  ref( $t ) eq 'ARRAY' )
		{ 
			my @pairs = ();

			my @arr = @{ $t };

			while( @arr )
			{
				my $k = shift @arr;
				my $sort_order = shift @arr;

				my $dbf = $k;
				if( my $t = $self -> meta() -> find_attribute_by_name( $k ) )
				{
					$dbf = ( $args{ '_table_alias' }
						 or
						 $self -> _db_table() ) . 
						 '.' .
						 &__get_db_field_name( $t );
				} elsif( LittleORM::Model::Field -> this_is_field( $k ) )
				{
					$dbf = $k -> form_field_name_for_db_select( $k -> table_alias()
										    or
										    $k -> determine_ta_for_field_from_another_model( $args{ '_tables_to_select_from' } ),
										    or
										    $args{ '_table_alias' }
										    or
										    $self -> _db_table() );
				}

				push @pairs, sprintf( '%s %s',
						      ( $dbf or $k ),
						      $sort_order );
			}
			$sql .= ' ORDER BY ' . join( ',', @pairs );

		} else
		{
			# then its attr name and unspecified order
			my $dbf = $t;

			if( my $t1 = $self -> meta() -> find_attribute_by_name( $t ) )
			{
				$dbf = ( $args{ '_table_alias' }
					 or
					 $self -> _db_table() ) . '.' . &__get_db_field_name( $t1 );
			} elsif( LittleORM::Model::Field -> this_is_field( $t ) )
			{
				$dbf = $t -> form_field_name_for_db_select( $t -> table_alias()
									    or
									    $args{ '_table_alias' }
									    or
									    $self -> _db_table() );
			}

			$sql .= ' ORDER BY ' . $dbf;
		}
	}

	if( my $t = int( $args{ '_limit' } or 0 ) )
	{
		$sql .= sprintf( ' LIMIT %d ', $t );
	}

	if( my $t = int( $args{ '_offset' } or 0 ) )
	{
		$sql .= sprintf( ' OFFSET %d ', $t );
	}

	return $sql;
}

sub __form_additional_sql_groupby
{
	my $self = shift;
	my %args = @_;
	my $rv = '';
	if( my $t = $args{ '_groupby' } )
	{
		$rv = ' GROUP BY ';


		my @sqls = ();

		my $ta = ( $args{ '_table_alias' }
			   or
			   $self -> _db_table() );

		foreach my $grp ( @{ $t } )
		{
			my $f = undef;

			if( LittleORM::Model::Field -> this_is_field( $grp ) )
			{
				# $self -> assert_field_from_this_model( $grp );

				my $use_ta = $ta;

				if( $grp -> model() and ( $grp -> model() ne $self ) )
				{
					$use_ta = $grp -> determine_ta_for_field_from_another_model( $args{ '_tables_used' } );
				}

				$f = $grp -> form_field_name_for_db_select( $use_ta );

			} else
			{
				$f = sprintf( "%s.%s",
					      $ta,
					      &__get_db_field_name( $self -> meta() -> find_attribute_by_name( $grp ) ) );
			}
			push @sqls, $f;
		}

		$rv .= join( ',', @sqls );
	}

	return $rv;
}

sub __process_clause_sys_arg_in_form_where
{
	my ( $self, $val, $args ) = @_;

	if( ref( $val ) eq 'ARRAY' )
	{
		my %more_args = ();
		
		if( my $ta = $args -> { '_table_alias' } )
		{
			$more_args{ 'table_alias' } = $ta;
		}
		
		$val = $self -> clause( @{ $val },
					%more_args );
		
		assert( ref( $val ) eq 'LittleORM::Clause' );
	} else
	{
		assert( ref( $val ) eq 'LittleORM::Clause' );
		if( my $ta = $args -> { '_table_alias' } )
		{
			unless( $val -> table_alias() )
			{
				if( ( ref( $self ) or $self ) eq $val -> model() )
				{
					my $copy = bless( { %{ $val } }, ref $val );
					$val = $copy;
					$val -> table_alias( $ta );
				}
				# my $copy = bless( { %{ $val } }, ref $val );
				# $val = $copy;
				# $val -> table_alias( $ta );
			}
		}
	}
	return $val;
}

sub __form_where
{
	my $self = shift;

	my @args = @_;
	my %args = @args;

	my @where_args = ();
	my $dbh = $self -> __get_dbh( @args );


fhFwaEknUtY5xwNr:
	while( my $attr = shift @args )
	{
		my $val = shift @args;

		if( $attr eq '_where' )
		{
			push @where_args, $val;

		} elsif( $attr eq '_clause' )
		{
			$val = $self -> __process_clause_sys_arg_in_form_where( $val, 
										\%args );
			push @where_args, $val -> sql();
		}

		if( $attr =~ /^_/ ) # skip system agrs, they start with underscore
		{
			next fhFwaEknUtY5xwNr;
		}

		my ( $op, $col ) = ( undef, undef );
		my ( $val1_type, $val2_type ) = ( undef, undef );
		my $ta = ( $args{ '_table_alias' } or $self -> _db_table() );

		( $op,
		  $val,
		  $col,
		  $val1_type,
		  $val2_type ) = $self -> determine_op_and_col_and_correct_val( $attr, $val, $ta, \%args, $dbh ); # this
														  # is
														  # not
														  # a
														  # structured
														  # method,
														  # this
														  # is
														  # just
														  # code
														  # moved
														  # away
														  # from
														  # growing
														  # too
														  # big
														  # function,
														  # hilarious
														  # comment
														  # formatting
														  # btw,
														  # thx
														  # emacs
		if( $op )
		{
			my $f = $col;

			unless( ( exists $args{ '_include_table_alias_into_sql' } )
				and
				( $args{ '_include_table_alias_into_sql' } == 0 ) )
			{
				$f = $ta . '.' . $f;
			}
					 
			if( LittleORM::Model::Field -> this_is_field( $attr ) )
			{
				$f = $attr -> form_field_name_for_db_select( $attr -> table_alias() or $ta );
			}

			my $cast = '';

			if( $val1_type and $val2_type and ( $val1_type ne $val2_type ) )
			{
				$cast = '::' . $val1_type;
			}

			push @where_args, sprintf( '%s %s %s%s', 
						   $f,
						   $op,
						   $val,
						   $cast );
		}
	}

	unless( @where_args )
	{
		@where_args = ( '3=3' );
	}
	# print Data::Dumper::Dumper( \@where_args );
	# print Carp::longmess() . "\n\n\n";
	return @where_args;
}

sub determine_op_and_col_and_correct_val
{
	my ( $self, $attr, $val, $ta, $args, $dbh ) = @_;

	my $op = '=';
	my $col = 'UNUSED';
	my ( $dbf_type1, $dbf_type2 ) = ( undef, undef );
	my $class_attr = undef;
	
	unless( LittleORM::Model::Field -> this_is_field( $attr ) )
	{
		assert( $class_attr = $self -> meta() -> find_attribute_by_name( $attr ),
			sprintf( 'invalid attribute: "%s"', $attr ) );
		
		if( &__descr_attr( $class_attr, 'ignore' ) )
		{
			$op = undef;
		} else
		{
			$attr = $self -> borrow_field( $class_attr -> name() );
			$col = &__get_db_field_name( $class_attr );
		}
	}

	if( $op and LittleORM::Model::Field -> this_is_field( $attr ) )
	{
		unless( $class_attr )
		{
			if( $attr -> base_attr() )
			{
				assert( $class_attr = $attr -> model() -> meta() -> find_attribute_by_name( $attr -> base_attr() ) );
			}
		}

		$dbf_type1 = $attr -> db_field_type();

		if( ref( $val ) eq 'HASH' )
		{
			if( $args -> { '__we_do_insert_now' } )
			{
				$val = $self -> __prep_value_for_db_w_field( &__prep_value_for_db( $class_attr, $val ),
									     $ta,
									     $args,
									     $dbh );
			} else
			{
				my %t = %{ $val };
				my $rval = undef;
				( $op, $rval ) = each %t;
				
				if( ref( $rval ) eq 'ARRAY' )
				{
					$val = sprintf( '(%s)', join( ',', map { $self -> __prep_value_for_db_w_field( &__prep_value_for_db( $class_attr, $_ ),
														       $ta,
														       $args,
														       $dbh ) } @{ $rval } ) );
					
				} else
				{
					$val = $self -> __prep_value_for_db_w_field( &__prep_value_for_db( $class_attr, $rval ),
										     $ta,
										     $args,
										     $dbh );
					
				}
			}
			
		} elsif( ref( $val ) eq 'ARRAY' )
		{
			if( $args -> { '__we_do_insert_now' } )
			{

				$val = &LittleORM::Db::dbq( $self -> __prep_value_for_db_w_field( &__prep_value_for_db( $class_attr, $val ),
											    $ta,
											    $args ),
						      $dbh );


				# my @values = map { $self -> __prep_value_for_db_w_field( &__prep_value_for_db( $class_attr, $_ ),
				# 							 $ta,
				# 							 $args ) } @{ $val };
				# $val = &LittleORM::Db::dbq( \@values, $dbh );

			} else
			{

				if( my @values = map { $self -> __prep_value_for_db_w_field( &__prep_value_for_db( $class_attr, $_ ),
											     $ta,
											     $args, 
											     $dbh ) } @{ $val } )
				{
					$val = sprintf( "(%s)", join( ',', @values ) );
					$op = 'IN';
				} else
				{
					$val = "ANY('{}')";
				}
			}
			
		} elsif( LittleORM::Model::Field -> this_is_field( $val ) )
		{ 
			$dbf_type2 = $val -> db_field_type();
			my $use_ta = ( $val -> table_alias() or $ta );
			if( $val -> model() )
			{
				unless( $val -> model() eq $self )
				{
					$use_ta = $val -> determine_ta_for_field_from_another_model( $args -> { '_tables_used' } );
				}

			}
			$val = $val -> form_field_name_for_db_select( $use_ta );
		} else
		{
			if( LittleORM::Model::Value -> this_is_value( $val ) )
			{
				$dbf_type2 = $val -> db_field_type();
			}
			$val = $self -> __prep_value_for_db_w_field( &__prep_value_for_db( $class_attr, $val ),
								     $ta,
								     $args,
								     $dbh );
		}
	}

	return ( $op, $val, $col, $dbf_type1, $dbf_type2 );
}

sub __prep_value_for_db_w_field
{
	my ( $self, $v, $ta, $args, $dbh ) = @_;

	my $val = $v;

	if( LittleORM::Model::Field -> this_is_field( $v ) )
	{
		my $use_ta = $ta;
		if( $v -> model() )
		{
			unless( $v -> model() eq $self )
			{
				$use_ta = $v -> determine_ta_for_field_from_another_model( $args -> { '_tables_used' } );
			}

		}

		$val = $v -> form_field_name_for_db_select( $use_ta );

	} elsif( $dbh )
	{
		$val = &LittleORM::Db::dbq( $v,
				      $dbh );
	}
	    

	return $val;
}

sub __find_primary_key
{
	my $self = shift;

	my @pk = $self -> __find_primary_keys();

	return $pk[ 0 ];
}


sub __find_primary_keys
{
	my $self = shift;

	my @rv = ();

	foreach my $attr ( $self -> meta() -> get_all_attributes() )
	{
		if( my $pk = &__descr_attr( $attr, 'primary_key' ) )
		{
			push @rv, $attr;
		}
	}
	return @rv;
}

sub __descr_or_undef
{
	my $attr = shift;

	my $rv = undef;

	if( $attr -> can( 'description' ) )
	{
		$rv = $attr -> description();
	}
	
	return $rv;
}

sub __get_db_field_name
{
	my $attr = shift;

	assert( $attr );

	my $rv = $attr -> name();

	if( my $t = &__descr_attr( $attr, 'db_field' ) )
	{
		$rv = $t;
	}
	
	return $rv;
}

sub __descr_attr
{
	my $attr = shift;
	my $attr_attr_name = shift;

	my $rv = undef;

	if( my $d = &__descr_or_undef( $attr ) )
	{
		if( my $t = $d -> { $attr_attr_name } )
		{
			$rv = $t;
		}
	}

	return $rv;
}

42;
