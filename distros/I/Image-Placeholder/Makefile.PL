use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Image::Placeholder',
    AUTHOR              => 'Mark Norman Francis <norm@cackhanded.net>',
    VERSION_FROM        => 'lib/Image/Placeholder.pm',
    ABSTRACT_FROM       => 'lib/Image/Placeholder.pm',
    PL_FILES            => {},
    EXE_FILES           => [ 'bin/placeholder' ],
    PREREQ_PM => {
        'Test::More'                 => 0,
        'Modern::Perl'               => 0,
        'version'                    => 0,
        'Moose'                      => 0,
        'MooseX::FollowPBP'          => 0,
        'MooseX::Method::Signatures' => 0,
        'GD'                         => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Image-Placeholder-*' },
);
