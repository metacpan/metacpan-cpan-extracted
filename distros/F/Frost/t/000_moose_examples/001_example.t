#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More;
use Test::Exception;

use Frost::Asylum;
use Frost::Util;

$Frost::Util::UUID_CLEAR	= 1;		#	delivers simple 'UUIDs' A-A-A-A-1, -2, -3... for testing

$Data::Dumper::Deparse	= true;

our $ASYL;

$ASYL = Frost::Asylum->new ( data_root => $TMP_PATH );

#	from Moose-1.14/t/200_examples/001_example.t

## Roles

{
	package Constraint;
	use Moose::Role;

	has 'value' => (isa => 'Num', is => 'ro');

	around 'validate' => sub {
		my $c = shift;
		my ($self, $field) = @_;
		return undef if $c->($self, $self->validation_value($field));
		return $self->error_message;
	};

	sub validation_value {
		my ($self, $field) = @_;
		return $field;
	}

	sub error_message { confess "Abstract method!" }

	package Constraint::OnLength;
	use Moose::Role;

	has 'units' => (isa => 'Str', is => 'ro');

	override 'validation_value' => sub {
		return length(super());
	};

	override 'error_message' => sub {
		my $self = shift;
		return super() . ' ' . $self->units;
	};

}

## Classes

{
	package Constraint::AtLeast;
#	use Moose;
	use Frost;

	with 'Constraint';
	
	has id => ( auto_id => 1 );
	
	sub validate {
		my ($self, $field) = @_;
		($field >= $self->value);
	}

	sub error_message { 'must be at least ' . (shift)->value; }

	no Frost;
	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;

	package Constraint::NoMoreThan;
#	use Moose;
	use Frost;

	with 'Constraint';

	has id => ( auto_id => 1 );

	sub validate {
		my ($self, $field) = @_;
		($field <= $self->value);
	}

	sub error_message { 'must be no more than ' . (shift)->value; }

	no Frost;
	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;

	package Constraint::LengthNoMoreThan;
	use Moose;

	extends 'Constraint::NoMoreThan';
	   with 'Constraint::OnLength';

	no Moose;
	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;

	package Constraint::LengthAtLeast;
	use Moose;

	extends 'Constraint::AtLeast';
	   with 'Constraint::OnLength';

	no Moose;
	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

my $IDS	= {};

foreach my $load ( 0..1 )
{
	my $load_text	= $load ? ' Loading...' : ' Creating...';

	diag $load_text;

#	my $no_more_than_10 = Constraint::NoMoreThan->new(value => 10);
	my $no_more_than_10;
	if ( $load )	{ $no_more_than_10	= Constraint::NoMoreThan->new( asylum => $ASYL, id => $IDS->{NMT10} );	}
	else				{ $no_more_than_10	= Constraint::NoMoreThan->new( asylum => $ASYL, value => 10 );	}
	
	$IDS->{NMT10}	||= $no_more_than_10->id;

	is ( $IDS->{NMT10},	$no_more_than_10->id,	'...got correct id ' . $IDS->{NMT10} );

	isa_ok($no_more_than_10, 'Constraint::NoMoreThan');

	ok($no_more_than_10->does('Constraint'), '... Constraint::NoMoreThan does Constraint');

	ok(!defined($no_more_than_10->validate(1)), '... validated correctly');
	is($no_more_than_10->validate(11), 'must be no more than 10', '... validation failed correctly');

#	my $at_least_10 = Constraint::AtLeast->new(value => 10);
	my $at_least_10;
	if ( $load )	{ $at_least_10	= Constraint::AtLeast->new( asylum => $ASYL, id => $IDS->{AL10} );	}
	else				{ $at_least_10	= Constraint::AtLeast->new( asylum => $ASYL, value => 10 );	}

	$IDS->{AL10}	||= $at_least_10->id;

	is ( $IDS->{AL10},	$at_least_10->id,	'...got correct id ' . $IDS->{AL10} );

	isa_ok($at_least_10, 'Constraint::AtLeast');

	ok($at_least_10->does('Constraint'), '... Constraint::AtLeast does Constraint');

	ok(!defined($at_least_10->validate(11)), '... validated correctly');
	is($at_least_10->validate(1), 'must be at least 10', '... validation failed correctly');

	# onlength

#	my $no_more_than_10_chars = Constraint::LengthNoMoreThan->new(value => 10, units => 'chars');
	my $no_more_than_10_chars;
	if ( $load )	{ $no_more_than_10_chars	= Constraint::LengthNoMoreThan->new( asylum => $ASYL, id => $IDS->{NMT10C} );	}
	else				{ $no_more_than_10_chars	= Constraint::LengthNoMoreThan->new( asylum => $ASYL, value => 10, units => 'chars' );	}

	$IDS->{NMT10C}	||= $no_more_than_10_chars->id;

	is ( $IDS->{NMT10C},	$no_more_than_10_chars->id,	'...got correct id ' . $IDS->{NMT10C} );

	isa_ok($no_more_than_10_chars, 'Constraint::LengthNoMoreThan');
	isa_ok($no_more_than_10_chars, 'Constraint::NoMoreThan');

	ok($no_more_than_10_chars->does('Constraint'), '... Constraint::LengthNoMoreThan does Constraint');
	ok($no_more_than_10_chars->does('Constraint::OnLength'), '... Constraint::LengthNoMoreThan does Constraint::OnLength');

	ok(!defined($no_more_than_10_chars->validate('foo')), '... validated correctly');
	is($no_more_than_10_chars->validate('foooooooooo'),
		'must be no more than 10 chars',
		'... validation failed correctly');

#	my $at_least_10_chars = Constraint::LengthAtLeast->new(value => 10, units => 'chars');
	my $at_least_10_chars;
	if ( $load )	{ $at_least_10_chars	= Constraint::LengthAtLeast->new( asylum => $ASYL, id => $IDS->{AL10C} );	}
	else				{ $at_least_10_chars	= Constraint::LengthAtLeast->new( asylum => $ASYL, value => 10, units => 'chars' );	}

	$IDS->{AL10C}	||= $at_least_10_chars->id;
	
	is ( $IDS->{AL10C},	$at_least_10_chars->id,	'...got correct id ' . $IDS->{AL10C} );

	isa_ok($at_least_10_chars, 'Constraint::LengthAtLeast');
	isa_ok($at_least_10_chars, 'Constraint::AtLeast');

	ok($at_least_10_chars->does('Constraint'), '... Constraint::LengthAtLeast does Constraint');
	ok($at_least_10_chars->does('Constraint::OnLength'), '... Constraint::LengthAtLeast does Constraint::OnLength');

	ok(!defined($at_least_10_chars->validate('barrrrrrrrr')), '... validated correctly');
	is($at_least_10_chars->validate('bar'), 'must be at least 10 chars', '... validation failed correctly');

	$ASYL->close;
}

done_testing;
