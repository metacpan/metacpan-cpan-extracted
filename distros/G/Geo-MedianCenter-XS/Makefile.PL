use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Geo::MedianCenter::XS',
    VERSION_FROM      => 'lib/Geo/MedianCenter/XS.pm', # finds $VERSION
    PREREQ_PM         => {
      'Test::More'    =>  0,
    }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Geo/MedianCenter/XS.pm', # retrieve abstract from module
       AUTHOR         => 'Bjoern Hoehrmann <bjoern@hoehrmann.de>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
	# Insert -I. if you add *.h files later:
    INC               => '', # e.g., '-I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
    LICENSE           => 'perl',
    'dist'            => {
      PREOP     => 'chmod 600 Makefile.PL',
      TARFLAGS	=> '--group=cpan --owner=bjoern -cvf',
    },
);
