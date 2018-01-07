use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

my %write_makefile_param = (
    NAME             => 'JIP::Debug',
    AUTHOR           => q{Vladimir Zhavoronkov <flyweight@yandex.ru>},
    VERSION_FROM     => 'lib/JIP/Debug.pm',
    ABSTRACT_FROM    => 'lib/JIP/Debug.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    META_MERGE       => {
        'meta-spec'    => {version => 2},
        resources      => {
            license    => ['http://www.opensource.org/licenses/artistic-license-2.0'],
            bugtracker => {web => 'https://github.com/outtaspace/jip_debug/issues'},
            repository => {
                type => 'git',
                url  => 'https://github.com/outtaspace/jip_debug.git',
                web  => 'https://github.com/outtaspace/jip_debug',
            },
        },
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {},
    TEST_REQUIRES => {
        'English'         => 0,
        'Test::More'      => 0,
        'Capture::Tiny'   => 0,
        'Test::Exception' => 0,
        'Term::ANSIColor' => '3.0',
    },
    PREREQ_PM => {
        'Devel::StackTrace' => 0,
        'Term::ANSIColor'   => '3.0',
        'Exporter'          => 0,
        'English'           => 0,
        'Fcntl'             => 0,
        'Data::Dumper'      => 0,
        'Carp'              => 0,
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
    clean => {FILES => 'JIP-Debug-*'},
);

unless (eval { ExtUtils::MakeMaker->VERSION(6.63_03); }) {
    $write_makefile_param{PREREQ_PM} = {
        %{ delete $write_makefile_param{'TEST_REQUIRES'} },
        %{ delete $write_makefile_param{'BUILD_REQUIRES'} },
    };
}

unless (eval { ExtUtils::MakeMaker->VERSION(6.52) }) {
    delete $write_makefile_param{'CONFIGURE_REQUIRES'};
}

WriteMakefile(%write_makefile_param);

