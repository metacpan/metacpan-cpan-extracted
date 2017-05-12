use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Fortran::Format',
    'VERSION_FROM'	=> 'Format.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        'Test::Simple' => 0,
    },
);
