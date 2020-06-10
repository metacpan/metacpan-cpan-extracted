use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

my %makefile_param = (
    NAME             => 'JIP::LockFile',
    AUTHOR           => q{Vladimir Zhavoronkov <flyweight@yandex.ru>},
    VERSION_FROM     => 'lib/JIP/LockFile.pm',
    ABSTRACT_FROM    => 'lib/JIP/LockFile.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    META_MERGE       => {
        'meta-spec'    => {version => 2},
        resources      => {
            license    => ['http://www.opensource.org/licenses/artistic-license-2.0'],
            bugtracker => {web => 'https://github.com/outtaspace/jip_lockfile/issues'},
            repository => {
                type => 'git',
                url  => 'https://github.com/outtaspace/jip_lockfile.git',
                web  => 'https://github.com/outtaspace/jip_lockfile',
            },
        },
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {},
    TEST_REQUIRES => {
        'Test::More' => 0,
        'English'    => 0,
        'File::Temp' => 0,
    },
    PREREQ_PM => {
        'Carp'            => 0,
        'Fcntl'           => 0,
        'English'         => 0,
        'IO::File'        => 0,
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
    clean => {FILES => 'JIP-LockFile-*'},
);

if (!eval { ExtUtils::MakeMaker->VERSION(6.63_03); }) {
    $makefile_param{PREREQ_PM} = {
        %{ delete $makefile_param{'TEST_REQUIRES'} },
        %{ delete $makefile_param{'BUILD_REQUIRES'} },
    };
}

if (!eval { ExtUtils::MakeMaker->VERSION(6.52) }) {
    delete $makefile_param{'CONFIGURE_REQUIRES'};
}

WriteMakefile(%makefile_param);

