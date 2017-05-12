use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Lingua::TokenParse',
    'VERSION_FROM' => 'lib/Lingua/TokenParse.pm',
    'PREREQ_PM'    => {
        'Math::BaseCalc' => 0,
        'Storable'       => 0,
    },
    ($] >= 5.005
        ? (ABSTRACT_FROM => 'lib/Lingua/TokenParse.pm',
           AUTHOR        => 'Gene Boggs <gene@cpan.org>')
        : ()
    ),
);
