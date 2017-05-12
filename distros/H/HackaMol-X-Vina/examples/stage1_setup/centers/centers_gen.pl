# Demian Riccardi May 15, 2014
#
# takes centers stored in xyz files and drops them into a yaml 
# for more convenient use
use Modern::Perl;
use HackaMol;
use YAML::XS qw(DumpFile);

my $hack = new HackaMol; 

my %centers;

foreach my $xyz ( glob ("*.xyz") ){
  my ($key)   = split ("_", $xyz);
  my @centers = map{ [ @{ $_->xyz } ] } $hack->read_file_atoms($xyz);
  $centers{FTMAP}{$key} = \@centers; 
}

DumpFile('centers.yaml',\%centers);

