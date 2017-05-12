# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name            'Your-Module';
all_from        'lib/Your/Module.pm';

# Specific dependencies
requires        'Carp'              => 0;
requires        'File::Spec'        => '0.80';
build_requires  'Test::More'        => '0.42';
recommends      'Your::OtherModule' => '0.01';

no_index        'directory'         => 'demos';

install_script  'bin/myscript';

auto_install;
WriteAll;