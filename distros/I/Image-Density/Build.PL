use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Image::Density',
    license             => 'perl',
    dist_author         => 'Gregor N. Purdy, Sr. <gnp@acm.org>',
    dist_version_from   => 'lib/Image/Density/TIFF.pm',
    requires => {
        'MAS:TIFF'     => 0.4,
    },
);

$builder->create_build_script();
