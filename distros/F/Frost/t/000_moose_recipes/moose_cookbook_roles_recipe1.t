#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

#use Test::More 'no_plan';
use Test::More tests => 137;

use Frost::Asylum;

#	from Moose-0.87/t/000_recipes/moose_cookbook_roles_recipe1.t

# =begin testing SETUP
{
	package Eq;
	use Moose::Role;

	requires 'equal_to';

	sub not_equal_to {
			my ( $self, $other ) = @_;
			not $self->equal_to($other);
	}

	package Comparable;
	use Moose::Role;

	with 'Eq';

	requires 'compare';

	sub equal_to {
			my ( $self, $other ) = @_;
			$self->compare($other) == 0;
	}

	sub greater_than {
			my ( $self, $other ) = @_;
			$self->compare($other) == 1;
	}

	sub less_than {
			my ( $self, $other ) = @_;
			$self->compare($other) == -1;
	}

	sub greater_than_or_equal_to {
			my ( $self, $other ) = @_;
			$self->greater_than($other) || $self->equal_to($other);
	}

	sub less_than_or_equal_to {
			my ( $self, $other ) = @_;
			$self->less_than($other) || $self->equal_to($other);
	}

	package Printable;
	use Moose::Role;

	requires 'to_string';

	package US::Currency;
#	use Moose;
	use Frost;

	with 'Comparable', 'Printable';

	has 'amount' => ( is => 'rw', isa => 'Num', default => 0 );

	sub compare {
			my ( $self, $other ) = @_;
			$self->amount <=> $other->amount;
	}

	sub to_string {
			my $self = shift;
			sprintf '$%0.2f USD' => $self->amount;
	}

	no Frost;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

ok( US::Currency->does('Comparable'),	'... US::Currency does Comparable' );
ok( US::Currency->does('Eq'),				'... US::Currency does Eq' );
ok( US::Currency->does('Printable'),	'... US::Currency does Printable' );

foreach my $load ( 0..1 )

# =begin testing
{
	my $load_text	= $load ? "\tLoading..." : "\tCreating...";

	diag $load_text;

	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed' . $load_text;

	#	my $hundred = US::Currency->new( amount => 100.00 );
	my $hundred;
	if ( $load )	{ $hundred	= US::Currency->new( asylum => $ASYL, id => 'HUNDRED' );	}
	else				{ $hundred	= US::Currency->new( amount => 100.00, asylum => $ASYL, id => 'HUNDRED' );	}

	isa_ok	( $hundred, 'US::Currency',			'hundred'	);
	ISA_NOT	( $hundred, 'Comparable',				'hundred'	);	#	role
	isa_ok	( $hundred, 'Frost::Locum',	'hundred'	);
	isa_ok	( $hundred, 'Moose::Object',			'hundred'	);

	ok	( $hundred->DOES("US::Currency"),						'UNIVERSAL::DOES for class'. $load_text );			#	isa
	ok	( $hundred->DOES("Comparable"),							'UNIVERSAL::DOES for role' . $load_text );			#	does
	ok	( $hundred->DOES('Frost::Locum'),				'UNIVERSAL::DOES for Locum' . $load_text );			#	isa
	ok	( $hundred->DOES('Moose::Object'),						'UNIVERSAL::DOES for Moose' . $load_text );			#	isa

	can_ok( $hundred, 'amount' );
	is( $hundred->amount, 100, '... got the right amount' . $load_text );

	can_ok( $hundred, 'to_string' );
	is( $hundred->to_string, '$100.00 USD',	'... got the right stringified value' . $load_text );

	ok( $hundred->does('Comparable'),	'... US::Currency does Comparable' . $load_text );
	ok( $hundred->does('Eq'),				'... US::Currency does Eq' . $load_text );
	ok( $hundred->does('Printable'),		'... US::Currency does Printable' . $load_text );

	#my $fifty = US::Currency->new( amount => 50.00 );
	my $fifty;
	if ( $load )	{ $fifty	= US::Currency->new( asylum => $ASYL, id => 'FIFTY' );	}
	else				{ $fifty	= US::Currency->new( amount => 50.00, asylum => $ASYL, id => 'FIFTY' );	}

	isa_ok( $fifty, 'US::Currency', 'fifty' );

	can_ok( $fifty, 'amount' );
	is( $fifty->amount, 50, '... got the right amount' . $load_text );

	can_ok( $fifty, 'to_string' );
	is( $fifty->to_string, '$50.00 USD', '... got the right stringified value' . $load_text );

	ok( $hundred->greater_than($fifty),						'... 100 gt 50' . $load_text );
	ok( $hundred->greater_than_or_equal_to($fifty),		'... 100 ge 50' . $load_text );
	ok( !$hundred->less_than($fifty),						'... !100 lt 50' . $load_text );
	ok( !$hundred->less_than_or_equal_to($fifty),		'... !100 le 50' . $load_text );
	ok( !$hundred->equal_to($fifty),							'... !100 eq 50' . $load_text );
	ok( $hundred->not_equal_to($fifty),						'... 100 ne 50' . $load_text );

	ok( !$fifty->greater_than($hundred),					'... !50 gt 100' . $load_text );
	ok( !$fifty->greater_than_or_equal_to($hundred),	'... !50 ge 100' . $load_text );
	ok( $fifty->less_than($hundred),							'... 50 lt 100' . $load_text );
	ok( $fifty->less_than_or_equal_to($hundred),			'... 50 le 100' . $load_text );
	ok( !$fifty->equal_to($hundred),							'... !50 eq 100' . $load_text );
	ok( $fifty->not_equal_to($hundred),						'... 50 ne 100' . $load_text );

	ok( !$fifty->greater_than($fifty),						'... !50 gt 50' . $load_text );
	ok( $fifty->greater_than_or_equal_to($fifty),		'... !50 ge 50' . $load_text );
	ok( !$fifty->less_than($fifty),							'... 50 lt 50' . $load_text );
	ok( $fifty->less_than_or_equal_to($fifty),			'... 50 le 50' . $load_text );
	ok( $fifty->equal_to($fifty),								'... 50 eq 50' . $load_text );
	ok( !$fifty->not_equal_to($fifty),						'... !50 ne 50' . $load_text );

	## ... check some meta-stuff

	# Eq

	my $eq_meta = Eq->meta;
	isa_ok( $eq_meta, 'Moose::Meta::Role', 'eq_meta' );

	ok( $eq_meta->has_method('not_equal_to'),		'... Eq has_method not_equal_to' . $load_text );
	ok( $eq_meta->requires_method('equal_to'),	'... Eq requires_method not_equal_to' . $load_text );

	# Comparable

	my $comparable_meta = Comparable->meta;
	isa_ok( $comparable_meta, 'Moose::Meta::Role', 'comparable_meta' );

	ok( $comparable_meta->does_role('Eq'), '... Comparable does Eq' . $load_text );

	foreach my $method_name (
			qw(
			equal_to not_equal_to
			greater_than greater_than_or_equal_to
			less_than less_than_or_equal_to
			)
			) {
			ok( $comparable_meta->has_method($method_name),	'... Comparable has_method ' . $method_name . $load_text );
	}

	ok( $comparable_meta->requires_method('compare'),	'... Comparable requires_method compare' . $load_text );

	# Printable

	my $printable_meta = Printable->meta;
	isa_ok( $printable_meta, 'Moose::Meta::Role', 'printable_meta' );

	ok( $printable_meta->requires_method('to_string'),	'... Printable requires_method to_string' . $load_text );

	# US::Currency

	my $currency_meta = US::Currency->meta;
	isa_ok( $currency_meta, 'Moose::Meta::Class', 'currency_meta' );

	ok( $currency_meta->does_role('Comparable'),	'... US::Currency does Comparable' . $load_text );
	ok( $currency_meta->does_role('Eq'),			'... US::Currency does Eq' . $load_text );
	ok( $currency_meta->does_role('Printable'),	'... US::Currency does Printable' . $load_text );

	foreach my $method_name (
			qw(
			amount
			equal_to not_equal_to
			compare
			greater_than greater_than_or_equal_to
			less_than less_than_or_equal_to
			to_string
			)
			) {
			ok( $currency_meta->has_method($method_name),	'... US::Currency has_method ' . $method_name . $load_text );
	}

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved' . $load_text;
}
