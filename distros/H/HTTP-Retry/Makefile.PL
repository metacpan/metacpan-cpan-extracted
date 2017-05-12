use 5.008008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'HTTP::Retry',
    VERSION_FROM      => 'lib/HTTP/Retry.pm',
    PREREQ_PM         => { 'HTTP::Tiny' => 0.017 }, 
    ($] >= 5.005 ?     
      (ABSTRACT_FROM  => 'lib/HTTP/Retry.pm', 
       AUTHOR         => 'Chen Gang <yikuyiku.com@gmail.com>') : ()),
);
