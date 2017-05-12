use strict;
use warnings;
use ExtUtils::MakeMaker;

my %conf = (
    NAME          => 'IO-AIO-Util',
    AUTHOR        => 'gray <gray@cpan.org>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/IO/AIO/Util.pm',
    ABSTRACT_FROM => 'lib/IO/AIO/Util.pm',
    PREREQ_PM     => {
        'File::Spec::Functions' => 0,
        'IO::AIO'               => 2,
        'POSIX'                 => 0,
        'Test::More'            => 0,
    },
    META_MERGE    => {
        resources => {
            repository => 'http://github.com/gray/io-aio-util',
        },
    },
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean         => { FILES => 'IO-AIO-Util-*' },
);

unless (eval { ExtUtils::MakeMaker->VERSION(6.46) }) {
    delete $conf{META_MERGE};
}

WriteMakefile(%conf);
