use 5.006;
use strict;
use warnings;

package LINQ::FieldSet::Assertion;

my $_process_args = sub {
	require Scalar::Util;
	if ( Scalar::Util::blessed( $_[0] )
		and Scalar::Util::blessed( $_[1] )
		and @_ < 4 )
	{
		return $_[2] ? ( $_[1], $_[0] ) : ( $_[0], $_[1] );
	}
	
	my ( $self, @other ) = @_;
	my $other = __PACKAGE__->new( @other );
	return ( $self, $other );
};

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use Class::Tiny;
use parent qw( LINQ::FieldSet );

use LINQ::Util::Internal ();

use overload (
	'fallback' => !!1,
	q[bool]    => sub { !! 1 },
	q[""]      => 'to_string',
	q[&{}]     => 'coderef',
	q[|]       => 'or',
	q[&]       => 'and',
	q[~]       => 'not',
);

sub _known_parameter_names {
	my ( $self ) = ( shift );
	
	return (
		$self->SUPER::_known_parameter_names,
		'is'      => 1,
		'in'      => 1,
		'like'    => 1,
		'match'   => 1,
		'to'      => 1,
		'cmp'     => 1,
		'numeric' => 0,
		'string'  => 0,
		'nix'     => 0,
		'nocase'  => 0,
	);
} #/ sub _known_parameter_names

sub coderef {
	my ( $self ) = ( shift );
	$self->{coderef} ||= $self->_build_coderef;
}

sub BUILD {
	my ( $self ) = ( shift );
	if ( $self->seen_asterisk ) {
		LINQ::Util::Internal::throw(
			"CallerError",
			message => "Field '*' does not make sense for assertions",
		);
	}
}

sub _build_coderef {
	my ( $self ) = ( shift );
	my @checks   = map $self->_make_check( $_ ), @{ $self->fields };
	return sub {
		for my $check ( @checks ) {
			return !!0 unless $check->( $_ );
		}
		return !!1;
	};
} #/ sub _build_coderef

{
	my %makers = (
		'is'       => '_make_is_check',
		'in'       => '_make_in_check',
		'to'       => '_make_to_check',
		'like'     => '_make_like_check',
		'match'    => '_make_match_check',
	);

	sub _make_check {
		my ( $self, $field ) = ( shift, @_ );
		
		my @found;
		for my $key ( sort keys %makers ) {
			push @found, $key if exists $field->params->{$key};
		}
		
		if ( @found > 1 ) {
			my $params = join q[, ], map "-$_", @found;
			LINQ::Util::Internal::throw(
				"CallerError",
				message => "Multiple conflicting assertions ($params) found for field '@{[ $field->name ]}'",
			);
		}
		
		if ( @found == 0 ) {
			LINQ::Util::Internal::throw(
				"CallerError",
				message => "No assertions found for field '@{[ $field->name ]}'",
			);
		}
		
		my $method = $makers{ $found[0] };
		return $self->$method( $field );
	}
}

{
	my %templates = (
		'numeric ==' => '%s == %s',
		'numeric !=' => '%s != %s',
		'numeric >'  => '%s >  %s',
		'numeric >=' => '%s >= %s',
		'numeric <'  => '%s <  %s',
		'numeric <=' => '%s <= %s',
		'string =='  => '%s eq %s',
		'string !='  => '%s ne %s',
		'string >'   => '%s gt %s',
		'string >='  => '%s ge %s',
		'string <'   => '%s lt %s',
		'string <='  => '%s le %s',
		'null =='    => '! defined( %s )',
	);
	
	sub _make_is_check {
		my ( $self, $field ) = ( shift, @_ );
		my $getter = $field->getter;
		
		my $expected = $field->params->{is};
		my $cmp      = $field->params->{cmp} || "==";
		my $type =
			$field->params->{numeric}             ? 'numeric'
			: $field->params->{string}            ? 'string'
			: !defined( $expected )               ? 'null'
			: $expected =~ /^[0-9]+(?:\.[0-9]+)$/ ? 'numeric'
			: !ref( $expected )                   ? 'string'
			: 'numeric';
		my $template = $templates{"$type $cmp"}
			or LINQ::Util::Internal::throw(
			"CallerError",
			message => "Unexpected comparator '$cmp' for type '$type'",
			);
			
		my $guts;
		if ( $type eq 'null' ) {
			$guts = sprintf( $template, '$getter->( $_ )' );
		}
		elsif ( $field->params->{nocase} ) {
			my $fold = ( $] > 5.016 ) ? 'CORE::fc' : 'lc';
			$guts = sprintf(
				$template,
				"$fold( \$getter->( \$_ ) )",
				ref( $expected ) ? "$fold( \$expected )" : do {
					require B;
					"$fold( " . B::perlstring( $expected ) . ' )';
				},
			);
		} #/ elsif ( $field->params->{...})
		else {
			$guts = sprintf(
				$template,
				'$getter->( $_ )',
				ref( $expected ) ? '$expected' : do {
					require B;
					B::perlstring( $expected );
				},
			);
		} #/ else [ if ( $type eq 'null' )]
		
		if ( $field->params->{nix} ) {
			$guts = "!( $guts )";
		}
		
		no warnings qw( uninitialized );
		return eval "sub { $guts }";
	}
	
	sub _make_to_check {
		my ( $self, $field ) = ( shift, @_ );
		my $getter = $field->getter;
		
		my $other    = 'LINQ::Field'->new( value => $field->params->{to} )->getter;
		my $cmp      = $field->params->{cmp} || "==";
		my $type     = $field->params->{string} ? 'string' : 'numeric';
		my $template = $templates{"$type $cmp"}
			or LINQ::Util::Internal::throw(
				"CallerError",
				message => "Unexpected comparator '$cmp' for type '$type'",
			);
		
		my $guts;
		if ( $field->params->{nocase} ) {
			my $fold = ( $] > 5.016 ) ? 'CORE::fc' : 'lc';
			$guts = sprintf(
				$template,
				"$fold( \$getter->( \$_ ) )",
				"$fold( \$other->( \$_ ) )",
			);
		} #/ elsif ( $field->params->{...})
		else {
			$guts = sprintf(
				$template,
				'$getter->( $_ )',
				'$other->( $_ )',
			);
		} #/ else [ if ( $type eq 'null' )]
		
		if ( $field->params->{nix} ) {
			$guts = "!( $guts )";
		}
		
		no warnings qw( uninitialized );
		return eval "sub { $guts }";
	}
}

