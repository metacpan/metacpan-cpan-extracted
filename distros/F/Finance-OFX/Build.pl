use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Finance::OFX',
    license             => 'bsd',
    dist_author         => q{Brandon Fosdick <bfoz@bfoz.net>},
    dist_version        => '2',
    configure_requires => { 'Module::Build' => 0.38 },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.006,
        'Data::GUID'     => 0,
        'HTML::Parser'   => 0,
        'HTTP::Date'     => 0,
        'LWP'            => 0,
    },
    add_to_cleanup      => [ 'Finance-OFX-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
