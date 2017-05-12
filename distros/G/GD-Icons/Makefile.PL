use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'GD::Icons',
    AUTHOR              => 'Payan Canaran <pcanaran@cpan.org>',
    VERSION_FROM        => 'lib/GD/Icons.pm',
    ABSTRACT_FROM       => 'lib/GD/Icons.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'      => 0,
        'Config::General' => 0,
        'GD'              => 0,
        'Tie::IxHash'     => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'GD-Icons-*' },
);
