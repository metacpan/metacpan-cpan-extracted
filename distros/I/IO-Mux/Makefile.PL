use 5.008 ;
use ExtUtils::MakeMaker ;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'IO::Mux',
    VERSION_FROM      => 'lib/IO/Mux.pm', # finds $VERSION
    PREREQ_PM         => {
	}, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/IO/Mux.pm', # retrieve abstract from module
       AUTHOR         => 'Patrick LeBoutillier <patl@cpan.org>') : ()),
);
