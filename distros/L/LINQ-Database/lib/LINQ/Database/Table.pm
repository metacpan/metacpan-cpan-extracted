use 5.008003;
use strict;
use warnings;

package LINQ::Database::Table;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Class::Tiny qw( database name sql_select sql_where sql_alias _join_info );

use LINQ ();
use LINQ::Util::Internal ();
use LINQ::Database::Util ();
use Object::Adhoc ();
use Scalar::Util ();

use Role::Tiny::With ();
Role::Tiny::With::with 'LINQ::Collection';

sub _clone {
	my ( $self ) = ( shift );
	
	my %args = ( %$self, @_ );
	delete $args{'_linq_iterator'};
	ref( $self )->new( %args );
}

sub select {
	my ( $self ) = ( shift );
	my $selection = LINQ::Util::Internal::assert_code( @_ );
	
	if ( ! defined($self->sql_select) ) {
		my $columns = LINQ::Database::Util::selection_to_sql( $selection );
		return $self->_clone( sql_select => $selection ) if $columns;
	}
	
	$self->LINQ::Collection::select( $selection );
}

sub where {
	my ( $self ) = ( shift );
	my $assertion = LINQ::Util::Internal::assert_code( @_ );
	
	if ( ! defined($self->sql_where) and ! defined($self->sql_select) ) {
		my $filter = LINQ::Database::Util::assertion_to_sql( $assertion );
		return $self->_clone( sql_where => $assertion ) if $filter;
	}
	
	$self->LINQ::Collection::where( $assertion );
}

sub to_iterator {
	my ( $self ) = ( shift );
	$self->_linq_iterator->to_iterator;
}

sub to_list {
	my ( $self ) = ( shift );
	$self->_linq_iterator->to_list;
}

sub to_array {
	my ( $self ) = ( shift );
	$self->_linq_iterator->to_array;
}

sub _linq_iterator {
	my ( $self ) = ( shift );
	$self->{_linq_iterator} ||= $self->_build_linq_iterator;
}

sub _build_linq_iterator {
	my ( $self ) = ( shift );
	
	my $sth = $self->_build_sth;
	my $map = defined( $self->sql_select )
		? $self->sql_select
		: sub { Object::Adhoc::object( $_ ) };
	my $started = 0;
	
	LINQ::LINQ( sub {
		if ( not $started ) {
			$sth->execute;
			++$started;
		}
		local $_ = $sth->fetchrow_hashref or return LINQ::END;
		return $map->( $_ );
	} );
}

sub _build_sth {
	my ( $self ) = ( shift );
	
	my $sql_select = defined($self->sql_select) ? $self->sql_select : '*';
	if ( ref( $sql_select ) ) {
		$sql_select = LINQ::Database::Util::selection_to_sql(
			$sql_select,
			sub { $self->database->quote_identifier( @_ ) },
		) || '*';
	}
	
	my $sql_where = defined($self->sql_where) ? $self->sql_where : '';
	if ( ref( $sql_where ) ) {
		$sql_where = LINQ::Database::Util::assertion_to_sql(
			$sql_where,
			sub { $self->database->quote_identifier( @_ ) },
			sub { $self->database->quote( @_ ) },
		) || '';
	}
	
	if ( $self->_join_info ) {
		my $sql = sprintf(
			'SELECT %s FROM %s t1 %s JOIN %s t2 ON t1.%s=t2.%s%s',
			$sql_select,
			$self->name,
			( $self->_join_info->[0] =~ /^-(?:left|right|inner)$/ )
				? uc(substr($self->_join_info->[0], 1))
				: '',
			$self->database->quote_identifier( $self->_join_info->[1] ),
			$self->database->quote_identifier( $self->_join_info->[2] ),
			$self->database->quote_identifier( $self->_join_info->[3] ),
			( $sql_where ? " WHERE $sql_where" : $sql_where ),
		);
		return $self->database->prepare($sql);
	}
	
	$self->database->prepare( sprintf(
		'SELECT %s FROM %s%s',
		$sql_select,
		$self->name,
		( $sql_where ? " WHERE $sql_where" : $sql_where ),
	) );
}

sub join {
	my ( $self, $other, $hint, $field1, $field2, $joiner );
	
	if ( @_ == 6 ) {
		( $self, $other, $hint, $field1, $field2, $joiner ) = @_;
	}
	else {
		( $self, $other ) = ( shift, shift );
		( $field1, $field2, $joiner ) = @_;
		$hint = '-outer';
	}
	
	if ( Scalar::Util::blessed($self)   and $self->isa(__PACKAGE__)
	and  Scalar::Util::blessed($other)  and $other->isa(__PACKAGE__)
	and  Scalar::Util::blessed($field1) and $field1->isa('LINQ::FieldSet::Single')
	and  Scalar::Util::blessed($field2) and $field2->isa('LINQ::FieldSet::Single')
	and  $joiner eq '-auto'
	and  $self->database == $other->database
	and  !$self->_join_info
	and  !$other->_join_info and !$other->sql_where and !$other->sql_select
	) {
		return $self->_clone(
			_join_info => [ $hint, $other->name, $field1->fields->[0]->name, $field2->fields->[0]->name ]
		);
	}
	
	if ( $joiner eq -auto ) {
		require LINQ::DSL;
		$joiner = LINQ::DSL::HashSmush();
	}
	
	return $self->LINQ::Collection::join( $hint, $other, $field1, $field2, $joiner );
}



1;
