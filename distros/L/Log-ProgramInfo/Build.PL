# Safe Perl
use strict;
use autodie;

use Module::Build;


my $builder = Module::Build->new(
    module_name         => 'Log-ProgramInfo',
    license             => 'perl',
    dist_author         => [
		'Boutros Lab Software Engineering  <BoutrosLabSoftware@oicr.on.ca>',
		'John Macdonald  <jmacdonald@oicr.on.ca>',
	],

    dist_version_from   => 'lib/Log/ProgramInfo.pm',
    dist_abstract       => 'Module to log program termination status info.',

    # Modules required to use this module
	configure_requires => {
		'Module::Build'      => 0.42,
	},
    requires => {
		'perl'               => '5.10.0',
        'strict'             => 0,
        'warnings'           => 0,
        'Carp'               => 0,
        'Data::Dumper'       => 0,
        'FindBin'            => 0,
        'Time::HiRes'        => 0,
        'DateTime'           => 0,
        'DateTime::Duration' => 0,
        'Fcntl'              => 0,
    },

	test_requires => {
        'Test::More'         => '0.10',
		'Test::Exception'    => 0,
		'File::Path'         => 0,
	},
);

$builder->create_build_script();
