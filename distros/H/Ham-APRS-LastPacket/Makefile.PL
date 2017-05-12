use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Ham::APRS::LastPacket',
    AUTHOR              => 'Brad McConahay N8QQ <brad@n8qq.com>',
    VERSION_FROM        => 'lib/Ham/APRS/LastPacket.pm',
    ABSTRACT_FROM       => 'lib/Ham/APRS/LastPacket.pm',
    LICENSE             => 'artistic2',
    PL_FILES            => {},
    PREREQ_PM => {
		'Test::More' => 0,
		'XML::Simple' => 0,
		'LWP::UserAgent' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Ham-APRS-LastPacket-*' },
);
