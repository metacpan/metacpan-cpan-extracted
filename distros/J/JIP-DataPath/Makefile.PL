use 5.010001;
use strict;
use warnings FATAL => 'all';

use ExtUtils::MakeMaker;

my %makefile_param = (
    NAME             => 'JIP::DataPath',
    AUTHOR           => q{Volodymyr Zhavoronkov <flyweight@yandex.ru>},
    VERSION_FROM     => 'lib/JIP/DataPath.pm',
    ABSTRACT_FROM    => 'lib/JIP/DataPath.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.010001',
    META_MERGE       => {
        'meta-spec' => { version => 2 },
        resources   => {
            license    => ['http://www.opensource.org/licenses/artistic-license-2.0'],
            bugtracker => { web => 'https://github.com/outtaspace/jip_datapath/issues' },
            repository => {
                type => 'git',
                url  => 'https://github.com/outtaspace/jip_datapath.git',
                web  => 'https://github.com/outtaspace/jip_datapath',
            },
        },
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {},
    TEST_REQUIRES  => {
        English      => 0,
        'Test::More' => 0,
    },
    PREREQ_PM => {
        Exporter => 5.57,
        English  => 0,
        Carp     => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES    => 'JIP-DataPath-*' },
);

if ( !eval { ExtUtils::MakeMaker->VERSION(6.63_03); } ) {
    $makefile_param{PREREQ_PM} = {
        %{ delete $makefile_param{'TEST_REQUIRES'} },
        %{ delete $makefile_param{'BUILD_REQUIRES'} },
    };
}

if ( !eval { ExtUtils::MakeMaker->VERSION(6.52) } ) {
    delete $makefile_param{'CONFIGURE_REQUIRES'};
}

if ( !eval { ExtUtils::MakeMaker->VERSION(6.48) } ) {
    delete $makefile_param{'MIN_PERL_VERSION'};
}

WriteMakefile(%makefile_param);

