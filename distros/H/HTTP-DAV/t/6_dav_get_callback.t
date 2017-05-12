use strict;
use HTTP::DAV;
use Test;
use lib 't';
use TestDetails qw($test_user $test_pass $test_url $test_cwd do_test fail_tests test_callback);


# Sends out a propfind request to the server 
# specified in "PROPFIND" in the TestDetails 
# module.

my $TESTS;
$TESTS=19;
plan tests => $TESTS;
fail_tests($TESTS) unless $test_url =~ /http/;


my $user = $test_user;
my $pass = $test_pass;
my $url = $test_url;
my $cwd = $test_cwd;

HTTP::DAV::DebugLevel(0);
my $dav;

# Test get_workingurl on empty client
$dav = HTTP::DAV->new( );
$dav->credentials( $user, $pass, $url );
do_test $dav, $dav->open( $url ), 1, "OPEN $url";

# Make a directory with our process id after it 
# so that it is somewhat random
my $newdir = "perldav_test$$";
do_test $dav, $dav->mkcol($newdir), 1, "MKCOL $newdir";
do_test $dav, $dav->cwd($newdir), 1, "CWD to $newdir";

# Make a big temporary file
print "CREATING temporary 1Mb file\n";
my $tmp_file = "perldav_$$.tmp";
open(TMP,">$tmp_file") ||die;
my $bytes = 1000000;
print TMP "X"x$bytes;
close TMP;
my $size = -s $tmp_file;
do_test $dav, $dav->put($tmp_file), 1, "PUT $tmp_file ($size bytes)";

######################################################################
# GET
# Create a local directory
# No error checking required. Don't care if it fails.
# Get it the normal way
do_test $dav, $dav->get($tmp_file, "${tmp_file}2"), 1, "GET of $tmp_file to ${tmp_file}2";
my $newsize = -s "${tmp_file}2";

sub remove_temps {
   no warnings;
   unlink ${tmp_file};
   unlink "${tmp_file}2";
}

print "SIZE of original file: $size\n";
print "SIZE of new      file: $newsize\n";
do_test $dav,($size == $newsize),1,"SIZE compare of $tmp_file and ${tmp_file}2";
&remove_temps; print "\n";

do_test $dav, $dav->get(-url=>$tmp_file, -to=>"${tmp_file}2"), 1, "GET of $tmp_file to ${tmp_file}2";
do_test $dav,-e "${tmp_file}2",1,"SIZE compare of $tmp_file and ${tmp_file}2 with to";
&remove_temps; print "\n";

do_test $dav, $dav->get(-url=>"XXXX", -to=>"/tmp", -callback=>\&callback), 0, "GET of XXXXX with callback";
&remove_temps; print "\n";

do_test $dav, $dav->get(-url=>$tmp_file, -callback=>\&callback), 1, "GET of $tmp_file to ${tmp_file}2 with callback";
$newsize = -s "${tmp_file}2" || -1;
do_test $dav,($size != $newsize),1,"SIZE compare of $tmp_file and ${tmp_file}2";
&remove_temps;

do_test $dav, $dav->get(-url=>$tmp_file, -to=>"${tmp_file}2", -callback=>\&callback), 1, "GET of $tmp_file to ${tmp_file}2 with callback and to";
$newsize = -s "${tmp_file}2";
do_test $dav,($size == $newsize),1,"SIZE compare of $tmp_file and ${tmp_file}2";
&remove_temps; print "\n";

my $scalar;
do_test $dav, $dav->get(-url=>$tmp_file, -to=>\$scalar, -callback=>\&callback), 1, "GET of $tmp_file to \$scalar with callback and scalar to";
do_test $dav,($size == length($scalar)),1,"SIZE compare of $tmp_file and \$scalar";
&remove_temps; print "\n";

do_test $dav, $dav->get(-url=>$tmp_file, -to=>\$scalar), 1, "GET of $tmp_file to \$scalar";
do_test $dav,($size == length($scalar)),1,"SIZE compare of $tmp_file and \$scalar";
&remove_temps; print "\n";

{
my $in_transfer=0;

sub callback {
   my($status,$mesg,$url,$so_far,$length,$data) = @_;
   $|=1;
   if ($status == 1) {
      print "Transfer complete.\n";
      $in_transfer=0;
   }
   if ($status == 0) {
      print "Transfer failed: ($mesg)\n";
      $in_transfer=0;
   } 
   if ($status == -1) {
      if (!$in_transfer++) {
         print "Transferring $url ($length bytes):\n";
      }
      my $width = 60;
      if ($length>0) {
         my $num = int($so_far/$length * $width);
         my $space = $width-$num;
         print "[" . "#"x$num . " "x$space . "]";
      } 
      print " $so_far bytes\r";
   }
}
}


######################################################################
# CLEANUP
END {
   if ( $test_url =~ /http/ ) {
      print "Cleaning up\n";
      do_test $dav, $dav->cwd(".."),  1,  "CWD ..";
      do_test $dav, $dav->delete("$newdir"),  1,  "DELETE $newdir";
   }
   &remove_temps;
}
