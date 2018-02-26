package Games::LatticeGenerator::Geometry::Polygon;
use strict;
use warnings;
use Carp;
use Games::LatticeGenerator::ObjectDescribedByFacts;
use base 'Games::LatticeGenerator::ObjectDescribedByFacts';




=head1 NAME

Games::LatticeGenerator::Geometry::Polygon

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';



=head1 SUBROUTINES/METHODS

=head2 new

A constructor. It adds knowledge about the edges.

=cut
sub new
{
	my $class = shift;
	my $this = $class->SUPER::new(@_);	
	croak "missing edges" unless $this->get_amount_of_edges() == grep { defined($_) } map { $$this{edges}[$_] } 0..$this->get_amount_of_edges()-1;

	$$this{description} .= join("", map { 
<<DESCRIPTION
$$this{edges}[$_]{description}
belongs_to($$this{edges}[$_]{name}, $this).
DESCRIPTION
} 0..$this->get_amount_of_edges()-1);

	$$this{description} .= <<DESCRIPTION;
is_a_Polygon($$this{name}).
DESCRIPTION

	return $this;
}

1;
