#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Image::Imlib2::Thumbnail',
    VERSION_FROM => 'lib/Image/Imlib2/Thumbnail.pm',
    AUTHOR       => 'Leon Brocard <acme@astray.com>',
    ABSTRACT     => 'Generate a set of thumbnails of an image',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'Class::Accessor::Fast' => '0',
        'Image::Imlib2'         => '2.00',
        'MIME::Types'           => '0',
        'Path::Class'           => '0',
    }
);

