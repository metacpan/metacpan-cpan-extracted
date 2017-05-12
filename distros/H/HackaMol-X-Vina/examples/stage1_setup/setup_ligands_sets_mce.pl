#!/usr/bin/env perl
# Demian Riccardi, June 6, 2014
#
# Store the json databases by ligand
# see setup_receptors_sets_mce.pl to store by ligand 
#
# pull down some pdbs:
# wget http://autodock.scripps.edu/local_files/screening/NCI-Diversity-AutoDock-0.2.tar.gz
# use MCE to set up the subsets faster
use Modern::Perl;
use HackaMol;
use Time::HiRes qw(time);
use MCE::Loop max_workers => 8, chunk_size => 1;
use MCE::Subs qw( :worker );
use JSON::XS qw(encode_json);
use Array::Split qw(split_by);

my $t1 = time;
my $dockem = HackaMol->new(
    hush_read => 1,
    data      => 'pdbqts',
    scratch   => 'dbs'
);
$dockem->scratch->mkpath unless ( $dockem->scratch->exists );

# split up all the ligands into sets with 10 ligands per set
my $nligsper = 10;

my @jobs = split_by( $nligsper, $dockem->data->children( qr/\.pdbqt/ ) );


mce_loop_s {
  my $i   = $_;
  my $fname = sprintf("set_%03d.json",$i); 
  my $json = $dockem->scratch->child($fname);
  my $fh = $json->openw_raw;
  my $stor;
  foreach my $lig (@{$jobs[$i]}){
    my $mol = $dockem->read_file_mol($lig);
    $stor->{$lig->basename('.pdbqt')} = {
                                          BEST    => { BE => 0 },
                                          TMass   => $mol->total_mass,
                                          formula => $mol->bin_atoms_name, 
                                          lpath   => $lig->stringify,
    };
  } 
  print $fh encode_json $stor;
} 0, $#jobs;

my $t2 = time;
printf ("%5.4f\n", $t2-$t1);
