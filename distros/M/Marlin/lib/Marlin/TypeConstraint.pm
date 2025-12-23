use 5.008008;
use strict;
use warnings;

package Marlin::TypeConstraint;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.007001';

use parent 'Type::Tiny::Class';
use Types::Common qw( signature Any Optional ArrayRef is_TypeTiny is_ArrayRef );

sub exportables {
	my $me = shift;
	my @ex = @{ $me->SUPER::exportables( @_ ) };
	my ( $main ) = grep { $_->{tags}[0] eq 'types' } @ex;
	$main->{code} = $me->coderef_but_cooler;
	return \@ex;
}

sub coderef_but_cooler {
	my $me  = shift;

	my $sig = signature(
		subname       => $me->name,
		package       => $me->{_marlin}{_caller},
		bless         => 0,
		list_to_named => 1,
		named         => [
			map {
				my $attr = $_;
				my $name = exists($attr->{init_arg}) ? $attr->{init_arg} : $attr->{slot};
				my $type = $attr->{isa} ? to_TypeTiny( $attr->{isa} ) : Any;
				my $opts = { optional => !$attr->{required} };
				defined( $name ) ? ( $name, $type, $opts ) : ();
			} @{ $me->{_marlin}->attributes_with_inheritance }
		],
	);
	
	my $coderef = sub (;@) {
		my ( $params, $r );
		$params = shift if is_ArrayRef $_[0];
		if ( $params ) {
			my $args = $sig->( @$params );
			$r = $me->class->new( $args );
		}
		else {
			$r = $me;
		}
		wantarray ? ( $r, @_ ) : $r;
	};
	
	require Scalar::Util && &Scalar::Util::set_prototype( $coderef, ';$' )
		if Eval::TypeTiny::NICE_PROTOTYPES;
	
	return $coderef;
}

1;
