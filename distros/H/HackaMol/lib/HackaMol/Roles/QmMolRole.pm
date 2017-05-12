package HackaMol::Roles::QmMolRole;
$HackaMol::Roles::QmMolRole::VERSION = '0.039';
#ABSTRACT: provides attributes needed for quantum chemistry calculations
# this will need updating as needs arise
use Moose::Role;

with 'HackaMol::Roles::QmAtomRole';

has 'multiplicity', is => 'rw', isa => 'Int', lazy => 1, default => 1;

my @tscl = qw(
  score
  energy
  Etot Eelec Enuc
  qm_dipole_moment ionization_energy gradient_norm
  Hform
  U H G S
  S_t
  S_r
  S_v
  Etot_mp2
  Etot_ccsdt
  Ecds
);

has "$_" => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[Num]',
    default => sub { [] },
    handles => {
        "push_$_"  => 'push',
        "get_$_"   => 'get',
        "all_$_"   => 'elements',
        "clear_$_" => 'clear',
        "count_$_" => 'count',
    },
    lazy => 1,
) foreach @tscl;

has "$_" => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[Math::Vector::Real]',
    default => sub { [] },
    handles => {
        "push_$_"  => 'push',
        "get_$_"   => 'get',
        "all_$_"   => 'elements',
        "clear_$_" => 'clear',
        "count_$_" => 'count',
    },
    lazy => 1,
) for qw(qm_dipole frequencies eigvec alpha beta);

no Moose::Role;

1;

__END__

=pod

=head1 NAME

HackaMol::Roles::QmMolRole - provides attributes needed for quantum chemistry calculations

=head1 VERSION

version 0.039

=head1 SYNOPSIS

   # instance of class that consumes the QmMolRole.

   $obj->multiplicity(1);
   my @energies = $mol->all_Etot;

=head1 DESCRIPTION

QmMolRole provides attributes that will be useful for setting up interfaces to 
quantum chemistry packages.  This role consumes the QmAtomRole so there is some 
overlap for basis_geom, basis, and ecp.  For interfaces, the Molecule should 
take precedence over the atom; i.e. if a Molecule has a basis of 6-31G*, that 
should be used for all atoms regardless of the basis set that they may have. 
All attributes are 'rw' and lazy, so they will not contaminate the namespace 
unless called upon. QmMolRole has 'basis_atoms' that should be generated from the 
binned unique atoms in a molecule.  basis_atoms are just instances of the 
HackaMol::Atom class with all the basis sets and effective core potentials loaded,
 either as simple strings supported by the package or the full descriptions 
pulled from the EMSL basis set  exchange as a single Str. 
https://bse.pnl.gov/bse/portal

A dream is to interface with EMSL library directly. Attributes below are
described without much detail; they will contain information mapped from
calculations and are not exhaustive.  This role will probably evolve as 
interfaces are added.

=head1 ATTRIBUTES

=head2 multiplicity

isa Int that is lazy and rw

=head2 Etot Eelec Enuc 

each isa ArrayRef[Num] that is lazy with public ARRAY traits: push_$_ get_$_
all_$_ clear_$_ count_$_

=head2 qm_dipole_moment ionization_energy gradient_norm Hform

each isa ArrayRef[Num] that is lazy with public ARRAY traits: push_$_ get_$_
all_$_ clear_$_ count_$_

=head2 U H G S S_t S_r S_v

each isa ArrayRef[Num] that is lazy with public ARRAY traits: push_$_ get_$_
all_$_ clear_$_ count_$_

=head2 Etot_mp2 Etot_ccsdt Ecds

each isa ArrayRef[Num] that is lazy with public ARRAY traits: push_$_ get_$_
all_$_ clear_$_ count_$_

=head2 qm_dipole frequencies eigvec alpha beta

each isa ArrayRef[Math::Vector::Real] that is lazy with public ARRAY traits: push_$_ get_$_
all_$_ clear_$_ count_$_

=head1 SEE ALSO

=over 4

=item *

L<HackaMol::Molecule>

=item *

L<EMSL | https://bse.pnl.gov/bse/portal>

=back

=head1 CONSUMES

=over 4

=item * L<HackaMol::Roles::QmAtomRole>

=back

=head1 AUTHOR

Demian Riccardi <demianriccardi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Demian Riccardi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
