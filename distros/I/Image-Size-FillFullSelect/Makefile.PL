use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Image::Size::FillFullSelect',
    AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
    VERSION_FROM        => 'lib/Image/Size/FillFullSelect.pm',
    ABSTRACT_FROM       => 'lib/Image/Size/FillFullSelect.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Image::Size' => 1,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Image-Size-FillFullSelect-*' },
);
