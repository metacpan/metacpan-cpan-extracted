use v5.18;
# Last modified: Sun Aug 10 2025 03:07:50 PM -04:00 [EDT]
use strict;
use warnings;
use utf8;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name         => 'Env::AsYaml',
    license             => 'artistic_2',
    dist_author         => q{Sören Andersen <somian08@gmail.com>},
    dist_version_from   => 'lib/Env/AsYaml.pm',
    release_status      => 'experimental',
    configure_requires => {
        'Module::Build' => '0.4004',
    },
    test_requires => {
        'Test::More' => '0',
    },
    requires => {
        'Env'               => '1.06',
        'YAML::Any'         => '1.31',
	'Data::Dump::Color' => '0.251',
    },
    add_to_cleanup     => [ 'Env-AsYaml-*' ],
);

$builder->create_build_script();
