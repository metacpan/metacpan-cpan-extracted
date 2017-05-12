use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Lingua::JA::Regular',
    'VERSION_FROM' => 'lib/Lingua/JA/Regular.pm', # finds $VERSION
    'PREREQ_PM'    => {
        Test::More => 0.32,
    },
);
