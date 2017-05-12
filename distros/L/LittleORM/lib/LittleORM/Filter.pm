#!/usr/bin/perl

use strict;

package LittleORM::Model;
use LittleORM::Model::Field ();

# Extend LittleORM::Model capabilities with filter support:

sub f
{
	my $self = shift;
	return $self -> filter( @_ );
}

sub _disambiguate_filter_args
{
	my ( $self, $args ) = @_;

	{
		assert( ref( $args ) eq 'ARRAY', 'sanity assert' );

		my $argsno = scalar @{ $args };
		my $class = ( ref( $self ) or $self );
		my @disambiguated = ();

		my $i = 0;
		foreach my $arg ( @{ $args } )
		{
			if( blessed( $arg ) and $arg -> isa( 'LittleORM::Filter' ) )
			{
				unless( $i % 2 )
				{
					# this will wrk only with single column PKs

					if( my $attr_co_connect = &LittleORM::Filter::find_corresponding_fk_attr_between_models( $class,
															   $arg -> model() ) )
					{
						push @disambiguated, $attr_co_connect;
						$i ++;

					} elsif( my $rev_connect = &LittleORM::Filter::find_corresponding_fk_attr_between_models( $arg -> model(),
															    $class ) )
					{
						# print $class, "\n";
						# print $arg -> model(), "\n";
						# print $rev_connect, "\n";

						my $to_connect_with = 0;

						{
							assert( my $attr = $arg -> model() -> meta() -> find_attribute_by_name( $rev_connect ) );

							if( my $foreign_key_attr_name = &LittleORM::Model::__descr_attr( $attr, 'foreign_key_attr_name' ) )
							{
								$to_connect_with = $foreign_key_attr_name;
							} else
							{
								$to_connect_with = $class -> __find_primary_key() -> name();
							}

						}

						push @disambiguated, $to_connect_with;
						unless( $arg -> returning() )
						{
							$arg -> returning( $rev_connect );
						}

						$i ++;


					} else
					{
						assert( 0,
							sprintf( "Can not automatically connect %s and %s - do they have FK between?",
								 $class,
								 $arg -> model() ) );
					}
				}
			} elsif( blessed( $arg ) and $arg -> isa( 'LittleORM::Clause' ) )
			{
				unless( $i % 2 )
				{
					push @disambiguated, '_clause';
					$i ++;
				}
			}

			push @disambiguated, $arg;
			$i ++;
		}
		$args = \@disambiguated;
	}

	return $args;
}

sub filter
{
	my ( $self, @args ) = @_;

	my $class = ( ref( $self ) or $self );

	my $rv = LittleORM::Filter -> new( model => $class );

	$rv -> push_anything_appropriate( @args );

	return $rv;
}


package LittleORM::Filter;

# Actual filter implementation:

use Moose;

has 'model' => ( is => 'rw', isa => 'Str', required => 1 );
has 'table_alias' => ( is => 'rw', isa => 'Str', default => \&get_uniq_alias_for_table );
has 'returning' => ( is => 'rw', isa => 'Maybe[Str]' ); # return column name for connecting with other filter
has 'returning_field' => ( is => 'rw', isa => 'Maybe[LittleORM::Model::Field]', default => undef );
has 'clauses' => ( is => 'rw', isa => 'ArrayRef[LittleORM::Clause]', default => sub { [] } );
has 'joined_tables' => ( is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { [] } );

use Carp::Assert 'assert';
use List::MoreUtils 'uniq';
use LittleORM::Filter::Update ();
use LittleORM::Clause ();

{
	my $counter = 0;

	sub get_uniq_alias_for_table
	{
		$counter ++;

		return "T" . $counter;
	}

}

sub borrow_field
{
	my $self = shift;

	my $rv = $self -> model() -> borrow_field( @_ );
	$rv -> table_alias( $self -> table_alias() );
	return $rv;
}

