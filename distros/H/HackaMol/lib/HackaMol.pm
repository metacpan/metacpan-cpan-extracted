package HackaMol;
$HackaMol::VERSION = '0.040';
#ABSTRACT: HackaMol: Object-Oriented Library for Molecular Hacking
use 5.008;
use Moose;
use HackaMol::AtomGroup;
use HackaMol::Molecule;
use HackaMol::Atom;
use HackaMol::Bond;
use HackaMol::Angle;
use HackaMol::Dihedral;
use namespace::autoclean;
use MooseX::StrictConstructor;
use Scalar::Util qw(refaddr);
use Carp;

with 'HackaMol::Roles::NameRole', 
     'HackaMol::Roles::MolReadRole', 
     'HackaMol::Roles::PathRole',
     'HackaMol::Roles::ExeRole', 
     'HackaMol::Roles::FileFetchRole';

sub pdbid_mol {
  my $self  = shift;
  my $pdbid = shift || croak "Croak on passing pdbid, e.g. 2cba";
  my ($file,$rc) = $self->getstore_pdbid($pdbid);
  return($self->read_file_mol($file));
}

sub read_file_push_coords_mol{
    my $self = shift;
    my $file = shift;
    my $mol  = shift or croak "must pass molecule to add coords to";

    my @atoms = $self->read_file_atoms($file);
    my @matoms= $mol->all_atoms;

    if (scalar(@matoms) != scalar(@atoms) ){
      croak "file_push_coords_mol> number of atoms not same";
    }
    foreach my $i (0 .. $#atoms) {
      if ($matoms[$i]->Z != $atoms[$i]->Z){
        croak "file_push_coords_mol> atom mismatch";
      }
      $matoms[$i]->push_coords($_) foreach ($atoms[$i]->all_coords);
    }
}

sub read_file_mol{
    my $self = shift;
    my $file = shift;

    my @atoms = $self->read_file_atoms($file);
    my $name = $file . ".mol";
    return (HackaMol::Molecule->new(name=>$name, atoms=>[@atoms]));
}

sub read_string_mol{
    my $self = shift;
    my $string = shift;
    my $format = shift or croak "must pass format: xyz, pdb, pdbqt, zmat, yaml";

    my @atoms = $self->read_string_atoms($string,$format);
    my $name = $format. ".mol";
    return (HackaMol::Molecule->new(name=>$name, atoms=>[@atoms]));
}

sub build_bonds {

    #take a list of n, atoms; walk down list and generate bonds
    my $self  = shift;
    my @atoms = @_;
    croak "<2 atoms passed to build_bonds" unless ( @atoms > 1 );
    my @bonds;
    # build the bonds
    my $k = 0;
    while ( $k + 1 <= $#atoms ) {
        my $name =
              join( "_", map { _name_resid($_,'B')} @atoms[ $k .. $k + 1 ] );
        push @bonds,
          HackaMol::Bond->new(
            name  => $name,
            atoms => [ @atoms[ $k, $k + 1 ] ]
          );
        $k++;
    }
    return (@bonds);
}

sub build_angles {

    #take a list of n, atoms; walk down list and generate angles
    my $self  = shift;
    my @atoms = @_;
    croak "<3 atoms passed to build_angles" unless ( @atoms > 2 );
    my @angles;

    # build the angles
    my $k = 0;

    while ( $k + 2 <= $#atoms ) {
        my $name =
              join( "_", map { _name_resid($_,'A')} @atoms[ $k .. $k + 2 ] );
        push @angles,
          HackaMol::Angle->new(
            name  => $name,
            atoms => [ @atoms[ $k .. $k + 2 ] ]
          );
        $k++;
    }
    return (@angles);
}

sub _name_resid {
  my $atom    = shift;
  my $default = shift;
  return ($default    . $atom->resid) unless $atom->has_name; # this comes up when undefined atoms are passed 
  return ($atom->name . $atom->resid);
}

