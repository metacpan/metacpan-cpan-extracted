use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Hatena::Star::Mobile',
    VERSION_FROM      => 'lib/Hatena/Star/Mobile.pm',
    PREREQ_PM         => {
        URI::Escape => 0,
        LWP::UserAgent => 0,
        HTTP::Request => 0,
        JSON::Syck => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Hatena/Star/Mobile.pm', # retrieve abstract from module
       AUTHOR         => 'Junya Kondo <jkondo@hatena.com>') : ()),
);
