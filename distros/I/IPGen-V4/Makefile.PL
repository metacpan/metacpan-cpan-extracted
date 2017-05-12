use 5.005;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'IPGen::V4',
    VERSION_FROM      => 'lib/IPGen/V4.pm', # finds $VERSION
    PREREQ_PM         => {'Test'        =>  0, }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/IPGen/V4.pm', # retrieve abstract from module
       AUTHOR         => 'Sadegh Ahmadzadegan <sadegh.ahm@gmail.com>') : ()),
);
