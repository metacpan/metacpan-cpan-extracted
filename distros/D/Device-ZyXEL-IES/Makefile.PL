use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Device::ZyXEL::IES',
    AUTHOR              => 'Jesper Dalberg <jdalberg@gmail.com>',
    VERSION_FROM        => 'lib/Device/ZyXEL/IES.pm',
    ABSTRACT_FROM       => 'lib/Device/ZyXEL/IES.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'SNMP' => 0,
        'Capture::Tiny' => 0,
        'Net::SNMP::Util' => 0,
        'namespace::autoclean' => 0,
        'Moose' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Device-ZyXEL-IES-*' },
);
