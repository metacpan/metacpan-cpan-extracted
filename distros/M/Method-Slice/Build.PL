use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Method::Slice',
    license             => 'Artistic_2_0',
    dist_author         => q{Laurent Dami <dami@cpan.org>},
    dist_version_from   => 'lib/Method/Slice.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Want'       => 0,
    },
    add_to_cleanup     => [ 'Method-Slice-*' ],
    meta_merge => {
      resources => {
        repository => 'https://github.com/damil/Method-Slice',
       }
     },
);

$builder->create_build_script();
