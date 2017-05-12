
use strict;
use warnings;
use Module::Build;
my $build_class = 'Module::Build';

my $builder = $build_class->new(
	module_name         => 'Math::Vec',
	license             => 'perl',
	dist_version_from   => 'lib/Math/Vec.pm',
	requires => {
		'Test::More'    => 0,
	},
	create_makefile_pl => 'passthrough',
	add_to_cleanup      => [ qw(Math-Vec-* META.yml)],
);

$builder->create_build_script();
