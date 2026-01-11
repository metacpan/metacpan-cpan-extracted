use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Hax::Alg::RollingWindow',
    DISTNAME     => 'Hax-Alg-RollingWindow',
    VERSION_FROM => 'lib/Hax/Alg/RollingWindow.pm',
    ABSTRACT     => 'Fixed-capacity rolling window (overwrite-oldest)',
    AUTHOR       => 'Joshua S. Day',
    LICENSE      => 'perl',

    PREREQ_PM    => {},

    TEST_REQUIRES => {
        'Test::More'   => 0,
        'Scalar::Util' => 0,
    },

     # Metadata consumed by MetaCPAN
    META_MERGE => {
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/haxmeister/Hax-Alg-RollingWindow.git',
                web  => 'https://github.com/haxmeister/Hax-Alg-RollingWindow',
            },
            bugtracker => {
                web => 'https://github.com/haxmeister/Hax-Alg-RollingWindow/issues',
            },
            homepage => 'https://github.com/haxmeister/Hax-Alg-RollingWindow',
        },
    },

);
