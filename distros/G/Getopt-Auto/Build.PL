use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name        => 'Getopt::Auto',
	license            => 'perl',
	dist_author        => 'Geoffrey Leach <geoff@hughes.net>',
    dist_version_from  => 'lib/Getopt/Auto.pm',
    dist_abstract      => 'An easy way to organize a script to handle whatever option mechanism it requires.',
	requires           => {
                            'perl'                  => '5.6.0',
                            'File::Spec'            => 0,
                            'File::Basename'        => 0,
                            'File::Spec::Functions' => 0,
                            'Readonly'              => 0,
                            'Pod::Usage'            => 0,
},
	build_requires     => { 'Test::More'            => 0,
                            'Test::Output'          => 0,
},
    configure_requires => { 'Module::Build'         => 0.42,
},
	add_to_cleanup     => [ 'Getopt-Auto-*' ],
 	create_makefile_pl => 'traditional',
);

$builder->create_build_script();