sub build_dihedrals {

    #take a list of n, atoms; walk down list and generate dihedrals
    my $self  = shift;
    my @atoms = @_;
    croak "<4 atoms passed to build_dihedrals" unless ( @atoms > 3 );
    my @dihedrals;

    # build the dihedrals
    my $k = 0;
    while ( $k + 3 <= $#atoms ) {
        my $name =
              join( "_", map { _name_resid($_,'D')} @atoms[ $k .. $k + 3 ] );
        push @dihedrals,
          HackaMol::Dihedral->new(
            name  => $name,
            atoms => [ @atoms[ $k .. $k + 3 ] ]
          );
        $k++;
    }
    return (@dihedrals);
}

sub group_by_atom_attr {

    # group atoms by attribute
    # Z, name, bond_count, etc.
    my $self  = shift;
    my $attr  = shift;
    my @atoms = @_;

    my %group;
    foreach my $atom (@atoms) {
        push @{ $group{ $atom->$attr } }, $atom;
    }

    my @atomgroups =
      map { HackaMol::AtomGroup->new( atoms => $group{$_} ) } sort
      keys(%group);

    return (@atomgroups);

}

sub group_by_atom_attrs {

    # group atoms by attributes
    # Z, name, bond_count, etc.
    # keep splitting the groups until there are no more attributes
    my $self  = shift ;
    my @attrs = @{+ shift } ;
    my @atoms = @_;

    return () unless @attrs;

    my @groups = ( HackaMol::AtomGroup->new( atoms => [ @atoms ] ) );

    foreach my $attr (@attrs){
      my @local_groups;
      foreach my $group (@groups){
          push @local_groups, $self->group_by_atom_attr( $attr, $group->all_atoms );
      }
      @groups = @local_groups;
    }

    return (@groups);

}

sub find_disulfide_bonds {
    my $self  = shift;
    my @sulf  = grep {$_->Z == 16} @_;
    my @ss = $self->find_bonds_brute(
                                     bond_atoms => [@sulf],
                                     candidates => [@sulf],
                                     fudge      => 0.45,
                                     max_bonds  => 1,
                                    );
    return @ss;
}

sub find_bonds_brute {
    my $self       = shift;
    my %args       = @_;
    my @bond_atoms = @{ $args{bond_atoms} };
    my @atoms      = @{ $args{candidates} };

    my $fudge = 0.45;
    my $max_bonds = 99;

    $fudge     = $args{fudge}     if ( exists( $args{fudge} ) );
    $max_bonds = $args{max_bonds} if ( exists( $args{max_bonds} ) );

    my @init_bond_counts = map {$_->bond_count} (@bond_atoms,@atoms);

    my @bonds;
    my %name;

    foreach my $at_i (@bond_atoms) {
        next if ($at_i->bond_count >= $max_bonds);
        my $cov_i = $at_i->covalent_radius;
        my $xyz_i = $at_i->xyz;

        foreach my $at_j (@atoms) {
            next if ( refaddr($at_i) == refaddr($at_j) );
            next if ($at_j->bond_count >= $max_bonds);
            my $cov_j = $at_j->covalent_radius;
            my $dist  = $at_j->distance($at_i);

            if ( $dist <= $cov_i + $cov_j + $fudge ) {
                my $nm = $at_i->symbol . "-" . $at_j->symbol;
                $name{$nm}++;
                push @bonds,
                  HackaMol::Bond->new(
                    name  => "$nm\_" . $name{$nm},
                    atoms => [ $at_i, $at_j ],
                  );
                $at_i->inc_bond_count;
                $at_j->inc_bond_count;
            }

        }
    }
  
    my $i = 0;
    foreach my $at (@bond_atoms,@atoms){
      $at->reset_bond_count;
      $at->inc_bond_count($init_bond_counts[$i]);
      $i++;
    }
    return (@bonds);

}

