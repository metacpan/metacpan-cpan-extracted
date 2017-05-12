use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Math::SparseVector',
    VERSION_FROM      => 'lib/Math/SparseVector.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Math/SparseVector.pm', # retrieve abstract from module
       AUTHOR         => 'Amruta Purandare <amruta@cs.pitt.edu>; Ted Pedersen <tpederse@d.umn.edu>; Mahesh Joshi <joshi031@d.umn.edu>') : ()),
);