sub push_anything_appropriate
{
	my $self = shift;
	my @args = @_;

	my @clauseargs = ();
	assert( my $class = $self -> model(), 'must know my model' );

	@args = @{ $self -> model() -> _disambiguate_filter_args( \@args ) };
	assert( scalar @args % 2 == 0 );

	while( my $arg = shift @args )
	{
		my $val = shift @args;

		if( $arg eq '_return' )
		{
			if( LittleORM::Model::Field -> this_is_field( $val ) )
			{
				$val -> assert_model( $class );
				$self -> returning_field( $val );
			} else
			{

				assert( $self -> model() -> meta() -> find_attribute_by_name( $val ), sprintf( 'Incorrect %s attribute "%s" in return',
													       $class,
													       $val ) );
				$self -> returning( $val ); 
			}

		} elsif( $arg eq '_sortby' )
		{
			assert( 0, '_sortby is not allowed in filter' );

		} elsif( $arg eq '_exists' )
		{
			assert( $val and ( ( ref( $val ) eq 'HASH' )
					   or
					   $val -> isa( 'LittleORM::Filter' ) ) );
			$self -> connect_filter_exists( 'EXISTS', $val );

		} elsif( $arg eq '_not_exists' )
		{
			assert( $val and ( ( ref( $val ) eq 'HASH' )
					   or
					   $val -> isa( 'LittleORM::Filter' ) ) );
			$self -> connect_filter_exists( 'NOT EXISTS', $val );

		} elsif( blessed( $val ) and $val -> isa( 'LittleORM::Filter' ) )
		{

			$self -> connect_filter( $arg => $val );

		} elsif( blessed( $val ) and $val -> isa( 'LittleORM::Clause' ) )
		{
			$self -> push_clause( $val );
		} else
		{
			push @clauseargs, ( $arg, $val );
		}

	}

	{
		unless( @clauseargs )
		{
			@clauseargs = ( _where => '1=1' );
		}
		my $clause = LittleORM::Clause -> new( model => $class,
						 cond => \@clauseargs,
						 table_alias => $self -> table_alias() );

		$self -> push_clause( $clause );
	}

}

sub form_conn_sql
{
	my ( $self, $arg, $filter ) = @_;

	my $conn_sql = '';

	{
		my $ta1 = $self -> table_alias();
		my $ta2 = $filter -> table_alias();

		my $attr1_t = '';
		my $attr2_t = '';
		my $cast = '';

		my $arg1 = $arg;
		my $arg2 = $filter -> get_returning();

		my ( $f1, $f2 ) = ( '', '' );

		{
			my $attr1 = $self -> model() -> meta() -> find_attribute_by_name( $arg1 );

			assert( ( $attr1 or LittleORM::Model::Field -> this_is_field( $arg1 ) ),
				'Injalid attribute 1 in filter: ' . $arg1 );

			my $attr2 = $filter -> model() -> meta() -> find_attribute_by_name( $arg2 );
			assert( ( $attr2 or LittleORM::Model::Field -> this_is_field( $arg2 ) ),
				'Injalid attribute 2 in filter (much rarer case)' );

			
			if( ( $attr1 and $attr2 ) and ( my $fk = &LittleORM::Model::__descr_attr( $attr1, 'foreign_key' ) ) )
			{
				if( ( $fk eq $filter -> model() ) 
				    and
				    ( my $fkattr = &LittleORM::Model::__descr_attr( $attr1, 'foreign_key_attr_name' ) ) )
				{
					assert( $attr2 = $filter -> model() -> meta() -> find_attribute_by_name( $fkattr ),
						'Injalid attribute 2 in filter (subcase of much rarer case)' );
				}
			}
			if( $attr1 )
			{
				$attr1_t = &LittleORM::Model::__descr_attr( $attr1, 'db_field_type' );
				$f1 = sprintf( "%s.%s",
					       $ta1,
					       &LittleORM::Model::__get_db_field_name( $attr1 ) );
				
			} else
			{
				$f1 = $arg1 -> form_field_name_for_db_select( $ta1 );
			}

			if( $attr2 )
			{
				$attr2_t = &LittleORM::Model::__descr_attr( $attr2, 'db_field_type' );
				$f2 = sprintf( "%s.%s",
					       $ta2,
					       &LittleORM::Model::__get_db_field_name( $attr2 ) );

			} else
			{
				$f2 = $arg2 -> form_field_name_for_db_select( $ta2 );
			}

			if( $attr1_t and $attr2_t and ( $attr1_t ne $attr2_t ) )
			{
				$cast = '::' . $attr1_t;
			}

		}



		$conn_sql = sprintf( "%s=%s%s",
				     $f1,
				     $f2,				     
				     $cast );
	}

	return $conn_sql;

}


