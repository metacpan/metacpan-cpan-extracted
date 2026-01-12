BEGIN {{{ # Port of Moose::Cookbook::Basics::Point_AttributesAndSubclassing

package Point {
	use Marlin::Antlers;

	has [ qw( x y ) ] => ( is => rw, isa => Int, required => true );

	sub clear ( $self ) {
		$self->x( 0 );
		$self->y( 0 );
	}
}

package Point3D {
	use Marlin::Antlers;
	extends 'Point';
	
	has z => ( is => rw, isa => Int, required => true );

	after clear => sub ( $self ) {
		$self->z( 0 );
	};
}

}}};

use Test2::V0;
use Data::Dumper;

my $point1 = Point->new(x => 5, y => 7);
is( $point1->x, 5 );
is( $point1->y, 7 );

my $point2 = Point->new({x => 5, y => 7});
is( $point2->x, 5 );
is( $point2->y, 7 );

my $point3d = Point3D->new(x => 5, y => 42, z => -5);
is( $point3d->x, 5 );
is( $point3d->y, 42 );
is( $point3d->z, -5 );

$point3d->clear;
is( $point3d->x, 0 );
is( $point3d->y, 0 );
is( $point3d->z, 0 );

done_testing;
