
use strict;
use warnings;
use Module::Build;
my $build_class = 'Module::Build';
my $custom_build = 'Module::Build::Live';
eval("require $custom_build;");
unless($@) {
	warn "using custom build class:  '$custom_build'\n";
	$build_class = $custom_build;
}

my $builder = $build_class->new(
	module_name         => 'Getopt::Helpful',
	license             => 'perl',
	dist_version_from   => 'lib/Getopt/Helpful.pm',
	requires => {
		'Test::More'   => 0.54,
		'IPC::Run'     => 0.78,
		'Getopt::Long' => 2.34,
		'YAML'         => 0.39,
	},
	add_to_cleanup      => [ qw(
		Getopt-Helpful-* META.yml
		t/config_check/configs/global.conf
		)],
	script_files => [qw(
		bin/mk_helpful
		)],
);

$builder->create_build_script();