sub _look_for_connecting_args_in_args_and_do_it_in_a_compatible_way
{
	my $self = shift;
	
	my @kws = ( '_clause' );
	my %kws = map { $_ => 1 } @kws;

	my @rest_args = ();
	my $connecting_args = {};

	my $next_arg_is_what_we_need = undef;

	foreach my $t ( @_ )
	{
		if( $next_arg_is_what_we_need )
		{
			assert( not exists $kws{ $t } );
			$connecting_args -> { $next_arg_is_what_we_need } = $t;
			$next_arg_is_what_we_need = undef;

		} elsif( exists $kws{ $t } )
		{
			$next_arg_is_what_we_need = $t;
		} else
		{
			push @rest_args, $t;
		}
	}
	assert( not defined $next_arg_is_what_we_need );

	return ( \@rest_args, $connecting_args );
}

sub _get_connecting_clause_from_connecting_args
{
	my ( $self, $args ) = @_;

	my $rv = $args -> { '_clause' };

	if( ref( $rv ) eq 'ARRAY' )
	{
		$rv = $self -> model() -> clause( @{ $rv } );
	}

	return $rv;
}

sub connect_filter
{
	my $self = shift;

	my ( $rest_args, $connecting_args ) = $self -> _look_for_connecting_args_in_args_and_do_it_in_a_compatible_way( @_ );

	@_ = @{ $rest_args };
	my $connecting_clause = $self -> _get_connecting_clause_from_connecting_args( $connecting_args );

	my ( $arg, $filter ) = $self -> _sanitize_args_for_connecting( ArgAndFilter => \@_,
								       ConnectingClause => $connecting_clause );

	map { $self -> push_clause( $_, $filter -> table_alias() ) } @{ $filter -> clauses() };

	unless( $connecting_clause )
	{
		my $conn_sql = $self -> form_conn_sql( $arg, $filter );

		$connecting_clause = $self -> model() -> clause( cond => [ _where => $conn_sql ],
								 table_alias => $self -> table_alias() );

	}

	$self -> push_clause( $connecting_clause );

	map { $self -> _self_add_table_join( $_ ) } @{ $filter -> joined_tables() };
}

sub _valid_join_type
{
	my ( $self, $jtype ) = @_;

	my @known = ( 'JOIN', 'INNER JOIN', 'LEFT JOIN', 'RIGHT JOIN', 'LEFT OUTER JOIN', 'RIGHT OUTER JOIN', 'MEGAJOIN 3000' );
	my %known = map { $_ => 1 } @known;

	my $rv = 0;

	if( exists $known{ uc( $jtype ) } )
	{
		$rv = 1;
	}

	return $rv;
}

sub connect_filter_right_join
{
	my $self = shift;
	$self -> connect_filter_complex( 'RIGHT JOIN', @_ );
}

sub connect_filter_right_outer_join
{
	my $self = shift;
	$self -> connect_filter_complex( 'RIGHT OUTER JOIN', @_ );
}

sub connect_filter_left_join
{
	my $self = shift;
	$self -> connect_filter_complex( 'LEFT JOIN', @_ );
}

sub connect_filter_left_outer_join
{
	my $self = shift;
	$self -> connect_filter_complex( 'LEFT OUTER JOIN', @_ );
}

sub connect_filter_inner_join
{
	my $self = shift;
	$self -> connect_filter_complex( 'INNER JOIN', @_ );
}


sub connect_filter_join
{
	my $self = shift;
	$self -> connect_filter_complex( 'JOIN', @_ );
}

