use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'              => 'Language::Homespring::Visualise::GraphViz',
    'VERSION_FROM'      => 'GraphViz.pm',
    'PREREQ_PM'         => {
				GraphViz => 1.8,
                                Test::Simple => 0,
                        },
);

