package Games::LatticeGenerator::Geometry::Trapezoid;
use strict;
use warnings;
use Games::LatticeGenerator::Geometry::Polygon;
use Carp;
use base 'Games::LatticeGenerator::Geometry::Polygon';


=head1 NAME

Games::LatticeGenerator::Geometry::Trapezoid 

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
	
	$$this{description} .=<<DESCRIPTION;
is_a_Trapezoid($$this{name}).
DESCRIPTION

	$this->add_knowledge_about_internal_angles();
	return $this;
}

=head2 add_knowledge_about_internal_angles

=cut
sub add_knowledge_about_internal_angles
{
	croak "should be redefined";
}

=head2 get_amount_of_edges

=cut
sub get_amount_of_edges
{
	return 4;
}

1;
