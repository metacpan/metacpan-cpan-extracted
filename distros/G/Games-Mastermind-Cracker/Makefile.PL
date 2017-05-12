# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name           'Games-Mastermind-Cracker';
all_from       'lib/Games/Mastermind/Cracker.pm';
githubmeta;

requires       'Moose';

build_requires 'Test::Exception';

auto_install;
WriteAll;

