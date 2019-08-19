use 5.10.0;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Geoffrey::Changelog::Yaml',
    AUTHOR             => q{Mario Zieschang <mziescha@cpan.org>},
    VERSION_FROM       => 'lib/Geoffrey/Changelog/Yaml.pm',
    LICENSE            => 'artistic_2',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.10.0,
    EXE_FILES          => [],
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0, },
    PREREQ_PM          => {
        'Geoffrey' => 0,
        'YAML'     => 0,
        'YAML::XS' => 0,
    },
    TEST_REQUIRES => {
        'Test::Exception' => 0,
        'Test::Requires'  => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://gitlab.com/mziescha/Geoffrey-Changelog-Yaml.git',
                web  => 'https://gitlab.com/mziescha/Geoffrey-Changelog-Yaml',
            },
        }
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Geoffrey-Changelog-Yaml-*' },
);
