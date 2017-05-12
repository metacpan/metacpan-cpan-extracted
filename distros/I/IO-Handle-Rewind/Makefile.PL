use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'IO::Handle::Rewind',
    AUTHOR              => 'Hans Dieter Pearcey <hdp@cpan.org>',
    VERSION_FROM        => 'lib/IO/Handle/Rewind.pm',
    ABSTRACT_FROM       => 'lib/IO/Handle/Rewind.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Class::Accessor' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'IO-Handle-Rewind-*' },
);
