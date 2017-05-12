#!/usr/bin/env perl
use Modern::Perl;
use Math::Trig;
use HackaMol;

my $radius = shift || 16;
my $oxy = HackaMol::Atom->new( Z => 8 );
my $hyd = HackaMol::Atom->new( Z => 1 );

my $mass = $oxy->mass + 2 * $hyd->mass;
my $rho  = 1.0;

say "H2O g/mol: $mass";
say "H2O mol/L:",             $rho * 1000 / $mass;     # g/cm3 * cm3/L  * mol/g
say "H2O molar (moles/mL): ", $rho * 1 * 1 / $mass;    # g/cm3 * cm3/ml * mol/g
my $cm_ang = 100 / 10E9;
say "cm/ang :", $cm_ang;

my $Na = 6.02214179E+23;

say "rho (molecules/ang^3): ",
  ( $rho / $mass ) *
  ( $cm_ang**3 ) *
  $Na;    # g/cm3 * mol/g * cm3/ang3 * molecules/mol

my $natoms = int( 0.0334 * ( $radius**3 ) * 4 * pi / 3 );

say "$natoms in radius $radius Angstroms"; 
