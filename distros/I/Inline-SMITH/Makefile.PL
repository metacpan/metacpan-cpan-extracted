use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Inline::SMITH',
    'VERSION_FROM'	=> 'SMITH.pm', # finds $VERSION
    'PREREQ_PM'		=> {Inline => 0.43},
);
