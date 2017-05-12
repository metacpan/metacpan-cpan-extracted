use strict;
use warnings;
use Module::Build;
use Config;

die 'OS unsupported' unless ( $Config{osname} eq 'freebsd' );

my $builder = Module::Build->new(
	module_name		=> 'FreeBSD::Jails',
	license			=> 'perl',
	dist_author		=> 'Athanasios Douitsis <aduitsis@cpan.org>',
	dist_version_from	=> 'lib/FreeBSD/Jails.pm',
	build_requires => {
		'Test::More'		=> 0,
		'Module::Build'		=> 0,
		'ExtUtils::CBuilder'	=> 0,
	},
	requires => {
		'version'	=> 0,
	},
	configure_requires => { 
		'Module::Build'	=> 0.42 
	},
	meta_merge => {
		resources => {
			repository => 'https://github.com/aduitsis/FreeBSD-Jails',
		}
	},
	dist_abstract => 'jail list for FreeBSD systems',
	#provides => 'FreeBSD::Jails',
	#xs_files => { 'jls.xs' => 'ls.xs' } ,
	create_makefile_pl => 'traditional',
);

$builder->create_build_script();
