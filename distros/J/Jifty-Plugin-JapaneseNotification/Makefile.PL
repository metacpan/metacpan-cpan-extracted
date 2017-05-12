# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name            'Jifty-Plugin-JapaneseNotification';
all_from        'lib/Jifty/Plugin/JapaneseNotification.pm';

# Specific dependencies
#requires        'Carp'              => 0;
#requires        'File::Spec'        => '0.80';
#build_requires  'Test::More'        => '0.42';
#recommends      'Your::OtherModule' => '0.01';
#no_index        'directory'         => 'demos';
#install_script  'bin/myscript';

requires        'Encode'        => '2.11';
requires        'Jifty'         => '0.71129';

auto_install;
WriteAll;
