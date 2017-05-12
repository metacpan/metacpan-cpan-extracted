use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'EnsEMBL::Web::Record',
    AUTHOR              => 'Matt Wood <mjw@cpan.org>',
    VERSION_FROM        => 'lib/EnsEMBL/Web/Record.pm',
    ABSTRACT_FROM       => 'lib/EnsEMBL/Web/Record.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'EnsEMBL-Web-Record-*' },
);
