use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'HTML::Scrubber::StripScripts',
    'VERSION_FROM' => 'StripScripts.pm',
    'PREREQ_PM'    => {
                        'Test::More'     => 0,
                        'HTML::Scrubber' => 0.03,
                      },
);

