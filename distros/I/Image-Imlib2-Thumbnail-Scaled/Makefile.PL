use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Image::Imlib2::Thumbnail::Scaled',
    AUTHOR           => q{Adam Hopkins <srchulo@cpan.org>},
    VERSION_FROM     => 'lib/Image/Imlib2/Thumbnail/Scaled.pm',
    ABSTRACT_FROM    => 'lib/Image/Imlib2/Thumbnail/Scaled.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Image::Imlib2'         => '2.00',
        'MIME::Types'           => '0',
		'Object::Tiny::RW::XS' => '0',
		'File::Copy' => '0',
		'File::Basename' => '0',
		'Path::Class' => '0',
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Image-Imlib2-Thumbnail-Scaled-*' },
);
