use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Log::Facile',
    VERSION_FROM      => 'lib/Log/Facile.pm', # finds $VERSION
    LICENSE           => 'perl',
    PREREQ_PM         => {},
    ($] >= 5.005 ? 
      (ABSTRACT_FROM  => 'lib/Log/Facile.pm', 
       AUTHOR         => 'Kazuhiro Sera <webmaster@seratch.net>') : ()),
);
