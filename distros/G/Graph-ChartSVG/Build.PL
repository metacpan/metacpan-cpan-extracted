#! /usr/bin/perl
use strict;
use Cwd;

use File::Basename;

use File::Spec 0.82;
use lib File::Spec->catdir('lib');      # use our self to install
use lib File::Spec->catdir('t'); # use bundled Test::More
use Module::Build;
my $build = Module::Build->new
  (
   module_name => 'Graph::ChartSVG',
   dist_name => 'Graph-ChartSVG',
   dist_author => 'DULAUNOY Fabrice <fabrice at dulaunoy dot com>',
   dist_abstract => 'Wraper arround SVG to graph chart',
   license => 'gpl',
   requires => {
		'perl'           => '5.005_03',
		'SVG'  => 0,
		'SVG::Parser'  => 0,
		'Moose' => 0,
		'List::Util' => 0,
		'Hash::Merge' => 0, 
		'Data::Serializer' => 0,
	       },
   recommends => {
		  'Data::Dumper' => 0,
		 },
   sign => 0,
   create_readme => 1,

   auto_features => {
		     YAML_support =>
		     {
		      description => "Use YAML.pm to write META.yml files",
		      requires => { YAML => ' >= 0.35, != 0.49_01 ' },
		     },
		     manpage_support =>
		     {
		      description => "Create Unix man pages",
		      requires => { 'Pod::Man' => 0 },
		     },
		    },
  );

$build->create_build_script;

