package Games::LatticeGenerator::ObjectWithName;

use strict;
use warnings;
use Carp;
use overload '""' => \&get_name;


=head1 NAME

Games::LatticeGenerator::ObjectWithName 

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SUBROUTINES/METHODS

=head2 new

A constructor. It croaks if the name is not defined.

=cut
sub new
{
	my $class = shift;
	my $this = { @_ };
	bless $this, $class;
	croak "missing name" unless $$this{name};
	return $this;
}

=head2 get_name

A getter for the name.

=cut
sub get_name 
{	
	return $_[0]->{name}; 
}


1;
