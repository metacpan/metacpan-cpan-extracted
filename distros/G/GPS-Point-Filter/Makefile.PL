use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'GPS::Point::Filter',
    VERSION_FROM => 'lib/GPS/Point/Filter.pm',
    AUTHOR       => 'Michael R. Davis (domain=>stopllc,tld=>com,account=>mdavis)',
    ABSTRACT     => 'Algorithm to filter extraneous GPS points from a track',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'GPS::Point'   => 0.11,
                     'DateTime'     => 0,
                    },
);
