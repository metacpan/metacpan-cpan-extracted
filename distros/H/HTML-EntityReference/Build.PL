use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'HTML::EntityReference',
    license             => 'perl',
    dist_author         => q{John M. Dlugosz <john@dlugosz.com>},
    dist_version_from   => 'lib/HTML/EntityReference.pm',
    build_requires => {
        'Test::More' => 0,
        'Test::Fatal' => 0.005,
    },
    requires => {
        'perl' => 5.010001,
    },
    add_to_cleanup      => [ 'HTML-EntityReference-*' ],
    create_makefile_pl => 'traditional',
);
$builder->add_build_element('inc');  ###
$builder->create_build_script();
