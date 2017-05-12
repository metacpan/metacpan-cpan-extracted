use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Geo::GoogleEarth::Pluggable::Plugin::Styles',
    VERSION_FROM => 'lib/Geo/GoogleEarth/Pluggable/Plugin/Styles.pm',
    AUTHOR       => 'Michael R. Davis (domain=>michaelrdavis,tld=>com,account=>perl)',
    ABSTRACT     => 'Pre-loaded Styles for Geo::GoogleEarth::Pluggable',
    PREREQ_PM    => {
                     'Test::Simple'                => 0.44,
                     'strict'                      => 0,
                     'warnings'                    => 0,
                     'Geo::GoogleEarth::Pluggable' => 0.06,
                    },
);
