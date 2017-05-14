use 5.000005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'FLAT',
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
       ( #ABSTRACT_FROM  => 'lib/FLAT.pm',  
         AUTHOR         => '.o0o. <estrabd@mailcan.com>') : ()),
);
