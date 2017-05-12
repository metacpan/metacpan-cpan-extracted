use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	=> 'Filter::Trigraph',
    'VERSION_FROM' => 'Trigraph.pm',
    'PREREQ_PM'    => { 'Filter::Simple' => '0.50'},
);
