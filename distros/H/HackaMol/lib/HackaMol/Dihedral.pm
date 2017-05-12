package HackaMol::Dihedral;
$HackaMol::Dihedral::VERSION = '0.039';
#ABSTRACT: Dihedral Angle class for HackaMol
use 5.008;
use Moose;
use namespace::autoclean;
use Carp;
use Math::Trig;
use MooseX::StrictConstructor;
#use MooseX::Storage;
#with Storage( 'io' => 'StorableFile' ), 
with 'HackaMol::Roles::NameRole', 'HackaMol::Roles::AtomGroupRole';

has $_ => (
    is      => 'rw',
    isa     => 'Num',
    default => 0,
    lazy    => 1,
    clearer => "clear_$_",
) foreach qw(dihe_fc dihe_dphase dihe_eq dihe_mult);

sub dihe_deg {
    my $self  = shift;
    my @atoms = $self->all_atoms;
    return ( $atoms[0]->dihedral_deg( $atoms[1], $atoms[2], $atoms[3] ) );
}

sub dihe_rad {
    my $self  = shift;
    my @atoms = $self->all_atoms;
    return ( $atoms[0]->dihedral_rad( $atoms[1], $atoms[2], $atoms[3] ) );
}

has 'improper_dihe_efunc' => (
    is      => 'rw',
    isa     => 'CodeRef',
    builder => "_build_improper_dihe_efunc",
    lazy    => 1,
);

sub _build_improper_dihe_efunc {
    my $subref = sub {
        my $dihedral = shift;
        my $val      = ( $dihedral->dihe_deg - $dihedral->dihe_eq )**2;
        return ( $dihedral->dihe_fc * $val );
    };
    return ($subref);
}

has 'torsion_efunc' => (
    is      => 'rw',
    isa     => 'CodeRef',
    builder => "_build_torsion_efunc",
    lazy    => 1,
);

sub _build_torsion_efunc {
    my $subref = sub {
        my $dihedral = shift;
        my $val =
          1 +
          cos( $dihedral->dihe_mult * $dihedral->dihe_rad -
              $dihedral->dihe_dphase );
        return ( $dihedral->dihe_fc * $val );
    };
    return ($subref);
}

sub torsion_energy {
    my $self = shift;
    my $energy = &{ $self->torsion_efunc }( $self, @_ );
    return ($energy);
}

sub improper_dihe_energy {
    my $self = shift;
    my $energy = &{ $self->improper_dihe_efunc }( $self, @_ );
    return ($energy);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

HackaMol::Dihedral - Dihedral Angle class for HackaMol

=head1 VERSION

version 0.039

=head1 SYNOPSIS

   use HackaMol::Atom;
   use HackaMol::Dihedral;

   my ($atom1,$atom4) = map {
                          Atom->new(
                             name    => "C".($_+1),
                             charges => [0],
                             coords  => [ V( $_, $_, 0) ],
                             Z       => 6, 
                          )} (-1, 1);
   
   my ($atom2,$atom3) = map {
                          Atom->new(
                             name    => "S".($_+1),
                             charges => [0],
                             coords  => [ V( $_, 0, 0) ],
                             Z       => 16, 
                          )} (-1, 1);
   
   my $dihe = HackaMol::Dihedral->new(name=>'disulfide', 
                                     atoms=>[$atom1,$atom2,$atom3,$atom4]);
   
   my $pdihe = sprintf(
                   "Dihedral: %s, angle: %.2f\n"
                   $dihe->name, 
                   $dihe->dihe_deg, 
   );
   
   print $pdihe;
   
   my $COM_atom = HackaMol::Atom->new(
                                   name    => "X".$_->name."X",
                                   coords  => [ $dihe->COM ],
                                   Z       => 1,
   );

=head1 DESCRIPTION

The HackaMol Dihedral class provides a set of methods and attributes for working 
with three connections between four atoms.  Like the L<HackaMol::Bond> and 
L<HackaMol::Angle> classes, the Dihedral class consumes the 
L<HackaMol::AtomGroupRole> 
providing methods to determine the center of mass, total charge, etc. 
(see AtomGroupRole). A $dihedral containing (atom1,atom2,atom3,atom4) produces 
the angle ($dihedral->dihe_deg) between the planes containing (atom1, atom2, 
atom3) and (atom2, atom3, atom4).

The Dihedral class also provides attributes and methods to set parameters and  
functions to measure energy.  The energy methods call on CodeRef attributes that 
the user may define.  See descriptions below.  

=head1 METHODS

=head2 dihe_deg 

no arguments. returns the angle (degrees) between the planes containing 
(atom1,atom2,atom3) and (atom2, atom3, atom4). 

=head2 dihe_rad

no arguments. returns the angle (radians) between the planes containing 
(atom1,atom2,atom3) and (atom2, atom3, atom4). 

=head2 improper_dihe_energy 

arguments, as many as you want. Calculates energy using the 
improper_dihe_efunc described below, if the attribute, dihe_fc > 0.  
The improper_dihe_energy method calls the improper_dihe_efunc as follows: 

   my $energy = &{$self->improper_dihe_efunc}($self,@_);

which will pass $self and that in @_ array to improper_dihe_efunc, which, similar to the Bond and Angle classes, can be redefined. torsion_energy is analogous.

=head2 torsion_energy

analogous to improper_dihe_energy

=head1 ATTRIBUTES

=head2 atoms

isa ArrayRef[Atom] that is lazy with public ARRAY traits provided by the 
AtomGroupRole (see documentation for more details).

=head2 name

isa Str that is lazy and rw. useful for labeling, bookkeeping...

=head2 dihe_dphase

isa Num that is lazy and rw. default = 0.  phase shift for torsion potentials.

=head2 dihe_mult

isa Num that is lazy and rw. default = 0.  multiplicity for torsion potentials.

=head2 dihe_fc

isa Num that is lazy and rw. default = 0.  force constant for harmonic bond potentials.

=head2 dihe_eq

isa Num that is lazy and rw. default = 0.  Equilibrium dihedral angle.  

=head2 improper_dihe_efunc 

isa CodeRef that is lazy and rw. default uses builder to generate a 
harmonic potential for the improper_dihedral and a torsion potential. 

=head2 torsion_efunc

analogous to improper_dihe_efunc 

=head1 SEE ALSO

=over 4

=item *

L<HackaMol::AtomGroupRole>

=item *

L<Chemistry::Bond>

=item *

L<HackaMol::Angle>

=back

=head1 EXTENDS

=over 4

=item * L<Moose::Object>

=back

=head1 CONSUMES

=over 4

=item * L<HackaMol::Roles::AtomGroupRole>

=item * L<HackaMol::Roles::NameRole>

=item * L<HackaMol::Roles::NameRole|HackaMol::Roles::AtomGroupRole>

=back

=head1 AUTHOR

Demian Riccardi <demianriccardi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Demian Riccardi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
