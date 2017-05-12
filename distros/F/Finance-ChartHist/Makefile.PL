use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Finance::ChartHist',
    AUTHOR              => 'Garth Douglass <garth@rubberband.org>',
    VERSION_FROM        => 'lib/Finance/ChartHist.pm',
    ABSTRACT_FROM       => 'lib/Finance/ChartHist.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Finance::QuoteHist' => 1.09,
        'Date::Simple' => 0,
        'GD::Graph' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Finance-ChartHist-*' },
);
