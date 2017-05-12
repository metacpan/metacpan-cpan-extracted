use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'Digest::Haval256',
    'VERSION_FROM' => 'Haval256.pm',
    'PREREQ_PM' => {'MIME::Base64' => '0'},
    'AUTHOR' => 'Julius C. Duque',
    'LIBS' => [''],
    'DEFINE' => '',
    'INC' => '-I.',
    'dist' => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'}
);

