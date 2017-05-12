use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Geo::WebService::OpenCellID',
    VERSION_FROM => 'lib/Geo/WebService/OpenCellID.pm',
    AUTHOR       => 'Michael R. Davis (domain=>michaelrdavis,tld=>com,account=>perl)',
    ABSTRACT     => 'Perl API for the opencellid.org database',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'strict'       => 0,
                     'base'         => 0,
                     'warnings'     => 0,
                     'URI'          => 0,
                     'XML::Simple'  => 0,
                     'LWP::Simple'  => 0,
                    },
);
