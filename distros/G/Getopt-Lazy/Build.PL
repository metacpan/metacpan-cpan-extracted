use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Getopt::Lazy',
    license             => 'perl',
    dist_author         => 'Ruey-Cheng Chen <rueycheng@gmail.com>',
    dist_version_from   => 'lib/Getopt/Lazy.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Getopt-Lazy-*' ],
);

$builder->create_build_script();