sub group_rot {
  # no pod yet
  # this method walks out from the two atoms in a bond and returns a group
  my $self  = shift;
  my $mol   = shift;
  my $bond  = shift;
  my $iba = $bond->get_atoms(0)->iatom;
  my $ibb = $bond->get_atoms(1)->iatom;

  my $init = { 
              $iba => 1, 
              $ibb => 1, 
  };
  my $root  = $ibb; 
  my $rotation_indices =  _qrotatable($mol->atoms,$ibb, $init);
  delete( $rotation_indices->{ $iba } );
  delete( $rotation_indices->{ $ibb } );

  return  (
            HackaMol::AtomGroup->new( 
                      atoms => [
                                map {$mol->get_atoms($_)} 
                                    keys %{$rotation_indices} 
                      ] 
            )
  );

}

sub _qrotatable {
    my $atoms   = shift;
    my $iroot   = shift;
    my $visited = shift;

    $visited->{$iroot}++;
    
    if (scalar (keys %$visited) > 80){
      carp "search too deep. exiting recursion";
      return;
    }

    my @cands;
    foreach my $at (@$atoms) {
        push @cands, $at unless ( grep { $at->iatom == $_ } keys %{$visited} );
    }

    #not calling in object context, hence the dummy 'self' 
    my @bonds = find_bonds_brute('self',
        bond_atoms => [ $atoms->[$iroot] ],
        candidates => [@cands],
        fudge      => 0.45,
    );

    foreach my $cand ( map { $_->get_atoms(1) } @bonds ) {
        next if $visited->{ $cand->iatom };
        my $visited = _qrotatable( $atoms, $cand->iatom, $visited );
    }
    return ($visited);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

HackaMol - HackaMol: Object-Oriented Library for Molecular Hacking

=head1 VERSION

version 0.040

=head1 DESCRIPTION

The L<HackaMol publication|http://pubs.acs.org/doi/abs/10.1021/ci500359e> has
a more complete description of the library (L<pdf available from researchgate|http://www.researchgate.net/profile/Demian_Riccardi/publication/273778191_HackaMol_an_object-oriented_Modern_Perl_library_for_molecular_hacking_on_multiple_scales/links/550ebec60cf27526109e6ade.pdf>). 

Citation: J. Chem. Inf. Model., 2015, 55, 721 

Loading the HackaMol library in a script with 

       use HackaMol;

provides attributes and methods of a builder class. It also loads all the 
classes provided by the core so including them is not necessary, e.g.:

       use HackaMol::Atom;
       use HackaMol::Bond;
       use HackaMol::Angle;
       use HackaMol::Dihedral;
       use HackaMol::AtomGroup;
       use HackaMol::Molecule;

The methods, described below, facilitate the creation of objects from files and
other objects.

=head1 METHODS

=head2 pdbid_mol

one argument: pdbid

This method will download the pdb, unless it exists, and load it into a 
HackaMol::Molecule object. For example,

      my $mol = HackaMol->new->pdbid_mol('2cba');

=head2 read_file_atoms

one argument: filename.

This method parses the file (e.g. file.xyz, file.pdb) and returns an 
array of HackaMol::Atom objects.

=head2 read_file_mol

one argument: filename.

This method parses the file (e.g. file.xyz, file.pdb) and returns a 
HackaMol::Molecule object.

=head2 read_file_push_coords_mol

two arguments: filename and a HackaMol::Molecule object. 

This method reads the coordinates from a file and pushes them into the atoms 
contained in the molecule. Thus, the atoms in the molecule and the atoms in 
the file must be the same.

=head2 build_bonds

takes a list of atoms and returns a list of bonds.  The bonds are generated for
"list neighbors" by simply stepping through the atom list one at a time. e.g.

  my @bonds = $hack->build_bonds(@atoms[1,3,5]);

will return two bonds: B13 and B35 

=head2 build_angles

takes a list of atoms and returns a list of angles. The angles are generated 
analagously to build_bonds, e.g.

  my @angles = $hack->build_angles(@atoms[1,3,5]);

will return one angle: A135

=head2 build_dihedrals

takes a list of atoms and returns a list of dihedrals. The dihedrals are generated 
analagously to build_bonds, e.g.

  my @dihedral = $hack->build_dihedrals(@atoms[1,3,5]);

will croak!  you need atleast four atoms.

  my @dihedral = $hack->build_dihedrals(@atoms[1,3,5,6,9]);

will return two dihedrals: D1356 and D3569

=head2 group_by_atom_attr

arguments are an atom attribute and then a list of atoms. 

This method builds AtomGroup objects that are grouped by attribute.

=head2 find_bonds_brute 

The arguments are key_value pairs of bonding criteria (see example below). 

This method returns bonds between bond_atoms and the candidates using the 
criteria (many of wich have defaults).

  my @oxy_bonds = $hack->find_bonds_brute(
                                    bond_atoms => [$hg],
                                    candidates => [$mol->all_atoms],
                                    fudge      => 0.45,
                                    max_bonds  => 6,
  );

fudge is optional with Default is 0.45 (open babel uses same default); 
max_bonds is optional with default of 99. max_bonds is compared against
the atom bond count, which are incremented during the search. Before returning
the bonds, the bond_count are returned the values before the search.  For now,
molecules are responsible for setting the number of bonds in atoms. 
find_bonds_brute uses a bruteforce algorithm that tests the interatomic 
separation against the sum of the covalent radii + fudge. It will not test
for bond between atoms if either atom has >= max_bonds. It does not return 
a self bond for an atom (C< next if refaddr($ati) == refaddr($atj) >).

=head2 find_disulfide_bonds

the argument is a list of atoms, e.g. '($mol->all_atoms)'. 

this method returns disulfide bonds as bond objects.

=head1 ATTRIBUTES

=head2 name 

name is a rw str provided by HackaMol::NameRole.

=head1 SYNOPSIS 

       # simple example: load pdb file and extract the disulfide bonds

       use HackaMol;

       my $bldr = HackaMol->new( name => 'builder');
       my $mol  = $bldr->pdbid_mol('1kni');

       my @disulfide_bonds = $bldr->find_disulfide_bonds( $mol->all_atoms );

       print $_->dump foreach @disulfide_bonds;

See the above executed in this L<linked notebook|https://github.com/demianriccardi/p5-IPerl-Notebooks/blob/master/HackaMol/HackaMol-Synopsis.ipynb>

=head1 SEE ALSO

=over 4

=item *

L<HackaMol::Atom>

=item *

L<HackaMol::Bond>

=item *

L<HackaMol::Angle>

=item *

L<HackaMol::Dihedral>

=item *

L<HackaMol::AtomGroup>

=item *

L<HackaMol::Molecule>

=item *

L<HackaMol::X::Calculator>

=item *

L<HackaMol::X::Vina>

=item *

L<Protein Data Bank|http://pdb.org>

=item *

L<VMD|http://www.ks.uiuc.edu/Research/vmd/>

=back

=head1 EXTENDS

=over 4

=item * L<Moose::Object>

=back

=head1 CONSUMES

=over 4

=item * L<HackaMol::Roles::ExeRole>

=item * L<HackaMol::Roles::FileFetchRole>

=item * L<HackaMol::Roles::MolReadRole>

=item * L<HackaMol::Roles::NERFRole>

=item * L<HackaMol::Roles::NameRole>

=item * L<HackaMol::Roles::NameRole|HackaMol::Roles::MolReadRole|HackaMol::Roles::PathRole|HackaMol::Roles::ExeRole|HackaMol::Roles::FileFetchRole>

=item * L<HackaMol::Roles::PathRole>

=item * L<HackaMol::Roles::ReadPdbRole>

=item * L<HackaMol::Roles::ReadPdbqtRole>

=item * L<HackaMol::Roles::ReadXyzRole>

=item * L<HackaMol::Roles::ReadYAMLRole>

=item * L<HackaMol::Roles::ReadYAMLRole|HackaMol::Roles::ReadZmatRole|HackaMol::Roles::ReadPdbRole|HackaMol::Roles::ReadPdbqtRole|HackaMol::Roles::ReadXyzRole>

=item * L<HackaMol::Roles::ReadZmatRole>

=back

=head1 AUTHOR

Demian Riccardi <demianriccardi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Demian Riccardi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
