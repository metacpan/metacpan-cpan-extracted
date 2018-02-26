package Games::LatticeGenerator::Geometry::IsoscelesTrapezoid;
use strict;
use warnings;
use Games::LatticeGenerator::Geometry::Trapezoid;
use Carp;
use base 'Games::LatticeGenerator::Geometry::Trapezoid';


=head1 NAME

Games::LatticeGenerator::Geometry::IsoscelesTrapezoid 

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SUBROUTINES/METHODS

=head2 new

A constructor. It adds knowledge about the bases (upper and lower).

=cut
sub new
{
	my $class = shift;
	my $this = $class->SUPER::new(@_);

	if ($$this{base_lower})
	{
		$$this{description} .= <<DESCRIPTION;
is_a_BaseLower($$this{base_lower}{name}, $$this{name}).
DESCRIPTION
	}	

	if ($$this{base_upper})
	{
		$$this{description} .= <<DESCRIPTION;
is_a_BaseUpper($$this{base_upper}{name}, $$this{name}).
DESCRIPTION
	}	

	return $this;
}



=head2 add_knowledge_about_internal_angles

Calculates the internal angles and adds the knowledge about them.

=cut
sub add_knowledge_about_internal_angles
{
	my $this = shift;
	my @points_at_base_lower = $this->get_solution(__LINE__,"POINT", "is_a_Point(POINT), belongs_to(POINT, $$this{base_lower}{name}), belongs_to($$this{base_lower}{name}, $$this{name})");

	my @points_at_base_upper = $this->get_solution(__LINE__,"POINT", "is_a_Point(POINT), belongs_to(POINT, $$this{base_upper}{name}), belongs_to($$this{base_upper}{name}, $$this{name})");


	my ($point_at_base_upper) = $this->get_solution(__LINE__,"POINT", <<CONDITION);
is_a_Point(POINT), 
belongs_to(POINT, EDGE1), 
belongs_to(POINT, EDGE2), 
belongs_to(EDGE1, $$this{name}), 
belongs_to(EDGE2, $$this{name}), 
not(eq(EDGE1, $$this{base_lower}{name})), 
not(eq(EDGE2, $$this{base_lower}{name})), 
not(eq(EDGE1, EDGE2))
CONDITION


	croak "there are no vertices" unless scalar(@points_at_base_lower);
	croak "there are no vertices" unless scalar(@points_at_base_upper);

	my ($base_lower_length) = $this->get_solution(__LINE__, "LENGTH", "has_length($$this{base_lower}{name}, LENGTH)");
	my ($base_upper_length) = $this->get_solution(__LINE__, "LENGTH", "has_length($$this{base_upper}{name}, LENGTH)");

	croak "point_at_base_upper not found" unless defined($point_at_base_upper);

	my ($length_of_arm) = $this->get_solution(__LINE__, "LENGTH", "has_length(EDGE, LENGTH), belongs_to($point_at_base_upper, EDGE), not(eq(EDGE, $$this{base_lower}{name})), not(eq(EDGE, $$this{base_upper}{name}))");

	croak "missing length" unless defined($base_lower_length);
	croak "missing length" unless defined($base_upper_length);


	croak "undefined arm" unless defined($length_of_arm);

	my $d;

	if ($base_lower_length > $base_upper_length)
	{
		$d = ($base_lower_length - $base_upper_length)/2.0;
	}
	else
	{
		$d = ($base_upper_length - $base_lower_length)/2.0;
	}

	if ($length_of_arm < $d) 
	{ 
		croak "$length_of_arm < $d"; 
	}

	my $height = sqrt($length_of_arm*$length_of_arm-$d*$d);

	my $angle1 = atan2($height, $d)*180/3.14159;
	my $angle2 = 180.0-$angle1;

	if ($base_lower_length > $base_upper_length)
	{
		$$this{description}.= <<DESCRIPTION;
is_an_InternalAngle($$this{name}, $points_at_base_lower[0], $angle1).
is_an_InternalAngle($$this{name}, $points_at_base_lower[1], $angle1).
is_an_InternalAngle($$this{name}, $points_at_base_upper[0], $angle2).
is_an_InternalAngle($$this{name}, $points_at_base_upper[1], $angle2).
DESCRIPTION
	}
	else
	{
		$$this{description}.= <<DESCRIPTION;
is_an_InternalAngle($$this{name}, $points_at_base_lower[0], $angle2).
is_an_InternalAngle($$this{name}, $points_at_base_lower[1], $angle2).
is_an_InternalAngle($$this{name}, $points_at_base_upper[0], $angle1).
is_an_InternalAngle($$this{name}, $points_at_base_upper[1], $angle1).
DESCRIPTION
	}
}

1;
