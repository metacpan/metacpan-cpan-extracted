BEGIN {{{ # Port of Moose::Cookbook::Basics::Company_Subtypes

package Address {
	use Marlin::Antlers;

	use Locale::US;
	use Regexp::Common 'zip';

	my $USState =
		Str->where( sub {
			state $STATES = Locale::US->new;
			exists $STATES->{code2state}{ uc($_) } or
			exists $STATES->{state2code}{ uc($_) }
		} );

	my $USZipCode =
		StrMatch[ qr/^$RE{zip}{US}{-extended => 'allow'}$/ ];

	has street    => ( is => rw, isa => Str );
	has city      => ( is => rw, isa => Str );
	has state     => ( is => rw, isa => $USState );
	has zip_code  => ( is => rw, isa => $USZipCode );
}

package Company {
	use Marlin::Antlers;

	has name      => ( is => rw, isa => Str, required => true );
	has address   => ( is => rw, isa => 'Address' );
	has employees => ( is => rw, isa => 'ArrayRef[Employee]', default => [], trigger => true );

	sub _trigger_employees ( $self, $employees ) {
		for my $employee ( $self->employees->@* ) {
			$employee->employer( $self );
		}
	}
}

package Person {
	use Marlin::Antlers;

	has first_name     => ( is => rw, isa => Str, required => true );
	has last_name      => ( is => rw, isa => Str, required => true );
	has middle_initial => ( is => rw, isa => Str, predicate => true );
	has address        => ( is => rw, isa => 'Address' );

	sub full_name ( $self ) {
		state $SPACE = q[ ];
		return join $SPACE => (
			$self->first_name,
			$self->has_middle_initial ? $self->middle_initial : (),
			$self->last_name,
		);
	}
}

package Employee {
	use Marlin::Antlers;
	extends 'Person';

	has title    => ( is => rw, isa => Str, required => true );
	has employer => ( is => rw, isa => 'Company', weak_ref => true );

	around full_name => sub ( $next, $self ) {
		sprintf '%s, %s', $self->$next(), $self->title;
	};
}

}}};

use Test2::V0;
use Data::Dumper;

my $alice = Employee->new(
	first_name => 'Alice',
	last_name  => 'Smith',
	title      => 'President',
);

is( $alice->full_name, "Alice Smith, President" );

my $bob = Employee->new(
	first_name => 'Bob',
	middle_initial => 'B',
	last_name  => 'Jones',
	title      => 'Vice President',
);

is( $bob->full_name, "Bob B Jones, Vice President" );

my $acme = Company->new(
	name    => 'ACME',
	address => Address->new(
		street   => '123 Test Street',
		city     => 'Somewhere',
		state    => 'CA',
		zip_code => '12345',
	),
	employees => [ $alice, $bob ],
);

is( $alice->employer->name, 'ACME' );

diag Dumper( $acme ) if $ENV{EXTENDED_TESTING};

done_testing;
