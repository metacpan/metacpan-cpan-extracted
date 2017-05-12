######################################################################
#
# MakeMaker file for JavaScript::SpiderMonkey
#
# Revision:     $Revision: 1.7 $
# Last Checkin: $Date: 2011/10/23 10:27:21 $
# By:           $Author: thomas_busch $
#
# Authors: Mike Schilli  m@perlmeister.com, 2002-2005
#          Thomas Busch  tbusch@cpan.org, 2006-2011
#
######################################################################

use ExtUtils::MakeMaker;
use Getopt::Long;

# Get the right lib and include dirs for different platforms

my $JS_LIB_DIR;
my @JS_INCL_DIRS;

my @c_header_files = qw(
  jsapi.h
  jsautocfg.h
);

my @possible_libraries = qw(
  libjs.a
  js32.dll
  libmozjs.so
);

my %possible_install_paths = (
  "../js/src/*"      => "../js/src",
  "/usr/lib"         => "/usr/include",
  "/usr/lib64"       => "/usr/include",          # CentOS 5 / 64 bit
  "/usr/local/lib"   => "/usr/local/include",
  "/usr/lib/firefox" => "/usr/include/firefox",
  "/opt/local/lib"   => "/opt/local/include",    # MacPorts
);

my ($JS_LIB_DIR, @JS_INCL_DIRS, $JS_LIB_NAME);

#### Determine compile options
##############################

my $JS_DEFINE;
my $E4X = 0;
my $JS_THREADSAFE = 0;

## Get options from command line

# Altered so that library location can be specified from the command line.
# BKB 2010-05-24 10:03:09

GetOptions(
  "E4X" => \$E4X,
  "JS_THREADSAFE" => \$JS_THREADSAFE,
  "JS_LIB_DIR=s"    => \$JS_LIB_DIR,
  "JS_LIB_NAME=s"   => \$JS_LIB_NAME,         
);
if ($JS_LIB_DIR) {
    push @JS_INCL_DIRS, $JS_LIB_DIR;
}
foreach my $install_path(keys %possible_install_paths) {
  foreach my $possible_lib(@possible_libraries) {
    foreach my $libfile(glob "$install_path/$possible_lib") {
      next if ! -f $libfile;
      my $include_path = $possible_install_paths{$install_path};
      foreach my $c_header(@c_header_files) {
        if (-f "$include_path/$c_header") {
          my $include_dir = "$include_path/$c_header";
          $include_dir =~ s/$c_header$//;
          push @JS_INCL_DIRS, $include_dir;
        }
        foreach my $headerfile(glob "$include_path/*/$c_header") {
          my $include_dir = $headerfile;
          $include_dir =~ s/$c_header$//;
          push @JS_INCL_DIRS, $include_dir;
        }
      }
      if (scalar(@JS_INCL_DIRS) == scalar(@c_header_files)) {
        $JS_LIB_DIR = $libfile;
        $JS_LIB_DIR =~ s/$possible_lib$//;

        $JS_LIB_NAME = $possible_lib;
        $JS_LIB_NAME =~ s/\.(a|so|dll)$//;
        $JS_LIB_NAME =~ s/^lib//;

        last;
      } else {
        @JS_INCL_DIRS = ();
      }
    }
    last if $JS_LIB_DIR;
  }
  last if $JS_LIB_DIR;
}

if ($JS_INCL_DIRS[0] eq $JS_INCL_DIRS[1]) {
  shift @JS_INCL_DIRS;
}

## If no SpiderMonkey library found report that and exit.
## Otherwise print lib and include paths.

if (!$JS_LIB_DIR) {
    print <<EOT;

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
This module requires the SpiderMonkey C library -- please read the
README file on how to download, compile and link it.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

EOT
    exit 0;
} else {
  print "JS_LIB_DIR:  $JS_LIB_DIR\n";
  foreach my $include_dir(@JS_INCL_DIRS) {
    print "JS_INCL_DIR: $include_dir\n";
  }
  print "JS_LIB_NAME: $JS_LIB_NAME\n";
}



## Determine library name and system-related defines
if ($^O ne 'MSWin32') {
  $JS_DEFINE  = '-DXP_UNIX';
} else {
  $JS_DEFINE  = '-DXP_WIN';
};

## Add E4X support if flag set.
## For more info about E4X check http://en.wikipedia.org/wiki/E4X
if ($E4X) {
  $JS_DEFINE .= " -DE4X";
  print "E4X support enabled\n";
}

## Support compiling in thread safe environment
if ($JS_THREADSAFE) {
  $JS_DEFINE .= " -DJS_THREADSAFE";
  print "Compiling with JS_THREADSAFE flag\n";
}


#### See lib/ExtUtils/MakeMaker.pm for details of how to influence
#### the contents of the Makefile that is written.
##################################################

WriteMakefile(
    'NAME'		=> 'JavaScript::SpiderMonkey',
    'VERSION_FROM'	=> 'SpiderMonkey.pm', # finds $VERSION
    'PREREQ_PM'		=> {
# In fact, the following module isn't needed unless debugging is
# switched on, so let's reduce the dependencies:
# BKB 2010-05-24 10:01:52
#        'Log::Log4perl' => 0,
        'Data::Dumper'  => 0,
                           },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'SpiderMonkey.pm', # retrieve abstract from module
       AUTHOR     => 'Mike Schilli <m@perlmeister.com>') : ()),
    'LIBS'		=> ["-L$JS_LIB_DIR -l$JS_LIB_NAME"],
    'DEFINE'		=> $JS_DEFINE, # e.g., '-DHAVE_SOMETHING'
	# Insert -I. if you add *.h files later:
    'INC'		=> "-I".join " -I", @JS_INCL_DIRS,
	# Un-comment this if you add C files to link with later:
    # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
);

######################################################################
sub MY::postamble {
######################################################################
    '
README: SpiderMonkey.pm
	pod2text SpiderMonkey.pm >README
    ';
}
