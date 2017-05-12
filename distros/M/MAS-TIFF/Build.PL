use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'MAS::TIFF',
    license             => 'perl',
    dist_author         => 'Gregor N. Purdy, Sr. <gnp@acm.org>',
    dist_version_from   => 'lib/MAS/TIFF/File.pm',
);

$builder->create_build_script();
