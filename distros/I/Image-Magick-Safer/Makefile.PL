#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Image::Magick::Safer',
    VERSION_FROM     => 'lib/Image/Magick/Safer.pm',
    AUTHOR           => 'Lee Johnson <leejo@cpan.org>',
    LICENSE          => 'perl',
    PREREQ_PM => {
        'File::LibMagic' => 1.15,
    },
    BUILD_REQUIRES => {
    },
    META_MERGE => {
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            homepage   => 'https://metacpan.org/module/Image::Magick::Safer',
            bugtracker => 'https://github.com/Humanstate/image-magick-safer/issues',
            repository => 'https://github.com/Humanstate/image-magick-safer'
        },
    },
    test => {
        RECURSIVE_TEST_FILES => 1,
    },
);

# vim: ts=4:sw=4:et
