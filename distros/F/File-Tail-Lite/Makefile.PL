use 5.008008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'File::Tail::Lite',
    VERSION_FROM      => 'lib/File/Tail/Lite.pm',
    PREREQ_PM         => {},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/File/Tail/Lite.pm',
       AUTHOR         => 'ChenGang <yikuyiku.com@gmail.com>') : ()),
);
