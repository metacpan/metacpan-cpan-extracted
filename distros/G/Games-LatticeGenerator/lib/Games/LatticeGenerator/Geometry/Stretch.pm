package Games::LatticeGenerator::Geometry::Stretch;
use strict;
use warnings;
use Games::LatticeGenerator::Geometry::Point;
use Games::LatticeGenerator::ObjectDescribedByFacts;
use base 'Games::LatticeGenerator::ObjectDescribedByFacts';
use Carp;



=head1 NAME

Games::LatticeGenerator::Geometry::Stretch

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
	croak "missing points" unless 2 == grep { defined($_) } map { $$this{points}[$_] } 0..1;
	
	croak "missing length" unless defined($$this{length});
	
	croak "length cannot be negative ($$this{length}) " unless $$this{length}>=0.0;

	$$this{description} .= join("", map { 
<<DESCRIPTION
$$this{points}[$_]{description}
belongs_to($$this{points}[$_]{name}, $this).
DESCRIPTION
} 0..1);

	$$this{description} .= <<DESCRIPTION;
has_length($$this{name}, $$this{length}).
DESCRIPTION
	
	return $this;
}

1;
