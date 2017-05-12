package HPCD::SLURM::Group;

=head1 NAME

	HPCD::SLURM::Group

=head1 SYNOPSIS

	This is an internal module that would never cause a user to write "use HPCD::SLURM::Group"
	themselves. Users get it provided for them when they write "use HPCI; HPCI->Group( cluster
	=> 'SLURM', ... )

=cut

### INCLUDES ##############################################################################

# safe Perl
use warnings;
use strict;
use Carp;

use Moose;
use namespace::autoclean;
use HPCD::SLURM::Stage;

with
	'HPCI::Group'    => { theDriver => 'HPCD::SLURM' },
	'HPCD::SLURM::JobGroup',
	HPCI::get_extra_roles('SLURM', 'group');



=head1 AUTHOR

John Macdonald         - Boutros Lab

Anqi (Joyce) Yang      - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros Lab

The Ontario Institute for Cancer Research

=cut

1;

