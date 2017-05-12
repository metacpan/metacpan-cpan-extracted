use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'EBook::EPUB::Lite',
    AUTHOR              => [q{Oleksandr Tymoshenko <gonzo@bluezbox.com>},
                            q{Marco Pessotto <melmothx@gmail.com>},
                           ],
    VERSION_FROM        => 'lib/EBook/EPUB/Lite.pm',
    ABSTRACT_FROM       => 'lib/EBook/EPUB/Lite.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'bsd')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Archive::Zip'  => 0,
        'Carp'          => 0,
        'UUID::Tiny'    => 0,
        'File::Copy'    => 0,
        'File::Find'    => 0,
        'File::Temp'    => 0,
        'Moo'           => 1,
        'Type::Tiny'    => 1,
        'Test::More'    => 0,
        'XML::Writer'   => 0,
    },
    META_ADD => {
        resources => {
                      repository => 'http://github.com/melmothx/EBook-EPUB-Lite',
                      homepage => 'http://amusewiki.org',
                      x_IRC => 'irc://chat.freenode.net/#amusewiki',
                      x_WebIRC => 'https://webchat.freenode.net/?channels=#amusewiki',
                     },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'EBook-EPUB-*' },
);
