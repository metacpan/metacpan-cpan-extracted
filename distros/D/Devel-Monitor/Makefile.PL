use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Devel::Monitor',
    VERSION_FROM      => 'lib/Devel/Monitor.pm', # finds $VERSION
    PREREQ_PM         => {'Error'       => 0.15,
                          'Tie::Scalar' => 1.00,  #For TestScalar only
                          'Tie::Hash'   => 1.01,  #For TestHash only
                          'Tie::Array'  => 1.03}, #For TestArray only
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Devel/Monitor.pm', # retrieve abstract from module
       AUTHOR         => 'Philippe Cote <philippe.cote@usherbrooke.ca>') : ()),
);
