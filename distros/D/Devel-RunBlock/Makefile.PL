use strict;
use warnings;
use ExtUtils::MakeMaker;
use inc::ExtUtils::MY_Metafile qw(my_metafile);

my $requires = +{
	# none.
};
my $build_requires = +{
	'Test::More' => 0,
};
my_metafile 'Devel::RunBlock' => +{
	license => 'perl',
	requires => $requires,
	build_requires => $build_requires,
};
WriteMakefile(
    NAME                => 'Devel::RunBlock',
    AUTHOR              => 'YAMASHINA Hio <hio@cpan.org>',
    VERSION_FROM        => 'lib/Devel/RunBlock.pm',
    ABSTRACT_FROM       => 'lib/Devel/RunBlock.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        %$requires,
        %$build_requires,
    },
		LICENSE => 'perl',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Devel-RunBlock-*' },
);
