use ExtUtils::MakeMaker;

WriteMakefile(
    'AUTHOR'        => 'John McNamara (jmcnamara@cpan.org)',
    'ABSTRACT'      => 'Include awk code in a Perl program.',
    'NAME'          => 'Inline::Awk',
    'VERSION_FROM'  => 'Awk.pm',
    'NEEDS_LINKING' => 0,
    'PREREQ_PM'     => {Inline => 0},
    'dist'          => {COMPRESS => 'gzip --best', SUFFIX => 'gz'},
);
