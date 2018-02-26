package Games::LatticeGenerator::Geometry::Quadrangle;
use strict;
use warnings;
use Games::LatticeGenerator::Geometry::Point;
use Games::LatticeGenerator::Geometry::Stretch;
use Games::LatticeGenerator::Geometry::Polygon;
use base 'Games::LatticeGenerator::Geometry::Polygon';



=head1 NAME

Games::LatticeGenerator::Geometry::Quadrangle

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';



=head1 SUBROUTINES/METHODS

=head2 new

A constructor. It adds knowledge about the internal angles.

=cut
sub new
{
	my $class = shift;
	my $this = $class->SUPER::new(@_);
	
	$$this{description} .=<<DESCRIPTION;
is_a_Quadrangle($$this{name}).
DESCRIPTION

	$this->add_knowledge_about_internal_angles();
	return $this;
}

=head2 add_knowledge_about_internal_angles

=cut
sub add_knowledge_about_internal_angles
{
	my $this = shift;
	for my $w (keys %{$$this{internal_angles}})
	{
		$$this{description}.= <<DESCRIPTION;
is_an_InternalAngle($$this{name}, $w, $$this{internal_angles}{$w}).
DESCRIPTION
	}
}

=head2 get_amount_of_edges

=cut
sub get_amount_of_edges
{
	return 4;
}

1;
