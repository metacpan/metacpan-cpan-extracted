use strict;
use warnings;
use ExtUtils::MakeMaker;
use inc::ExtUtils::MY_Metafile;

my_metafile 'Hash::Extract' => {
	license => 'perl',
	requires => {
		'PadWalker' => 0,
	},
	build_requires => {
		'Test::More' => 0,
	}
};

WriteMakefile(
    NAME                => 'Hash::Extract',
    AUTHOR              => 'YAMASHINA Hio <hio@cpan.org>',
    VERSION_FROM        => 'lib/Hash/Extract.pm',
    ABSTRACT_FROM       => 'lib/Hash/Extract.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'PadWalker'  => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Hash-Extract-*' },
);
