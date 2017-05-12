use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Kwiki::EscapeURI',
    VERSION_FROM      => 'lib/Kwiki/EscapeURI.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Kwiki/EscapeURI.pm', # retrieve abstract from module
       AUTHOR         => 'Kazuhiro Osawa <ko@yappo.ne.jp>') : ()),
);
