use 5.010001;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'IO::Pipe::Producer',
    VERSION_FROM      => 'lib/IO/Pipe/Producer.pm', # finds $VERSION
    PREREQ_PM         => {'IO::Pipe' => 1.13,
                          'Carp'     => 1.26,
                          'strict'   => 1.07,
                          'warnings' => 1.13,
                          'base'     => 2.18},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/IO/Pipe/Producer.pm', # get abstract from module
       AUTHOR         => 'Robert William Leach <rleach@princeton.edu>') : ()),
);
