use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'JIP::LockSocket',
    AUTHOR           => q{Vladimir Zhavoronkov <flyweight@yandex.ru>},
    VERSION_FROM     => 'lib/JIP/LockSocket.pm',
    ABSTRACT_FROM    => 'lib/JIP/LockSocket.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'English'    => 0,
    },
    PREREQ_PM => {
        'Carp'            => 0,
        'Socket'          => 0,
        'English'         => 0,
        'JIP::ClassField' => '0.03',
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
    clean => {FILES => 'JIP-LockSocket-*'},
);

