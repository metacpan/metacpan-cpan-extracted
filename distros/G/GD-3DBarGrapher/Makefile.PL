use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'GD::3DBarGrapher',
    AUTHOR              => 'S.I.Warhurst <swarhurst@cpan.org>',
    VERSION_FROM        => 'lib/GD/3DBarGrapher.pm',
    ABSTRACT_FROM       => 'lib/GD/3DBarGrapher.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'GD'         => '2.0.1',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'GD-3DBarGrapher-*' },
);
