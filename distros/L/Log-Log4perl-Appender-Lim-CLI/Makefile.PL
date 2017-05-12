use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Log::Log4perl::Appender::Lim::CLI',
    AUTHOR              => q{Jerry Lundström <lundstrom.jerry@gmail.com>},
    VERSION_FROM        => 'lib/Log/Log4perl/Appender/Lim/CLI.pm',
    ABSTRACT_FROM       => 'lib/Log/Log4perl/Appender/Lim/CLI.pm',
    (! eval { ExtUtils::MakeMaker->VERSION(6.3002) } ? () :
        (LICENSE => 'perl')
    ),
    (eval { ExtUtils::MakeMaker->VERSION(6.5503) } ?
    (
        BUILD_REQUIRES => {
            'Test::More' => 0,
            'Log::Log4perl' => 1,
            'Log::Log4perl::Appender' => 0
        },
        PREREQ_PM => {
            'Log::Log4perl' => 1,
            'Log::Log4perl::Appender' => 0
        }
    ) : (
        PREREQ_PM => {
            'Test::More' => 0,
            'Log::Log4perl' => 1,
            'Log::Log4perl::Appender' => 0
        }
    )),
    (! eval { ExtUtils::MakeMaker->VERSION(6.46) } ? () :
        (META_ADD => {
            resources => {
                homepage   => 'http://github.com/jelu/log-log4perl-appender-lim-cli/wiki',
                repository => 'http://github.com/jelu/log-log4perl-appender-lim-cli',
                bugtracker => 'http://github.com/jelu/log-log4perl-appender-lim-cli/issues',
            },
        })
    ),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Log-Log4perl-Appender-Lim-CLI-*' },
);
