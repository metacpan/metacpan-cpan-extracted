use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

open my $fh,"pkg-config --cflags appindicator-0.1 gtk+-2.0 2>/dev/null |";
my $inc=<$fh>;
chomp $inc;
close $fh;

open $fh,"pkg-config --libs appindicator-0.1 gtk+-2.0 2>/dev/null |";
my $lib=<$fh>;
chomp $lib;
close $fh;

if (not($inc)) {
	die "pkg-config --cflags appindicator-0.1 gtk+-2.0 didn't succeed, make sure it is righly installed";
}


WriteMakefile(
    NAME              => 'Gtk2::AppIndicator',
    VERSION_FROM      => 'lib/Gtk2/AppIndicator.pm', # finds $VERSION
    PREREQ_PM         => { Gtk2 => 1.2 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Gtk2/AppIndicator.pm', # retrieve abstract from module
       AUTHOR         => 'Hans Oesterholt <oesterhol@cpan.org>') : ()),
    LIBS              => [$lib], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    #INC               => '-I.'." $inc $perl2gtkInc", # e.g., '-I. -I/usr/include/other'
    INC               => '-I.'." $inc", # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);

if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}

