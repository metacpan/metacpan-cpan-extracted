#!/usr/bin/env perl
use Modern::Perl;
use HackaMol;
use Math::Vector::Real;
use Math::Vector::Real::Random;
use Math::Trig;

my $hack = HackaMol->new( name => "hackitup" );
my @atoms = $hack->read_file_atoms("t/lib/1L2Y.pdb");

# all coordinates from NMR ensemble are loaded into atoms
my $mol = HackaMol::Molecule->new(
    name  => 'trp-cage',
    atoms => [@atoms]
);

#recenter all coordinates to center of mass
foreach my $t ( 0 .. $atoms[0]->count_coords - 1 ) {
    $mol->t($t);
    $mol->translate( -$mol->COM );
}

# print coordinates from t=0 to trp-cage.xyz and return filehandle
my $fh = $mol->print_xyz( $mol->name . ".xyz" );

# print coordinates for @t=(1..4) to same filehandle
foreach my $t ( 1 .. 4 ) {
    $mol->t($t);
    $mol->print_xyz($fh);
}

$mol->t(0);
foreach ( 1 .. 10 ) {
    $mol->rotate(
        V( 0, 0, 1 ),    # rotation vector
        36,              # rotate by 180 degrees
        V( 5, 0, 0 )     # origin of rotation
    );
    $mol->print_xyz($fh);
}

# translate/rotate method is provided by AtomGroupRole
# populate groups byatom resid attr
my @groups = $hack->group_by_atom_attr( 'resid', $mol->all_atoms );
$mol->push_groups(@groups);

foreach my $ang ( 1 .. 10 ) {
    $_->rotate( V( 1, 1, 1 ), 36, $_->COM ) foreach $mol->all_groups;
    $mol->print_xyz($fh);
}

$fh->close;    # done filling trp-cage.xyz with coordinates

# let's create a 20 Angstrom ball of oxygen atoms from density of water
my $radius = 20;
my $natoms = int( 0.0334 * ( $radius**3 ) * 4 * pi / 3 );

my @sphatoms =
  map { HackaMol::Atom->new( Z => 8, charges => [0], coords => [$_] ) }
  map { Math::Vector::Real->random_in_sphere( 3, $radius ) } 1 .. $natoms;

my $sphere = HackaMol::Molecule->new(
    name  => "ball",
    atoms => [@sphatoms]
);

# create new system with both trp-cage and O atom sphere
my $bigmol = HackaMol::Molecule->new(
    name  => "bigoverlap",
    atoms => [ $mol->all_atoms, $sphere->all_atoms ],
);

# write out and get new filehandle
$fh = $bigmol->print_xyz( $bigmol->name . ".xyz" );

# rotate the O atom sphere inside bigmol
foreach my $ang ( 1 .. 10 ) {
    $sphere->rotate( V( 1, 1, 1 ), 36, $sphere->COM );
    $bigmol->print_xyz($fh);
}

