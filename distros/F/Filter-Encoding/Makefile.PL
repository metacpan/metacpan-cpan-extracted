use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Filter::Encoding',
    AUTHOR              => 'Father Chrysostomos <sprout & cpan . org>',
    VERSION_FROM        => 'lib/Filter/Encoding.pm',
    ABSTRACT_FROM       => 'lib/Filter/Encoding.pm',
    PREREQ_PM => {
         Carp               => 0,
         Encode             => 0,
         Filter::Util::Call => 0,
         utf8               => 0,
    },
    dist               => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
                            TAR => 'COPYFILE_DISABLE=1 tar' },
    clean              => { FILES => 'Filter-Encoding-*' },
);
