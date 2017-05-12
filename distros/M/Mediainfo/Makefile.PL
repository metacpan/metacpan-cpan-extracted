use 5.008008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Mediainfo',
    VERSION_FROM      => 'lib/Mediainfo.pm',
    PREREQ_PM         => { 'IPC::Open3'=>0, },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Mediainfo.pm',
       AUTHOR         => 'ChenGang <yikuyiku.com@gmail.com>') : ()),
);
