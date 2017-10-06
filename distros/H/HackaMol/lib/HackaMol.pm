package HackaMol;
$HackaMol::VERSION = '0.045';
#ABSTRACT: HackaMol: Object-Oriented Library for Molecular Hacking
use 5.008;
use Moose;
use HackaMol::AtomGroup;
use HackaMol::Molecule;
use HackaMol::Atom;
use HackaMol::Bond;
use HackaMol::Angle;
use HackaMol::Dihedral;
use Math::Vector::Real;
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
    my $self   = shift;
    my $pdbid  = shift || croak "Croak on passing pdbid, e.g. 2cba";
    my ($file) = $self->getstore_pdbid($pdbid);
    return ( $self->read_file_mol($file) ) if $file;
}

sub read_file_push_coords_mol {
    my $self = shift;
    my $file = shift;
    my $mol  = shift or croak "must pass molecule to add coords to";

    my @atoms  = $self->read_file_atoms($file);
    my @matoms = $mol->all_atoms;

    if ( scalar(@matoms) != scalar(@atoms) ) {
        croak "file_push_coords_mol> number of atoms not same";
    }
    foreach my $i ( 0 .. $#atoms ) {
        if ( $matoms[$i]->Z != $atoms[$i]->Z ) {
            croak "file_push_coords_mol> atom mismatch";
        }
        $matoms[$i]->push_coords($_) foreach ( $atoms[$i]->all_coords );
    }
}

sub read_file_mol {
    my $self = shift;
    my $file = shift;

    my @atoms = $self->read_file_atoms($file);
    my $name  = $file . ".mol";
    return ( HackaMol::Molecule->new( name => $name, atoms => [@atoms] ) );
}

sub read_string_mol {
    my $self   = shift;
    my $string = shift;
    my $format = shift or croak "must pass format: xyz, pdb, pdbqt, zmat, yaml";

    my @atoms = $self->read_string_atoms( $string, $format );
    my $name = $format . ".mol";
    return ( HackaMol::Molecule->new( name => $name, atoms => [@atoms] ) );
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
          join( "_", map { _name_resid( $_, 'B' ) } @atoms[ $k .. $k + 1 ] );
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
          join( "_", map { _name_resid( $_, 'A' ) } @atoms[ $k .. $k + 2 ] );
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
    return ( $default . $atom->resid )
      unless $atom->has_name;    # this comes up when undefined atoms are passed
    return ( $atom->name . $atom->resid );
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
          join( "_", map { _name_resid( $_, 'D' ) } @atoms[ $k .. $k + 3 ] );
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
    my $self  = shift;
    my @attrs = @{ +shift };
    my @atoms = @_;

    return () unless @attrs;

    my @groups = ( HackaMol::AtomGroup->new( atoms => [@atoms] ) );

    foreach my $attr (@attrs) {
        my @local_groups;
        foreach my $group (@groups) {
            push @local_groups,
              $self->group_by_atom_attr( $attr, $group->all_atoms );
        }
        @groups = @local_groups;
    }

    return (@groups);

}

