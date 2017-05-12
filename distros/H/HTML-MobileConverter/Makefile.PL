use 5.008005;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'HTML::MobileConverter',
    VERSION_FROM      => 'lib/HTML/MobileConverter.pm', # finds $VERSION
    PREREQ_PM         => {
        HTML::Parser => 3.45,
        URI => 1.33,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/HTML/MobileConverter.pm', # retrieve abstract from module
       AUTHOR         => 'Junya Kondo <jkondo@hatena.ne.jp>') : ()),
);
