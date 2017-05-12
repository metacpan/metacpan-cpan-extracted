use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Device::SpaceNavigator',
    AUTHOR              => q{Kay Bærulfsen <kaysb@cpan.org>},
    VERSION_FROM        => 'lib/Device/SpaceNavigator.pm',
    ABSTRACT_FROM       => 'lib/Device/SpaceNavigator.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Device-SpaceNavigator-*' },
);
