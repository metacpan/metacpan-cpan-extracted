use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'MILA::Transliterate',
	license             => 'perl',
	dist_author         => 'Shlomo Yona <yona@cs.technion.ac.il>',
	dist_abstract       => 'A Perl Module for transliterating text from Hebrew to various transliterations used in the Knowledge Center for Processing Hebrew (MILA) and vise versa',
	create_makefile_pl  => 'traditional',
	create_readme       => 1,
	requires            => {
		'Test::More'                        => '0.47',
		'perl'                              => '5.8.0',
	},
);

$builder->create_build_script();
