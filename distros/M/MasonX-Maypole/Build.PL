use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'MasonX::Maypole',
    license             => 'perl',
    dist_author         => 'David Baird <cpan@riverside-cms.co.uk>',
    dist_version_from   => 'lib/MasonX/Maypole.pm',
    requires => {
        'Test::More' => 0,
        'Maypole' => 2,
        'HTML::Mason' => 1,
        'Symbol' => 0,
        'MasonX::Request::ExtendedCompRoot' => 0.03,

    },
    add_to_cleanup      => [ 'MasonX-Maypole-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
