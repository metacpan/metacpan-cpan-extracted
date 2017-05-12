use strict;

package LittleORM::Model;

# Extend LittleORM::Model capabilities with clause support:

sub clause
{
	my $self = shift;

	my @args = @_;

	my $class = ( ref( $self ) or $self );

	my @clause_creation_args = ( model => $class,
				     LittleORM::Clause -> __smart_clause_creation_args( @args ) );

	return LittleORM::Clause -> new( @clause_creation_args );
}

package LittleORM::Clause;

use Moose;

has 'logic' => ( is => 'rw', isa => 'Str', default => 'AND' );
has 'model' => ( is => 'rw', isa => 'Str', required => 1 );
has 'table_alias' => ( is => 'rw', isa => 'Maybe[Str]' );
has 'cond' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );

use Carp::Assert 'assert';
use Data::Dumper 'Dumper';

sub __smart_clause_creation_args
{
	my $self = shift;
	my @args = @_;

	my %my_attrs = map { $_ -> name() => 1 } $self -> meta() -> get_all_attributes();
	my @goes_into_cond = ();
	my @goes_as_is = ();
	my $seen_cond = 0;

	while( my $arg = shift @args )
	{
		my $value = shift @args;

		if( exists $my_attrs{ $arg } )
		{
			if( $arg eq 'cond' )
			{
				$seen_cond = 1;
			}

			push @goes_as_is, ( $arg => $value );
		} else
		{
			push @goes_into_cond, ( $arg => $value );
		}
	}

	if( @goes_into_cond )
	{
		assert( ( $seen_cond == 0 ),
			'ambiguous clause creation arguments: ' . Dumper( \@args ) );
		push @goes_as_is, ( cond => \@goes_into_cond );
	}

	return @goes_as_is;
}

sub sql
{
	my $self = shift;

	my @rv = $self -> gen_clauses( &LittleORM::Model::__for_read(), # default, can be overwritten with following in @_
				       @_ );

	return sprintf( ' ( %s ) ', join( ' '. $self -> logic() . ' ', @rv ) );
}

sub gen_clauses
{
	my $self = shift;
	my @args = @_;

	my @rv = ();

	my @c = @{ $self -> cond() };

	while( @c )
	{
		my $item = shift @c;

		if( ref( $item ) eq 'LittleORM::Clause' )
		{
			if( ( $item -> model() eq $self -> model() ) and ( my $ta = $self -> table_alias() ) and ( not $item -> table_alias() ) )
			{
				# copy obj ?
				my $copy = bless( { %{ $item } }, ref $item );
				$item = $copy;
				$item -> table_alias( $ta );
			}

			push @rv, $item -> sql();
		} else
		{
			my $value = shift @c;

			push @rv, $self -> model() -> __form_where( @args,
								    $item => $value,
								    _table_alias => $self -> table_alias() );

		}
	}

	unless( @rv )
	{
		@rv = ( '2=2' );
	}

	return @rv;

}


42;
