use ExtUtils::MakeMaker;
require Config;

foreach $arg (@ARGV) {
  if($arg =~ m/^--with-fltk-libs/) {
    @dvals = split /=/, $arg;
    $FLTKLDFLAGS = "-L".$dvals[1];
    print "Adding $FLTKLDFLAGS to linker flags.\n";
  } elsif($arg =~ m/^--with-fltk-includes/) {
    @dvals = split /=/, $arg;
    $FLTKINC = "-I".$dvals[1];
    print "Adding $FLTKINC to include flags.\n";
  } elsif($arg =~ m/^--help/) {
  print <<"EOF";
Usage: perl Makefile.PL [options]
Available build options:
------------------------
--with-fltk-libs=DIR        Specify path to FLTK library.
--with-fltk-includes=DIR    Specify path to FLTK header files.
--help                      Display this message.

EOF
    exit 0;
  }
}

$CC = 'c++';
@fltklib = ( $ENV{HOME}."/fltk-cvs/lib",
             $ENV{HOME}."/devel/fltk-cvs/lib",
             $ENV{HOME}."/src/fltk-cvs/lib",
             $ENV{HOME}."/Programming/fltk-cvs/lib",
             '../fltk-cvs/lib',
             '../src/fltk-cvs/lib',
             '/usr/local/devel/lib',
             '/usr/local/src/fltk-cvs/lib',
             '/usr/src/fltk-cvs/lib',
             '/usr/local/lib',
             '/usr/lib',
             '../lib');
@fltkinc = ( $ENV{HOME}."/fltk-cvs",
             $ENV{HOME}."/devel/fltk-cvs",
             $ENV{HOME}."/src/fltk-cvs",
             $ENV{HOME}."/Programming/fltk-cvs",
             '../fltk-cvs',
             '../src/fltk-cvs',
             '/usr/local/devel/include',
             '/usr/local/src/fltk-cvs',
             '/usr/src/fltk-cvs',
             '/usr/local/include',
             '/usr/include',
             '../include');

if(!$FLTKLDFLAGS && !$FLTKINC) {
  print "Looking for fltk library...";
  $cntx = 0;
  foreach $d (@fltklib) {
    if(-f "$d/libfltk.a") {
      $icheck = $fltkinc[$cntx];
        if(-f "$icheck/FL/Fl_Text_Buffer.H") {
        $FLTKLDFLAGS = "-L$d";
        $FLTKINC = "-I$icheck";
        print "found.\nUsing library at $d/libfltk.a\nWith headers in $icheck.\n";
        last;
     } else {
        $maybelib = $d;
      }
    }
    $cntx++;
  }
  if(!$FLTKLDFLAGS && !$maybelib) {
    print "not found.\nI could not find the fltk library on your system.\n";
    print "Please verify that your have fltk installed before continuing.\n";
    exit 1;
  }

  if(!$FLTKINC) {
    foreach $id (@fltkinc) {
      if(-f "$icheck/FL/Fl_Text_Buffer.H") {
        $FLTKLDFLAGS = "-L$maybelib";
        $FLTKINC = "-I$id";
        print "found.\nUsing library at $maybelib/libfltk.a\nWith headers in $id.\n";      
        last;
      }
    }
  }
  if(!$FLTKINC && $maybelib) {
    print "not found.\nThe fltk library was found at $maybelib, but I was not";
    print "\nable to find the fltk 2 header files. Please verify that you\n";
    print "have fltk 2 installed before continuing.\n";
    exit 1;
  }
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'FLTK',
    'VERSION_FROM' => 'FLTK.pm', # finds $VERSION
    'CC'    => $CC,
    'CCFLAGS' => '-fforce-mem -fforce-addr -fcaller-saves -fno-exceptions',
    'LIBS'	=> ["$FLTKLDFLAGS -L/usr/X11R6/lib -lX11 -lXext -lfltk -ldl -lm"],
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> "$FLTKINC -I/usr/X11R6/include",
     # e.g., '-I/usr/include/other'
#    'TYPEMAPS' => ['typemap'],
    'XSOPT'    => '',
    'XSPROTOARG'  => '',
);
