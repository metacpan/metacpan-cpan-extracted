use 5.014002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Message::Passing::Filter::Regexp',
    VERSION_FROM      => 'lib/Message/Passing/Filter/Regexp.pm', # finds $VERSION
    PREREQ_PM         => {
        'Message::Passing' => 0.11,
        'Config::Tiny' => 0,
        'Regexp::Log' => 0,
        'JSON::Types' => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Message/Passing/Filter/Regexp.pm', # retrieve abstract from module
       AUTHOR         => 'chenryn <rao.chenlin@gmail.com>') : ()),
);
