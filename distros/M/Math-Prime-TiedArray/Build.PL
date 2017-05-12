use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Math::Prime::TiedArray',
    license             => 'perl',
    dist_author         => 'Dan Boger <cpan@peeron.com>',
    dist_version_from   => 'lib/Math/Prime/TiedArray.pm',
    build_requires => {
        'Test::More' => 0.01,
    },
    requires            => { 'Tie::Array' => 0.01, },
    add_to_cleanup      => [ 'Math-Prime-TiedArray-*' ],
);

$builder->create_build_script();
