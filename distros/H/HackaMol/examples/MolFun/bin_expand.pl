#!/usr/bin/env perl
# Demian Riccardi August, 22, 2013
#
use Modern::Perl;
use HackaMol;
use Math::Vector::Real;

my $t1    = time;
my $angle = shift;
$angle = 180 unless ( defined($angle) );

my $hack = HackaMol->new( name => "hackitup" );

my @atoms = $hack->read_file_atoms("t/lib/1L2Y.pdb");
my $max_t = $atoms[0]->count_coords - 1;

my $mol = HackaMol::Molecule->new( name => 'trp-cage', atoms => [@atoms] );

my @groups = $hack->group_by_atom_attr( 'resid', $mol->all_atoms );
$mol->push_groups(@groups);

$_->translate( -$_->COM, 1 ) foreach $mol->all_groups;

$mol->print_xyz;
$mol->t(1);
$mol->print_xyz;

my %Z;
foreach my $atom ( $mol->all_atoms ) {
    my $z = $atom->Z;
    $Z{$z}++;
    $atom->push_coords( V( 3 * $z, $Z{$z} / 4, 0 ) );
}

$mol->t($max_t+1);
$mol->print_xyz;
$_->push_coords( V( 3 * $_->Z, 0, 0 ) ) foreach $mol->all_atoms;
$mol->t($max_t+2);
$mol->print_xyz;
$_->push_coords( V( 0, 0, 0 ) ) foreach $mol->all_atoms;
$mol->t($max_t+3);
$mol->print_xyz;
