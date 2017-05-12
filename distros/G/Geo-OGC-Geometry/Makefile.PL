use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	     => 'Geo::OGC::Geometry',
    AUTHOR           => 'Ari Jolma https://github.com/ajolma',
    VERSION_FROM     => 'lib/Geo/OGC/Geometry.pm',
    ABSTRACT_FROM    => 'lib/Geo/OGC/Geometry.pm',
    LICENSE          => 'perl_5',
    META_MERGE       => {
        'meta-spec' => { version => 2 },
        resources => {
            repository  => {
                type => 'git',
                web  => 'https://github.com/ajolma/Geo-OGC-Geometry',
                url  => 'https://github.com/ajolma/Geo-OGC-Geometry.git',
            },
        },
    }
    );
