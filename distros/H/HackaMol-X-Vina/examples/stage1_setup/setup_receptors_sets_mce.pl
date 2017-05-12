# Demian Riccardi, June 6, 2014
#
# Store the json databases by receptor
# see setup_ligands_sets_mce.pl to store by ligand 
#
use Modern::Perl;
use HackaMol;
use Time::HiRes qw(time);
use MCE::Loop max_workers => 12, chunk_size => 1;
use MCE::Subs qw( :worker );
use JSON::XS qw(encode_json);
use Array::Split qw(split_by);

my $t1 = time;
my $dockem = HackaMol->new(
    hush_read => 1,
    data      => 'pdbqts',
    scratch   => 'dbs',
);
$dockem->scratch->mkpath unless ( $dockem->scratch->exists );

my $nrecsper = 15;

my @jobs = split_by( $nrecsper, $dockem->data->children( qr/\.pdbqt/ ) );


mce_loop_s {
  my $i   = $_;
  my $fname = sprintf("set_%03d.json",$i); 
  my $json = $dockem->scratch->child($fname);
  my $fh = $json->openw_raw;
  my $stor;
  foreach my $rec (@{$jobs[$i]}){
    my $mol = $dockem->read_file_mol($rec);
    $stor->{$rec->basename('.pdbqt')} = {
                                          BEST    => { BE => 0 },
                                          TMass   => $mol->total_mass/1000,
                                          formula => $mol->bin_atoms_name, 
                                          rpath   => $rec->stringify,
    };
  } 
  print $fh encode_json $stor;
} 0, $#jobs;

my $t2 = time;
printf ("%5.4f\n", $t2-$t1);
