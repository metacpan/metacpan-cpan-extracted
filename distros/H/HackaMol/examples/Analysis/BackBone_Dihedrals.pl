#!/usr/bin/env perl
# DMR: update 04-10-2014
# print out backbone dihedrals for each model in an NMR ensemble
use Modern::Perl;
use HackaMol;
use Time::HiRes qw(time);

my $t1 = time;

my $hack = HackaMol->new( name => "hackitup" );

my $mol = $hack->read_file_mol("t/lib/2LL5_mod123.pdb");

#backbone
my @N_CA_C =
  grep { $_->name eq 'N' or $_->name eq 'CA' or $_->name eq 'C' } $mol->all_atoms;

my @dihedrals = $hack->build_dihedrals(@N_CA_C);

foreach my $dihe (@dihedrals) {
    printf( "%20s ", $dihe->name );
    foreach my $t (0 .. $mol->tmax){
      $dihe->gt($t);
      printf( "%7.2f ", $dihe->dihe_deg );
    }
    print "\n";
}

my $t2 = time;

printf( "time: %10.6f\n", $t2 - $t1 );
