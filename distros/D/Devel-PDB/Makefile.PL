use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Devel::PDB',
    VERSION_FROM      => 'lib/Devel/PDB.pm', # finds $VERSION
    PREREQ_PM         => {
    	'Curses::UI' => 0.95,
    	'Class::Accessor' => 0.25,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Devel/PDB.pm', # retrieve abstract from module
       AUTHOR         => 'Ivan Yat-Cheung Wong <email@ivanwong.info>') : ()),
);
