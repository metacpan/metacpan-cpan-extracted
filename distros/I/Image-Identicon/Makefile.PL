use strict;
use warnings;
use ExtUtils::MakeMaker;
use inc::ExtUtils::MY_Metafile qw(my_metafile);

my $requires = {
	'GD' => '2.05',
	'Digest::SHA' => 0,
};
my $build_requires = {
        'Test::More' => 0,
};
my_metafile 'Image::Identicon' => {
	requires => $requires,
	build_requires => $build_requires,
	license => 'Perl',
};

WriteMakefile(
    NAME                => 'Image::Identicon',
    AUTHOR              => 'YAMASHINA Hio <hio@cpan.org>',
    VERSION_FROM        => 'lib/Image/Identicon.pm',
    ABSTRACT_FROM       => 'lib/Image/Identicon.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        %$requires, %$build_requires,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Image-Identicon-*' },
);
