use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $cflags = `mm-config --cflags`;
my $ldflags = `mm-config --ldflags`;
my $libs = `mm-config --libs`;
WriteMakefile(
    'NAME'	=> 'IPC::MM',
    'VERSION_FROM' => 'MM.pm', # finds $VERSION
    'LIBS'	=> ["$ldflags $libs"],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> $cflags,     # e.g., '-I/usr/include/other' 
);
