# WBB 2018-03-29

use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;
use Data::Dumper;

my $builder = Module::Build->new(
    module_name         => 'ICC::Profile',
    license             => 'GPL_3',
    dist_abstract       => 'A set of object-oriented modules implementing ICC profiles and related color functions',
    dist_author         => q{William B. Birkett <wbirkett@doplganger.com>},
    dist_version   => '0.605',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => '5.10.0', # version shipped with OSX 10.6 (Snow Leopard)
        'Carp' => 0,
        'Compress::Raw::Zlib' => 0,
        'Config' => 0,
        'Data::Dumper' => 0,
        'Digest::MD5' => 0,
        'Encode' => 0,
        'Exporter' => 0,
        'File::Glob' => 0,
        'File::Spec' => 0,
        'List::Util' => 0,
        'Math::Complex' => 0,
        'Math::Matrix' => 0.8,
        'Scalar::Util' => 0,
        'Storable' => 0,
        'Template' => 0,
        'Time::Piece' => 1.17,
        'XML::LibXML' => 0,
        'XSLoader' => 0,
        'YAML::Tiny' => 0,
    },
    add_to_cleanup     => [ 'ICC-Profile-*' ],
    create_makefile_pl => 'traditional',
    pod_files => {
        'pod/ICC/Profile.pod' => 'lib/ICC/Profile.pod',
        'pod/ICC/Shared.pod' => 'lib/ICC/Shared.pod',
        'pod/ICC/Support/Chart.pod' => 'lib/ICC/Support/Chart.pod',
        'pod/ICC/Support/Color.pod' => 'lib/ICC/Support/Color.pod',
    },
);

$builder->add_build_element('xml');
$builder->add_build_element('yml');
$builder->add_build_element('xsd');
$builder->add_build_element('js');
$builder->add_build_element('tt2');
$builder->create_build_script();

# print Dumper($builder);
