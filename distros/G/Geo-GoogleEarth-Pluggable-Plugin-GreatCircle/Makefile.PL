use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Geo::GoogleEarth::Pluggable::Plugin::GreatCircle',
    VERSION_FROM => 'lib/Geo/GoogleEarth/Pluggable/Plugin/GreatCircle.pm',
    AUTHOR       => 'Michael R. Davis (domain=>michaelrdavis,tld=>com,account=>perl)',
    ABSTRACT     => 'Great Circle plugin for Geo::GoogleEarth::Pluggable',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'strict'       => 0,
                     'warnings'     => 0,
                     'GPS::Point'   => 0.14,
                     'Geo::Forward' => 0,
                     'Geo::Inverse' => 0,
                    },
);
