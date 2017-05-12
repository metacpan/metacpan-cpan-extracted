#!/usr/bin/perl

use warnings;
use strict;

use lib		't/lib',		'lib';

use Frost::Test;

use Test::More;

# =begin testing SETUP
BEGIN
{
	eval		'use Regexp::Common; use Locale::US;';
	if ($@)
	{
		plan skip_all	=> 'Regexp::Common & Locale::US required for this test';
	}
	else
	{
		plan tests => 146;
	}
}

use Frost::Asylum;

#	from Moose-0.87/t/000_recipes/moose_cookbook_basics_recipe4.t

diag "Running a company...";

my $ADDRESS_ID	= 999;

# =begin testing SETUP
{

	package Address;
#	use Moose;
	use Frost;
	use Moose::Util::TypeConstraints;

	use Locale::US;
	use Regexp::Common		'zip';

	my $STATES = Locale::US->new;
	subtype 'USState'
			=> as Str
			=> where {
					(		exists $STATES->{code2state}{ uc($_) }
						|| exists $STATES->{state2code}{ uc($_) } );
				};

	subtype 'USZipCode'
			=> as Value
			=> where {
						/^$RE{zip}{US}{-extended => 'allow'}$/;
				};

	has 'street'	=> ( is => 'rw', isa => 'Str' );
	has 'city'		=> ( is => 'rw', isa => 'Str' );
	has 'state'		=> ( is => 'rw', isa => 'USState' );
	has 'zip_code'	=> ( is => 'rw', isa => 'USZipCode' );

	no Frost;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;

	package Company;
#	use Moose;
	use Frost;
	use Moose::Util::TypeConstraints;

	has 'name'			=> ( is => 'rw', isa => 'Str', required => 1 );
	has 'address'		=> ( is => 'rw', isa => 'Address' );
	has 'employees'	=> ( is => 'rw', isa => 'ArrayRef[Employee]' );

	sub BUILD {
		my ( $self, $params ) = @_;

		if ( @{ $self->employees || [] } ) {
			#::IS_DEBUG and ::DEBUG 'Company::BUILD B4', ::Dumper $self->employees;

			foreach my $employee ( @{ $self->employees } ) {
					$employee->employer($self);
			}

			#::IS_DEBUG and ::DEBUG 'Company::BUILD AF', ::Dumper $self->employees;
		}
	}

	after 'employees' => sub {
		my ( $self, $employees ) = @_;

		if ($employees) {
			#::IS_DEBUG and ::DEBUG 'Company::after_employees B4', ::Dumper $employees;

			foreach my $employee ( @{$employees} ) {
					$employee->employer($self);
			}

			#::IS_DEBUG and ::DEBUG 'Company::after_employees AF', ::Dumper $employees;
		}
	};

	no Frost;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;

	package Person;
#	use Moose;
	use Frost;

	has 'first_name'		=> ( is => 'rw', isa => 'Str', required => 1 );
	has 'last_name'		=> ( is => 'rw', isa => 'Str', required => 1 );
	has 'middle_initial'	=> ( is => 'rw', isa => 'Str', predicate => 'has_middle_initial' );
	has 'address'			=> ( is => 'rw', isa => 'Address' );

	sub full_name {
			my $self = shift;
			return $self->first_name
					. (
							$self->has_middle_initial
								? ' ' . $self->middle_initial . '. '
								: ' '
					) . $self->last_name;
	}

	no Frost;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;

	package Employee;
	use Moose;

	extends		'Person';

	has 'title'		=> ( is => 'rw', isa => 'Str',		required => 1 );
#	weak refs are VERBOTEN
#	has 'employer' => ( is => 'rw', isa => 'Company',	weak_ref => 1 );
	has 'employer' => ( is => 'rw', isa => 'Company',	weak_ref => 0 );

	override		'full_name' => sub {
			my $self = shift;
			super() . ', ' . $self->title;
	};

	no Moose;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

# =begin testing
{
	{
		package Company;

	#	sub get_employee_count { scalar @{(shift)->employees} }
		sub get_employee_count { scalar @{ (shift)->employees || [] } }		#	BUGFIX
	}

	diag "Create company...";

	#use Scalar::Util		'isweak';

	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	my $ii;

	lives_ok {
			$ii = Company->new(
					{
						asylum	=> $ASYL,			#	Frost
						id			=> 'II',				#	Frost
						name		=> 'Infinity Interactive',
						address	=> Address->new(
							asylum	=> $ASYL,			#	Frost
							id			=> ++$ADDRESS_ID,	#	Frost
							street	=> '565 Plandome Rd., Suite 307',
							city		=> 'Manhasset',
							state		=> 'NY',
							zip_code	=> '11030'
						),
						employees => [
							Employee->new(
								asylum		=> $ASYL,			#	Frost
								id				=> 1,					#	Frost
								first_name	=> 'Jeremy',
								last_name	=> 'Shao',
								title			=> 'President / Senior Consultant',
								address		=> Address->new(
									asylum	=> $ASYL,			#	Frost
									id			=> ++$ADDRESS_ID,	#	Frost
									city		=> 'Manhasset',
									state		=> 'NY'
								)
							),
							Employee->new(
								asylum		=> $ASYL,			#	Frost
								id				=> 2,					#	Frost
								first_name	=> 'Tommy',
								last_name	=> 'Lee',
								title			=> 'Vice President / Senior Developer',
								address		=>
										Address->new(
											asylum	=> $ASYL,			#	Frost
											id			=> ++$ADDRESS_ID,	#	Frost
											city		=> 'New York',
											state		=> 'NY'
										)
							),
							Employee->new(
								asylum			=> $ASYL,			#	Frost
								id					=> 3,					#	Frost
								first_name		=> 'Stevan',
								middle_initial => 'C',
								last_name		=> 'Little',
								title				=> 'Senior Developer',
								address			=> Address->new(
									asylum	=> $ASYL,			#	Frost
									id			=> ++$ADDRESS_ID,	#	Frost
									city		=> 'Madison',
									state		=> 'CT'
								)
							),
						]
					}
			);
	}
	'... created the entire company successfully';

	isa_ok( $ii,		'Company',					'ii' );
	isa_ok( $ii,		'Frost::Locum',	'ii' );

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}

{
	diag "Check company...";

	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	my $ii;

	lives_ok {
			$ii = Company->new(
					{
							asylum	=> $ASYL,
							id			=> 'II',
					}
			);
	}
	'... reloaded the entire company successfully';

	isa_ok( $ii,		'Company',					'ii' );
	isa_ok( $ii,		'Frost::Locum',	'ii' );

	is( $ii->name,		'Infinity Interactive',			'... got the right name for the company' );

	isa_ok( $ii->address,		'Address',					'ii->address' );
	isa_ok( $ii->address,		'Frost::Locum',	'ii->address' );

	is( $ii->address->street,		'565 Plandome Rd., Suite 307',	'... got the right street address' );
	is( $ii->address->city,			'Manhasset',							'... got the right city' );
	is( $ii->address->state,		'NY',										'... got the right state' );
	is( $ii->address->zip_code,	11030,									'... got the zip code' );

	is( $ii->get_employee_count,	3,											'... got the right employee count' );

	# employee #1

	isa_ok( $ii->employees->[0],		'Employee',					'ii->employees->[0]' );
	isa_ok( $ii->employees->[0],		'Person',					'ii->employees->[0]' );
	isa_ok( $ii->employees->[0],		'Frost::Locum',	'ii->employees->[0]' );

	is( $ii->employees->[0]->first_name,			'Jeremy',		'... got the right first name' );
	is( $ii->employees->[0]->last_name,				'Shao',			'... got the right last name' );
	ok( !$ii->employees->[0]->has_middle_initial,					'... no middle initial' );
	is( $ii->employees->[0]->middle_initial,		undef,			'... got the right middle initial value' );
	is( $ii->employees->[0]->full_name,				'Jeremy Shao, President / Senior Consultant',
																					'... got the right full name' );
	is( $ii->employees->[0]->title,					'President / Senior Consultant',
																					'... got the right title' );
	#is( $ii->employees->[0]->employer, $ii,							'... got the right company' );
	#ok( isweak( $ii->employees->[0]->{employer} ),					'... the company is a weak-ref' );
	#	Locum...
	is( $ii->employees->[0]->employer->id,			'II',				'... has the ii company id' );

	isa_ok($ii->employees->[0]->employer,	'Company',					'ii->employees->[0]->employer' );
	isa_ok($ii->employees->[0]->employer,	'Frost::Locum',	'ii->employees->[0]->employer' );

	isa_ok( $ii->employees->[0]->address,	'Address',					'ii->employees->[0]->address' );
	isa_ok( $ii->employees->[0]->address,	'Frost::Locum',	'ii->employees->[0]->address' );

	is( $ii->employees->[0]->address->city,		'Manhasset',	'... got the right city' );
	is( $ii->employees->[0]->address->state,		'NY',				'... got the right state' );

	# employee #2

	isa_ok( $ii->employees->[1],		'Employee',					'ii->employees->[1]' );
	isa_ok( $ii->employees->[1],		'Person',					'ii->employees->[1]' );
	isa_ok( $ii->employees->[1],		'Frost::Locum',	'ii->employees->[1]' );

	is( $ii->employees->[1]->first_name,			'Tommy',			'... got the right first name' );
	is( $ii->employees->[1]->last_name,				'Lee',			'... got the right last name' );
	ok( !$ii->employees->[1]->has_middle_initial,					'... no middle initial' );
	is( $ii->employees->[1]->middle_initial,		undef,			'... got the right middle initial value' );
	is( $ii->employees->[1]->full_name,				'Tommy Lee, Vice President / Senior Developer',
																					'... got the right full name' );
	is( $ii->employees->[1]->title,					'Vice President / Senior Developer',
																					'... got the right title' );
	#is( $ii->employees->[1]->employer, $ii,							'... got the right company' );
	#ok( isweak( $ii->employees->[1]->{employer} ),					'... the company is a weak-ref' );
	#	Locum...
	is( $ii->employees->[1]->employer->id,			'II',				'... has the ii company id' );

	isa_ok($ii->employees->[1]->employer,	'Company',					'ii->employees->[1]->employer' );
	isa_ok($ii->employees->[1]->employer,	'Frost::Locum',	'ii->employees->[1]->employer' );

	isa_ok( $ii->employees->[1]->address,	'Address',					'ii->employees->[1]->address' );
	isa_ok( $ii->employees->[1]->address,	'Frost::Locum',	'ii->employees->[1]->address' );

	is( $ii->employees->[1]->address->city,		'New York',		'... got the right city' );
	is( $ii->employees->[1]->address->state,		'NY',				'... got the right state' );

	# employee #3

	isa_ok( $ii->employees->[2],		'Employee',					'ii->employees->[2]' );
	isa_ok( $ii->employees->[2],		'Person',					'ii->employees->[2]' );
	isa_ok( $ii->employees->[2],		'Frost::Locum',	'ii->employees->[2]' );

	is( $ii->employees->[2]->first_name,			'Stevan',		'... got the right first name' );
	is( $ii->employees->[2]->last_name,				'Little',		'... got the right last name' );
	ok( $ii->employees->[2]->has_middle_initial,						'... got middle initial' );
	is( $ii->employees->[2]->middle_initial,		'C',				'... got the right middle initial value' );
	is( $ii->employees->[2]->full_name,				'Stevan C. Little, Senior Developer',
																					'... got the right full name' );
	is( $ii->employees->[2]->title,					'Senior Developer',
																					'... got the right title' );
	#is( $ii->employees->[2]->employer, $ii,							'... got the right company' );
	#ok( isweak( $ii->employees->[2]->{employer} ),					'... the company is a weak-ref' );
	#	Locum...
	is( $ii->employees->[2]->employer->id,			'II',				'... has the ii company id' );

	isa_ok($ii->employees->[2]->employer,	'Company',					'ii->employees->[2]->employer' );
	isa_ok($ii->employees->[2]->employer,	'Frost::Locum',	'ii->employees->[2]->employer' );

	isa_ok( $ii->employees->[2]->address,	'Address',					'ii->employees->[2]->address' );
	isa_ok( $ii->employees->[2]->address,	'Frost::Locum',	'ii->employees->[2]->address' );

	is( $ii->employees->[2]->address->city,		'Madison',		'... got the right city' );
	is( $ii->employees->[2]->address->state,		'CT',				'... got the right state' );

	diag "Create new company...";

	my $new_company
			= Company->new(
				asylum	=> $ASYL,
				id			=> 'III',
				name		=> 'Infinity Interactive International'
			);
	isa_ok( $new_company,		'Company',					'new_company' );
	isa_ok( $new_company,		'Frost::Locum',	'new_company' );

	my $ii_employees = $ii->employees;
	foreach my $employee (@$ii_employees) {
	#	Locum !!!
	#		is( $employee->employer, $ii,										'... has the ii company' );
			is( $employee->employer->id,		'II',							'... has the ii company id' );
			isa_ok( $employee->employer,		'Company',					'employee->employer' );
			isa_ok( $employee->employer,		'Frost::Locum',	'employee->employer' );
	}

	$new_company->employees($ii_employees);

	foreach my $employee ( @{ $new_company->employees } ) {
	#	Locum !!!
	#		is( $employee->employer, $new_company,							'... has the different company now' );
			is( $employee->employer->id,		'III',						'... has the different company id now' );
			isa_ok( $employee->employer,		'Company',					'employee->employer' );
			isa_ok( $employee->employer,		'Frost::Locum',	'employee->employer' );
	}

	{
		###############
		#	Frost	###
		#
		#	removing of employees was missing in original test:
		#
		my $old_company
				= Company->new(					#	from twilight...
					asylum	=> $ASYL,
					id			=> 'II',
				);

		isnt( $old_company->_dirty, true,	'II Company is clean' );

		$old_company->employees([]);

		is( $old_company->_dirty, true,		'II Company is dirty after removing employees' );
		#
		###############
	}

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}

my $CONTROL	= {};

{
	diag "Check some error conditions for the subtypes...";

	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	$ADDRESS_ID++;

	$CONTROL->{Address}->{bad}->{$ADDRESS_ID}++;

	dies_ok {
			Address->new(
				asylum	=> $ASYL,			#	Frost
				id			=> $ADDRESS_ID,	#	Frost
				street	=> {} );
	}
	'... we die correctly with bad args, Address ' . $ADDRESS_ID;

	#	DON'T DO THIS AT HOME!
	#
	#	We are NOT dead - test ist still running -,
	#	so if we do not manually remove the failing
	#	entry here, Locum->save will fail later,
	#	because the object is incomplete -
	#	i.e. asylum missing!
	#
	lives_ok { $ASYL->excommunicate ( 'Address', $ADDRESS_ID ); }	'... excommunicating Address ' . $ADDRESS_ID;

	$ADDRESS_ID++;

	$CONTROL->{Address}->{bad}->{$ADDRESS_ID}++;

	dies_ok {
			Address->new(
				asylum	=> $ASYL,			#	Frost
				id			=> $ADDRESS_ID,	#	Frost
				city		=> {} );
	}
	'... we die correctly with bad args, Address ' . $ADDRESS_ID;

	lives_ok { $ASYL->excommunicate ( 'Address', $ADDRESS_ID ); }	'... excommunicating Address ' . $ADDRESS_ID;

	$ADDRESS_ID++;

	$CONTROL->{Address}->{bad}->{$ADDRESS_ID}++;

	dies_ok {
			Address->new(
				asylum	=> $ASYL,			#	Frost
				id			=> $ADDRESS_ID,	#	Frost
				state		=> 'British Columbia' );
	}
	'... we die correctly with bad args, Address ' . $ADDRESS_ID;

	lives_ok { $ASYL->excommunicate ( 'Address', $ADDRESS_ID ); }	'... excommunicating Address ' . $ADDRESS_ID;

	$ADDRESS_ID++;

	$CONTROL->{Address}->{good}->{$ADDRESS_ID}++;

	lives_ok {
			Address->new(
				asylum	=> $ASYL,			#	Frost
				id			=> $ADDRESS_ID,	#	Frost
				state		=> 'Connecticut' );
	}
	'... we live correctly with good args, Address ' . $ADDRESS_ID;

	$ADDRESS_ID++;

	$CONTROL->{Address}->{bad}->{$ADDRESS_ID}++;

	dies_ok {
			Address->new(
				asylum	=> $ASYL,			#	Frost
				id			=> $ADDRESS_ID,	#	Frost
				zip_code	=> 'AF5J6$' );
	}
	'... we die correctly with bad args, Address ' . $ADDRESS_ID;

	lives_ok { $ASYL->excommunicate ( 'Address', $ADDRESS_ID ); }	'... excommunicating Address ' . $ADDRESS_ID;

	$ADDRESS_ID++;

	$CONTROL->{Address}->{good}->{$ADDRESS_ID}++;

	lives_ok {
			Address->new(
				asylum	=> $ASYL,			#	Frost
				id			=> $ADDRESS_ID,	#	Frost
				zip_code => '06443' );
	}
	'... we live correctly with good args, Address ' . $ADDRESS_ID;

	$CONTROL->{Company}->{bad}->{Empty}++;

	dies_ok {
			Company->new(
				asylum	=> $ASYL,			#	Frost
				id			=> 'Empty',			#	Frost
			);
	}
	'... we die correctly without good args, Company Empty';

	lives_ok { $ASYL->excommunicate ( 'Company', 'Empty' ); }		'... excommunicating Company Empty';

	$CONTROL->{Company}->{good}->{Foo1}++;

	lives_ok {
			Company->new(
				asylum	=> $ASYL,			#	Frost
				id			=> 'Foo1',			#	Frost
				name => 'Foo Ltd.' );
	}
	'... we live correctly with good args, Company Foo1';

	$CONTROL->{Company}->{bad}->{Foo2}++;

	dies_ok {
			Company->new(
				asylum	=> $ASYL,			#	Frost
				id			=> 'Foo2',			#	Frost
				name => 'Foo', employees => [ Person->new ] );		#	id & asylum missing...
	}
	'... we die correctly with bad employees, Company Foo2';

	$CONTROL->{Company}->{good}->{Foo3}++;

	lives_ok {
			Company->new(
				asylum	=> $ASYL,			#	Frost
				id			=> 'Foo3',			#	Frost
				name => 'Foo Inc.', employees => [] );
	}
	'... we live correctly without employees, Company Foo3';

	diag "Save, what changed...";

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}


{
	diag "Reload...";

	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	foreach my $class ( sort keys %$CONTROL )
	{
		my $good	= $CONTROL->{$class}->{good};
		my $bad	= $CONTROL->{$class}->{bad};

		foreach my $id ( sort keys %$good )
		{
			lives_ok	{ my $locum	= $class->new( asylum	=> $ASYL, id => $id, zip_code => 'Ignored, if saved' ); }
							"... $class\->$id was saved";
		}
		foreach my $id ( sort keys %$bad )
		{
			dies_ok	{ my $locum	= $class->new( asylum	=> $ASYL, id => $id, zip_code => 'Error, if not saved' ); }
						"... $class\->$id was NOT saved";
		}
	}

	my ( $foo1, $foo3, $ii, $iii );

	lives_ok {	$foo1	= Company->new( asylum	=> $ASYL, id => 'Foo1'	) }	'... Foo1 reloaded';
	lives_ok {	$foo3	= Company->new( asylum	=> $ASYL, id => 'Foo3'	) }	'... Foo3 reloaded';
	lives_ok {	$ii	= Company->new( asylum	=> $ASYL, id => 'II'		) }	'... II reloaded';
	lives_ok {	$iii	= Company->new( asylum	=> $ASYL, id => 'III'	) }	'... III reloaded';

	isa_ok( $foo1,	'Company',	'foo1'	);	isa_ok( $foo1,	'Frost::Locum',	'foo1'	);
	isa_ok( $foo3,	'Company',	'foo3'	);	isa_ok( $foo3,	'Frost::Locum',	'foo3'	);
	isa_ok( $ii,	'Company',	'ii'		);	isa_ok( $ii,	'Frost::Locum',	'ii'		);
	isa_ok( $iii,	'Company',	'iii'		);	isa_ok( $iii,	'Frost::Locum',	'iii'		);

	is	( $foo1->name,	'Foo Ltd.',										'Foo1 has the right name' );
	is	( $foo3->name,	'Foo Inc.',										'Foo3 has the right name' );
	is	( $ii->name,	'Infinity Interactive',						'II   has the right name' );
	is	( $iii->name,	'Infinity Interactive International',	'III  has the right name' );

	is	( $foo1->get_employee_count,	0,		'Foo1 has undef employees' );
	is	( $foo3->get_employee_count,	0,		'Foo3 has no employees' );
	is	( $ii->get_employee_count,		0,		'II   has no employees' );
	is	( $iii->get_employee_count,	3,		'III  has 3 employees' );

	foreach my $employee ( @{ $iii->employees } ) {
	#	Locum !!!
	#		is( $employee->employer, $new_company,						'... has the different company now' );
			is( $employee->employer->id,		'III',					'... has the different company id now' );
			isa_ok( $employee->employer,		'Company',					'employee->employer' );
			isa_ok( $employee->employer,		'Frost::Locum',	'employee->employer' );
	}

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}