sub connect_filter_complex
{
	my $self = shift;
	my $type = shift;

	if( $type )
	{
		assert( $self -> _valid_join_type( $type ), 'I dont know this join type: ' . $type );

		my ( $rest_args, $connecting_args ) = $self -> _look_for_connecting_args_in_args_and_do_it_in_a_compatible_way( @_ );
		@_ = @{ $rest_args };

		my $connecting_clause = $self -> _get_connecting_clause_from_connecting_args( $connecting_args );
		my ( $arg, $filter ) = $self -> _sanitize_args_for_connecting( ArgAndFilter => \@_,
									       ConnectingClause => $connecting_clause );
		
		map { $self -> push_clause( $_, $filter -> table_alias() ) } @{ $filter -> clauses() };

		my $conn_sql = undef;
		
		if( $connecting_clause )
		{
			$conn_sql = $connecting_clause -> sql();
		} else
		{
			$conn_sql = $self -> form_conn_sql( $arg, $filter );
		}
		
		my %join_spec = ( type => $type,
				  to => { $self -> model() -> _db_table() => $self -> table_alias() },
				  table => { $filter -> model() -> _db_table() => $filter -> table_alias() },
				  on => $conn_sql ); 
		
		$self -> _self_add_table_join( \%join_spec );
		
		map { $self -> _self_add_table_join( $_ ) } @{ $filter -> joined_tables() };

	} else
	{
		$self -> connect_filter( @_ );
	}
}

sub _self_add_table_join
{
	my ( $self, $join_spec ) = @_;

	push @{ $self -> joined_tables() }, $join_spec;
}

sub _sanitize_args_for_connecting
{

	my $self = shift;

	my %args = @_;
	my ( $arg_and_filter,
	     $connecting_clause ) = @args{ 'ArgAndFilter',
					   'ConnectingClause' };

	my ( $arg, $filter ) = @{ $arg_and_filter };

	unless( $filter )
	{
		if( ref( $arg ) eq 'HASH' )
		{
			assert( scalar keys %{ $arg } == 1 );
			( $arg, $filter ) = %{ $arg };
		}
	}

	unless( $filter )
	{
		if( $arg and blessed( $arg ) and $arg -> isa( 'LittleORM::Filter' ) )
		{
			$filter = $arg;

			unless( $connecting_clause )
			{
				my $args = $self -> model() -> _disambiguate_filter_args( [ $arg ] );

				( $arg, $filter ) = @{ $args };
			}

		} else
		{
			assert( 0, 'check args sanity' );
		}
	}

	return ( $arg, $filter );
}

sub connect_filter_exists
{
	my $self = shift;
	my $exists_keyword = shift;

	my ( $arg, $filter ) = $self -> _sanitize_args_for_connecting( ArgAndFilter => \@_ );

	my $exf = LittleORM::Filter -> new( model => $filter -> model(),
				      table_alias => $filter -> table_alias() );
	

	map { $exf -> push_clause( $_, $filter -> table_alias() ) } @{ $filter -> clauses() };
	
	my $conn_sql = $self -> form_conn_sql( $arg, $filter );

	{
		my $c1 = $self -> model() -> clause( cond => [ _where => $conn_sql ],
						     table_alias => $self -> table_alias() );


		$exf -> push_clause( $c1 );
	}

	{

		my $select_from_sql_part = '';

		{
			my %t = $exf -> all_tables_used_in_filter();
			# do not include outer table inside EXISTS select:
			$select_from_sql_part = join( ',', map { $t{ $_ } .
								 " " .
								 $_ }
						           grep { $_ ne $self -> table_alias() }
						           keys %t );

		}

		my $sql = sprintf( " %s (SELECT 1 FROM %s WHERE %s LIMIT 1) ",
				   $exists_keyword,
				   $select_from_sql_part,
				   join( ' AND ', $exf -> translate_into_sql_clauses() ) );
		
		my $c1 = $self -> model() -> clause( cond => [ _where => $sql ],
						     table_alias => $self -> table_alias() );
		
		
		$self -> push_clause( $c1 );
	}
	
	return 0;
}

sub push_clause
{
	my ( $self, $clause, $table_alias ) = @_;


	unless( $clause -> table_alias() )
	{
		unless( $table_alias )
		{
			if( $self -> model() eq $clause -> model() )
			{
				$table_alias = $self -> table_alias();

				# maybe clone here to preserve original clause obj ?
				my $copy = bless( { %{ $clause } }, ref $clause );
				$clause = $copy;
				$clause -> table_alias( $table_alias );
			}
		}
	}

	if( $clause -> table_alias() )
	{

		push @{ $self -> clauses() }, $clause;

	} else
	{
		assert( $self -> model() ne $clause -> model(), 'sanity assert' );

		my $other_model_filter = $clause -> model() -> filter( $clause );
		$self -> connect_filter( $other_model_filter );


	}



	# if( $self -> model() eq $clause -> model() )
	# {

	# } else
	# {
	# 	my $other_model_filter = $clause -> model() -> filter( _clause => $clause );
	# 	$self -> connect_filter( $other_model_filter );
	# }


	return $self -> clauses();
}

