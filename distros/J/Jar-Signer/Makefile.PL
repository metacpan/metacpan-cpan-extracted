use ExtUtils::MakeMaker;

WriteMakefile
(
    NAME            => 'Jar::Signer',
    VERSION_FROM    => 'lib/Jar/Signer.pm',
    (
        $] >= 5.8.0
        ? (ABSTRACT   => 'Ease the process of creating a signed Jar file.',
           AUTHOR     => 'Mark Southern (msouthern@exsar.com)')
        : ()
    ),
    PREREQ_PM => { 
                File::chdir => undef,
             },
    'dist' => {COMPRESS=>'gzip',SUFFIX=>'gz'},
);
