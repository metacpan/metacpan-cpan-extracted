use strict;
use warnings;
use constant WIN32 => ($^O eq 'MSWin32');
use constant CYGWIN => ($^O eq 'cygwin');
use ExtUtils::MakeMaker qw(prompt WriteMakefile);
use Cwd;
use File::Spec;
use Config;

my $cwd = getcwd;
my $use_boutell;

my @clean = map{File::Spec->catfile($cwd, 't', "$_.jpeg")}
  qw(eye_ifs eye_resampled eye_resized 
     face_ifs face_resampled face_resized
     th_ifs th_resampled th_resized);

unless (@ARGV) {
  warn <<END;
NOTICE: This module requires libgd 2.0.5 or higher.
        it will NOT work with earlier versions. If you are getting
        compile or link errors, then please get and install a new
        version of libgd from www.boutell.com.

        Type perl Makefile.PL -h for command-line option summary

END
}

####################################################################
### borrowed heavily from GD.pm's Makefile.PL
####################################################################
# =====> PATHS: CHECK AND ADJUST <=====
my (@INC, @LIBPATH, @LIBS, $lib_gd_path);
my $AUTOCONFIG = 0;      # global set by try_to_autoconfigure() below

unless (WIN32) {
  try_to_autoconfigure(\$lib_gd_path,\@INC,\@LIBPATH,\@LIBS);

  @INC     = qw(-I/usr/include -I/usr/include/gd) unless @INC;
  @LIBPATH = qw(-L/usr/lib/X11 -L/usr/X11R6/lib -L/usr/X11/lib -L/usr/lib) 
    unless @LIBPATH;
}

my $gd_lib = '-lgd';
if (WIN32 or CYGWIN) {
  my $ans = prompt('Are you using the precompiled bgd lib from boutell.com?',
                  'yes');
  if ($ans =~ /^y/i) {
    $gd_lib = '-lbgd';
    $use_boutell++;
  }
}

@LIBS    = ($gd_lib, qw(-lpng -lzlib)) unless @LIBS;

# support for AMD64 libraries
if (-d '/usr/lib64') {
  my @libs64 = map {my $a = $_; $a=~ s/lib$/lib64/; $a} @LIBPATH;
  @LIBPATH = (@LIBPATH,@libs64);
}

#########################################################################
use Getopt::Long;
my $result = GetOptions("lib_gd_path=s"   => \$lib_gd_path);
unless ($result) {
  print STDERR <<END;
Usage: perl Makefile.PL -lib_gd_path   /path/to/libgd

If no options are passed on the command line, the program will
attempt to autoconfigure itself with the gdlib-config program (present
in GD versions 2.0.27 or later).  Otherwise it will prompt for these
values interactively.
END
}

if( defined($lib_gd_path) ) {
  print "GD library used from:       $lib_gd_path\n";   
}

###################################################################
# path to libgd, skip prompt if passed in from above
###################################################################
my $PREFIX = $lib_gd_path;
if( ! defined($lib_gd_path) ) {
  warn "\n";
  $PREFIX = prompt('Where is the gd library installed?','/usr/lib');
}

unless ($AUTOCONFIG || $PREFIX eq '/usr/lib' || $use_boutell) {
  $PREFIX =~ s!/lib$!!;
  unshift @INC, "-I$PREFIX/include";
  unshift @LIBPATH, "-L$PREFIX/lib";
}

if ($use_boutell) {
  unshift @INC, "-I$PREFIX";
  unshift @LIBPATH, "-L$PREFIX";
}
my $env_lib = $ENV{GD_LIBS} || '';
my $env_inc = $ENV{GD_INC} || '';
my $objs = join ' ', qw(libIFS.o CopyIFS.o);
my $eu_version = $ExtUtils::MakeMaker::VERSION;

my %opts = (
            NAME           => 'GD::Image::CopyIFS',
            VERSION_FROM   => 'CopyIFS.pm',
            PREREQ_PM      => {GD => 2.05},
            ($] >= 5.005 ?    
             (ABSTRACT_FROM   => 'CopyIFS.pm',
              AUTHOR     => 'Randy Kobes <r.kobes@uwinnipeg.ca>') 
             : ()),
            OBJECT         => $objs,
            ($eu_version >= 6.11 ?
             (NO_META     => 1,)
             : ()),
            LIBS      => [join(' ', $env_lib, @LIBPATH, @LIBS)],
            INC       => join(' ', $env_inc, @INC),
            dist           => {
                               SUFFIX   => 'gz',
                               COMPRESS => 'gzip -9f',
                              },
            clean          => {FILES => "@clean"},
           );

if (WIN32 and not $use_boutell) {
  my $ans = prompt('Was the gd library compiled as a DLL?', 'yes');
  unless ($ans =~ /^y/i) {
    $opts{DEFINE} = ' -DNONDLL ';
  }
}

WriteMakefile(%opts);

my $make = $Config{make};
print <<"END";

You can now run

   $make
   $make test
   $make install

The tests will create, in the t/ subdirectory, zoomed-in 
areas and a resized image based on the original lena.jpeg
image. These images are all named "*_ifs.jpeg"; one can
compare these with the analagous "*_resized.jpeg" and
"*_resampled.jpeg" images made with, respectively, the
"copyResized" and "copyResampled" methods of GD.

END

sub try_to_autoconfigure {
  my ($lib_gd_path, $INC, $LIBPATH, $LIBS) = @_;
  my $config = `gdlib-config --all`;
  return unless $config;
  $AUTOCONFIG++;

  my ($version) = $config =~ /^GD library\s+(\S+)/m;
  warn "Configuring for libgd version $version.\n";

  my ($cflags)   = $config =~ /^cflags:\s+(.+)/m;
  my ($ldflags)  = $config =~ /^ldflags:\s+(.+)/m;
  my ($libs)     = $config =~ /^libs:\s+(.+)/m;
  my ($libdir)   = $config =~ /^libdir:\s+(.+)/m;

  @$INC          = map {s/^-I// && "-I$_"} split /\s+/,$cflags;
  @$LIBPATH      = map {s/^-L// && "-L$_"} split /\s+/,$ldflags;
  @$LIBS         = split /\s+/,$libs;

  push @$LIBS, "-lgd";
  push @$LIBPATH, "-L$libdir";
  ($$lib_gd_path = $libdir) =~ s!/[^/]+$!!;
}