sub get_returning
{
	my $self = shift;

	my $rv = $self -> returning();
	
	if( $rv )
	{
		1;
	} elsif( my $rv_f = $self -> returning_field() )
	{
		$rv = $rv_f;

	} else
	{
		assert( my $pk = $self -> model() -> __find_primary_key(),
			sprintf( 'Model %s must have PK or specify "returning" manually',
				 $self -> model() ) );
		$rv = $pk -> name();
	}

	return $rv;

}

sub translate_into_sql_clauses
{
	my $self = shift;
	my @args = @_;

	my $clauses_number = scalar @{ $self -> clauses() };

	my @all_clauses_together = ();

	for( my $i = 0; $i < $clauses_number; $i ++ )
	{
		my $clause = $self -> clauses() -> [ $i ];
		my $sql = $clause -> sql( $self -> _grep_out_non_system_and_clauses( @args ) );
		push @all_clauses_together, $sql;
	}

	return @all_clauses_together;
}

sub _grep_out_non_system_and_clauses
{
	my $self = shift;

	my @args = @_;
	my @rv = ();

	while( my $arg = shift @args )
	{
		my $val = shift @args;
		if( ( $arg =~ /^_/ ) and ( $arg ne '_clause' ) ) # looks crutchy
		{
			push @rv, ( $arg, $val );
		}
	}

	return @rv;
}

sub _table_spec_with_join_support
{
	my ( $self, $table, $depth ) = @_;

	$depth = ( $depth or 0 );

	assert( $depth < 100, 'Too deep in.' );

	my ( $tn, $ta ) = %{ $table };

	my $rv = '';

	if( ( $depth == 0 ) and &__in_skip_list( my $s = $tn . ' ' . $ta ) )
	{
		return $rv;

	} elsif( $depth ) # or &__in_skip_list( $s ) )
	{
		1;
	} else
	{
		$rv = $s;
	}

	foreach my $jt ( @{ $self -> joined_tables() } )
	{
		my ( $jt_to_n, $jt_to_a ) = %{ $jt -> { 'to' } };

		if( ( $jt_to_n eq $tn )
		    and
		    ( $jt_to_a eq $ta ) )
		{

			my ( $jt_n, $jt_a ) = %{ $jt -> { 'table' } };
			my $jspec = $jt_n . ' ' . $jt_a;

			$rv .= ' ' .
			    $jt -> { 'type' } .
			    ' ' .
			    $jspec .
			    ' ON ( ' . $jt -> { 'on' } . ' ) ';

			&__add_to_skip_list( $jspec );
			$rv .= $self -> _table_spec_with_join_support( $jt -> { 'table' }, $depth + 1 );
		}
	}
	return $rv;
}

{
	# revisit later TODO

	my %skip_list = ();

	sub __clear_skip_list
	{
		%skip_list = ();
	}

	sub __add_to_skip_list
	{
		my $what = shift;
		$skip_list{ $what } = 1;
	}

        sub __in_skip_list
        {
		my $what = shift;

		my $rv = 0;
		
		if( exists $skip_list{ $what } )
		{
			$rv = 1;
		}
		return $rv;
	}
}


sub _all_tables_used_in_filter_joinable # TODO
{
	my $self = shift;

	my @rv = ();

	my %skip_duplicates = ();

	&__clear_skip_list();

J1Dz1VhnaYMJllvy:
	foreach my $c ( @{ $self -> clauses() } )
	{
		my $t = $c -> model() -> _db_table();
		assert( my $ta = $c -> table_alias(), 'Unknown clause origin' );

		if( exists $skip_duplicates{ $ta } )
		{
			1;
		} else
		{
			if( my $spec = $self -> _table_spec_with_join_support( { $t => $ta } ) )
			{
				push @rv, $spec;
			}

			$skip_duplicates{ $ta } = 1;
		}
	}

	&__clear_skip_list();

	return \@rv;
}

