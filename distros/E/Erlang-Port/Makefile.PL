use strict;
use warnings;
use ExtUtils::MakeMaker;
use inc::ExtUtils::MY_Metafile qw(my_metafile);

my $requires = {
};
my $build_requires = {
};
my_metafile('Erlang::Port' => {
	license  => 'perl',
	requires => $requires,
	build_requires => $build_requires,
	no_index => {
		directory => [
			'inc',
			't',
		],
	},
});
WriteMakefile(
    NAME                => 'Erlang::Port',
    AUTHOR              => 'YAMASHINA Hio <hio@cpan.org>',
    VERSION_FROM        => 'lib/Erlang/Port.pm',
    ABSTRACT_FROM       => 'lib/Erlang/Port.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        %$requires,
				%$build_requires,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Erlang-Port-*' },
);
