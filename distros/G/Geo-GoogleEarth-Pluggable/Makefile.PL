use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Geo::GoogleEarth::Pluggable',
    VERSION_FROM => 'lib/Geo/GoogleEarth/Pluggable.pm',
    AUTHOR       => 'Michael R. Davis (domain=>michaelrdavis,tld=>com,account=>perl)',
    ABSTRACT_FROM=> 'lib/Geo/GoogleEarth/Pluggable.pm',
    PREREQ_PM    => {
                     'Test::Simple'             => 0.44,
                     'Scalar::Util'             => 0,
                     'IO::Scalar'               => 0,
                     'XML::LibXML::LazyBuilder' => 0,
                     'Archive::Zip'             => 0,
                     'Method::Autoload'         => 0,
                     'Module::Pluggable'        => 0,
                     'Package::New'             => 0,
                    },
);