sub all_tables_used_in_filter
{
	my $self = shift;

	my %rv = ();

J1Dz1VhnaYMJllvy:
	foreach my $c ( @{ $self -> clauses() } )
	{
		my $t = $c -> model() -> _db_table();
		assert( my $ta = $c -> table_alias(), 'Unknown clause origin' );

		# foreach my $join_spec ( @{ $self -> joined_tables() } )
		# {
		# 	if( exists $join_spec -> { 'table' } -> { $t } )
		# 	{
		# 		next J1Dz1VhnaYMJllvy;
		# 	}
		# }
		$rv{ $ta } = $t;
	}

	return %rv;
}

sub get_many
{
	my $self = shift;

	return $self -> call_orm_method( 'get_many', @_,
					 &LittleORM::Model::__for_read() );
}

sub get
{
	my $self = shift;

	return $self -> call_orm_method( 'get', @_,
					 &LittleORM::Model::__for_read() );
}

sub count
{
	my $self = shift;

	return $self -> call_orm_method( 'count', @_,
					 &LittleORM::Model::__for_read() );
}

sub max
{
	my $self = shift;

	return $self -> call_orm_method( 'max', @_,
					 &LittleORM::Model::__for_read() );
}

sub min
{
	my $self = shift;

	return $self -> call_orm_method( 'min', @_,
					 &LittleORM::Model::__for_read() );
}

sub delete
{
	assert( 0, 'Delete is not supported in LittleORM::Filter. Just map { $_ -> delete() } at what get_many() returns.' );
}

sub call_orm_method
{
	my $self = shift;
	my $method = shift;

	my @args = @_;

	my %all = $self -> all_tables_used_in_filter();
	my $all = $self -> _all_tables_used_in_filter_joinable();
	
	my @targs = $self -> _correct_args_for_sql_translation_when_calling_certain_orm_methods( $method, @args );

	return $self -> model() -> $method( $self -> _correct_args_for_calling_certain_orm_methods( $method, @args ),
					    _table_alias => $self -> table_alias(),
					    _tables_used => [ map { sprintf( "%s %s", $all{ $_ }, $_ ) } keys %all ],
					    _tables_to_select_from => $all,
					    _where => join( ' AND ', $self -> translate_into_sql_clauses( @targs ) ) );
}

sub _correct_args_for_calling_certain_orm_methods
{
	my $self = shift;
	my $method = shift;

	my @args = @_;

	my $replace_attr_with_field = sub { my $method = shift;
					    my @attrs = @_;
					    my $aname = $attrs[ 0 ];
					    unless( LittleORM::Model::Field -> this_is_field( $aname ) )
					    {
						    assert( my $attr = $self -> model() -> meta() -> find_attribute_by_name( $aname ) );
						    my $f = $self -> model() -> borrow_field( $aname,
											      select_as => $method );
						    $attrs[ 0 ] = $f;
					    }
					    return @attrs; };
					    
	my %cleanse = ( min => $replace_attr_with_field,
			max => $replace_attr_with_field );

	if( my $code = $cleanse{ $method } )
	{
		@args = $code -> ( $method, @args );
	}

	return @args;
}

sub _correct_args_for_sql_translation_when_calling_certain_orm_methods
{
	my $self = shift;
	my $method = shift;

	my @args = @_;

	my $skip_first_arg = sub { shift @_ ; return @_; };

	my %cleanse = ( 'min' => $skip_first_arg,
			'max' => $skip_first_arg );

	if( my $code = $cleanse{ $method } )
	{
		@args = $code -> ( @args );
	}

	return @args;
}

sub find_corresponding_fk_attr_between_models
{
	my ( $model1, $model2 ) = @_;

	my $rv = undef;

DQoYV7htzKfc5YJC:
	foreach my $attr ( $model1 -> meta() -> get_all_attributes() )
	{
		if( my $fk = &LittleORM::Model::__descr_attr( $attr, 'foreign_key' ) )
		{
			if( $fk eq 'yes' )
			{
				assert( my $tc = $attr -> type_constraint(), 
					sprintf( '%s attr type_constraint() is missing, did you specify "isa"?',
						 $attr -> name() ) );
				assert( $fk = $tc -> name() );
			}

			if( $model2 eq $fk )
			{
				$rv = $attr -> name();
			}
		}
	}
	
	return $rv;
}

42;
