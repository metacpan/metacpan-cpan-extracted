
use strict;
use warnings;
use Module::Build;
my $build_class = 'Module::Build';

my $builder = $build_class->new(
	module_name         => 'Math::Round::Var',
	license             => 'perl',
	dist_version_from   => 'lib/Math/Round/Var.pm',
	requires => {
		'Test::More'    => 0,
	},
	add_to_cleanup      => [ qw(Math-Round-Var-* META.yml)],
    #create_makefile_pl => 'passthrough'
);

$builder->create_build_script();
