use 5.018;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME               => 'Disk::SmartTools',
    AUTHOR             => q{Matt Martini <matt@imaginarywave.com>},
    VERSION_FROM       => 'lib/Disk/SmartTools.pm',
    ABSTRACT_FROM      => 'lib/Disk/SmartTools.pm',
    LICENSE            => 'gpl_3',
    MIN_PERL_VERSION   => '5.018',
    BUILD_REQUIRES     => { 'ExtUtils::MakeMaker' => '0', },
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => '0', },

    # EXE_FILES          => [ 'bin/smart_show.pl', 'bin/smart_run_tests.pl' ],
    PREREQ_PM => {     'Dev::Util'            => '2.19.12',
                       'Carp'                 => '1.50',
                       'Data::Dumper::Simple' => '0.11',
                       'Data::Printer'        => '1.002001',
                       'English'              => 0,
                       'Exporter'             => 0,
                       'Getopt::Long'         => 0,
                       'IPC::Cmd'             => '1.04',
                       'Path::Tiny'           => '0.148',
                       'Readonly'             => '2.05',
                       'Term::ANSIColor'      => '5.01',
                       'Term::ReadKey'        => '2.38',
                       'YAML::PP'             => '0.39.0',
                       'autodie'              => 0,
                       'strict'               => 0,
                       'utf8'                 => 0,
                       'version'              => 0,
                       'warnings'             => 0,
                 },
    TEST_REQUIRES => {     'ExtUtils::Manifest'            => 0,
                           'Test2::Require::AuthorTesting' => '1.302219',
                           'Test2::V0'                     => '1.302219',
                           'Test::More'                    => '1.302219',
                     },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {  repository => {
                                  type => 'git',
                                  url => 'https://github.com/mattmartini/Disk-SmartTools.git',
                                  web => 'https://github.com/mattmartini/Disk-SmartTools'
                          },
                     }
                  },
    MAN1PODS => {     'examples/smart_show.pl'      => 'blib/man1/smart_show.1',
                      'examples/smart_run_tests.pl' => 'blib/man1/smart_run_tests.1'
                },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Disk-SmartTools-*' },
    ## NOECHO => '', # make debug output if empty
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless ( eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 } ) {
    my $test_requires = delete $WriteMakefileArgs{ TEST_REQUIRES } || {};
    @{ $WriteMakefileArgs{ PREREQ_PM } }{ keys %$test_requires }
        = values %$test_requires;
}

unless ( eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 } ) {
    my $build_requires = delete $WriteMakefileArgs{ BUILD_REQUIRES } || {};
    @{ $WriteMakefileArgs{ PREREQ_PM } }{ keys %$build_requires }
        = values %$build_requires;
}

delete $WriteMakefileArgs{ CONFIGURE_REQUIRES }
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{ MIN_PERL_VERSION }
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{ LICENSE }
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);

