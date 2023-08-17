use strict;
use warnings;

return {
    NAME               => 'HTML::Blitz',
    AUTHOR             => q{Lukas Mai <l.mai@web.de>},
    LICENSE            => 'gpl_3',

    MIN_PERL_VERSION   => '5.24.0',
    CONFIGURE_REQUIRES => {},
    BUILD_REQUIRES     => {},
    TEST_REQUIRES      => {
        'Fcntl'         => 0,
        'File::Temp'    => '0.2307',
        'FindBin'       => 0,
        'Test2::API'    => 0,
        'Test2::V0'     => 0,
    },
    PREREQ_PM          => {
        'constant'             => 0,
        'feature'              => 0,
        'overload'             => 0,
        'strict'               => 0,
        'warnings'             => 0,
        'Carp'                 => 0,
        'Exporter'             => '5.57',
        'Function::Parameters' => '2',
        'List::Util'           => '1.33',
        'Scalar::Util'         => 0,
    },

    REPOSITORY => [ github => 'mauke' ],

    HARNESS_OPTIONS => ['j4'],
};
