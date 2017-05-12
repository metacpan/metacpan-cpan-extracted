use 5.012003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $CC = "g++";

WriteMakefile(
    NAME              => 'Image::SubImageFind',
    VERSION_FROM      => 'lib/Image/SubImageFind.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Image/SubImageFind.pm', # retrieve abstract from module
       AUTHOR         => 'Dennis K. Paulsen <ctrondlp@cpan.org>') : ()),
	CC => $CC,
	LD => '$(CC)',
	XSOPT => '-C++',
    LIBS => ['-lefence -lstdc++ -lfftw3 -lm '. `Magick++-config --ldflags --libs`],
    INC => '`Magick++-config --cppflags --cxxflags` -mpreferred-stack-boundary=8 -I procs/',
    TYPEMAPS => ['perlobject.map'],
	# Un-comment this if you add C files to link with later:
    OBJECT            => '$(O_FILES)', # link all the C files too
);

