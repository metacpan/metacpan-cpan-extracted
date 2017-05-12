#!/usr/bin/env perl
# wget http://autodock.scripps.edu/local_files/screening/NCI-Diversity-AutoDock-0.2.tar.gz
# setup subsets of json files keyed by ligand for virtual screens of receptors and centers
use Modern::Perl;
use HackaMol;
use Time::HiRes qw(time);
use JSON::XS;
use Array::Split qw(split_by);

my $dockem = HackaMol->new(
    hush_read => 1,
    data      => 'NCI_diversitySet2/pdbqt',
    scratch   => "some/different/otherpath/ligands/NCI_diversitySet2",
);

$dockem->scratch->mkpath unless ( $dockem->scratch->exists );

# split up all the ligands into sets with 100 ligands per set
my $nligsper = 10;

my @jobs = split_by( $nligsper, $dockem->data->children( qr/\.pdbqt/ ) );

foreach my $i ( 0 .. $#jobs ) {

    my $fname = sprintf("set_%03d.json",$i);
    my $json = $dockem->scratch->child($fname);
    my $fh = $json->openw_raw;
    my $stor;
    foreach my $lig ( @{ $jobs[$i] } ){
  
      my $mol = $dockem->read_file_mol($lig);
      $stor->{$lig->basename('.pdbqt')} = {
                                                BEST    => { BE => 0 },
                                                TMass   => $mol->total_mass,
                                                formula => $mol->bin_atoms_name, 
                                                lpath   => $lig->stringify,
      };
    }
    print $fh encode_json $stor; 

}

