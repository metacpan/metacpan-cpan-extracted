use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Graphics::GnuplotIF::Shortcut',
    AUTHOR              => 'Boris Zentner <bzm@2bz.de>',
    VERSION_FROM        => 'lib/Graphics/GnuplotIF/Shortcut.pm',
    ABSTRACT_FROM       => 'lib/Graphics/GnuplotIF/Shortcut.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Graphics::GnuplotIF'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Graphics-GnuplotIF-Shortcut-*' },
);
