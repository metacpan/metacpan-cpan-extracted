# Build.PL
use strict; use warnings;

use Module::Build;
my $build = Module::Build->new(
	# look up Module::Build::API for the info!
	'dynamic_config'	=> 0,
	'module_name'	=> 'Log::Log4perl::Appender::Socket::UNIX',
	'license'		=> 'perl',

	'dist_abstract'	=> 'Log/Stream to a UDP Unix Domain Socket',

	'create_packlist'		=> 1,
	'create_makefile_pl'	=> 'traditional',
	'create_readme'		=> 1,

	'test_files'		=> 't/*.t',

	'add_to_cleanup'	=> [ 'META.yml', 'Makefile.PL', 'README', 'Makefile' ],	# automatically generated

	'requires'		=> {
		'perl'		=> '5.006',
	},
);

# all done!
$build->create_build_script;
