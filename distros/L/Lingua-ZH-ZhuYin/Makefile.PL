use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Lingua::ZH::ZhuYin',
    AUTHOR              => 'Cheng-Lung Sung <clsung@cpan.org>',
    VERSION_FROM        => 'lib/Lingua/ZH/ZhuYin.pm',
    ABSTRACT_FROM       => 'lib/Lingua/ZH/ZhuYin.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Encode'     => 0,
	'List::Util' => 0,
	'DBD::SQLite'=> 0,
	'DBI'        => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Lingua-ZH-ZhuYin-*' },
);
