use 5.008003;
use strict;
use warnings;

package LINQ::Database::Util;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Scalar::Util qw( blessed );

sub selection_to_sql {
	my ( $selection, $name_quoter ) = ( shift, @_ );
	
	return unless blessed( $selection );
	return unless $selection->isa( 'LINQ::FieldSet::Selection' );
	return if $selection->seen_asterisk;
	
	$name_quoter ||= sub {
		my $name = shift;
		return sprintf( '"%s"', quotemeta( $name ) );
	};
	
	my @cols;
	for my $field ( @{ $selection->fields } ) {
		my $orig_name = $field->value;
		my $aliased   = $field->name;
		return if ref( $orig_name );
		# uncoverable branch true
		return if !defined( $aliased );
		
		push @cols, $name_quoter->( $orig_name );
	} #/ for my $field ( @{ $self...})
	
	return join( q[, ], @cols );
} #/ sub _sql_selection

sub assertion_to_sql {
	my ( $assertion, $name_quoter, $value_quoter ) = ( @_ );
	
	return unless blessed( $assertion );
	
	$name_quoter ||= sub {
		my $name = shift;
		return sprintf( '"%s"', quotemeta( $name ) );
	};
	
	$value_quoter ||= sub {
		my $name = shift;
		return sprintf( '"%s"', quotemeta( $name ) );
	};
	
	if ( $assertion->isa( 'LINQ::FieldSet::Assertion::AND' ) ) {
		return _assertion_to_sql_AND( $assertion, $name_quoter, $value_quoter );
	}
	elsif ( $assertion->isa( 'LINQ::FieldSet::Assertion::OR' ) ) {
		return _assertion_to_sql_OR( $assertion, $name_quoter, $value_quoter );
	}
	elsif ( $assertion->isa( 'LINQ::FieldSet::Assertion::NOT' ) ) {
		return _assertion_to_sql_NOT( $assertion, $name_quoter, $value_quoter );
	}
	elsif ( $assertion->isa( 'LINQ::FieldSet::Assertion' ) ) {
		return _assertion_to_sql_FIELDSET( $assertion, $name_quoter, $value_quoter );
	}
}

sub _assertion_to_sql_AND {
	my ( $assertion, $name_quoter, $value_quoter ) = ( @_ );
	
	my $left  = assertion_to_sql( $assertion->left,  $name_quoter, $value_quoter )
		or return;
	my $right = assertion_to_sql( $assertion->right, $name_quoter, $value_quoter )
		or return;
	
	return "($left) AND ($right)";
}

sub _assertion_to_sql_OR {
	my ( $assertion, $name_quoter, $value_quoter ) = ( @_ );
	
	my $left  = assertion_to_sql( $assertion->left,  $name_quoter, $value_quoter )
		or return;
	my $right = assertion_to_sql( $assertion->right, $name_quoter, $value_quoter )
		or return;
	
	return "($left) OR ($right)";
}

sub _assertion_to_sql_NOT {
	my ( $assertion, $name_quoter, $value_quoter ) = ( @_ );
	
	my $left  = assertion_to_sql( $assertion->left,  $name_quoter, $value_quoter )
		or return;
	
	return "NOT ($left)";
}

sub _assertion_to_sql_FIELDSET {
	my ( $assertion, $name_quoter, $value_quoter ) = ( @_ );
	
	my @fields;
	for my $field ( @{ $assertion->fields } ) {
		my $field_sql = _assertion_to_sql_FIELD( $field, $name_quoter, $value_quoter )
			or return;
		push @fields, "($field_sql)";
	}
	
	join " AND ", @fields;
}

sub _assertion_to_sql_FIELD {
	my ( $field, $name_quoter, $value_quoter ) = ( @_ );
	
	return if ref( $field->value );
	my $result;
	
	if ( exists $field->params->{is} ) {
		$result = _assertion_to_sql_FIELD_IS( @_ );
	}
	elsif ( exists $field->params->{in} ) {
		$result = _assertion_to_sql_FIELD_IN( @_ );
	}
	elsif ( exists $field->params->{like} ) {
		$result = _assertion_to_sql_FIELD_LIKE( @_ );
	}
	elsif ( exists $field->params->{to} ) {
		$result = _assertion_to_sql_FIELD_TO( @_ );
	}
	
	return unless defined $result;
	
	if ( exists $field->params->{nix} ) {
		return "NOT ($result)";
	}
	
	return $result;
}

sub _assertion_to_sql_FIELD_IS {
	my ( $field, $name_quoter, $value_quoter ) = ( @_ );
	
	my $cmp = $field->params->{cmp} || '==';
	if ( $cmp eq '!=' ) {
		$cmp = '<>'; # SQL syntax <> Perl syntax
	}
	
	my $wrapper = $field->params->{nocase}
		? sub { sprintf( 'LOWER(%s)', $_[0] ) }
		: sub { $_[0] };
	
	return sprintf(
		'%s %s %s',
		$wrapper->( $name_quoter->( $field->value ) ),
		$cmp,
		$wrapper->( $value_quoter->( $field->params->{is} ) ),
	);
}

sub _assertion_to_sql_FIELD_IN {
	my ( $field, $name_quoter, $value_quoter ) = ( @_ );
	
	return sprintf(
		'%s IN (%s)',
		$name_quoter->( $field->value ),
		join(
			q[, ],
			map $value_quoter->( $_ ), @{ $field->params->{to} },
		),
	);
}

sub _assertion_to_sql_FIELD_LIKE {
	my ( $field, $name_quoter, $value_quoter ) = ( @_ );
	
	my $wrapper = $field->params->{nocase}
		? sub { sprintf( 'LOWER(%s)', $_[0] ) }
		: sub { $_[0] };
	
	return sprintf(
		'%s LIKE %s',
		$wrapper->( $name_quoter->( $field->value ) ),
		$wrapper->( $value_quoter->( $field->params->{like} ) ),
	);
}

sub _assertion_to_sql_FIELD_TO {
	my ( $field, $name_quoter, $value_quoter ) = ( @_ );
	
	my $cmp = $field->params->{cmp} || '==';
	if ( $cmp eq '!=' ) {
		$cmp = '<>'; # SQL syntax <> Perl syntax
	}
	
	my $wrapper = $field->params->{nocase}
		? sub { sprintf( 'LOWER(%s)', $_[0] ) }
		: sub { $_[0] };
	
	return sprintf(
		'%s %s %s',
		$wrapper->( $name_quoter->( $field->value ) ),
		$cmp,
		$wrapper->( $name_quoter->( $field->params->{to} ) ),
	);
}

1;
