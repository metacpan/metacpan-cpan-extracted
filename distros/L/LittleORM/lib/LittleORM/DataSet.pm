#!/usr/bin/perl

use strict;


package LittleORM::DataSet;
use Moose;

#use LittleORM::DataSet::Field ();

 # 'model' => ( is => 'rw', isa => 'Str' );
 # 'dbfield' => ( is => 'rw', isa => 'Str' );
 # 'base_attr' => ( is => 'rw', isa => 'Str' );
 # 'value' => ( is => 'rw' );


use Carp::Assert 'assert';

#has 'fields' => ( is => 'rw', isa => 'ArrayRef[LittleORM::DataSet::Field]', default => sub { [] } );
has 'fields' => ( is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { [] } );

sub add_to_set
{
	my ( $self, $item ) = @_;

	push @{ $self -> fields() }, $item;
}

our $AUTOLOAD;
sub AUTOLOAD
{
	my $self = shift;
	$AUTOLOAD =~ s/^LittleORM::DataSet:://;
	return $self -> field_by_name( $AUTOLOAD );
}


sub field
{
	my ( $self, $field ) = @_;


	my $rv = $self -> field_by_name( $field -> select_as() );

	# if( ( my $m = $field -> model() ) and ( my $attr = $field -> base_attr() ) and $field -> type_preserve() )
	# {
	# 	my $attr = $m -> meta() -> find_attribute_by_name( $attr );
	# 	$rv = $m -> __lazy_build_value_actual( $attr, $rv );
	# }

	return $rv;
}

sub field_by_name
{
	my ( $self, $name ) = @_;

	my $rv = undef;
	my $found = 0;

	unless( $found )
	{
OnR4gMKVoLEq1YDH:
		foreach my $f ( @{ $self -> fields() } )
		{
			if( my $m = $f -> { 'model' } )
			{
				my $attr = undef;

				if( my $t = $f -> { 'base_attr' } )
				{
					assert( $attr = $m -> meta() -> find_attribute_by_name( $t ) );#, $m . " - " . $t );
				} else
				{
					$attr = $m -> __find_attr_by_its_db_field_name( $f -> { 'dbfield' } );
				}

				if( $attr
				    and
				    ( $f -> { 'dbfield' } eq $name ) )
				{
				# say no more!
					$found = 1;

					if( $f -> { 'orm_coerce' } )
					{
						$rv = $m -> __lazy_build_value_actual( $attr, $f -> { 'value' } );
					} else
					{
						$rv = $f -> { 'value' };
					}


					last OnR4gMKVoLEq1YDH;
				}
			}
		}
	}

	unless( $found )
	{
iaBPEvHDdSBDBo1O:
		foreach my $f ( @{ $self -> fields() } )
		{
			if( $name eq $f -> { 'dbfield' } )
			{
				$found = 1;
				$rv = $f -> { 'value' };
				
				last iaBPEvHDdSBDBo1O;
			}
		}
	}

	unless( $found )
	{
		assert( 0, sprintf( '%s: not found', $name ) );
	}

	return $rv;
}


__PACKAGE__ -> meta() -> make_immutable();

4242;
