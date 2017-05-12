use strict;
use warnings;
use ExtUtils::MakeMaker;

my %conf = (
    NAME             => 'Filesys::DiskUsage',
    AUTHOR           => 'Jose Castro <cog@cpan.org>',
    VERSION_FROM     => 'lib/Filesys/DiskUsage.pm',
    ABSTRACT_FROM    => 'lib/Filesys/DiskUsage.pm',
    EXE_FILES        => [ 'fdu' ],
    MIN_PERL_VERSION => 5.006,
    BUILD_REQUIRES   => {
        'Test::More' => 0,
        'Test::Warn' => 0,
        'File::Temp' => 0,
        'File::Find' => 0,
    },
    PREREQ_PM => {
        'File::Basename' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Filesys-DiskUsage-*' },
);

if (eval { ExtUtils::MakeMaker->VERSION(6.3002) }) {
    $conf{LICENSE} = 'perl';
}

if (eval { ExtUtils::MakeMaker->VERSION(6.46) }) {
    $conf{META_MERGE} = {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'http://github.com/manwar/Filesys-DiskUsage.git',
                web  => 'http://github.com/manwar/Filesys-DiskUsage',
            },
        },
    };
}

WriteMakefile(%conf);
