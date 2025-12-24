use 5.008008;
use strict;
use warnings;

package Marlin::TypeConstraint;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.008000';

use parent 'Type::Tiny::Class';
use Types::Common qw( signature ArrayRef HashRef is_ArrayRef is_HashRef to_TypeTiny );

sub exportables {
	my $me = shift;
	my @ex = @{ $me->SUPER::exportables( @_ ) };
	my ( $main ) = grep { $_->{tags}[0] eq 'types' } @ex;
	$main->{code} = $me->coderef_but_cooler;
	return \@ex;
}

sub _cool_sig {
	my $me  = shift;
	
	$me->{_cool_sig} ||= signature(
		want_object   => 1,
		subname       => $me->name,
		package       => $me->{_marlin}->caller,
		bless         => 0,
		list_to_named => 1,
		named         => [
			map {
				my $attr = $_;
				my $name = exists($attr->{init_arg}) ? $attr->{init_arg} : $attr->{slot};
				my $type = $attr->{isa} ? to_TypeTiny( $attr->{isa} ) : 1;
				my $opts = { optional => !$attr->{required} };
				defined( $name ) ? ( $name, $type, $opts ) : ();
			} @{ $me->{_marlin}->attributes_with_inheritance }
		],
	);
}

sub coderef_but_cooler {
	my $me    = shift;
	my $sig   = $me->_cool_sig->coderef->compile;
	my $klass = $me->class;
	
	my $coderef = sub (;@) {
		my $r =
			is_HashRef($_[0])   ? $klass->new(shift) :
			is_ArrayRef($_[0])  ? $klass->new($sig->(@{+shift})) :
			$me;
		wantarray ? ( $r, @_ ) : $r;
	};
	
	require Scalar::Util && &Scalar::Util::set_prototype( $coderef, ';$' )
		if Eval::TypeTiny::NICE_PROTOTYPES;
	
	return $coderef;
}

sub has_coercion {
	return !!1;
}

sub _build_coercion {
	my $me = shift;
	
	my $sig   = $me->_cool_sig->coderef->compile;
	my $klass = $me->class;
	
	#warn( $me->_cool_sig->coderef->code );
	
	return $me
		->SUPER::_build_coercion( @_ )
		->add_type_coercions(
			HashRef,   sprintf( q{%s->new($_)}, B::perlstring($klass) ),
			ArrayRef,  sub { $klass->new($sig->(@$_)) },
		)
		->freeze;
}

1;
