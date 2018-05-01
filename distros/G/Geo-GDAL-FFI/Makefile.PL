use Alien::gdal;
use ExtUtils::MakeMaker;
use Alien::Base::Wrapper qw( Alien::gdal !export );
use Config;
 
WriteMakefile(
    NAME => 'Geo::GDAL::FFI',
    VERSION_FROM => "lib/Geo/GDAL/FFI.pm",
    Alien::Base::Wrapper->mm_args,
    CONFIGURE_REQUIRES => {
        'Alien::gdal' => 0
    },
    PREREQ_PM => {
        'FFI::Platypus' => 0,
        'Alien::gdal' => 0,
        'PDL' => 0
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
        'JSON' => 0,
        'Data::Dumper' => 0
    },
    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/ajolma/Geo-GDAL-FFI.git',
                web => 'https://github.com/ajolma/Geo-GDAL-FFI',
            },
        },
    },
);
