use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Geo::MapInfo::MIF::Writer::Region',
    VERSION_FROM => 'lib/Geo/MapInfo/MIF/Writer/Region.pm',
    AUTHOR       => 'Michael R. Davis (mdavis@stopllc.com)',
    ABSTRACT_FROM=> 'lib/Geo/MapInfo/MIF/Writer/Region.pm',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Package::New' => 0,
                     'DateTime'     => 0,
                     'Path::Class'  => 0,
                     'Text::CSV_XS' => 0,
                    },
);
