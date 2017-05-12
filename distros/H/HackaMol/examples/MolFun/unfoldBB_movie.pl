#!/usr/bin/env perl
# Demian Riccardi 2013/09/16
#
# Description
# grep out the backbone atoms and rotate the dihedrals by increment until
# they are close to 180 degrees
use Modern::Perl;
use HackaMol;
use Time::HiRes qw(time);

my $t1    = time;
my $angle = shift;
$angle = 180 unless ( defined($angle) );

my $hack = HackaMol->new( name => "hackitup" );

#my @all_atoms = $hack->read_file_atoms("t/lib/2cba.pdb");
my @all_atoms = $hack->pdbid_mol("1L2Y")->all_atoms; #read_file_atoms("1L2Y.pdb");

#to keep example simple, keep only the backbone
my @atoms =
  grep { $_->name eq 'N' or $_->name eq 'CA' or $_->name eq 'C' } @all_atoms;

#reset iatom
$atoms[$_]->iatom($_) foreach 0 .. $#atoms;

my @dihedrals = $hack->build_dihedrals(@atoms);

my $max_t = $atoms[0]->count_coords - 1;
my $mol   = HackaMol::Molecule->new(
    name      => 'trp-cage',
    atoms     => [@atoms],
    dihedrals => [@dihedrals],
);

my $natoms = $mol->count_atoms;
my $t      = 0;
$mol->t($t);

my @iatoms = map { $_->iatom } @atoms;

foreach my $dihe ( $mol->all_dihedrals ) {
   
    my $ratom1 = $dihe->get_atoms(1);
    my $ratom2 = $dihe->get_atoms(2);

    # atoms from nterm to ratom1 and from ratom2 to cterm
    my @nterm = 0 .. $ratom1->iatom - 1;
    my @cterm = $ratom2->iatom + 1 .. $natoms - 1;

    # use the smaller list for rotation
    my $r_these = \@nterm;
    $r_these = \@cterm if ( @nterm > @cterm );

    #set angle to rotate
    my $rang  = $angle;
    my @slice = @atoms[ @{$r_these} ];

    #ready to rotate!
    my $nrot1 = int( abs( ( $dihe->dihe_deg - 180 ) / $rang ) );
    my $nrot2 = int( abs( ( $dihe->dihe_deg + 180 ) / $rang ) );
    my $nrot  = $nrot1;
    if ( $nrot2 < $nrot1 ) {
        $nrot = $nrot2;
        $rang *= -1;
    }
    $rang *= -1 if ( @nterm > @cterm );
    foreach ( 1 .. $nrot ) {
        $mol->dihedral_rotate_atoms( $dihe, $rang, @slice );
        $mol->print_xyz;
    }
}

my $t2 = time;

printf( "time: %10.6f\n", $t2 - $t1 );
