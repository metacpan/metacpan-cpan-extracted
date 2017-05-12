use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Hardware::SensorsParser',
    AUTHOR              => q{"Davide Ticozzi" <"dticozzi@gmail.com">},
    VERSION_FROM        => 'lib/Hardware/SensorsParser.pm',
    ABSTRACT_FROM       => 'lib/Hardware/SensorsParser.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Hardware-SensorsParser-*' },
);