sub _make_in_check {
	my ( $self, $field ) = ( shift, @_ );
	my $getter = $field->getter;
	my @expected = @{ $field->params->{in} };
	
	my $nix = ! $field->params->{nix};
	
	if ( $field->params->{nocase} ) {
		return sub {
			my $value = lc $getter->( $_ );
			for my $expected ( @expected ) {
				return !!$nix if $value eq lc $expected;
			}
			return !$nix;
		};
	}
	else {
		return sub {
			my $value = $getter->( $_ );
			for my $expected ( @expected ) {
				return !!$nix if $value eq $expected;
			}
			return !$nix;
		};
	}
}

{
	my $_like_to_regexp = sub {
		my ( $like, $ci ) = @_;
		my $re      = '';
		my %anchors = (
			start => substr( $like, 0,  1 ) ne '%',
			end   => substr( $like, -1, 1 ) ne '%',
		);
		my @parts = split qr{(\\*[.%])}, $like;
		for my $p ( @parts ) {
			next unless length $p;
			my $backslash_count =()= $p =~ m{(\\)}g;
			my $wild_count      =()= $p =~ m{([%.])}g;
			if ( $wild_count ) {
				if ( $backslash_count && $backslash_count % 2 ) {
					my $last = substr( $p, -2, 2, '' );
					$p =~ s{\\\\}{\\};
					$re .= quotemeta( $p . substr( $last, -1, 1 ) );
				}
				elsif ( $backslash_count ) {
					my $last = substr( $p, -1, 1, '' );
					$p =~ s{\\\\}{\\};
					$re .= quotemeta( $p ) . ( $last eq '%' ? '.*' : '.' );
				}
				else {
					$re .= $p eq '%' ? '.*' : '.';
				}
			} #/ if ( $wild_count )
			else {
				$p =~ s{\\(.)}{$1}g;
				$re .= quotemeta( $p );
			}
		} #/ for my $p ( @parts )
		
		substr( $re, 0, 0, '\A' ) if $anchors{start};
		$re .= '\z'               if $anchors{end};
		
		$ci ? qr/$re/i : qr/$re/;
	};

	sub _make_like_check {
		my ( $self, $field ) = ( shift, @_ );
		my $getter = $field->getter;
		
		my $match = $_like_to_regexp->(
			$field->params->{like},
			$field->params->{nocase},
		);
		
		if ( $field->params->{nix} ) {
			return sub {
				my $value = $getter->( $_ );
				$value !~ $match;
			};
		}
		else {
			return sub {
				my $value = $getter->( $_ );
				$value =~ $match;
			};
		}
	}
}

sub _make_match_check {
	my ( $self, $field ) = ( shift, @_ );
	my $getter = $field->getter;
	
	my $match = $field->params->{match};
	
	require match::simple;
	
	if ( $field->params->{nix} ) {
		return sub {
			my $value = $getter->( $_ );
			not match::simple::match( $value, $match );
		};
	}
	else {
		return sub {
			my $value = $getter->( $_ );
			match::simple::match( $value, $match );
		};
	}
}

sub not {
	my ( $self ) = ( shift );
	return 'LINQ::FieldSet::Assertion::NOT'->new(
		left => $self,
	);
}

sub and {
	my ( $self, $other ) = &$_process_args;
	return 'LINQ::FieldSet::Assertion::AND'->new(
		left  => $self,
		right => $other,
	);
}

sub or {
	my ( $self, $other ) = &$_process_args;
	return 'LINQ::FieldSet::Assertion::OR'->new(
		left  => $self,
		right => $other,
	);
}

sub to_string {
	my ( $self ) = ( shift );
	sprintf 'check_fields(%s)', join q[, ], map $_->name, @{ $self->fields };
}

