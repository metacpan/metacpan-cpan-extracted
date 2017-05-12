#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Image::Imlib2::Thumbnail::S3',
    VERSION_FROM => 'lib/Image/Imlib2/Thumbnail/S3.pm',
    AUTHOR       => 'Leon Brocard <acme@astray.com>',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'File::Temp'                 => '0.19',
        'Image::Imlib2::Thumbnail'   => '0.32',
        'Net::Amazon::S3'            => '0.41',
    }
);

