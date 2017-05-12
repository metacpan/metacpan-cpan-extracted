use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Device::Delcom::VSI',
    license             => 'perl',
    dist_author         => 'G. Wade Johnson <wade@anomaly.org>',
    dist_version_from   => 'lib/Device/Delcom/VSI.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
	'Device::USB' => 0,
    },
    add_to_cleanup      => [ 'Device-Delcom-VSI-*' ],
);

$builder->create_build_script();
