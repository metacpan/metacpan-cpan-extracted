use ExtUtils::MakeMaker;

# man files

WriteMakefile(
    NAME        => 'Device::ISDN::OCLM',
    DISTNAME    => 'Device-ISDN-OCLM',
    VERSION_FROM => 'lib/Device/ISDN/OCLM.pm',
    PREREQ_PM   => {
        'LWP' => 5.47,
        'URI::URL' => 5.02,
        'HTTP::Request' => 1.26,
        'HTTP::Request::Form' => 0.5,
        'HTML::TreeBuilder' => 2.06,
    },
    PL_FILES    => { "bin/oclm.PL" => "bin/oclm" },
    EXE_FILES   => [ "bin/oclm" ],
);
