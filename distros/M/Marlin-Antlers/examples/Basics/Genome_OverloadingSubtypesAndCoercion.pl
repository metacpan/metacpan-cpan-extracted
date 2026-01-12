BEGIN {{{ # Port of Moose::Cookbook::Basics::Genome_OverloadingSubtypesAndCoercion

package Human::Gene::bey2 {
	use Marlin::Antlers;
	has color => ( enum => [qw( brown blue )] );
}

package Human::Gene::gey {
	use Marlin::Antlers;
	has color => ( enum => [qw( green blue )] );
}

package Human::EyeColor {
	use Marlin::Antlers;

	my $Bey2 = InstanceOf->of( 'Human::Gene::bey2' )->plus_coercions(
		Str, sub { Human::Gene::bey2->new( color => $_ ) },
	);

	my $Gey = InstanceOf->of( 'Human::Gene::gey' )->plus_coercions(
		Str, sub { Human::Gene::gey->new( color => $_ ) },
	);

	has [ qw( bey2_1 bey2_2 ) ] => ( isa => $Bey2, coerce => true );
	has [ qw( gey_1  gey_2  ) ] => ( isa => $Gey,  coerce => true );

	# Include @dummy because `use overload` sometimes passes
	# fairly unexpected additional parameters.
	sub color ( $self, @dummy ) {
		return 'brown' if $self->bey2_1->color eq 'brown';
		return 'brown' if $self->bey2_2->color eq 'brown';
		return 'green' if $self->gey_1->color eq 'green';
		return 'green' if $self->gey_2->color eq 'green';
		return 'blue';
	}

	my sub _overload_add ( $one, $two, @dummy ) {
		my sub rand2 ( $prefix ) {
			my $n = 1 + int( rand(2) );
			return \ join q[_] => ( $prefix, $n ) ;
		}
		
		return __PACKAGE__->new(
			bey2_1 => $one->${ rand2 'bey2' }->color,
			bey2_2 => $two->${ rand2 'bey2' }->color,
			gey_1  => $one->${ rand2 'gey' }->color,
			gey_2  => $two->${ rand2 'gey' }->color,
		);
	}

	use overload '""' => \&color, '+' => \&_overload_add, fallback => 1;
}

package Human {
	use Marlin::Antlers;
	use Carp 'confess';
	use List::Util 1.56 'mesh';

	my $EyeColor = do {
		my $genes = [ qw( bey2_1 bey2_2 gey_1 gey_2 ) ];
		InstanceOf->of('Human::EyeColor')->plus_coercions(
			ArrayRef, sub { Human::EyeColor->new( mesh $genes, $_ ) },
		);
	};

	has sex        => ( enum => [qw( f m )], required => true );
	has eye_color  => ( isa => $EyeColor, coerce => true, required => true );
	has mother     => ( isa => __PACKAGE__ );
	has father     => ( isa => __PACKAGE__ );

	my sub _overload_add ( $one, $two, @dummy ) {

		confess 'Only male and female humans may create children' if $one->sex eq $two->sex;

		my ( $mother, $father )
			= $one->sex eq 'f' ? ( $one, $two ) : ( $two, $one );

		return __PACKAGE__->new(
			sex        => ( rand() >= 0.5 ) ? 'f' : 'm',
			eye_color  => $mother->eye_color + $father->eye_color,
			mother     => $mother,
			father     => $father,
		);
	}

	use overload '+' => \&_overload_add, fallback => 1;
}

}}};

use Test2::V0;

my @gene_color_sets = (
	[ qw( blue blue blue blue )     => 'blue' ],
	[ qw( blue blue green blue )    => 'green' ],
	[ qw( blue blue blue green )    => 'green' ],
	[ qw( blue blue green green )   => 'green' ],
	[ qw( brown blue blue blue )    => 'brown' ],
	[ qw( brown brown green green ) => 'brown' ],
	[ qw( blue brown green blue )   => 'brown' ],
);

for my $set ( @gene_color_sets ) {
	my $expected_color = pop( $set->@* );

	my $person = Human->new( sex => 'f', eye_color => $set );

	is(
		$person->eye_color(),
		$expected_color,
		sprintf( 'gene combination %s produces %s eye color', join( q[ + ], $set->@* ), $expected_color )
	);
}

my @parent_sets = (
	[
		[qw( blue blue blue blue )],
		[qw( blue blue blue blue )] => 'blue'
	],
	[
		[qw( blue blue blue blue )],
		[qw( brown brown green blue )] => 'brown'
	],
	[
		[qw( blue blue green green )],
		[qw( blue blue green green )] => 'green'
	],
);

for my $set ( @parent_sets ) {
	my $expected_color = pop( $set->@* );

	my $mother = Human->new( sex => 'f', eye_color => shift( $set->@* ) );
	my $father = Human->new( sex => 'm', eye_color => shift( $set->@* ) );
	my $child  = $mother + $father;

	is(
		$child->eye_color(),
		$expected_color,
		sprintf( 'mother %s + father %s = child %s', $mother->eye_color, $father->eye_color, $expected_color )
	);
}

done_testing;