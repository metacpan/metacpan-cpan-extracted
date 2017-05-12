use strict;
use warnings;
use ExtUtils::MakeMaker;

use lib 'lib';
use ExtUtils::MY_Metafile qw(my_metafile);

my_metafile( 'ExtUtils::MY_Metafile' => {
	no_index => {
		directory => [ qw(example t), ],
	},
	license => 'perl',
	
	requires => {
		'ExtUtils::MakeMaker' => 0,
	},
	build_requires => {
		'Test::More'      => 0,
		'Test::Exception' => 0,
	},
});

WriteMakefile(
    NAME                => 'ExtUtils::MY_Metafile',
    AUTHOR              => 'YAMASHINA Hio <hio@cpan.org>',
    VERSION_FROM        => 'lib/ExtUtils/MY_Metafile.pm',
    ABSTRACT_FROM       => 'lib/ExtUtils/MY_Metafile.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'ExtUtils::MakeMaker' => 0,
        'Test::More' => 0,
        'Test::Exception' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'ExtUtils-MY_Metafile-*' },
);
