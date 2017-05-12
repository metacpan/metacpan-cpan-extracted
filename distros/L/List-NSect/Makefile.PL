use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'List::NSect',
    VERSION_FROM => 'lib/List/NSect.pm',
    AUTHOR       => 'Michael R. Davis (mdavis@stopllc.com)',
    ABSTRACT_FROM=> 'lib/List/NSect.pm',
    PREREQ_PM    => {
                     'Test::Simple'    => 0.44,
                     'List::MoreUtils' => 0,
                     'Exporter'        => 0,
                    },
);
