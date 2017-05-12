use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Devel::Command::Viz',
    AUTHOR              => 'Joe McMahon <mcmahon@cpan.org>',
    VERSION_FROM        => 'lib/Devel/Command/Viz.pm',
    ABSTRACT_FROM       => 'lib/Devel/Command/Viz.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Devel::Command' => 0,
        'GraphViz::Data::Structure' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Devel-Command-Viz-*' },
);
