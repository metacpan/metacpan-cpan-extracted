use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'GSM::ARFCN',
    VERSION_FROM => 'lib/GSM/ARFCN.pm',
    AUTHOR       => 'Michael R. Davis (domain=>michaelrdavis,tld=>com,account=>perl)',
    ABSTRACT     => 'Absolute Radio Frequency Channel Number (ARFCN) Converter',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'strict'       => 0,
                    },
);
