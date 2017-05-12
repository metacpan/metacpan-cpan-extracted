use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Geo::Google::StaticMaps::V2',
    VERSION_FROM => 'lib/Geo/Google/StaticMaps/V2.pm',
    AUTHOR       => 'Michael R. Davis (mdavis@stopllc.com)',
    ABSTRACT_FROM=> 'lib/Geo/Google/StaticMaps/V2.pm',
    PREREQ_PM    => {
                     'Test::Simple'       => 0.44,
                     'Package::New'       =>0,
                     'Path::Class'        =>0,
                     'URI'                =>0,
                     'LWP'                =>0,
                    },
);
