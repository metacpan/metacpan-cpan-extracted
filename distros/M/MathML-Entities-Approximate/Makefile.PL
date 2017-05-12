use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'MathML::Entities::Approximate',
    VERSION_FROM      => 'lib/MathML/Entities/Approximate.pm', # finds $VERSION
    PREREQ_PM         => {'Test::More'  =>  0,
                          'MathML::Entities' => 0,}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/MathML/Entities/Approximate.pm', # retrieve abstract from module
       AUTHOR         => 'Ian Stuart <Ian.Stuart@ed.ac.uk>') : ()),
);
