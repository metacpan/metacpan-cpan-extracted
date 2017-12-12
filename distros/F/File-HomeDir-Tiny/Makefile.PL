use 5.004;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'File::HomeDir::Tiny',
    AUTHOR              => 'Father Chrysostomos <sprout & cpan . org>',
    VERSION_FROM        => 'lib/File/HomeDir/Tiny.pm',
    ABSTRACT_FROM       => 'lib/File/HomeDir/Tiny.pod',
    dist               => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
                            TAR => 'COPYFILE_DISABLE=1 tar' },
    clean              => { FILES => 'File-HomeDir-Tiny-*' },
    META_MERGE         => { dynamic_config => 0 },
);
