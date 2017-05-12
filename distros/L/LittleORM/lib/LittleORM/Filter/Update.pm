#!/usr/bin/perl
use strict;

package LittleORM::Filter;

# update related subs moved here to keep module file size from growing
# too much

sub update
{
	my $self = shift;

	assert( scalar @{ $self -> joined_tables() } == 0,
		'update is not defined for filter with joined tables' );

	assert( ( not defined $self -> returning_field() ),
		'update is not defined for filter with returning_field() set' );

	map { assert( $_ -> model() eq $self -> model() ); } @{ $self -> clauses() };

	return $self -> call_orm_method( 'update',
					 &LittleORM::Model::__for_write(),
					 @_,
					 _include_table_alias_into_sql => 0 );
	
}

42;
