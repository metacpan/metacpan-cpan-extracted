
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'DBIx::Class' => '0',
    'DBIx::Class::Core' => '0',
    'DBIx::Class::Schema' => '0',
    'DateTime' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'HTML::FormFu::Element::Text' => '0',
    'Module::Build' => '0.3601',
    'Test::More' => '0.88',
    'overload' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Render and validate ExtJS forms using HTML::FormFu',
  'dist_author' => [
    'Moritz Onken <onken@netcubed.de>'
  ],
  'dist_name' => 'HTML-FormFu-ExtJS',
  'dist_version' => '0.090',
  'license' => 'bsd',
  'module_name' => 'HTML::FormFu::ExtJS',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Carp' => '0',
    'Class::C3' => '0',
    'Data::Dumper' => '0',
    'Exporter' => '0',
    'HTML::FormFu' => '0.09',
    'HTML::FormFu::Element::Block' => '0',
    'HTML::FormFu::Util' => '0',
    'Hash::Merge::Simple' => '0',
    'JavaScript::Dumper' => '0',
    'Moose' => '0',
    'Scalar::Util' => '0',
    'Tie::Hash::Indexed' => '0',
    'utf8' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
