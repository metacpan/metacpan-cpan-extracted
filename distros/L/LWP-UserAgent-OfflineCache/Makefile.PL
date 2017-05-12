use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'LWP::UserAgent::OfflineCache',
    AUTHOR        => 'Dmytro Gorbunov <gdm@savesources.com>',
    VERSION_FROM  => 'lib/LWP/UserAgent/OfflineCache.pm',
    ABSTRACT_FROM => 'lib/LWP/UserAgent/OfflineCache.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ('LICENSE' => 'perl')
        : ()),
    PL_FILES  => {},
    PREREQ_PM => {
        'Moose'              => 0,
        'IO::All'            => 0,
        'LWP::UserAgent'     => 0,
        'LWP'                => 0,
        'Log::Log4perl'      => 0,
        'HTTP::Message'      => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'LWP-UserAgent-* cache/*' },
);
