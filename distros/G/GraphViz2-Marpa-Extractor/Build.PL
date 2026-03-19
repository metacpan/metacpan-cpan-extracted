use strict ;
use warnings ;

use Module::Build ;

my $builder = Module::Build->new
	(
	module_name        => 'GraphViz2::Marpa::Extractor',
	license            => 'artistic_2',
	dist_author        => 'Nadim Khemir <nadim.khemir@gmail.com>',
	dist_version_from  => 'lib/GraphViz2/Marpa/Extractor.pm',
	dist_abstract      => 'Extracts a simplified AST from GraphViz2::Marpa tree',

	requires =>
		{
		'perl'                      => '5.010',
		'Data::TreeDumper'          => '0',
		'Getopt::Long'              => '0',
		'GraphViz2::Marpa'          => '0',
		},

	build_requires =>
		{
		'Test::More'       => '0',
		'Test::Exception'  => '0',
		},

	configure_requires => { 'Module::Build' => 0.42 },

	script_files => ['script/dtd7'],

	meta_merge =>
		{
		resources =>
			{
			repository => 'https://github.com/nkh/P5-GraphViz2-Marpa-Extractor',
			},
		},
	) ;

$builder->create_build_script() ;
