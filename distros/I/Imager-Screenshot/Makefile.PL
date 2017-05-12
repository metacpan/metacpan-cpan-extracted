#!perl -w
use strict;
use ExtUtils::MakeMaker;
use Imager 0.88;
use Imager::ExtUtils;
use Config;
use File::Spec;
use Getopt::Long;
use lib "inc";
use Imager::Probe;

my @incpaths; # places to look for headers
my @libpaths; # places to look for libraries
my $verbose;

GetOptions("incpath=s", \@incpaths,
           "libpath=s" => \@libpaths,
	   "v|verbose" => \$verbose);

my @objs = qw/Screenshot.o/;
my @cflags;
my @lflags;
my @lddlflags;
my %seen_incdir;
my %seen_libdir;
my @inc = Imager::ExtUtils->includes;
my %x11_probe =
  (
   name => "X11",
   libbase => "X11",
   inccheck => sub { -e File::Spec->catfile($_[0], "X11/Xlib.h") },
   verbose => $verbose,
   libpath => [ @libpaths, "/usr/X11R6/lib", "/usr/X11/lib" ],
   incpath => [ @incpaths, "/usr/X11R6/include", "/usr/X11/include" ],
  );
$x11_probe{alternatives} =
  [
   {
     altname => "Cygwin",
     libbase => "X11.dll",
   },
  ] if $^O eq "cygwin";
my $x11_result = Imager::Probe->probe(\%x11_probe);
if ($x11_result) {
  push @objs, 'scx11.o';
  push @cflags, '-DSS_X11', $x11_result->{DEFINE};
  push @lflags, $x11_result->{LIBS};
  push @inc, $x11_result->{INC};
  print "Found X11\n";
}
my %win32_probe =
  (
   name => "Win32",
   inccheck => sub { -e File::Spec->catfile($_[0], "windows.h") },
   libbase => "gdi32",
   testcode => _win32_test_code(),
   testcodeheaders => [ "stdio.h", "string.h", "windows.h" ],
   incpath => \@incpaths,
   libpath => \@libpaths,
   verbose => $verbose,
  );
my $win32_result = Imager::Probe->probe(\%win32_probe);
if ($win32_result) {
  push @objs, 'scwin32.o', 'svwin32.o';
  push @cflags, '-DSS_WIN32', $win32_result->{DEFINE};
  if ($^O eq 'cygwin') {
    push @lflags, '-L/usr/lib/w32api', '-lgdi32';
  }
  print "Found Win32\n";
}

if ($^O eq "darwin" and my ($rel) = `uname -r` =~ /^([0-9]+)/) {
  # this test is overly simple
  if ($rel < 11) {
    push @objs, "scdarwin.o";
    push @cflags, "-DSS_DARWIN";
    push @lddlflags, qw/-framework OpenGL -framework Cocoa/;
    print "Found OS X (<11)\n";
  }
  else {
    push @objs, "scdarwin2.o";
    push @cflags, "-DSS_DARWIN";
    push @lddlflags, qw/-framework Cocoa/;
    print "Found OS X (>=11)\n";
  }
}

unless (@objs > 1) {
  die <<DEAD;
OS unsupported: Headers or libraries not found for a supported GUI

Sorry, I can't find headers or libraries for a supported GUI
You need to install development headers and libraries for your GUI
For Win32: Platform SDK or a substitute
For X11: X11 headers and libraries, eg. the libX11-dev package on Debian
For OS X: Install Xcode

DEAD
}

my %opts = 
  (
   NAME => 'Imager::Screenshot',
   VERSION_FROM => 'Screenshot.pm',
   OBJECT => "@objs",
   PREREQ_PM => {
		 'Imager'    => 0.88,
		 'Imager::Probe' => 0,
		 'XSLoader'  => 0,
		},
   INC => "@inc",
   TYPEMAPS => [ Imager::ExtUtils->typemap ],
  );

$opts{LIBS} = "@lflags" if @lflags;
$opts{INC} .= " @cflags" if @cflags;

if (@lddlflags) {
  $opts{LDDLFLAGS} = $Config{lddlflags} . " @lddlflags";
}

# avoid "... isn't numeric in numeric gt ..." warnings for dev versions
my $eu_mm_version = eval $ExtUtils::MakeMaker::VERSION;
if ($eu_mm_version > 6.06) {
  $opts{AUTHOR} = 'Tony Cook <tonyc@cpan.org>';
  $opts{ABSTRACT} = 'Screen/Window capture to Imager images';
}

# LICENSE was introduced in 6.30_01, but Debian etch includes
# (as of 2007/01/12) an ExtUtils::MakeMaker versioned 6.30_01 without
# LICENSE support
# EXTRA_META was also introduced in 6.30_01
if ($eu_mm_version > 6.3001) {
  $opts{LICENSE} = 'perl';
}
if ($eu_mm_version >= 6.46) {
  $opts{META_MERGE} =
    {
     configure_requires => 
     {
      Imager => "0.88",
      'Imager::Probe' => 0,
     },
     build_requires => 
     {
      Imager => "0.88",
      "Test::More" => "0.47",
     },
     dynamic_config => 1,
     resources =>
     {
      homepage => "http://imager.perl.org/",
      repository => "git://git.imager.perl.org/imager-screenshot.git",
      bugtracker => "http://rt.cpan.org/NoAuth/Bugs.html?Dist=Imager-Screenshot",
     },
    };
}

WriteMakefile(%opts);

sub _win32_test_code {
  return <<'CODE';
HDC dc = GetDC(NULL);
HDC bmpDc = CreateCompatibleDC(dc);
DeleteDC(bmpDc);
ReleaseDC(NULL, dc);
return 0;
CODE
}
