use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Geo::GoogleEarth::Pluggable::Plugin::CircleByCenterPoint',
    VERSION_FROM => 'lib/Geo/GoogleEarth/Pluggable/Plugin/CircleByCenterPoint.pm',
    AUTHOR       => 'Michael R. Davis (domain=>michaelrdavis,tld=>com,account=>perl)',
    ABSTRACT     => 'CircleByCenterPoint plugin for Geo::GoogleEarth::Pluggable',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'strict' => 0,
                     'warnings' => 0,
                     'Geo::Forward' => 0,
                    },
);
