use ExtUtils::MakeMaker;

WriteMakefile
(
    NAME => "LSF",
    'VERSION'    => '0.21',
    (
        $] >= 5.6
        ? (ABSTRACT   => 'LSF command line tools wrapped in PERL',
           AUTHOR     => 'Mark Southern (mark_southern@merck.com)')
        : ()
    ),
    PREREQ_PM => { 
                    System2     => 0.82,
                    Date::Manip => 5.40,
                 },
    'dist' => {COMPRESS=>'gzip',SUFFIX=>'gz'},
);
