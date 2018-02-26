package Games::LatticeGenerator::Model::Spaceship;

use strict;
use warnings;
use Games::LatticeGenerator::Geometry::Point;
use Games::LatticeGenerator::Geometry::Stretch;
use Games::LatticeGenerator::Geometry::Quadrangle;
use Games::LatticeGenerator::Geometry::IsoscelesTrapezoid;
use Games::LatticeGenerator::Geometry::Solid;
use Math::Trig;
use Carp;
use Games::LatticeGenerator::Model;
use base 'Games::LatticeGenerator::Model';




=head1 NAME

Games::LatticeGenerator::Model::Spaceship

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';



=head1 SUBROUTINES/METHODS

=head2 new

A constructor.

=cut
sub new
{
	my $class = shift;
	
	my $this = $class->SUPER::new(@_);
	
	my $prefix = $$this{prefix};
	
	croak "missing prefix" unless $prefix;

	my $amount_of_points = int(rand()*6)+4;
	
	# create the profiles
	my @profile_0 = map { 
		{ 
			x=>40+rand()*50.0, 
			y=>30 + $_*60+rand()*30, 
			z=> -sin(3.14159*$_/$amount_of_points)*40.0 - 10.0
		} 
	} 0..$amount_of_points-1;

	my @profile_1 = map { 
		{ 
			x=>$profile_0[$_]{x} - rand()*30.0, 
			y=>$profile_0[$_]{y} - 10.0 + rand()*20.0, 
			z=>sin(3.14159*$_/$amount_of_points)*40 + 10 + rand()*20.0
		}
	} 0..$amount_of_points-1;


	for my $i (1..$amount_of_points-1)
	{
		# point $i must be in one plane with the points:
		my $p0 = $profile_0[$i-1];
		my $p1 = $profile_0[$i];
		my $q0 = $profile_1[$i-1];

		#
		# $profile_1[$i]{y} = $$p0{y}+($$p1{y}-$$p0{y})*$A+($$q0{y}-$$p0{y})*$B;
		# $profile_1[$i]{z} = $$p0{z}+($$p1{z}-$$p0{z})*$A+($$q0{z}-$$p0{z})*$B;

		my @matrix =
		(
			[$$p1{y}-$$p0{y}, $$q0{y}-$$p0{y}],		
			[$$p1{z}-$$p0{z}, $$q0{z}-$$p0{z}]
		);
		my @vector =
		(
			$profile_1[$i]{y}-$$p0{y},
			$profile_1[$i]{z}-$$p0{z}
		);

		my $det = $matrix[0][0]*$matrix[1][1]-$matrix[0][1]*$matrix[1][0];
		my $det_A = $vector[0]*$matrix[1][1]-$matrix[0][1]*$vector[1];
		my $det_B = $matrix[0][0]*$vector[1]-$vector[0]*$matrix[1][0];

		my $A = $det_A/$det;
		my $B = $det_B/$det;

		$profile_1[$i]{x} = $$p0{x}+($$p1{x}-$$p0{x})*$A+($$q0{x}-$$p0{x})*$B;
		$profile_1[$i]{y} = $$p0{y}+($$p1{y}-$$p0{y})*$A+($$q0{y}-$$p0{y})*$B;
		$profile_1[$i]{z} = $$p0{z}+($$p1{z}-$$p0{z})*$A+($$q0{z}-$$p0{z})*$B;

		while ($profile_1[$i]{x} < 0.0) 
		{ 
			$A = 0.7+rand()*0.5;
			$B = 0.7+rand()*0.5;

			$profile_1[$i]{x} = $$p0{x}+($$p1{x}-$$p0{x})*$A+($$q0{x}-$$p0{x})*$B;
			$profile_1[$i]{y} = $$p0{y}+($$p1{y}-$$p0{y})*$A+($$q0{y}-$$p0{y})*$B;
			$profile_1[$i]{z} = $$p0{z}+($$p1{z}-$$p0{z})*$A+($$q0{z}-$$p0{z})*$B;

		}
	}
	
	
	my @points_left_0 = map { Games::LatticeGenerator::Geometry::Point->new(name => "${prefix}_left_0_$_") } 0..$amount_of_points-1;
	my @points_left_1 = map { Games::LatticeGenerator::Geometry::Point->new(name => "${prefix}_left_1_$_") } 0..$amount_of_points-1;
	my @points_right_0 = map { Games::LatticeGenerator::Geometry::Point->new(name => "${prefix}_right_0_$_") } 0..$amount_of_points-1;
	my @points_right_1 = map { Games::LatticeGenerator::Geometry::Point->new(name => "${prefix}_right_1_$_") } 0..$amount_of_points-1;

	my @stretches_middle_up = map 
	{ 
		Games::LatticeGenerator::Geometry::Stretch->new(
			name => "${prefix}_center_0_0_${_}",
			points => [$points_left_0[$_], $points_right_0[$_]],
			length => abs($profile_0[$_]{x}*2)
		) 
	} 0..$amount_of_points-1;

	my @stretches_middle_down = map 
	{ 
		Games::LatticeGenerator::Geometry::Stretch->new(
			name => "${prefix}_bottom_0_0_${_}",
			points => [$points_left_1[$_], $points_right_1[$_]],
			length => abs($profile_1[$_]{x}*2)
		) 
	} 0..$amount_of_points-1;

	my @stretches_left_vertical_0_1 = map 
	{ 
		Games::LatticeGenerator::Geometry::Stretch->new(
			name => "${prefix}_left_vertical_0_1_${_}",
			points => [$points_left_0[$_], $points_left_1[$_]],
			length => $this->get_distance($profile_0[$_], $profile_1[$_])) 
	} 0..$amount_of_points-1;

	my @stretches_right_vertical_0_1 = map 
	{ 
		Games::LatticeGenerator::Geometry::Stretch->new(
			name => "${prefix}_right_vertical_0_1_${_}",
			points => [$points_right_0[$_], $points_right_1[$_]],
			length => $this->get_distance($profile_0[$_], $profile_1[$_])) 
	} 0..$amount_of_points-1;

	
	
	
	my @stretches_left_horizontal_0 = map
	{
		Games::LatticeGenerator::Geometry::Stretch->new(
			name => "${prefix}_left_horizontal_0_${_}",
			points => [$points_left_0[$_], $points_left_0[$_+1]],
			length => $this->get_distance($profile_0[$_], $profile_0[$_+1])) 
	} 0..$amount_of_points-2;

	my @stretches_right_horizontal_0 = map
	{
		Games::LatticeGenerator::Geometry::Stretch->new(
			name => "${prefix}_right_horizontal_0_${_}",
			points => [$points_right_0[$_], $points_right_0[$_+1]],
			length => $this->get_distance($profile_0[$_], $profile_0[$_+1])) 
	} 0..$amount_of_points-2;

	my @stretches_left_horizontal_1 = map
	{
		Games::LatticeGenerator::Geometry::Stretch->new(
			name => "${prefix}_left_horizontal_1_${_}",
			points => [$points_left_1[$_], $points_left_1[$_+1]],
			length => $this->get_distance($profile_1[$_], $profile_1[$_+1])) 
	} 0..$amount_of_points-2;

	my @stretches_right_horizontal_1 = map
	{
		Games::LatticeGenerator::Geometry::Stretch->new(
			name => "${prefix}_right_horizontal_1_${_}",
			points => [$points_right_1[$_], $points_right_1[$_+1]],
			length => $this->get_distance($profile_1[$_], $profile_1[$_+1])) 
	} 0..$amount_of_points-2;

	
	my @planes_left = map 
	{ 
		Games::LatticeGenerator::Geometry::Quadrangle->new(
		name => "${prefix}_left_plane_0_1_${_}", 
		edges => [ $stretches_left_vertical_0_1[$_], $stretches_left_horizontal_1[$_], $stretches_left_vertical_0_1[$_+1], $stretches_left_horizontal_0[$_] ],
		sheet => 1,
		base => $stretches_left_horizontal_0[$_],
		internal_angles =>
			{
				"${prefix}_left_0_$_" => $this->get_angle_between_vectors(
						$profile_0[$_],
						$profile_0[$_+1],
						$profile_1[$_]),

				"${prefix}_left_0_".($_+1) => $this->get_angle_between_vectors(
						$profile_0[$_+1],
						$profile_0[$_],
						$profile_1[$_+1]
						),

				"${prefix}_left_1_$_" => $this->get_angle_between_vectors(
						$profile_1[$_],
						$profile_1[$_+1],
						$profile_0[$_]
						),

				"${prefix}_left_1_".($_+1) => $this->get_angle_between_vectors(
						$profile_1[$_+1],
						$profile_1[$_],
						$profile_0[$_+1]
						)
			},
			rotation => [ 
				$points_left_0[$_], 
				$points_left_0[$_+1], 
				$points_left_1[$_+1],
				$points_left_1[$_]
			]
		) 
	} 0..$amount_of_points-2;

	
	
	my @planes_right = map 
	{ 
		Games::LatticeGenerator::Geometry::Quadrangle->new(
		name => "${prefix}_right_plane_0_1_${_}", 
		edges => [ $stretches_right_vertical_0_1[$_], $stretches_right_horizontal_1[$_], $stretches_right_vertical_0_1[$_+1], $stretches_right_horizontal_0[$_] ],
		sheet => 2,
		base => $stretches_right_horizontal_0[$_],
		internal_angles =>
			{
				"${prefix}_right_0_$_" => $this->get_angle_between_vectors(
						$profile_0[$_],
						$profile_0[$_+1],
						$profile_1[$_]),

				"${prefix}_right_0_".($_+1) => $this->get_angle_between_vectors(
						$profile_0[$_+1],
						$profile_0[$_],
						$profile_1[$_+1]
						),

				"${prefix}_right_1_$_" => $this->get_angle_between_vectors(
						$profile_1[$_],
						$profile_1[$_+1],
						$profile_0[$_]
						),

				"${prefix}_right_1_".($_+1) => $this->get_angle_between_vectors(
						$profile_1[$_+1],
						$profile_1[$_],
						$profile_0[$_+1]
						)
			},
			rotation => [ 
				$points_right_0[$_], 
				$points_right_1[$_], 
				$points_right_1[$_+1],
				$points_right_0[$_+1]
			]
		) 
	} 0..$amount_of_points-2;
	
	
	
	my $plane_front = Games::LatticeGenerator::Geometry::IsoscelesTrapezoid->new(
		name => "${prefix}_front_plane_0_0_", 
		edges => [ $stretches_right_vertical_0_1[$amount_of_points-1], $stretches_middle_up[$amount_of_points-1], $stretches_left_vertical_0_1[$amount_of_points-1], 
		$stretches_middle_down[$amount_of_points-1] ],
		base_lower => $stretches_middle_up[$amount_of_points-1],
		base_upper => $stretches_middle_down[$amount_of_points-1],
		sheet => 3,

		rotation => [ 
				$points_left_0[$amount_of_points-1], 
				$points_left_1[$amount_of_points-1], 
				$points_right_1[$amount_of_points-1],
				$points_right_0[$amount_of_points-1]
			]

		);
		
	
	my $plane_rear = Games::LatticeGenerator::Geometry::IsoscelesTrapezoid->new(
		name => "${prefix}_rear_plane_0_0_", 
		edges => [ $stretches_right_vertical_0_1[0], $stretches_middle_up[0], $stretches_left_vertical_0_1[0], 
		$stretches_middle_down[0] ],
		base_lower => $stretches_middle_up[0],
		base_upper => $stretches_middle_down[0],
		sheet => 4,

		rotation => [ 
				$points_left_0[0], 
				$points_left_1[0], 
				$points_right_1[0],
				$points_right_0[0]
			]
		);

	my @planes_middle_up = map 
	{ 
		Games::LatticeGenerator::Geometry::IsoscelesTrapezoid->new(
		name => "${prefix}_top_plane_0_0_${_}", 
		edges => [ $stretches_left_horizontal_0[$_], $stretches_middle_up[$_], $stretches_right_horizontal_0[$_], $stretches_middle_up[$_+1] ],
		base_lower => $stretches_middle_up[$_],
		base_upper => $stretches_middle_up[$_+1],
		sheet => 5,
		
		rotation => [ 
				$points_left_0[$_+1], 
				$points_left_0[$_], 
				$points_right_0[$_],
				$points_right_0[$_+1]
			]

		) 
	} 0..$amount_of_points-2;
	
	my @planes_middle_down = map 
	{ 
		Games::LatticeGenerator::Geometry::IsoscelesTrapezoid->new(
		name => "${prefix}_bottom_plane_0_0_${_}", 
		edges => [ $stretches_left_horizontal_1[$_], $stretches_middle_down[$_], $stretches_right_horizontal_1[$_], $stretches_middle_down[$_+1] ],
		base_lower => $stretches_middle_down[$_],
		base_upper => $stretches_middle_down[$_+1],
		sheet => 6,

		rotation => [ 
				$points_left_1[$_], 
				$points_left_1[$_+1], 
				$points_right_1[$_+1],
				$points_right_1[$_]
			]
		) 
	} 0..$amount_of_points-2;


	my $body = Games::LatticeGenerator::Geometry::Solid->new(name => "${prefix}_body",
		planes => [ 
			@planes_left, 
			@planes_middle_up, 
			$plane_front,
			@planes_right,
			@planes_middle_down,
			$plane_rear
			]);

	$$this{solids} = [ $body ];
	
	$this->add_knowledge_about_solids();
	
	$$this{amount_of_sheets} = 6;
			
	return $this;
}


1;
