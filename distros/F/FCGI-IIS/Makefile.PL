use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'FCGI::IIS',
    VERSION_FROM      => 'lib/FCGI/IIS.pm', # finds $VERSION
    PREREQ_PM         => {
        'FCGI'  => '0',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/FCGI/IIS.pm', # retrieve abstract from module
       AUTHOR         => 'Lyle Hopkins bristol.pm bath.pm') : ()),
);
