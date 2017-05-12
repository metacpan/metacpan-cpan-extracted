use 5.006;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME              => 'Math::SparseMatrix',
    VERSION_FROM      => 'lib/Math/SparseMatrix.pm', # finds $VERSION
    PREREQ_PM         => {Math::SparseVector => 0.01}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Math/SparseMatrix.pm', # retrieve abstract from module
       AUTHOR         => 'Ted Pedersen <tpederse at d.umn.edu>; Mahesh Joshi <maheshj@cmu.edu>') : ()),
  # allows make dist to create .tar.gz with correct name/version
   'dist'             => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'},
   # allows for automatic creation of META.yml
   ($ExtUtils::MakeMaker::VERSION ge '6.30_00'?
   ('LICENSE' => 'gpl', ) : ()),

);
