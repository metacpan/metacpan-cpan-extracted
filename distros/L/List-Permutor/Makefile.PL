use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	=> 'List::Permutor',
    'VERSION_FROM' => 'Permutor.pm', # finds $VERSION
    'dist'      => { 'COMPRESS' => 'gzip', 'SUFFIX' => 'gz' },
);
