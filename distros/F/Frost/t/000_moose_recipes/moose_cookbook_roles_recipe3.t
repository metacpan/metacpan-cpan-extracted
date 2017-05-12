#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More;

BEGIN
{
	plan skip_all => 'TODO: No dynamic roles with Frost yet';
}

#	Applying a role at run-time creates an __ANON__ class
#	with new attributes, which can not be stored.

use Frost::Asylum;

#	from Moose-0.87/t/000_recipes/moose_cookbook_roles_recipe3.t

{
	# Not in the recipe, but needed for writing tests.
	package Employee;

#	use Moose;
	use Frost;

	has 'name' => (
		is	=> 'ro',
		isa	=> 'Str',
		required => 1,
	);

	has 'work' => (
		is		=> 'rw',
		isa	=> 'Str',
		predicate => 'has_work',
	);

	no Frost;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

{
	package MyApp::Role::Job::Manager;

	use List::Util qw( first );

	use Moose::Role;

	has 'employees' => (
		is	=> 'rw',
		isa => 'ArrayRef[Employee]',
	);

	sub assign_work {
		my $self = shift;
		my $work = shift;

		my $employee = first { !$_->has_work } @{ $self->employees };

		die 'All my employees have work to do!' unless $employee;

		$employee->work($work);
	}
}

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	my $lisa		= Employee->new( name => 'Lisa', asylum => $ASYL, id => 1 );

	ok( ! $lisa->does('MyApp::Role::Job::Manager'),	'Lisa does not yet the manager role' );

	MyApp::Role::Job::Manager->meta->apply($lisa);

	ok( $lisa->does('MyApp::Role::Job::Manager'),	'Lisa does the manager role now' );

	my $homer	= Employee->new( name => 'Homer',	asylum => $ASYL, id => 10 );
	my $bart		= Employee->new( name => 'Bart',		asylum => $ASYL, id => 11 );
	my $marge	= Employee->new( name => 'Marge',	asylum => $ASYL, id => 12 );

	$lisa->employees( [ $homer, $bart, $marge ] );

	$lisa->assign_work('mow the lawn');

	is( $homer->work,	'mow the lawn',	'homer was assigned a task by lisa' );

	DEBUG "XXXXXXXXXXXXXXXXXXXX\n$lisa, $homer", Dumper $lisa, $homer;

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	my $lisa		= Employee->new( asylum => $ASYL, id => 1 );

	ok( ! $lisa->does('MyApp::Role::Job::Manager'),	'Lisa does not yet the manager role after RELOAD' );

	is( $lisa->name,	'Lisa',	'lisa is Lisa' );

	my ( $homer, $homers_work );

	throws_ok	{ $homer	= $lisa->employees->[0]; }
		qr/Can\'t locate object method "employees" via package "Employee"/,
		'cannot access Lisas employees via Locum after RELOAD';

	MyApp::Role::Job::Manager->meta->apply($lisa);

	ok( $lisa->does('MyApp::Role::Job::Manager'),	'Lisa does the manager role NOW' );

	lives_ok	{ $homer	= $lisa->employees->[0]; }		'can access Lisas employees NOW';
	lives_ok	{ $homers_work	= $homer->work; }			'can access Homers task NOW';

	is( $homers_work, 'mow the lawn',					'Homer was assigned a task by lisa' );

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}


done_testing;

