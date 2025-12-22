use 5.008008;
use strict;
use warnings;

package Marlin::TypeConstraint;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.007000';

use parent 'Type::Tiny::Class';
use Types::Common qw( signature Any Optional ArrayRef is_TypeTiny assert_ArrayRef );

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
	
	return sub (;$) {
		if ( @_ == 1 ) {
			assert_ArrayRef $_[0];
			my $args = $sig->( @{ $_[0] } );
			return $me->class->new( $args );
		}
		return $me;
	};
}

1;
