use 5.006;
eval 'use Inline::MakeMaker';
die "Inline required for building XS" if $@;
WriteMakefile(
    NAME         => 'Image::GeoTIFF::Tiled',
    VERSION_FROM => 'Tiled.pm',                # finds $VERSION
    ABSTRACT  => 'Read data and extract shapes from tiled GeoTIFF rasters',
    PREREQ_PM => {
        Module::Load    => 0.18,
        List::MoreUtils => 0.22,
        Inline          => 0.46,
    },
    INC  => '-I/usr/include/geotiff',
    LIBS => [ qw( -ltiff -lgeotiff ) ],
    AUTHOR  => 'Blake Willmarth <bwillmarth@gmail.com>',
    LICENSE => 'perl',
);
