use 5.001;
use ExtUtils::MakeMaker;
#
#  WARNING: Do not try to "make dist" under Windows; it destroys the Upper/lower CaSe of some files.
#
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
#
# Many thanks to Randy Kobes for helping me figure out how to make this work on multiple platforms
#

use Config;
my $os_src = ($^O =~ /Win32/) ? 'win/win' : 'linux/linux';
my $o = $Config{obj_ext};
my $c='.c';

my($libdir)= ($^O =~ /Win32/) ? '' : 'linux-labjack/liblabjack';
my($drvdir)= ($^O =~ /Win32/) ? '' : 'linux-labjack/driver';
my($tstdir)= ($^O =~ /Win32/) ? '' : 'linux-labjack/test';

# my $libs = ($^O =~ /Win32/) ? 'ljackuw.lib' : '-L./linux-labjack/liblabjack -llabjack -lm';
my $libs = ($^O =~ /Win32/) ? 'ljackuw.lib' : "-L$libdir -llabjack -lm";
my $def = ($^O =~ /Win32/) ? '-DLJWIN' : '-DLJLIN';  # See LabJack.pm - controls which header: linux-labjack/liblabjack/ljackul.h
my $inc = ($^O =~ /Win32/) ? '-I.' : "-I. -I$libdir";

my $obj = ($^O =~ /Win32/) ? '' : "$libdir/liblabjack.so";
my $lver = ($Config{osvers} =~/^2\.4/) ? 'linux-2.4' : 'linux-2.6';


sub MY::postamble {

  if($^O =~ /Win32/) {
    return '';
  } else {
    return "

$obj: $libdir/Makefile
	cd $drvdir/$lver && \$(MAKE) && echo `insmod labjack.o` && tail /var/log/messages
	cd $libdir && \$(MAKE)

";
  }
} # MY::postamble




WriteMakefile(
    NAME              => 'Device::LabJack',
    VERSION_FROM      => 'LabJack.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'LabJack.pm', # retrieve abstract from module
       AUTHOR         => 'Chris Drake <christopher@pobox.com>') : ()),
    LIBS              => [$libs], # e.g., '-lm'
    DEFINE            => $def, # e.g., '-DHAVE_SOMETHING'
    INC               => $inc, # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
#    OBJECT            => $obj, # link all the C files too
    'depend'	      => {'LabJack.c' => $obj},
    'clean'	      => {FILES => "$obj $libdir/ljackul.o $drvdir/$lver/labjack.o $tstdir/list-all $tstdir/firmware-revision $tstdir/analog-outs"},
);


if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw());
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Device::LabJack',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}

package MY;

sub c_o {
  my $inherited = shift->SUPER::c_o(@_);
  if($^O =~ /darwin/) {	# Mac
    # cc -Os -DLINUX -DOSX -isystem -I/usr/include   -c -o sslv3.o sslv3.c
    $inherited =~ s{\$\*.c\n}{\$\*.c -DOSX -isystem -I/usr/include -o\$\*.o\n}mg;
  } elsif($^O =~ /Win32/) {	# Microsoft
    $inherited =~ s{\$\*.c\n}{\$\*.c -Fo\$\*.obj\n}mg;
  } else {			# linux/other unicies: Tell the Makefile to put the .o files with the .c ones
    $inherited =~ s{\$\*.c\n}{\$\*.c -o\$\*.o\n}mg;
  }
  return $inherited;
}


