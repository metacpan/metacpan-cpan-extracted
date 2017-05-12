# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name 'Gitosis-Config';
all_from 'lib/Gitosis/Config.pm';

# Specific dependencies
requires 'Moose'                      => '0.56';
requires 'MooseX::AttributeHelpers'   => '0.13';
requires 'MooseX::Types::Path::Class' => '0.04';
requires 'Config::INI'                => '0.013';

build_requires 'Test::More'      => '0.92';
build_requires 'Test::Exception' => '0.27';

no_index 'directory' => 'ex';

auto_set_repository;
auto_manifest;
WriteAll;
