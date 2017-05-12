use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'HTML::Laundry',
    AUTHOR        => 'Six Apart, Ltd. <scook@sixapart.com>',
    VERSION_FROM  => 'lib/HTML/Laundry.pm',
    ABSTRACT_FROM => 'lib/HTML/Laundry.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::Differences' => 0,
        'Test::More'        => 0,
        'Test::Exception'   => 0,
        'HTML::Entities'    => 0,
        'HTML::Parser'      => 0,
        'HTML::TreeBuilder' => 0,
        'Scalar::Util'      => 0,
        'URI'               => 0,
        'URI::Escape'       => 0,
        'URI::Split'        => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'HTML-Laundry-*' },
    META_MERGE => {
        'meta-spec' => { version => 2.0 },
        resources => {
            repository => {
                type => 'git',
                web => 'https://github.com/snark/html-laundry',
                url => 'https://github.com/snark/html-laundry',
            },
            bugtracker => {
                web => 'https://github.com/snark/html-laundry/issues',
            },
        },
    },
);
