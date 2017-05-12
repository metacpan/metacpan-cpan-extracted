use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'File::Maintenance',
    AUTHOR              => 'Dan Horne <dhorne@cpan.org>',
    VERSION_FROM        => 'lib/File/Maintenance.pm',
    ABSTRACT_FROM       => 'lib/File/Maintenance.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'          => 0,
        'File::Stat::OO'      => 0,
        'File::Find::Rule'    => 0,
        'File::Copy'          => 0,
        'File::Path'          => 0,
        'File::Basename'      => 0,
        'DateTime'            => 0,
        'Class::Accessor'     => 0,
        'IO::Compress::Gzip'  => 2.012,
        'IO::Compress::Zip'   => 2.012,
        'IO::Compress::Bzip2' => 2.012,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'File-Maintenance-*' },
);
