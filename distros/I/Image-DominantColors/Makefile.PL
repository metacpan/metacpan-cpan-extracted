use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Image::DominantColors',
    AUTHOR           => q{Gideon Israel Dsouza <gideon@cpan.org>},
    VERSION_FROM     => 'lib/Image/DominantColors.pm',
    ABSTRACT_FROM    => 'lib/Image/DominantColors.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Imager'              => 0.94,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Image-DominantColors-*' },
	META_MERGE        => {
	     resources =>  {	
	 			repository => 'https://github.com/gideondsouza/image-dominant-colors',
			},
	}
);
