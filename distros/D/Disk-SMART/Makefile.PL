use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Disk::SMART',
    AUTHOR           => 'Paul Trost <ptrost@cpan.org>',
    VERSION_FROM     => 'lib/Disk/SMART.pm',
    MIN_PERL_VERSION => '5.010',
    ABSTRACT_FROM    => 'lib/Disk/SMART.pm',
    PL_FILES         => {},
    TEST_REQUIRES => {
        'Test::More'          => 0,
        'Test::Fatal'         => 0,
        'Test::Pod'           => 0,
        'Test::Pod::Coverage' => 0,
        'Test::MockModule'    => 0,
    },
    PREREQ_PM => {
        'Math::Round' => 0,
        'Carp'        => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/paultrost/Disk-SMART-Perl.git',
                web  => 'https://github.com/paultrost/Disk-SMART-Perl',
            },
        },
        license => ['gpl_2'],
        dist    => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
        clean   => { FILES => 'Disk-SMART-*' },
        prereqs => {
            runtime => {
                requires => {
                    'perl'        => '5.010',
                    'Carp'        => 0,
                    'Math::Round' => 0,
                    'File::Which' => 0,
                }
            },
            test => {
                requires => {
                    'Test::More'          => 0,
                    'Test::Fatal'         => 0,
                    'Test::Pod'           => 0,
                    'Test::Pod::Coverage' => 0,
                    'Test::MockModule'    => 0,
                }
            }
        }
    }
);
