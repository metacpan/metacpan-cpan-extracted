use strict;
use warnings;

return {
    NAME   => 'File::Open',
    AUTHOR => q{Lukas Mai <l.mai@web.de>},

    CONFIGURE_REQUIRES => {},
    BUILD_REQUIRES => {},
    TEST_REQUIRES => {
        'if'          => 0,
        'open'        => 0,
        'File::Spec'  => 0,
        'File::Temp'  => '0.19',
        'IO::Handle'  => 0,
        'Test2::V0'   => 0,
    },
    PREREQ_PM => {
        'Carp'           => 0,
        'Errno'          => 0,
        'Exporter'       => 0,
        'Fcntl'          => 0,
        'File::Basename' => 0,
        'strict'         => 0,
        'warnings'       => 0,
    },
    DEVELOP_REQUIRES => {
        'Test::Pod' => 1.22,
    },

    REPOSITORY => [ github => 'mauke' ],
};
