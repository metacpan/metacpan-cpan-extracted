use 5.006;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'File::Format::RIFF',
    VERSION           => '1.0.1',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/File/Format/RIFF.pm', # retrieve abstract from module
       AUTHOR         => 'Paul Sturm <sturm@branewave.com>') : ()),
);