sub find_disulfide_bonds {
    my $self = shift;
    my @sulf = grep { $_->Z == 16 } @_;
    my @ss   = $self->find_bonds_brute(
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

    my $fudge     = 0.45;
    my $max_bonds = 99;

    $fudge     = $args{fudge}     if ( exists( $args{fudge} ) );
    $max_bonds = $args{max_bonds} if ( exists( $args{max_bonds} ) );

    my @init_bond_counts = map { $_->bond_count } ( @bond_atoms, @atoms );

    my @bonds;
    my %name;

    foreach my $at_i (@bond_atoms) {
        next if ( $at_i->bond_count >= $max_bonds );
        my $cov_i = $at_i->covalent_radius;
        my $xyz_i = $at_i->xyz;

        foreach my $at_j (@atoms) {
            next if ( refaddr($at_i) == refaddr($at_j) );
            next if ( $at_j->bond_count >= $max_bonds );
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
    foreach my $at ( @bond_atoms, @atoms ) {
        $at->reset_bond_count;
        $at->inc_bond_count( $init_bond_counts[$i] );
        $i++;
    }
    return (@bonds);

}

sub group_rot {

    # no pod yet
    # this method walks out from the two atoms in a bond and returns a group
    my $self = shift;
    my $mol  = shift;
    my $bond = shift;
    my $iba  = $bond->get_atoms(0)->iatom;
    my $ibb  = $bond->get_atoms(1)->iatom;

    my $init = {
        $iba => 1,
        $ibb => 1,
    };
    my $root = $ibb;
    my $rotation_indices = _qrotatable( $mol->atoms, $ibb, $init );
    delete( $rotation_indices->{$iba} );
    delete( $rotation_indices->{$ibb} );

    return (
        HackaMol::AtomGroup->new(
            atoms => [
                map { $mol->get_atoms($_) }
                  keys %{$rotation_indices}
            ]
        )
    );

}

sub superpose_rt {

# args: two HackaMol::AtomGroup or HackaMol::Molecule with the same number of atoms
# the atoms are assumed to be in the same order, that's it!
#
# uses all vectors (mvr) in group to calculate the rotation matrix, and translation vector
# needed to superpose the second group on to the first group.
#
# a typical workflow will run this to get the rotation and translation and then the AtomGroupRole
# rotate_translate method to actually do the coordinate transformation.
#
# the algorithm is lifted from Bio::PDB::Structure, which in turn implements
# method from S. Kearsley, Acta Cryst. A45, 208-210 1989
# may not be very fast.  better suited to PDL
#
# returns:
#        1. rotation matrix [3 rows, each is a MVR , e.g. x' = row_1 * xyz]
#        2. translation vector (MVR)
#        3. rmsd
#
    my $self = shift;
    my $g2   = shift;    # switch order, function here vs method in Bio::PDB
    my $g1   = shift;

    my $nrd1 = $g1->count_atoms;
    my $nrd2 = $g2->count_atoms;
    die "superpose error: groups must have same number of atoms\n"
      unless ( $nrd1 == $nrd2 && $nrd1 > 0 );

    my ( $x1,    $y1,    $z1 );
    my ( $x2,    $y2,    $z2 );
    my ( $xm,    $ym,    $zm );
    my ( $xp,    $yp,    $zp );
    my ( $Sxmxm, $Sxpxp, $Symym, $Sypyp, $Szmzm, $Szpzp );
    my ( $Sxmym, $Sxmyp, $Sxpym, $Sxpyp );
    my ( $Sxmzm, $Sxmzp, $Sxpzm, $Sxpzp );
    my ( $Symzm, $Symzp, $Sypzm, $Sypzp );

    my $gc1 = $g1->center;
    my $gc2 = $g2->center;    # these are MVRs

    my @mvr1 = map { $_->xyz - $gc1 } $g1->all_atoms;
    my @mvr2 = map { $_->xyz - $gc2 } $g2->all_atoms;

    foreach my $i ( 0 .. $nrd1 - 1 ) {
        ( $x1, $y1, $z1 ) = @{ $mvr1[$i] };
        ( $x2, $y2, $z2 ) = @{ $mvr2[$i] };
        $xm = ( $x1 - $x2 );
        $xp = ( $x1 + $x2 );
        $ym = ( $y1 - $y2 );
        $yp = ( $y1 + $y2 );
        $zm = ( $z1 - $z2 );
        $zp = ( $z1 + $z2 );

        $Sxmxm += $xm * $xm;
        $Sxpxp += $xp * $xp;
        $Symym += $ym * $ym;
        $Sypyp += $yp * $yp;
        $Szmzm += $zm * $zm;
        $Szpzp += $zp * $zp;

        $Sxmym += $xm * $ym;
        $Sxmyp += $xm * $yp;
        $Sxpym += $xp * $ym;
        $Sxpyp += $xp * $yp;

        $Sxmzm += $xm * $zm;
        $Sxmzp += $xm * $zp;
        $Sxpzm += $xp * $zm;
        $Sxpzp += $xp * $zp;

        $Symzm += $ym * $zm;
        $Symzp += $ym * $zp;
        $Sypzm += $yp * $zm;
        $Sypzp += $yp * $zp;
    }

    my @m;
    $m[0]  = $Sxmxm + $Symym + $Szmzm;
    $m[1]  = $Sypzm - $Symzp;
    $m[2]  = $Sxmzp - $Sxpzm;
    $m[3]  = $Sxpym - $Sxmyp;
    $m[4]  = $m[1];
    $m[5]  = $Sypyp + $Szpzp + $Sxmxm;
    $m[6]  = $Sxmym - $Sxpyp;
    $m[7]  = $Sxmzm - $Sxpzp;
    $m[8]  = $m[2];
    $m[9]  = $m[6];
    $m[10] = $Sxpxp + $Szpzp + $Symym;
    $m[11] = $Symzm - $Sypzp;
    $m[12] = $m[3];
    $m[13] = $m[7];
    $m[14] = $m[11];
    $m[15] = $Sxpxp + $Sypyp + $Szmzm;

    #compute the egienvectors and eigenvalues of the matrix
    my ( $revec, $reval ) = &__diagonalize(@m);

    #the smallest eigenvalue is the rmsd for the optimal alignment
    my $rmsd = sqrt( abs( $reval->[0] ) / $nrd1 );

    #fetch the optimal quaternion
    my @q;
    $q[0] = $revec->[0][0];
    $q[1] = $revec->[1][0];
    $q[2] = $revec->[2][0];
    $q[3] = $revec->[3][0];

    #construct the rotation matrix given by the quaternion
    my @mt;
    $mt[0] = $q[0] * $q[0] + $q[1] * $q[1] - $q[2] * $q[2] - $q[3] * $q[3];
    $mt[1] = 2.0 * ( $q[1] * $q[2] - $q[0] * $q[3] );
    $mt[2] = 2.0 * ( $q[1] * $q[3] + $q[0] * $q[2] );

    $mt[3] = 2.0 * ( $q[2] * $q[1] + $q[0] * $q[3] );
    $mt[4] = $q[0] * $q[0] - $q[1] * $q[1] + $q[2] * $q[2] - $q[3] * $q[3];
    $mt[5] = 2.0 * ( $q[2] * $q[3] - $q[0] * $q[1] );

    $mt[6] = 2.0 * ( $q[3] * $q[1] - $q[0] * $q[2] );
    $mt[7] = 2.0 * ( $q[3] * $q[2] + $q[0] * $q[1] );
    $mt[8] = $q[0] * $q[0] - $q[1] * $q[1] - $q[2] * $q[2] + $q[3] * $q[3];

    #compute the displacement vector
    my @vt;
    $vt[0] =
      $gc2->[0] - $mt[0] * $gc1->[0] - $mt[1] * $gc1->[1] - $mt[2] * $gc1->[2];
    $vt[1] =
      $gc2->[1] - $mt[3] * $gc1->[0] - $mt[4] * $gc1->[1] - $mt[5] * $gc1->[2];
    $vt[2] =
      $gc2->[2] - $mt[6] * $gc1->[0] - $mt[7] * $gc1->[1] - $mt[8] * $gc1->[2];

    return ( [ V( @mt[ 0, 1, 2 ] ), V( @mt[ 3, 4, 5 ] ), V( @mt[ 6, 7, 8 ] ) ],
        V(@vt), $rmsd );
}

sub rmsd {
    my $self = shift;
    my $g1   = shift;    # switch order, function here vs method in Bio::PDB
    my $g2   = shift;
    my $w    = shift;

    my $nrd1 = $g1->count_atoms;
    my $nrd2 = $g2->count_atoms;
    die "rmsd error: groups must have same number of atoms\n"
      unless ( $nrd1 == $nrd2 && $nrd1 > 0 );

    my @w;
    if( defined($w) ){
      @w = @{$w};
    }
    else{
      @w = map{1} 0 .. $nrd1-1;
    }

    die "rmsd error: atom array weight must have same dimension as groups\n" unless ($nrd1 == scalar(@w));
    my $sum_weights = 0; # will be same as number of atoms if no weights are defined

    $sum_weights += $_ foreach @w;

    my @xyz_1 = map{$_->xyz} $g1->all_atoms; 
    my @xyz_2 = map{$_->xyz} $g2->all_atoms; 
    
    my $sqr_dev = 0;
    $sqr_dev += $w[$_]*$xyz_1[$_]->dist2($xyz_2[$_]) foreach 0 .. $#xyz_1;
    return sqrt($sqr_dev/$sum_weights);
}

sub _qrotatable {
    my $atoms   = shift;
    my $iroot   = shift;
    my $visited = shift;

    $visited->{$iroot}++;

    if ( scalar( keys %$visited ) > 80 ) {
        carp "search too deep. exiting recursion";
        return;
    }

    my @cands;
    foreach my $at (@$atoms) {
        push @cands, $at unless ( grep { $at->iatom == $_ } keys %{$visited} );
    }

    #not calling in object context, hence the dummy 'self'
    my @bonds = find_bonds_brute(
        'self',
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

#Jacobi diagonalizer
sub __diagonalize {
    my ( $onorm, $dnorm );
    my ( $b, $dma, $q, $t, $c, $s );
    my ( $atemp, $vtemp, $dtemp );
    my ( $i, $j, $k, $l );
    my @a;
    my @v;
    my @d;
    my $nrot = 30;    #number of sweeps

    for ( $i = 0 ; $i < 4 ; $i++ ) {
        for ( $j = 0 ; $j < 4 ; $j++ ) {
            $a[$i][$j] = $_[ 4 * $i + $j ];
            $v[$i][$j] = 0.0;
        }
    }

    for ( $j = 0 ; $j <= 3 ; $j++ ) {
        $v[$j][$j] = 1.0;
        $d[$j] = $a[$j][$j];
    }

    for ( $l = 1 ; $l <= $nrot ; $l++ ) {
        $dnorm = 0.0;
        $onorm = 0.0;
        for ( $j = 0 ; $j <= 3 ; $j++ ) {
            $dnorm += abs( $d[$j] );
            for ( $i = 0 ; $i <= $j - 1 ; $i++ ) {
                $onorm += abs( $a[$i][$j] );
            }
        }
        last if ( ( $onorm / $dnorm ) <= 1.0e-12 );
        for ( $j = 1 ; $j <= 3 ; $j++ ) {
            for ( $i = 0 ; $i <= $j - 1 ; $i++ ) {
                $b = $a[$i][$j];
                if ( abs($b) > 0.0 ) {
                    $dma = $d[$j] - $d[$i];
                    if ( ( abs($dma) + abs($b) ) <= abs($dma) ) {
                        $t = $b / $dma;
                    }
                    else {
                        $q = 0.5 * $dma / $b;
                        $t = 1.0 / ( abs($q) + sqrt( 1.0 + $q * $q ) );
                        $t *= -1.0 if ( $q < 0.0 );
                    }
                    $c         = 1.0 / sqrt( $t * $t + 1.0 );
                    $s         = $t * $c;
                    $a[$i][$j] = 0.0;
                    for ( $k = 0 ; $k <= $i - 1 ; $k++ ) {
                        $atemp     = $c * $a[$k][$i] - $s * $a[$k][$j];
                        $a[$k][$j] = $s * $a[$k][$i] + $c * $a[$k][$j];
                        $a[$k][$i] = $atemp;
                    }
                    for ( $k = $i + 1 ; $k <= $j - 1 ; $k++ ) {
                        $atemp     = $c * $a[$i][$k] - $s * $a[$k][$j];
                        $a[$k][$j] = $s * $a[$i][$k] + $c * $a[$k][$j];
                        $a[$i][$k] = $atemp;
                    }
                    for ( $k = $j + 1 ; $k <= 3 ; $k++ ) {
                        $atemp     = $c * $a[$i][$k] - $s * $a[$j][$k];
                        $a[$j][$k] = $s * $a[$i][$k] + $c * $a[$j][$k];
                        $a[$i][$k] = $atemp;
                    }
                    for ( $k = 0 ; $k <= 3 ; $k++ ) {
                        $vtemp     = $c * $v[$k][$i] - $s * $v[$k][$j];
                        $v[$k][$j] = $s * $v[$k][$i] + $c * $v[$k][$j];
                        $v[$k][$i] = $vtemp;
                    }
                    $dtemp =
                      $c * $c * $d[$i] + $s * $s * $d[$j] - 2.0 * $c * $s * $b;
                    $d[$j] =
                      $s * $s * $d[$i] + $c * $c * $d[$j] + 2.0 * $c * $s * $b;
                    $d[$i] = $dtemp;
                }
            }
        }
    }
    $nrot = $l;
    for ( $j = 0 ; $j <= 2 ; $j++ ) {
        $k     = $j;
        $dtemp = $d[$k];
        for ( $i = $j + 1 ; $i <= 3 ; $i++ ) {
            if ( $d[$i] < $dtemp ) {
                $k     = $i;
                $dtemp = $d[$k];
            }
        }

        if ( $k > $j ) {
            $d[$k] = $d[$j];
            $d[$j] = $dtemp;
            for ( $i = 0 ; $i <= 3 ; $i++ ) {
                $dtemp     = $v[$i][$k];
                $v[$i][$k] = $v[$i][$j];
                $v[$i][$j] = $dtemp;
            }
        }
    }

    return ( \@v, \@d );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

HackaMol - HackaMol: Object-Oriented Library for Molecular Hacking

=head1 VERSION

version 0.045

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
other objects.  It is a builder class that evolves more rapidly than the classes for the molecular objects. 
For example, the superpose_rt and rmsd methods will likely be moved to a more suitable class or
functional module.

=head1 METHODS

=head2 pdbid_mol

one argument: pdbid

This method will download the pdb, unless it exists, and load it into a 
HackaMol::Molecule object. For example,

      my $mol = HackaMol->new->pdbid_mol('2cba');

=head2 read_file_atoms

one argument: filename.

This method parses the file (e.g. file.xyz, file.pdb) and returns an 
array of HackaMol::Atom objects. It uses the filename postfix to decide which parser to use. e.g. file.pdb will
trigger the pdb parser.

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

args: atom attribute (e.g. 'name') ; list of atoms (e.g. $mol->all_atoms)

returns array of AtomGroup objects

=head2 group_by_atom_attrs

args: array reference of multiple atom attributes (e.g. ['resname', 'chain' ]); list of atoms. 

returns array of AtomGroup objects

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

=head2 rmsd ($group1,$group2,$weights)

args: two hackmol objects (HackaMol::AtomGroup or HackaMol::Molecule) with same number of atoms;
      optional array_reference of weights that can be used to adjust the contribution from each atom.

Returns the root mean square deviation of the two sets of coordinates

=head2 superpose_rt ($group1, $group2)

WARNING: 1. needs more testing (feel free to contribute tests!).  2. may shift to another class.

args: two hackmol objects (HackaMol::AtomGroup or HackaMol::Molecule) with same number of atoms.
This method is intended to be very flexible.  It does not check meta data of the atoms, it just pulls
the vectors in each group to calculate the rotation matrix and translation vector needed to superpose 
the second set on to the first set.

The vectors assumed to be in the same order, that's it!  

A typical workflow:

  my $bb1 = $mol1->select_group('backbone');
  my $bb2 = $mol2->select_group('backbone');
  my ($rmat,$trans,$rmsd) = HackaMol->new()->superpose_rt($bb1,$bb2);
  # $rmsd is the RMSD between backbones

  # to calculate rmsd between other atoms after the backbone alignment
  $mol2->rotate_translate($rmat,$trans);
  my $total_rmsd = HackaMol->new()->rmsd($mol1,$mol2);
  # $total_rmsd is from all atoms in each mol

the algorithm is lifted from Bio::PDB::Structure, which in turn implements
method from S. Kearsley, Acta Cryst. A45, 208-210 1989
may not be very fast.  better suited to PDL

returns:
       1. rotation matrix [3 rows, each is a MVR , e.g. x' = row_1 * xyz]
       2. translation vector (MVR)
       3. rmsd

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
