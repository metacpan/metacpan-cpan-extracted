use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
    NAME          => 'Image::ExifTool::Location',
    AUTHOR        => 'Andy Armstrong <andy@hexten.net>',
    VERSION_FROM  => 'lib/Image/ExifTool/Location.pm',
    ABSTRACT_FROM => 'lib/Image/ExifTool/Location.pm',
    LICENSE       => 'perl',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Image::ExifTool' => '6.76',
        'Test::More'      => 0,
        'version'         => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Image-ExifTool-Location-*' },
);
