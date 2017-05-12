#!/usr/bin/env perl
# Demian Riccardi 06/02/2014
# use kmeans clustering from Math::Vector::Real::kdTree to process the results from FTMap into a set of 
# binding sites.  Print out as XYZ of mercury atoms.
#
# ftmap.bu.edu
#
# the ftmap pdbs have the small molecule binders in between /HEADER crosscluster/ and a /REMARK/
# if you process the ftmap pdbs and lose these separations, you'll have to work up another solution
# to pulling all the FTMAP small molecule binders into a set of Math::Vector::Real.
#
# arguments: 
#   1. Str to find pdbs to use
#   2. Num cutoff for separation between sites.
#
# The initial number of clusters is set at 20.  This is decremented until all clusters 
# are >= cutoff separation.
# 
use Modern::Perl;
use HackaMol;
use FileHandle;
use Modern::Perl;
use Math::Vector::Real;
use Math::Vector::Real::kdTree;
use Math::Vector::Real::Neighbors;
use YAML::XS;

die "pass Str cutoff\n" unless @ARGV ;
my $regex  = shift;
my $rcut   = shift || 7.5;

my @files = glob("$regex*.pdb");
say foreach @files;
my @ftmap;
foreach my $fh (map{FileHandle->new("< $_")} @files){ 

  while (<$fh>){
    if (/HEADER crosscluster/../REMARK/ ){
      if (/ATOM\s+\d+/){
        my ($symbol, $xyz) = unpack "x13A1x16A24", $_;
        push @ftmap, V(split(' ', $xyz) );
      }
    }
  }
}


my $tree = Math::Vector::Real::kdTree->new(@ftmap);

my @means;
my @dist;
my $ki = 20;

while ($ki){
  @means = $tree->k_means_start($ki);
  @means = $tree->k_means_loop(@means);
  my @ineigh = Math::Vector::Real::Neighbors->neighbors(@means);
  @dist = map {$means[$_]->dist($means[$ineigh[$_]]) } 0 .. $#ineigh;
  if (grep {$_ < $rcut} @dist){
    $ki--;
    next;  
  }
  else {
    last;
  }
}

HackaMol::Molecule->new( atoms => 
    [
        map{ HackaMol::Atom->new(Z=>80, coords=>[$_])} @means,
    ]    
)->print_xyz;


