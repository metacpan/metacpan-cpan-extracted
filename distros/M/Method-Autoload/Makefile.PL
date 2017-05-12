use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Method::Autoload',
    VERSION_FROM => 'lib/Method/Autoload.pm',
    AUTHOR       => 'Michael R. Davis (domain=>michaelrdavis,tld=>com,account=>perl)',
    ABSTRACT_FROM=> 'lib/Method/Autoload.pm',
    PREREQ_PM    => {
                     'Test::Simple'       => 0.44,
                     'UNIVERSAL::require' => 0,
                     'warnings'           => 0,
                     'strict'             => 0,
                    },
);
