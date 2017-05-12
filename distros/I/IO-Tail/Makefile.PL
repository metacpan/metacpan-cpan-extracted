use strict;
use warnings;
use ExtUtils::MakeMaker;

use lib 'inc';
use ExtUtils::MY_Metafile qw(my_metafile);

my $requires = {
};
my $build_requires = {
		'Test::More'      => 0,
		'Time::HiRes'     => 0,
		'File::Temp'      => 0,
};
my_metafile( 'ExtUtils::MY_Metafile' => {
	license => 'perl',
	
	requires => $requires,
	build_requires => $build_requires,
});

WriteMakefile(
    NAME                => 'IO::Tail',
    AUTHOR              => 'YAMASHINA Hio <hio@cpan.org>',
    VERSION_FROM        => 'lib/IO/Tail.pm',
    ABSTRACT_FROM       => 'lib/IO/Tail.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        %$requires,
        %$build_requires,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'IO-Tail-*' },
);
