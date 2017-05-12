use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'FFmpeg::Command',
    AUTHOR              => 'Gosuke Miyashita <gosukenator@gmail.com>',
    VERSION_FROM        => 'lib/FFmpeg/Command.pm',
    ABSTRACT_FROM       => 'lib/FFmpeg/Command.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'            => 0,
        'Class::Accessor::Fast' => 0,
        'Class::ErrorHandler'   => 0,
        'IPC::Run'              => 0,
        'MIME::Types'           => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'FFmpeg-Command-*' },
);
