# Demian Riccardi, June 6, 2014
#
# Here is a script to use to merge the dbs 
#
# this one is pretty straightforward.  Hash::Merge gives left precendence when merging hashes
# i.e. the left is untouched, and the right is woven into unique entries if free.
#
# Back up your stuff when using. please use with care; you have to know your paths to use this.
# 
use Modern::Perl;
use Hash::Merge qw(merge);
use JSON::XS;
use Path::Tiny;
use File::Slurp;


my $path = "/some/path/receptors/dbs/";

foreach my $fn_json (glob("*.json")){
  my $fn_orig = $fn_json;
  $fn_orig =~ s/consset/set/;
  $fn_orig = $path . $fn_orig;

  my $this    = read_file( $fn_json, { binmode => ':raw' } );
  my $json    = new JSON::XS;
  $json->incr_parse($this);
  my $stor = $json->incr_parse;

  my $orig    = read_file( $fn_orig, { binmode => ':raw' } );
  my $ojson   = new JSON::XS;
  $ojson->incr_parse($orig);
  my $ostor = $ojson->incr_parse;

  my %nhash = %{ merge($stor,$ostor)};
  
  my $fstor = path($fn_json);
  die "you should know what you are doing if using this script";
  $fstor->spew(encode_json \%nhash);
  
} 


