# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name           'Gesture-Simple';
all_from       'lib/Gesture/Simple.pm';
githubmeta;

requires 'Any::Moose';
requires 'Scalar::Defer';

WriteAll;

