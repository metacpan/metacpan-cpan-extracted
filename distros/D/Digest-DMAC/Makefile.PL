use ExtUtils::MakeMaker;

WriteMakefile (
    'AUTHOR' => 'Julius C. Duque',
    'ABSTRACT' => 'A MAC that uses an existing block cipher',
    'NAME' => 'Digest::DMAC',
    'VERSION_FROM' => 'DMAC.pm',
    'PREREQ_PM' => {'Crypt::CBC' => '2.08',
                    'MIME::Base64' => '0'},
    'LIBS' => [''],
    'DEFINE' => '',
    'INC' => '',
    'dist' => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'}
);

