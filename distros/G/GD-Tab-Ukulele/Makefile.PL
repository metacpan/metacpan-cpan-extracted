use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'GD::Tab::Ukulele',
    AUTHOR              => 'Yuichi Tateno <hotchpotch@gmail.com>',
    VERSION_FROM        => 'lib/GD/Tab/Ukulele.pm',
    ABSTRACT_FROM       => 'lib/GD/Tab/Ukulele.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'            => 0,
        'Class::Accessor::Fast' => 0,
        'List::Util'            => 0,
        'GD'                    => 2.30,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'GD-Tab-Ukulele-*' },
);
