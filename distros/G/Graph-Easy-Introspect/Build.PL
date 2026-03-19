use strict ;
use warnings ;
use Module::Build ;

my $build = Module::Build->new
	(
	module_name       => 'Graph::Easy::Introspect',
	dist_version_from => 'lib/Graph/Easy/Introspect.pm',
	dist_abstract     => 'Introspection and AST for Graph::Easy layouts',
	dist_author       => 'Nadim Khemir <nadim.khemir@gmail.com>',
	license           => 'perl',
	requires          =>
		{
		'Graph::Easy'                   => 0,
		'Graph::Easy::Parser::Graphviz' => 0,
		'Graph::Easy::Edge::Cell'       => 0,
		'JSON::PP'                      => 0,
		'Data::TreeDumper'              => 0,
		},
	build_requires    =>
		{
		'Test::More' => 0,
		},
	script_files      =>
		[
		'script/graph_easy_introspect',
		'script/graph_easy_render',
		'script/graph_easy_render_ascii',
		],
	meta_merge        =>
		{
		resources =>
			{
			repository => 'https://github.com/nkh/P5-graph_easy_ast',
			},
		},
	) ;

$build->create_build_script ;
