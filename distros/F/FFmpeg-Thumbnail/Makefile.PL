use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'FFmpeg::Thumbnail',
    AUTHOR              => q{Brian Sauls <bbqsauls@cpan.org>},
    VERSION_FROM        => 'lib/FFmpeg/Thumbnail.pm',
    ABSTRACT_FROM       => 'lib/FFmpeg/Thumbnail.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Moose' => 1.14,
        'FFmpeg::Command' => 0.15,
        'Capture::Tiny' => 0.01,
        'Scalar::Util'  => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'FFmpeg-Thumbnail-*' },
);
