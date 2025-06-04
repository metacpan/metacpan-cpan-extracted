# vi:set ft=perl:
use strict;
use warnings;

return {
    NAME    => 'Dispatch::Class',
    AUTHOR  => q{Lukas Mai <l.mai@web.de>},
    LICENSE => 'perl',

    MIN_PERL_VERSION => '5.6.0',
    CONFIGURE_REQUIRES => {},
    BUILD_REQUIRES => {},
    TEST_REQUIRES => {
        'Test::More' => 0,
        'IO::Handle' => 0,
    },
    PREREQ_PM => {
        'warnings'       => 0,
        'strict'         => 0,
        'Exporter::Tiny' => 0,
        'Scalar::Util'   => 0,
    },

    depend => {
        Makefile => '$(VERSION_FROM)',
    },

    REPOSITORY => [ codeberg => 'mauke' ],
    BUGTRACKER => 'https://codeberg.org/mauke/Dispatch-Class/issues',
};
