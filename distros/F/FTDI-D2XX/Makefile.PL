use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'FTDI::D2XX',
    VERSION_FROM      => 'lib/FTDI/D2XX.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/FTDI/D2XX.pm', # retrieve abstract from module
       AUTHOR         => 'Matthias Voelker <mvoelker@cpan.org>') : ()),
    LIBS              => ['-lftd2xx'], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I. -I/usr/include -I/usr/local/include -I..', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
#    OBJECT            => '$(O_FILES)', # link all the C files too
);
