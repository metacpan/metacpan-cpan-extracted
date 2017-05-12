# Demian Riccardi, June 6, 2014
#
# Here is a script to use to merge the temporary json files 
# (generated during a PBS screen) into the dbs for keeps
#
# the TMP JSON files are written out by the *_dock.pl scripts after every
# outer loop.  The TMP JSON files contain however many independent JSON 
# structs as there were successful steps of the outer loop. Essentially, a 
# new struct is appended to file with each loop.  It is a little inconvenient
# because the datastructure has to be adjusted slightly (wrap the TMPJSON in {}).
#
# sometimes you have to kill your runs and are left with these TMP files with useful
# stuff in them. This script takes merges them in. I wrote this for a receptor based
# run, but I think it should work for ligand based too.  
#
# Back up your stuff when using. please use with care; you have to know your paths to use this.
# 

use Modern::Perl;
use YAML::XS qw(Load Dump);
use JSON::XS;
use HackaMol;
use File::Slurp;
use Path::Tiny;
use Hash::Merge qw(merge);
use Math::Vector::Real;

my @jsons = @ARGV;

my $path = "/some/path/receptors/dbs/";

foreach my $jTMP_fn (@jsons){

  my $jDB_fn  = $jTMP_fn;
  $jDB_fn =~ s/\w+\/TMP_(\w+_\d+)_.+/$path$1\.json/;
  $jDB_fn =~ s/free//;
  my $jnew_fn = $jTMP_fn;
  $jnew_fn =~ s/\w+\/TMP_(\w+_\d+)_.+/dbs\/$1\.json/;
  die "already exists" if (-e $jnew_fn);

  my $out = path($jnew_fn);

  #load the TMP json data  
  my $TMP     = read_file( $jTMP_fn, { binmode => ':raw' } );
  my $jTMP    = new JSON::XS;
  $jTMP->incr_parse($TMP);
  my %hTMP;
  $hTMP{BEST}{BE} = 0;
  while (my $stor = $jTMP->incr_parse){
    my ($rec) = keys %$stor;
    $hTMP{$rec}=$stor->{$rec};
    $hTMP{BEST}=$stor->{$rec}{BEST} if ($hTMP{BEST}{BE}>$stor->{$rec}{BEST}{BE});
  } 

  #load the DB json data
  my $DB    = read_file( $jDB_fn, { binmode => ':raw' } );
  my $jDB   = new JSON::XS;
  $jDB->incr_parse($DB);
  my $hDB = $jDB->incr_parse;

  my %hNEW =  %{ merge(\%hTMP,$hDB)};
  die "you should know what you are doing if using this script";

  $out->spew(encode_json \%hNEW);
}
