use 5.008005;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Kwiki::DisableWikiNames',
    VERSION_FROM      => 'lib/Kwiki/DisableWikiNames.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Kwiki/DisableWikiNames.pm', # retrieve abstract from module
       AUTHOR         => 'root <root@inasan.ru>') : ()),
);
