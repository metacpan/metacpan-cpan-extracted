use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Device::BCM2835::LCD',
    AUTHOR              => q{Joshua Small <festy@cpan.org>},
    VERSION_FROM        => 'lib/Device/BCM2835/LCD.pm',
    ABSTRACT_FROM       => 'lib/Device/BCM2835/LCD.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
	'Device::BCM2835' => 1.3,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Device-BCM2835-LCD-*' },
);
