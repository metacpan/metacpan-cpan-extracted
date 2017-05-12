#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

#use Test::More 'no_plan';
use Test::More tests => 20;

use Frost::Asylum;

#	from Moose-0.87/t/200_examples/008_record_set_iterator.t

{
	package Record;
#	use Moose;
	use Frost;

	has 'first_name' => (is => 'ro', isa => 'Str');
	has 'last_name'  => (is => 'ro', isa => 'Str');

	no Frost;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;

	package RecordSet;
#	use Moose;
	use Frost;

	has 'data' => (
		is	=> 'ro',
		isa	=> 'ArrayRef[Record]',
		default => sub { [] },
	);

	has 'index' => (
		is	=> 'rw',
		isa	=> 'Int',
		transient => 1,				#	keep only in Locum, do not save!
		default => sub { 0 },
	);

	sub next {
		my $self = shift;
		my $i = $self->index;
		$self->index($i + 1);
		return $self->data->[$i];
	}

	no Frost;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;

	package RecordSetIterator;
	use Moose;
	#	no need to store this...

	has 'record_set' => (
		is  => 'rw',
		isa => 'RecordSet',
	);

	# list the fields you want to
	# fetch from the current record
	my @fields = Record->meta->get_attribute_list;

	has 'current_record' => (
		is	=> 'rw',
		isa	=> 'Record',
		lazy	=> 1,
		default => sub {
			my $self = shift;
			$self->record_set->next() # grab the first one
		},
		trigger => sub {
			my $self = shift;
			# whenever this attribute is
			# updated, it will clear all
			# the fields for you.
			$self->$_() for map { '_clear_' . $_ } @fields;
		}
	);

	# define the attributes
	# for all the fields.
	for my $field (@fields) {
		has $field => (
			is	=> 'ro',
			isa	=> 'Any',
			lazy	=> 1,
			default => sub {
				my $self = shift;
				# fetch the value from
				# the current record
				$self->current_record->$field();
			},
			# make sure they have a clearer ..
			clearer => ('_clear_' . $field)
		);
	}

	sub get_next_record {
		my $self = shift;
		$self->current_record($self->record_set->next());
	}

	no Moose;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	my $rs = RecordSet->new(
		data => [
			Record->new ( first_name => 'Bill',	last_name => 'Smith',	asylum => $ASYL,	id => 'R1' ),
			Record->new ( first_name => 'Bob',	last_name => 'Jones',	asylum => $ASYL,	id => 'R2' ),
			Record->new ( first_name => 'Jim',	last_name => 'Johnson',	asylum => $ASYL,	id => 'R3' ),
		],
		asylum => $ASYL,	id => 'RS'
	);
	isa_ok($rs, 'RecordSet', 'rs');

	my $rsi = RecordSetIterator->new ( record_set => $rs );
	isa_ok($rsi, 'RecordSetIterator', 'rsi');

	is($rsi->first_name, 'Bill', '... got the right first name');
	is($rsi->last_name, 'Smith', '... got the right last name');

	$rsi->get_next_record;

	is($rsi->first_name, 'Bob', '... got the right first name');
	is($rsi->last_name, 'Jones', '... got the right last name');

	$rsi->get_next_record;

	is($rsi->first_name, 'Jim', '... got the right first name');
	is($rsi->last_name, 'Johnson', '... got the right last name');

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	my $rs = RecordSet->new(
		asylum => $ASYL,	id => 'RS'
	);
	isa_ok($rs, 'RecordSet', 'rs');

	my $rsi = RecordSetIterator->new ( record_set => $rs );
	isa_ok($rsi, 'RecordSetIterator', 'rsi');

	is($rsi->first_name, 'Bill', '... got the right first name loaded');
	is($rsi->last_name, 'Smith', '... got the right last name loaded');

	$rsi->get_next_record;

	is($rsi->first_name, 'Bob', '... got the right first name loaded');
	is($rsi->last_name, 'Jones', '... got the right last name loaded');

	$rsi->get_next_record;

	is($rsi->first_name, 'Jim', '... got the right first name loaded');
	is($rsi->last_name, 'Johnson', '... got the right last name loaded');

	#DEBUG Dump [ $rs, $rsi ], [ $rs, $rsi ];

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}

