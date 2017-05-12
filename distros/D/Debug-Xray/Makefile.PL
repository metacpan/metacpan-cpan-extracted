use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Debug::Xray',
    AUTHOR              => q{Dave Carvell <dave_carvell@yahoo.com>},
    VERSION_FROM        => 'lib/Debug/Xray.pm',
    ABSTRACT_FROM       => 'lib/Debug/Xray.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Debug-Xray-*' },
);
