use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'LWP::UserAgent::Tor',
    AUTHOR           => q{spebern <bernhard@specht.net>},
    VERSION_FROM     => 'lib/LWP/UserAgent/Tor.pm',
    ABSTRACT_FROM    => 'lib/LWP/UserAgent/Tor.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'LWP::UserAgent'       => 0,
        'IO::Socket::INET'     => 0,
        'LWP::Protocol::socks' => 0,
        'Test::Exception'      => 0,
        'Net::EmptyPort'       => 0,
        'File::Which'          => 0,
        'Proc::Background'     => 0,
        'File::MMagic'         => 0,
        'Path::Tiny'           => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'LWP-UserAgent-Tor-*' },
    META_MERGE        => {
        x_contributors => [
            'Bernhard Specht <bernhard@specht.net>',
            'Chris',
        ],
    },
);
