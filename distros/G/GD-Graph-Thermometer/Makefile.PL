use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'GD::Graph::Thermometer',
    AUTHOR              => 'Hugh Esco <hesco@campaignfoundations.com>',
    VERSION_FROM        => 'lib/GD/Graph/Thermometer.pm',
    ABSTRACT_FROM       => 'lib/GD/Graph/Thermometer.pm',
    PL_FILES            => {},
    PREREQ_PM => {
          'Test::More' => 0,
             'version' => 0,
                  'GD' => 0,
     'GD::Text::Align' => 0,
# 'Test::Perl::Critic' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'GD-Graph-Thermometer-*' },
);
