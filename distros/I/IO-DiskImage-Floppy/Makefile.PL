use strict;
use warnings;
use ExtUtils::MakeMaker;
use inc::ExtUtils::MY_Metafile qw(my_metafile);

my $requires = {
};
my $build_requires = {
	'Test::More' => 0,
};
my_metafile 'IO::DiskImage::Floppy' => {
	requires => $requires,
	build_requires => $build_requires,
	license => 'Perl',,
};

WriteMakefile(
    NAME                => 'IO::DiskImage::Floppy',
    AUTHOR              => 'YAMASHINA Hio <hio@cpan.org>',
    VERSION_FROM        => 'lib/IO/DiskImage/Floppy.pm',
    ABSTRACT_FROM       => 'lib/IO/DiskImage/Floppy.pm',
    PL_FILES            => {},
    EXE_FILES            => [qw(bin/fdimage.pl)],
    PREREQ_PM => {
        %$requires,
				%$build_requires,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'IO-DiskImage-Floppy-*' },
);
