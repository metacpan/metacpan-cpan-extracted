use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'File::Stat::OO',
    AUTHOR              => 'Dan Horne <dhorne@cpan.org>',
    VERSION_FROM        => 'lib/File/Stat/OO.pm',
    ABSTRACT_FROM       => 'lib/File/Stat/OO.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'      => 0,
		'DateTime'        => 0,
		'Class::Accessor' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'File-Stat-OO-*' },
);
