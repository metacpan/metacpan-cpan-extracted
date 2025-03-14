# vi:set ft=perl:
use strict;
use warnings;

return {
    NAME    => 'Klonk',
    AUTHOR  => q{Lukas Mai <l.mai@web.de>},
    LICENSE => 'gpl_3',

    MIN_PERL_VERSION => '5.36.0',
    CONFIGURE_REQUIRES => {},
    BUILD_REQUIRES => {},
    TEST_REQUIRES => {
        'Test2::V0' => 0,
    },
    PREREQ_PM => {
        'Carp'                 => 0,
        'Function::Parameters' => 2,
        'HTML::Blitz'          => 0,
        'IO::Handle'           => 0,
        'Unicode::UTF8'        => 0,
        'constant'             => 0,
        'feature'              => 0,
        'parent'               => 0,
        'strict'               => 0,
        'warnings'             => 0,
    },

    depend => {
        Makefile => '$(VERSION_FROM)',
    },

    REPOSITORY => [ codeberg => 'mauke' ],
    BUGTRACKER => 'https://codeberg.org/mauke/Klonk/issues',
};
