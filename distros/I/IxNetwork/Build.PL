use strict;
use warnings;
use Module::Build;


my $builder = Module::Build->new(
    module_name       => 'IxNetwork',
	dist_name         => 'IxNetwork',
    dist_author       => 'diana.galan@keysight.com',
    dist_version      => '8.50',
	dist_abstract     => 'IxNetwork API Perl Bindings',
	license           => 'perl',
    requires          => {'perl' => '5.18.0'},
    create_makefile_pl => 'small',
);

$builder->create_build_script();
