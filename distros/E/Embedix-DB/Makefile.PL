use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Embedix::DB',
    'VERSION_FROM'  => 'DB.pm',
    'ABSTRACT_FROM' => 'DB.pm',
    'EXE_FILES'     => [ qw(bin/ebx) ],
    'PREREQ_PM'     => {
        'Embedix::ECD'      => 0,
        'DBI'               => 0,
        'Pod::Usage'        => 0,
        'Test'              => 0,
    },
);
