use 5.014002;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Message::Passing::Output::PocketIO',
    VERSION_FROM      => 'lib/Message/Passing/Output/PocketIO.pm', # finds $VERSION
    PREREQ_PM         => {
        'PocketIO' => 0,
        'PocketIO::Client::IO' => 0,
        'Data::Section::Simple' => 0,
        'Message::Passing' => 0,
        'AnyMQ' => 0,
        'JSON' => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Message/Passing/Output/PocketIO.pm', # retrieve abstract from module
       AUTHOR         => 'chenryn <chenryn@>') : ()),
);
