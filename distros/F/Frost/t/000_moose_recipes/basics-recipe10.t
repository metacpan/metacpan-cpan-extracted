#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More;

use Frost::Asylum;
use Frost::Util;

$Frost::Util::UUID_CLEAR	= 1;		#	delivers simple 'UUIDs' A-A-A-A-1, -2, -3... for testing

$Data::Dumper::Deparse	= true;

our $GENE_POOL;

$GENE_POOL = Frost::Asylum->new ( data_root	=> $TMP_PATH );

our $PERSONS	= {};
our $CHILDS		= {};

#	from Moose-1.14/t/000_recipes

{
	package Human::Persistent;

	use Frost;

	has id	=> ( auto_id	=> 1 );

	no Frost;
	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

{
	package Human;

	use Moose;
	extends 'Human::Persistent';
	use Moose::Util::TypeConstraints;

	subtype 'Gender'
		=> as 'Str'
		=> where { $_ =~ m{^[mf]$}s };

	has 'gender'	=> ( is	=> 'ro', isa	=> 'Gender', required	=> 1 );

	has 'mother'	=> ( is	=> 'ro', isa	=> 'Human' );
	has 'father'	=> ( is	=> 'ro', isa	=> 'Human' );

	use overload '+'	=> \&_overload_add, fallback	=> 1;

	sub _overload_add {
		my ( $one, $two ) = @_;

		die('Only male and female humans may create children')
			if ( $one->gender() eq $two->gender() );

		my ( $mother, $father )
			= ( $one->gender eq 'f' ? ( $one, $two ) : ( $two, $one ) );

		my $gender = 'f';
		$gender = 'm' if ( rand() >= 0.5 );

		return Human->new(
			gender		=> $gender,
			eye_color	=> ( $one->eye_color() + $two->eye_color() ),
			mother		=> $mother,
			father		=> $father,
			asylum		=> $mother->asylum,
		);
	}

	use List::MoreUtils qw( zip );

	coerce 'Human::EyeColor'
		=> from 'ArrayRef'
		=> via { my @genes = qw( bey2_1 bey2_2 gey_1 gey_2 );
				return Human::EyeColor->new( zip( @genes, @{$_} ), asylum => $::GENE_POOL ) };	#	arrgghhh, global var...

	has 'eye_color'	=> (
		is		=> 'ro',
		isa		=> 'Human::EyeColor',
		coerce	=> 1,
		required	=> 1,
	);

	no Moose;
	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

{
	package Human::Gene::bey2;

	use Moose;
	extends 'Human::Persistent';
	use Moose::Util::TypeConstraints;

	type 'bey2_color'	=> where { $_ =~ m{^(?:brown|blue)$} };

	has 'color'	=> ( is	=> 'ro', isa	=> 'bey2_color' );

	no Moose;
	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

{
	package Human::Gene::gey;

	use Moose;
	extends 'Human::Persistent';
	use Moose::Util::TypeConstraints;

	type 'gey_color'	=> where { $_ =~ m{^(?:green|blue)$} };

	has 'color'	=> ( is	=> 'ro', isa	=> 'gey_color' );

	no Moose;
	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

{
	package Human::EyeColor;

	use Moose;
	extends 'Human::Persistent';
	use Moose::Util::TypeConstraints;

	coerce 'Human::Gene::bey2'
		=> from 'Str'
			=> via { Human::Gene::bey2->new( color	=> $_, asylum => $::GENE_POOL ) };	#	arrgghhh, global var...

	coerce 'Human::Gene::gey'
		=> from 'Str'
			=> via { Human::Gene::gey->new( color	=> $_, asylum => $::GENE_POOL ) };	#	arrgghhh, global var...

	has [qw( bey2_1 bey2_2 )]	=>
		( is	=> 'ro', isa	=> 'Human::Gene::bey2', coerce	=> 1 );

	has [qw( gey_1 gey_2 )]	=>
		( is	=> 'ro', isa	=> 'Human::Gene::gey', coerce	=> 1 );

	sub color {
		my ($self) = @_;

		return 'brown'
			if ( $self->bey2_1->color() eq 'brown'
			or $self->bey2_2->color() eq 'brown' );

		return 'green'
			if ( $self->gey_1->color() eq 'green'
			or $self->gey_2->color() eq 'green' );

		return 'blue';
	}

	use overload '""'	=> \&color, fallback	=> 1;

	use overload '+'	=> \&_overload_add, fallback	=> 1;

	sub _overload_add {
		my ( $one, $two ) = @_;

		my $one_bey2 = 'bey2_' . _rand2();
		my $two_bey2 = 'bey2_' . _rand2();

		my $one_gey = 'gey_' . _rand2();
		my $two_gey = 'gey_' . _rand2();

		return Human::EyeColor->new(
			bey2_1	=> $one->$one_bey2->color(),
			bey2_2	=> $two->$two_bey2->color(),
			gey_1		=> $one->$one_gey->color(),
			gey_2		=> $two->$two_gey->color(),
			asylum	=> $one->asylum,
		);
	}

	sub _rand2 {
		return 1 + int( rand(2) );
	}

	no Moose;
	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

# Create...

my $gene_color_sets = [
	[ qw( blue blue blue blue )		=> 'blue'	],
	[ qw( blue blue green blue )		=> 'green'	],
	[ qw( blue blue blue green )		=> 'green'	],
	[ qw( blue blue green green )		=> 'green'	],
	[ qw( brown blue blue blue )		=> 'brown'	],
	[ qw( brown brown green green )	=> 'brown'	],
	[ qw( blue brown green blue )		=> 'brown'	],
];

foreach my $set (@$gene_color_sets) {
	my $expected_color	= pop(@$set);

	my $person = Human->new(
		gender		=> 'f',
		eye_color	=> $set,
		asylum		=> $GENE_POOL,
	);

	$PERSONS->{$person->id}	=
	{
		eye_color			=> $person->eye_color(),
		expected_color		=> $expected_color,
		set					=> $set,
	};

	is(
		$person->eye_color(),
		$expected_color,
		'gene combination '
			. join( ',', @$set )
			. ' produces '
			. $expected_color
			. ' eye color',
	);
}

#DEBUG Dumper $GENE_POOL;

my $parent_sets = [
	[
		[qw( blue blue blue blue )],
		[qw( blue blue blue blue )]	=> 'blue'
	],
	[
		[qw( blue blue blue blue )],
		[qw( brown brown green blue )]	=> 'brown'
	],
	[
		[qw( blue blue green green )],
		[qw( blue blue green green )]	=> 'green'
	],
];

foreach my $set (@$parent_sets) {
	my $expected_color	= pop(@$set);

	my $mother		= Human->new(
		gender		=> 'f',
		eye_color	=> shift(@$set),
		asylum		=> $GENE_POOL,
	);

	my $father = Human->new(
		gender		=> 'm',
		eye_color	=> shift(@$set),
		asylum		=> $GENE_POOL,
	);

	my $child = $mother + $father;

	$CHILDS->{$child->id}	=
	{
		eye_color			=> $child->eye_color(),
		expected_color		=> $expected_color,
		mother_eye_color	=> $mother->eye_color(),
		father_eye_color	=> $father->eye_color(),
	};

	is(
		$child->eye_color(),
		$expected_color,
		'mother '
			. $mother->eye_color()
			. ' + father '
			. $father->eye_color()
			. ' = child '
			. $expected_color,
	);
}

#DEBUG Dumper $GENE_POOL;

$GENE_POOL->close;		#	and save

# Reload...

foreach my $id (sort keys %$PERSONS ) {
	my $person = Human->new(
		id			=> $id,
		asylum	=> $GENE_POOL
	);

	is(
		$person->eye_color(),
		$PERSONS->{$id}->{expected_color},
		'gene combination '
			. join( ',', @{$PERSONS->{$id}->{set}} )
			. ' produces '
			. $PERSONS->{$id}->{expected_color}
			. ' eye color'
			.  ' (reloaded)',
	);
}

#DEBUG Dumper $GENE_POOL;

foreach my $id (sort keys %$CHILDS ) {
	my $child = Human->new(
		id			=> $id,
		asylum	=> $GENE_POOL
	);

	is(
		$child->eye_color(),
		$CHILDS->{$id}->{expected_color},
		'mother '
			. $CHILDS->{$id}->{mother_eye_color}
			. ' + father '
			. $CHILDS->{$id}->{father_eye_color}
			. ' = child '
			. $CHILDS->{$id}->{expected_color}
			.  ' (reloaded)',
	);
}


# Hmm, not sure how to test for random selection of genes since
# I could theoretically run an infinite number of iterations and
# never find proof that a child has inherited a particular gene.

# AUTHOR: Aran Clary Deltac <bluefeet@cpan.org>

# Maybe there is another way to implent this, but for no we have
# to use a global $GENE_POOL = Frost::Asylum :-(
#
# Ernesto

done_testing;