package LINQ::FieldSet::Assertion::Combination;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use Role::Tiny;
requires( qw/ left right _build_coderef / );

sub coderef {
	my ( $self ) = ( shift );
	$self->{coderef} ||= $self->_build_coderef;
}

sub not {
	my ( $self ) = ( shift );
	return 'LINQ::FieldSet::Assertion::NOT'->new(
		left => $self,
	);
}

sub and {
	my ( $self, $other ) = &$_process_args;
	return 'LINQ::FieldSet::Assertion::AND'->new(
		left  => $self,
		right => $other,
	);
}

sub or {
	my ( $self, $other ) = &$_process_args;
	return 'LINQ::FieldSet::Assertion::OR'->new(
		left  => $self,
		right => $other,
	);
}

package LINQ::FieldSet::Assertion::NOT;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use Class::Tiny qw( left );
use Role::Tiny::With ();
Role::Tiny::With::with( 'LINQ::FieldSet::Assertion::Combination' );

use overload ();
'overload'->import(
	q[&{}] => 'coderef',
	q[|]   => 'or',
	q[&]   => 'and',
	q[~]   => 'not',
);

sub _build_coderef {
	my ( $self ) = ( shift );
	my $left = $self->left->coderef;
	return sub { not $left->( $_ ) };
}

sub not {
	my ( $self ) = ( shift );
	return $self->left;
}

sub right {
	LINQ::Util::Internal::throw(
		"InternalError",
		message => 'Unexpected second branch to NOT.',
	);
}

package LINQ::FieldSet::Assertion::AND;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use Class::Tiny qw( left right );
use Role::Tiny::With ();
Role::Tiny::With::with( 'LINQ::FieldSet::Assertion::Combination' );

use overload ();
'overload'->import(
	q[&{}] => 'coderef',
	q[|]   => 'or',
	q[&]   => 'and',
	q[~]   => 'not',
);

sub _build_coderef {
	my ( $self ) = ( shift );
	my $left     = $self->left->coderef;
	my $right    = $self->right->coderef;
	return sub { $left->( $_ ) and $right->( $_ ) };
}

package LINQ::FieldSet::Assertion::OR;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use Class::Tiny qw( left right );
use Role::Tiny::With ();
Role::Tiny::With::with( 'LINQ::FieldSet::Assertion::Combination' );

use overload ();
'overload'->import(
	q[&{}] => 'coderef',
	q[|]   => 'or',
	q[&]   => 'and',
	q[~]   => 'not',
);

sub _build_coderef {
	my ( $self ) = ( shift );
	my $left     = $self->left->coderef;
	my $right    = $self->right->coderef;
	return sub { $left->( $_ ) or $right->( $_ ) };
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

LINQ::FieldSet::Assertion - represents an SQL-WHERE-like assertion/check

=head1 DESCRIPTION

LINQ::FieldSet::Assertion is a subclass of L<LINQ::FieldSet>.

This is used internally by LINQ and you probably don't need to know about it
unless you're writing very specific extensions for LINQ. The end user
interface is the C<check_fields> function in L<LINQ::Util>.

=head1 CONSTRUCTOR

=over

=item C<< new( ARGSLIST ) >>

Constructs a fieldset from a list of fields like:

  'LINQ::FieldSet::Assertion'->new(
    'field1', -param1 => 'value1', -param2,
    'field2', -param1 => 'value2',
  );

Allowed parameters are:
C<< -is >> (followed by a value),
C<< -to >> (followed by a value),
C<< -in >> (followed by a value),
C<< -like >> (followed by a value),
C<< -match >> (followed by a value),
C<< -cmp >> (followed by a value),
C<< -numeric >> (no value),
C<< -string >> (no value),
C<< -not >> (no value), and
C<< -nocase >> (no value).

=back

=begin trustme

=item BUILD

=end trustme 

=head1 METHODS

=over

=item C<< and( OTHER ) >>

Return a LINQ::FieldSet::Assertion::AND object which is a conjunction of this
assertion and another assertion.

=item C<< or( OTHER ) >>

Return a LINQ::FieldSet::Assertion::OR object which is an inclusive disjunction
of this assertion and another assertion.

=item C<not>

Return a LINQ::FieldSet::Assertion::NOT object which is the negation of this
assertion.

=item C<coderef>

Gets a coderef for this assertion; the coderef operates on C<< $_ >>.

=item C<to_string>

Basic string representation of the fieldset.

=back

The LINQ::FieldSet::Assertion::{AND,OR,NOT} classes are lightweight classes
which also implement the C<and>, C<or>, C<not>, and C<coderef> methods, and
have the same overloading as LINQ::FieldSet::Assertion, but do not inherit
from it.

=head1 OVERLOADING

This class overloads
C<< "" >> to call the C<< to_string >> method;
C<< & >> to call the C<< and >> method;
C<< | >> to call the C<< or >> method;
C<< ~ >> to call the C<< not >> method; and
C<< &{} >> to call the C<< coderef >> method.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=LINQ>.

=head1 SEE ALSO

L<LINQ::FieldSet>, L<LINQ::Util>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2021 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
