use Module::Build;

Module::Build->new(
	module_name => 'Env::PS1',
	license     => 'perl',
	dist_author => 'Jaap Karssenberg <pardus@cpan.org>',
	requires    => {
		'AutoLoader'    => 0,
		'Sys::Hostname' => 0,
		'POSIX'         => 0,
	},
	build_requires => {
		'AutoSplit'     => 0,
	},
	autosplit => 'lib/Env/PS1.pm',
	create_makefile_pl => 'passthrough',
)->create_build_script;
