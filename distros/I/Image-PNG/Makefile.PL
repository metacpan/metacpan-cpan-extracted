use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Constant;

use 5.008001;

WriteMakefile (
    NAME         => 'Image::PNG',
    VERSION      => '0.23',
    ABSTRACT     => 'Read and write PNG files',
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
	'Image::PNG::Libpng' => '0.39',
    },
    META_MERGE => {
        resources => {
            "bugtracker" => "https://github.com/benkasminbullock/Image-PNG/issues",
            "repository" => "https://github.com/benkasminbullock/Image-PNG",
        },
        no_index => {
            directory => ['tmpl', 'build'],
        },
    },
    MIN_PERL_VERSION => '5.008001',
);

# Local Variables:
# mode: perl
# End:
