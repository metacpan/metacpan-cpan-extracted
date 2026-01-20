BEGIN {
	package Local::Person;
	use Marlin::Util -all;
	use Marlin ':ToHash',
		'first_name!' => { to_hash => false },
		'last_name!'  => { to_hash => false },
		'age'         => { to_hash => true };

	sub AFTER_TO_HASH {
		my ( $self, $args, $hashref ) = @_;
		$hashref->{full_name} =
			join q[ ], $self->first_name, $self->last_name;
	}
};

use Test2::V0;

my $x = Local::Person->new(
	first_name   => 'Alice',
	last_name    => 'Smith',
	age          => 30,
);

is( $x->to_hash, { full_name => 'Alice Smith', age => 30 } );

done_testing;
