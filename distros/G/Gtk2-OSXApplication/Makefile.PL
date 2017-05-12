use 5.012003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $skip=shift @ARGV;

my $inc;
my $lib;
my $os;

if ($skip ne "skip") {
  open my $fh,"pkg-config --cflags gtk-mac-integration |";
  $inc=<$fh>;
  chomp $inc;
  close $fh;

  open $fh,"pkg-config --libs gtk-mac-integration |";
  $lib=<$fh>;
  chomp $lib;
  close $fh;

  $os=$^O;
  if ($os ne "darwin") {
    die "This module is only for OS X";
  }
}

WriteMakefile(
    NAME              => 'Gtk2::OSXApplication',
    VERSION_FROM      => 'lib/Gtk2/OSXApplication.pm', # finds $VERSION
    PREREQ_PM         => { Gtk2 => 1.2 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Gtk2/OSXApplication.pm', # retrieve abstract from module
       AUTHOR         => 'Hans Oesterholt <oesterhol@cpan.org>') : ()),
    LIBS              => [$lib], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    #INC               => '-I.'." $inc $perl2gtkInc", # e.g., '-I. -I/usr/include/other'
    INC               => '-I.'." $inc", # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);

# Work around a OS X bug (Lion)
if ($os eq "darwin") {
  print "Fixing i386 bug for OSX\n";
  open my $fh,"<Makefile"; 
  open my $fout,">Makefile.ff";
  while (my $line=<$fh>) {
    $line=~s/[-]arch[ ]i386//;
    print $fout $line;
  }
  close $fh;
  close $fout;
  open $fh,"<Makefile.ff";
  open $fout,">Makefile";
  while (my $line=<$fh>) { print $fout $line; }  
  close $fh; 
  close $fout; 
  unlink("Makefile.ff");
}




if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(GTK_TYPE_OSX_APPLICATION
		 GTK_TYPE_OSX_APPLICATION_ATTENTION_TYPE),
              {name=>"CRITICAL_REQUEST", macro=>"1"},
              {name=>"INFO_REQUEST", macro=>"1"});
#  ExtUtils::Constant::WriteConstants(
#                                     NAME         => 'Gtk2::OSXApplication',
#                                     NAMES        => \@names,
#                                     DEFAULT_TYPE => 'IV',
#                                     C_FILE       => 'const-c.inc',
#                                     XS_FILE      => 'const-xs.inc',
#                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
