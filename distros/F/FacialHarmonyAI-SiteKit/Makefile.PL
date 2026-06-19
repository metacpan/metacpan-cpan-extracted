use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'FacialHarmonyAI::SiteKit',
    VERSION_FROM  => 'lib/FacialHarmonyAI/SiteKit.pm',
    ABSTRACT      => 'URL helpers and metadata for FacialHarmonyAI',
    AUTHOR        => 'FacialHarmonyAI',
    LICENSE       => 'mit',
    MIN_PERL_VERSION => '5.010',
    PREREQ_PM     => {
        'URI::Escape' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    META_MERGE    => {
        'meta-spec' => { version => 2 },
        resources => {
            homepage   => 'https://facialharmonyai.com',
            repository => {
                type => 'git',
                url  => 'https://github.com/bbwdadfg/facialharmonyai-site-kit.git',
                web  => 'https://github.com/bbwdadfg/facialharmonyai-site-kit',
            },
            bugtracker => {
                web => 'https://github.com/bbwdadfg/facialharmonyai-site-kit/issues',
            },
        },
    },
);

