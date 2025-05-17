use strict;
use warnings;

return {
    NAME               => 'HTML::Blitz::Builder',
    AUTHOR             => q{Lukas Mai <l.mai@web.de>},
    LICENSE            => 'gpl_3',

    MIN_PERL_VERSION   => '5.20.0',
    CONFIGURE_REQUIRES => {},
    BUILD_REQUIRES     => {},
    TEST_REQUIRES      => {
        'Test2::V0' => 0,
    },
    PREREQ_PM          => {
        'constant' => 0,
        'feature'  => 0,
        'warnings' => 0,

        'Carp'     => 0,
        'Exporter' => '5.57',
    },

    REPOSITORY => [ codeberg => 'mauke' ],
    BUGTRACKER => 'https://codeberg.org/mauke/HTML-Blitz-Builder/issues',

    HARNESS_OPTIONS => ['j4'],
};
