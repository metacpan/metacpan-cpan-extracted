use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'EXE_FILES'         => ['ls2.pl'],
    'MAN3PODS'          => {'Ext2.pm'=>'blib/man3/Filesys::Ext2.3pm'},
    'NAME'		=> 'Filesys::Ext2',
    'VERSION_FROM'	=> 'Ext2.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'LIBS'		=> [''], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '', # e.g., '-I/usr/include/other'
);
