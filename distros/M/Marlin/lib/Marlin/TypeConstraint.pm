use 5.008008;
use strict;
use warnings;

package Marlin::TypeConstraint;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.022001';

use B                     ();
use Eval::TypeTiny        ();
use Scalar::Util          ();
use Type::Tiny::Class     ();
use Types::Common         qw( -all );

our @ISA = 'Type::Tiny::Class';

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
				my $type = is_TypeTiny($attr->{isa}) ? $attr->{isa} : $attr->{isa} ? to_TypeTiny( $attr->{isa} ) : Any;
				my $opts = { optional => !$attr->{required} };
				$opts->{alias} = $attr->{alias} if $attr->{'alias'};
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
	
	&Scalar::Util::set_prototype( $coderef, ';$' )
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

no Types::Common;

__PACKAGE__
__END__
