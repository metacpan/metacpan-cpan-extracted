use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my($GTMDIST)= $ENV{'gtm_dist'};  # Need GTM location

if(!$GTMDIST) {
  print "Environment variable \'gtm_dist\' not found.\n";
  print "Where is GTM? ";
}


die "Mumps executable not found in $GTMDIST" unless -x "$GTMDIST/mumps";
die "libgtmshr.so not in $GTMDIST" unless -e "$GTMDIST/libgtmshr.so";

print "Attempting to determine GT.M version...\n";
my($GTMVER,$full) = &vercheck();       # Try to get GT.M version

if(!$GTMVER) { die "Unable to determine MUMPS version."; } 
else {
  print "Detected: $full\n";
  die "You need GT.M version 4.4-003 or higher." unless $GTMVER >= 44;
}


if(0) {
#// File locations, default environment variable settings
#define _GT_GTMCI_LOC "/usr/local/gtm/xc/calltab.ci"
#define _GT_GTMRTN_LOC "/home/vmacs/rtn-obj(/home/vmacs/rtn-cvs/misc)"
#define _GT_GTMGBL_LOC "/usr/local/vmacs/vpro.gld"
#// gtmroutines, gtmgbldir = _GT_GTM(RTN|GBL)_LOC
# $ENV{'gtmgbldir'}   = "/usr/local/vmacs/vpro.gld";
#$ENV{'gtmgbldir'}   = "/usr/local/vmacs/voles.gld";
}


print "\n";

WriteMakefile(
    'NAME'		=> 'Db::GTM',
    'VERSION_FROM'	=> 'GTM.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'GTM.pm', # retrieve abstract from module
       AUTHOR     => 'Steven Zeck <spzeck@ucdavis.edu>') : ()),
    'LIBS'		=> ["-L$GTMDIST -lgtmshr -Wl,-R,$GTMDIST"], 
    'DEFINE'		=> "-D_GT_VER=$GTMVER", 
    'INC'		=> "-I. -I$GTMDIST", 
);

# Tries to get GT.M version
sub vercheck {
  return undef unless $ENV{'gtm_dist'}; local(*VCHECKM,*MUMPS); my($v,$fv);
  if(open(MUMPS,"/bin/echo \'w \$ZVersion h\'|$ENV{'gtm_dist'}/mumps -direct|"))
  {
    $v = 0; my($l,@v); while($l = <MUMPS>) {
      chomp($l); @v = split(/ /,$l); next unless @v == 4;
      if($v[0] eq "GT.M" && $v[1] =~ /^V(\d+)\.(\d)/) { $v=$1 . $2; $fv=$l; }
    }
    close(MUMPS);
  }
  unlink $mcode; return ($v,$fv);
}
