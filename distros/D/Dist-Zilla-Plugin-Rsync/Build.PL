
use strict;
use warnings;

use Module::Build 0.3601;

my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.3601'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Dist::Zilla plugin to upload the distribution tarball using rsync.',
  'dist_author' => [
    'Tomáš Znamenáček <zoul@fleuron.cz>'
  ],
  'dist_name' => 'Dist-Zilla-Plugin-Rsync',
  'dist_version' => '0.1',
  'license' => 'perl',
  'module_name' => 'Dist::Zilla::Plugin::Rsync',
  'recommends' => {},
  'requires' => {
    'CLASS' => '0',
    'Dist::Zilla::Role::Releaser' => '0',
    'Moose' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
