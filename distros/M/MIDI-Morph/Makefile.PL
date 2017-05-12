use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MIDI::Morph',
    AUTHOR              => 'Christian Renz <crenz@web42.com>',
    VERSION_FROM        => 'lib/MIDI/Morph.pm',
    ABSTRACT_FROM       => 'lib/MIDI/Morph.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'MIDI'       => 0.8,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MIDI-Morph-*' },
);
