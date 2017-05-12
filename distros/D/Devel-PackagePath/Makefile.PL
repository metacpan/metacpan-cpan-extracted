# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name 'Devel-PackagePath';
all_from 'lib/Devel/PackagePath.pm';

# Specific dependencies
requires 'Moose'                      => '0.64';
requires 'MooseX::Types::Path::Class' => '0.04';

build_requires 'Test::More' => '0.42';

no_index 'directory' => 'ex';

auto_install;
WriteAll;
