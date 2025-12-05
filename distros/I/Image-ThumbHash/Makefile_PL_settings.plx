use strict;
use warnings;

return {
    NAME               => 'Image::ThumbHash',
    AUTHOR             => q{Lukas Mai <l.mai@web.de>},
    LICENSE            => 'perl',

    MIN_PERL_VERSION   => '5.10.0',
    CONFIGURE_REQUIRES => {},
    BUILD_REQUIRES     => {},
    PREREQ_PM          => {
        'strict'       => 0,
        'warnings'     => 0,
        'Carp'         => 0,
        'Exporter'     => 5.57,
        'MIME::Base64' => 0,
        'List::Util'   => 0,
    },
    TEST_REQUIRES      => {
        'FindBin'   => 0,
        'Test2::V0' => 0,
    },
    DEVELOP_REQUIRES   => {
        'Test::Pod' => 1.22,
        'Imager'    => 0,
    },

    REPOSITORY => [ codeberg => 'mauke' ],
    BUGTRACKER => 'https://codeberg.org/mauke/Image-ThumbHash/issues',
};
