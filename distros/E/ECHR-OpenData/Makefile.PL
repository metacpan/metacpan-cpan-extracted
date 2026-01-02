use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'ECHR::OpenData',
    VERSION_FROM => 'lib/ECHR/OpenData.pm',
    ABSTRACT     => 'ECHR-OpenData utilities',
    AUTHOR       => 'Lubell',
    PREREQ_PM    => {
        'JSON'       => 0,
        'File::Spec' => 0,
    },
);
