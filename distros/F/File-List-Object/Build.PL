use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'File::List::Object',
	license             => 'perl',
	dist_author         => 'Curtis Jewell <csjewell@cpan.org>',
	dist_version_from   => 'lib/File/List/Object.pm',
	configure_requires  => {
		'Module::Build'    => 0.32,
	},
	requires => {
		'perl'             => 5.008001,
		'Exception::Class' => 1.29,
		'Moose'            => 0.90,
		'Params::Util'     => 0.35,
	},
	build_requires => {
		'Test::More'       => 0.61,
# Build dist requires these.
#		'Pod::Readme'              => 0,
#		'Software::License'        => 0,
	},
	add_to_cleanup      => [ 'File-List-Object-*' ],
	create_readme       => 1,
	create_license      => 1,
	create_makefile_pl  => 'passthrough',
);

$builder->create_build_script();
