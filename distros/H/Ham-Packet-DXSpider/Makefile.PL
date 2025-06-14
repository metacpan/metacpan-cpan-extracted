use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Ham::Packet::DXSpider',
    AUTHOR              => q{Bruce James <custard@cpan.org>},
    VERSION_FROM        => 'lib/Ham/Packet/DXSpider.pm',
    ABSTRACT_FROM       => 'lib/Ham/Packet/DXSpider.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    MIN_PERL_VERSION    => 5.006,
    PREREQ_PM => {
        'IO::Handle'    => 0,
        'IO::Socket'    => 0,
        'IO::Socket::INET' => 0,
        'POSIX'         => 0,
        'Moose'         => 0,
        'Test::More'    => 0,
        'Test::Pod'     => 0,
        'Test::Pod::Coverage' =>0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Ham-Packet-DXSpider-*' },
);
