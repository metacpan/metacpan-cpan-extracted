use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'File::Text::CSV',
    AUTHOR              => 'Johan Vromans <jv@cpan.org>',
    VERSION_FROM        => 'lib/File/Text/CSV.pm',
    ABSTRACT_FROM       => 'lib/File/Text/CSV.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Fatal' => 0,
	'Text::CSV_XS' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'File-Text-CSV-*' },
);
