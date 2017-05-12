package HPCD::SLURM::JobGroup;

=head1 NAME

	HPCD::SLURM::JobGroup

=head1 SYNOPSIS

	This is an internal module that would never cause a user to write "use HPCD::SLURM::JobGroup"
	themselves. Users get it provided for them when they write "use HPCI; HPCI->JobGroup( cluster
	=> 'SLURM', ... )

=cut

### INCLUDES ##################################################################

# safe Perl
use warnings;
use strict;
use Carp;
use Moose::Role;

with 'HPCI::JobGroup' => { theDriver => 'HPCD::SLURM' };

after 'BUILD' => sub {
	my $self = shift;
	$self->info(
		"SLURM job submission will use: srun\n"
	);
};

=head1 AUTHOR

John Macdonald         - Boutros Lab

Anqi (Joyce) Yang      - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros Lab

The Ontario Institute for Cancer Research

=cut

1;
