package HackaMol::Bond;
$HackaMol::Bond::VERSION = '0.050';
#ABSTRACT: HackaMol Bond class
use 5.008;
use Moose;
use namespace::autoclean;
use Carp;
use MooseX::StrictConstructor;
#use MooseX::Storage;
#with Storage( 'io' => 'StorableFile' ), 
with 'HackaMol::Roles::NameRole', 'HackaMol::Roles::AtomGroupRole';

has $_ => (
    is      => 'rw',
    isa     => 'Num',
    default => 1,
    lazy    => 1,
    clearer => 'clear_bond_order',
) foreach qw(bond_order);

has $_ => (
    is      => 'rw',
    isa     => 'Num',
    default => 0,
    lazy    => 1,
    clearer => "clear_$_",
) foreach qw(bond_fc bond_length_eq);

has 'bond_efunc' => (
    is      => 'rw',
    isa     => 'CodeRef',
    builder => "_build_bond_efunc",
    lazy    => 1,
);

sub _build_bond_efunc {

    #my $self = shift; #self is passed by moose, but we don't use it here
    my $subref = sub {
        my $bond = shift;
        my $val  = ( $bond->bond_length - $bond->bond_length_eq )**2;
        return ( $bond->bond_fc * $val );
    };
    return ($subref);
}

sub bond_vector {
    my $self  = shift;
    my @atoms = $self->all_atoms;
    return ( $atoms[0]->inter_dcoords( $atoms[1] ) );
}

sub bond_length {
    my $self  = shift;
    my @atoms = $self->all_atoms;
    return ( $atoms[0]->distance( $atoms[1] ) );
}

sub bond_energy {
    my $self = shift;
    my $energy = &{ $self->bond_efunc }( $self, @_ );
    return ($energy);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

HackaMol::Bond - HackaMol Bond class

=head1 VERSION

version 0.050

=head1 SYNOPSIS

   use HackaMol::Atom;
   use HackaMol::Bond;

   my $atom1 = HackaMol::Atom->new(
       name    => 'O1',
       coords  => [ V( 2.05274, 0.01959, -0.07701 ) ],
       Z       => 8,
   );

   my $atom2 = HackaMol::Atom->new(
       name    => 'H1',
       coords  => [ V( 1.08388, 0.02164, -0.12303 ) ],
       Z       => 1,
   );
   
   my $atom3 = HackaMol::Atom->new(
       name    => 'H2',
       coords  => [ V( 2.33092, 0.06098, -1.00332 ) ],
       Z       => 1,
   );
   
   my $bond1 = HackaMol::Bond->new(name=>'O1H1', atoms=>[$atom1,$atom2]);
   my $bond2 = HackaMol::Bond->new(name=>'O1H2', atoms=>[$atom1,$atom3]);
   my $bond3 = HackaMol::Bond->new(name=>'H1H2', atoms=>[$atom2,$atom3]);
   
   my @bonds = ($bond1, $bond2, $bond3);
   
   foreach my $bond ( @bonds ){
   
     my $pbond = sprintf(
                   "Bond: %s, Length: %.2f, Vector: %.5 %.5 %.5 \n",
                   $bond->name, 
                   $bond->bond_length, 
                   @{$bond->bond_vector},
     );

     print $pbond;
   
   }
   
   
   my @COM_ats = map {HackaMol::Atom->new(
                         name    => "X".$_->name."X",
                         coords  => [ $_->COM ],
                         Z       => 1,
                               )
                     } @bonds;
   
   my @HH_bonds = grep { $_->get_atoms(0)->Z == 1 and
                         $_->get_atoms(1)->Z == 1} @bonds;

=head1 DESCRIPTION

The HackaMol Bond class provides a set of methods and attributes for working 
with connections between two atoms.  The Bond class consumes the 
AtomGroupRole providing Bond objects with methods to determine the center of 
mass, total charge, etc (see L<HackaMol::AtomGroupRole>). 

The Bond class also provides attributes and methods to set force_constants and 
measure energy.  The bond_energy method calls on a CodeRef attribute that the 
user may define.  See descriptions below.  

=head1 METHODS

=head2 bond_vector

no arguments. returns Math::Vector::Real object from 
$atoms[0]->inter_dcoords($atoms[1]) for the two atoms in the bond.

=head2 bond_length

no arguments. returns $atoms[0]->distance($atoms[1]) for the two atoms in 
the bond.

=head2 bond_energy

arguments, as many as you want. Calculates energy using the bond_efunc 
described below, if the attribute, bond_fc > 0.  The bond_energy method calls 
the bond_efunc as follows: 

my $energy = &{$self->bond_efunc}($self,@_);

which will pass $self and that in @_ array to bond_efunc, which can be 
redefined.

=head1 ATTRIBUTES

=head2 atoms

isa ArrayRef[Atom] that is lazy with public ARRAY traits provided by the AtomGroupRole (see documentation for more details).

Pushing (atom1, atom2) on to the Bond object will produce bond_length and bond_vector from atom1 to atom2 (the atom12 interatomic vector).

=head2 name

isa Str that is lazy and rw. useful for labeling, bookkeeping...

=head2 bond_order

isa Num that is lazy and rw. default = 1, single bond. 

=head2 bond_fc

isa Num that is lazy and rw. default = 0.  force constant for harmonic bond 
potentials.

=head2 bond_length_eq

isa Num that is lazy and rw. default = 0.  Equilibrium bond length.

=head2 bond_efunc

isa CodeRef that is lazy and rw. default uses builder to generate harmonic 
potential from the bond_fc, bond_length_eq, and bond_length.  See the 
_build_bond_efunc, if interested in changing the function form.

=head1 SEE ALSO

=over 4

=item *

L<HackaMol::AtomGroupRole>

=item *

L<HackaMol::Angle>

=item *

L<HackaMol::Dihedral>

=item *

L<Chemistry::Bond>

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

This software is copyright (c) 2017 by Demian Riccardi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
